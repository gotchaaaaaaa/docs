# Paiement - Guide Fonctionnel

> **Derniere mise a jour** : Mai 2026 (commission absorbed 13% HT + acompte 30%/800 EUR conserve + TJM + half-day + additional fees)

---

## A quoi ca sert ?

Le systeme de paiement gere l'ensemble du flux financier entre l'entreprise (qui paye) et le prestataire (qui est paye), avec Gotcha comme intermediaire percevant une commission. Tout passe par **Stripe Connect** : charge directe a la signature du devis (acompte ou total), puis pre-autorisation + capture differee a la validation du rapport.

---

## Vue d'ensemble

Le paiement se fait en **deux temps** :

1. **A la signature du devis (acompte ou total)** :
   - Si `baseHt >= 800 EUR HT` : acompte de **30% TTC** preleve **directement** sur la CB de l'entreprise (`capture_method: 'automatic'`)
   - Sinon (`baseHt < 800 EUR HT`) : acompte de 0 (pas de prelevement a la signature)
   - Pas d'`application_fee` a ce stade : la totalite de l'acompte est transferee au prestataire
2. **A la validation du rapport (pre-auth + capture)** :
   - `capture_method: 'manual'` (pre-autorisation Stripe)
   - Montant = solde restant TTC (`providerTotalTtc - acompte_deja_capture`)
   - `application_fee_amount` = **commission 13% HT + TVA + frais Stripe** (deduits du transfer vers le prestataire)

> **Changement important (commits `42f78b7`, `acca872`)** :
> - **Inversion du modele de commission** : la commission n'est plus ajoutee a ce que paye l'entreprise — elle est **deduite du montant prestataire** (modele *absorbed*). L'entreprise paie le TTC prestataire et c'est tout. Stripe retient la commission pour Gotcha lors du transfer.
> - La commission passe de 12.5% TTC a **13% HT** + TVA 20% (avril 2026, `provider_commission_model_13_percent.sql`).
> - Les **frais Stripe** sont egalement absorbes par le prestataire (deduits du transfer via application fee).
> - Le prestataire ne signe plus le devis (depuis Mars). Seule l'entreprise signe via OTP, ce qui declenche le prelevement de l'acompte.

---

## Les acteurs

| Acteur | Role dans le paiement |
|--------|----------------------|
| **Entreprise** | Paye le **TTC prestataire** uniquement (pas de ligne "commission" ajoutee). Acompte 30% si `baseHt >= 800 EUR HT`, solde restant a la validation du rapport |
| **Prestataire** | Recoit `montant_prestataire_TTC - commission_TTC - frais_Stripe_TTC` sur son compte Stripe Connect (Custom). C'est lui qui absorbe la commission |
| **Gotcha** | Percoit une commission de **13% HT + TVA** via Stripe `application_fee_amount` (deduite du transfer prestataire) ; absorbe egalement les frais Stripe via la meme mecanique |

---

## Les regles de calcul

### Commission Gotcha (13% HT)

- **13% HT** du montant prestataire HT (TJM × jours factures + heures de preparation + frais additionnels)
- TVA 20% en sus (Gotcha est toujours assujetti)
- Implementation : `utils/payment-amounts.js` (`buildGotchaCommissionAmounts`)
- Constantes : `GOTCHA_COMMISSION_RATE_HT = 0.13`, `GOTCHA_TVA_RATE = 0.20`

### Frais de transaction Stripe (refactures a l'entreprise)

- 1.5% du TTC + 0.25 EUR HT
- TVA 20% en sus
- Affiches sur la facture de commission Gotcha (colonne dediee `stripe_fee_amount` sur `missions.invoices`)
- Cf. `update_commission_invoice_transaction_fee_ht_tva.sql`

### TJM et regle demi-journee

- Le prestataire facture en **TJM (HT)** depuis `migrate_to_tjm.sql`
- Conversion : 1 jour = 8h (`HOURS_PER_DAY` dans `utils/rate-calculation.js`)
- **Regle demi-journee** (`update_billing_to_half_day_rule.sql`) : `billing_days = ceil(hours / 4) * 0.5`
  - 1h-4h → 0.5j, 4.5h-8h → 1j, 8.5h-12h → 1.5j, etc.
- Le prestataire peut overrider le palier dans le PostulerDrawer (etape TJM)
- Multi-jour : `billing_days = nombre de jours de mission`

### Temps de preparation

- Indique soit par l'entreprise (`missions.has_preparation_time` + `preparation_hours`), soit ajoute par le prestataire dans son devis
- Tarif : meme TJM ramene a l'heure (`daily_rate / 8`)
- Ligne distincte sur le devis et la facture

### Frais additionnels (additional_fee_lines)

- Le prestataire peut ajouter des lignes libres sur son devis (etape 5 du PostulerDrawer)
- Format : `[{ description, amount_ht }]` (max 20 lignes, 160 caracteres, 2 decimales)
- Validation : `utils/additional-fees.js`
- Inclus dans le calcul de la commission et du pre-auth initial

### Ajustements finaux (final_adjustment_lines)

- Ajoutes par le prestataire **a la soumission de son rapport** post-mission
- Generent une pre-auth supplementaire **integree dans** `/api/missions/submit-report.post.js` (l'endpoint historique `/api/stripe/create-supp-hours-preauth` est obsolete et renvoie une erreur)
- Peuvent etre negatifs (avoir/penalite)
- Generent une **facture de commission FINALE** distincte

### Heures supplementaires

- TJM majore : `daily_rate_supp` (defaut `daily_rate * 1.25`)
- Memes regles half-day appliquees aux heures supp

### TVA prestataire

- Si `regime_tva = true` : TVA 20% sur la facture prestataire
- Sinon : mention "TVA non applicable (art. 293B du CGI)"

---

## Formules de calcul

Implementation : `server/utils/payment-flow.js` (`computeInitialPayment`, `computeFinalPayment`) + `utils/payment-amounts.js` (`buildAbsorbedFeeChargeAmounts`).

```
# Montant prestataire HT (base devis)
base_ht = daily_rate * billing_days(estimated_hours + preparation_hours)
        + additional_fees_ht
provider_tva_rate = regime_tva ? 0.20 : 0
base_tva = base_ht * provider_tva_rate
base_ttc = base_ht + base_tva

# ---- PHASE 1 : Charge directe a la signature du devis ----
deposit_applicable = base_ht >= 800   # DEPOSIT_THRESHOLD_HT
deposit_ht  = deposit_applicable ? base_ht  * 0.30 : 0
deposit_tva = deposit_applicable ? base_tva * 0.30 : 0
deposit_ttc = deposit_ht + deposit_tva

# Charge directe via Stripe :
#   amount = deposit_ttc   (l'entreprise paie cet acompte)
#   transfer_data.destination = compte Connect prestataire
#   application_fee_amount = 0  → tout l'acompte est transfere au prestataire
amount_charged_initial = deposit_ttc

# ---- PHASE 2 : Pre-auth + capture finale ----
final_adjustments_ht = sum(final_adjustment_lines.amount_ht)   # peut etre negatif
total_ht  = base_ht + final_adjustments_ht                     # HT effectif post-mission
total_tva = total_ht * provider_tva_rate
provider_total_ttc = total_ht + total_tva

# Restant a payer par l'entreprise :
provider_due_ttc = max(provider_total_ttc - deposit_ttc, 0)

# Commission Gotcha (13% HT) sur la TOTALITE du HT final :
commission_ht  = total_ht * 0.13
commission_tva = commission_ht * 0.20
commission_ttc = commission_ht + commission_tva

# Frais Stripe (refactures via application_fee, absorbes par le prestataire)
stripe_fee_ht  = (provider_due_ttc * 0.015) + 0.25
stripe_fee_tva = stripe_fee_ht * 0.20
stripe_fee_ttc = stripe_fee_ht + stripe_fee_tva

# PaymentIntent final :
#   amount = provider_due_ttc
#   capture_method = 'manual'
#   application_fee_amount = commission_ttc + stripe_fee_ttc
#   transfer_data.destination = compte Connect prestataire
# → Le prestataire recoit (provider_due_ttc - commission_ttc - stripe_fee_ttc) sur son compte
```

**Recap argent recu par le prestataire** (sur la totalite de la mission) :

```
total_recu_par_prestataire = deposit_ttc                            (acompte 100% transfere)
                           + (provider_due_ttc - commission_ttc - stripe_fee_ttc)   (solde net)
                           = provider_total_ttc - commission_ttc - stripe_fee_ttc
```

**Recap argent paye par l'entreprise** :

```
total_paye_par_entreprise = deposit_ttc + provider_due_ttc = provider_total_ttc
```

L'entreprise paie strictement le TTC prestataire, sans ligne de commission ajoutee. La commission est portee comme `application_fee_amount` Stripe et deduite du transfer au prestataire.

---

## Deroulement detaille

### Phase 1 : Charge directe a la signature du devis (acompte)

Quand l'entreprise signe le devis (verify-otp OK) — cf. `server/api/devis/company/verify-otp.post.js` :

1. Le systeme calcule `deposit_ttc` (30% TTC si `base_ht >= 800 EUR`, sinon 0)
2. Si `deposit_ttc > 0`, un `PaymentIntent` Stripe est cree avec :
   - `amount = deposit_ttc`
   - `capture_method: 'automatic'` (charge directe, **pas** pre-auth)
   - `transfer_data.destination = compte Connect prestataire`
   - **Pas** d'`application_fee_amount` → la totalite de l'acompte est transferee au prestataire (Gotcha ne prend rien a ce stade)
3. La carte est **debitee immediatement** (not bloquee)
4. `profile_missions.state` → `assigned`, autres candidats → `rejected`
5. Snapshot : `stripe_initial_payment_intent_id` chiffre + blind index
6. **Facture de commission initiale** generee (la commission portera sur le HT total a la phase 2)

### Phase 2 : Rapport de mission par le prestataire

Le **prestataire** soumet son rapport de fin de mission :

1. Il declare les heures travaillees (base + supp)
2. Il peut ajouter des `final_adjustment_lines` (frais kilometriques, materiel consomme, remise, etc.)
3. Il voit un recap avec **apercu de la facture prestataire**
4. SlideButton pour soumettre → `provider_submit_report` RPC
5. Etats mis a jour : `report_submitted_at`, `provider_validation_status = 'approved'`, `payment_status = 'awaiting_company_payment'`
6. L'entreprise est notifiee (push + email + realtime)

### Phase 3 : Validation et paiement final par l'entreprise

L'entreprise revoit le rapport — cf. `server/api/stripe/release-payment.js` :

1. Apercu de la facture prestataire + facture commission finale eventuelle
2. **Si elle valide** :
   - `POST /api/missions/validate-report` (approuve)
   - `POST /api/stripe/release-payment` :
     - Cree un nouveau `PaymentIntent` avec `amount = provider_due_ttc`, `capture_method: 'manual'` (pre-auth)
     - `application_fee_amount = commission_ttc + stripe_fee_ttc` (calcule sur le HT total)
     - `transfer_data.destination = compte Connect prestataire`
     - Capture immediate du PaymentIntent → l'entreprise paie `provider_due_ttc`
     - Stripe transfere `provider_due_ttc - application_fee_amount` au prestataire
     - Gotcha recupere `application_fee_amount` via Stripe Connect
   - Si `final_adjustments_ht != 0` : un PaymentIntent supplementaire identique mais sur le delta
   - Generation des factures : `PROVIDER` + `COMMISSION_FINAL` (si applicable)
3. **Si elle conteste** :
   - Ouverture d'un signalement (`missions.disputes` avec `opened_by = 'company'`)
   - Capture en attente via `/api/stripe/capture-on-dispute` (selon decision Gotcha)

---

## Exemple complet

Mission 1 jour, TJM 1000 EUR HT, 2h de preparation, 50 EUR de frais additionnels (peage), prestataire assujetti TVA, rapport conforme (pas d'ajustement).

```
# Base devis
base_ht  = 1000 * 1 + 2 * (1000/8) + 50   = 1000 + 250 + 50 = 1300 EUR
base_tva = 1300 * 0.20                     = 260 EUR
base_ttc = 1560 EUR

# Acompte (base_ht >= 800 → applicable)
deposit_ht  = 1300 * 0.30  = 390 EUR
deposit_tva =  260 * 0.30  =  78 EUR
deposit_ttc            = 468 EUR

# ---- Phase 1 : signature devis ----
# L'entreprise paie immediatement 468 EUR
# Le prestataire recoit 468 EUR (pas de commission a ce stade)

# ---- Phase 2 : rapport post-mission valide tel quel ----
total_ht  = base_ht  = 1300 EUR
total_tva = base_tva =  260 EUR
provider_total_ttc   = 1560 EUR

provider_due_ttc = 1560 - 468 = 1092 EUR

commission_ht  = 1300 * 0.13      = 169.00 EUR
commission_tva = 169.00 * 0.20    =  33.80 EUR
commission_ttc                    = 202.80 EUR

stripe_fee_ht  = 1092 * 0.015 + 0.25 = 16.63 EUR
stripe_fee_tva = 16.63 * 0.20        =  3.33 EUR
stripe_fee_ttc                       = 19.96 EUR

application_fee_amount = 202.80 + 19.96 = 222.76 EUR

# PaymentIntent final : amount = 1092 EUR, application_fee_amount = 222.76 EUR
# L'entreprise paie : 1092 EUR
# Transfer Stripe : 1092 - 222.76 = 869.24 EUR vers le prestataire
# Gotcha recupere : 222.76 EUR (incluant les frais Stripe)

# ---- Totaux ----
Entreprise paye total :    468 + 1092         = 1560 EUR (= provider_total_ttc, aucune commission ajoutee)
Prestataire recoit total : 468 + 869.24       = 1337.24 EUR (1560 - 222.76 application fee)
Gotcha conserve net     : 202.80 (commission) + 19.96 (stripe fees encaisses, deduits par Stripe) ≈ 202.80 EUR HT/TTC + retrocession des frais Stripe au profit de Stripe
```

> En pratique, sur l'application_fee_amount, Stripe preleve ses **propres frais** (~1.5% + 0.25 EUR par transaction). Le calcul ci-dessus integre une "ligne stripe_fee" pour que Gotcha conserve une marge nette proche de 13% du HT.

---

## Cas particuliers

### Annulation (cancel_mission v2 document-aware)

Migration : `cancel_mission.sql` + `009-cancel-mission-document-aware.sql`.

- **Regle 24h** : annulation impossible moins de 24h avant le `start_time`
- **Annulation par le prestataire (state = assigned)** : mission → `unassigned`, contrat → `canceled`, refund integral, log dans `providers.cancellation_logs` avec snapshot du contrat et du payment_flow
- **Annulation par l'entreprise** : mission → `canceled`, profile_missions → `canceled`, refund integral
- **Avant capture** : le PaymentIntent est juste annule (pas de debit reel)
- **Apres capture** : Stripe Refund vers la CB de l'entreprise

### Disputes / Signalements

- **Provider-initiated** (commit `0cda107`) : le prestataire peut ouvrir un signalement en cours ou en fin de mission via `/api/missions/open-problem-report`
- **Company-initiated** : l'entreprise conteste le rapport prestataire
- Table `missions.disputes` avec `auto_release_at = opened_at + 31 jours`
- Apres 31 jours sans resolution, liberation auto du paiement (cron)

### No-show

Geres via le flow disputes / signalements (plus de window 30 minutes hardcodee). L'entreprise ouvre un signalement avec motif `no_show`, le paiement est mis en pause, Gotcha tranche.

### Missions benevoles

- Aucun paiement, aucune commission
- Flow : 2 signatures (entreprise puis prestataire) sur la **convention de benevolat**
- Status payment : N/A

---

## Inscription du prestataire a Stripe Connect

1. Cote client : un `accountTokenId` est genere via Stripe.js avec prenom, nom, date de naissance, email et telephone. L'adresse de facturation Gotcha n'est jamais envoyee comme adresse personnelle.
2. `POST /api/stripe/create-connect-account` → creation du compte Custom avec la seule capacite `transfers`.
3. `POST /api/stripe/create-account-link` → lien Stripe `account_onboarding` pour le KYC, l'adresse personnelle, l'IBAN et les justificatifs.
4. En cas de donnee existante incorrecte, un lien `account_update` permet au prestataire de la corriger.
5. Le statut Connect est interroge via `/api/stripe/account-requirements`. Les anciens endpoints Stripe Identity ne sont que des adaptateurs de compatibilite.

**Configuration Stripe obligatoire :** dans les reglages Connect, activer la collecte des comptes bancaires externes pour les comptes dont les exigences sont collectees par la plateforme. Sans ce reglage, l'onboarding hosted ne demandera pas l'IBAN.

Les `stripe_id` sont **chiffres** en base + blind-indexes. L'IBAN et les documents KYC sont collectes directement par Stripe et ne transitent pas par Gotcha.

---

## En cas de probleme de paiement

### Echec de la capture finale

Cron `retry-final-payments` :
- 1er reessai apres 1 jour
- 2eme reessai apres 3 jours
- 3eme reessai apres 7 jours
- Admin alerte a chaque echec → intervention manuelle apres 3 echecs

### Litige bancaire (chargeback)

Webhook Stripe `charge.dispute.created` → admin alerte, mission marquee en litige.

---

## Recapitulatif des montants

### Ce que paye l'entreprise (modele absorbed)

| Moment | Montant |
|--------|---------|
| Signature du devis | Acompte 30% TTC du provider_amount si `base_ht >= 800 EUR`, sinon 0 |
| Validation du rapport | `provider_due_ttc = provider_total_ttc - acompte_deja_paye` |
| **Total** | `provider_total_ttc` (le TTC prestataire, **sans ligne de commission ajoutee**) |

### Ce que recoit le prestataire

| Moment | Montant |
|--------|---------|
| Acompte | 100% de l'acompte transfere par Stripe (pas d'application fee a ce stade) |
| Solde final | `provider_due_ttc - application_fee_amount` ou `application_fee_amount = commission_ttc + stripe_fee_ttc` |
| **Total net** | `provider_total_ttc - commission_ttc - stripe_fee_ttc` |

### Ce que garde Gotcha

| Moment | Montant |
|--------|---------|
| Acompte | 0 (Gotcha attend la phase finale pour percevoir sa commission) |
| Capture finale | `application_fee_amount` = commission 13% HT + TVA + frais Stripe HT + TVA (sur HT total) |

> **Modele "absorbed"** (`buildAbsorbedFeeChargeAmounts` dans `utils/payment-amounts.js`) : c'est le prestataire qui finance la commission Gotcha (et les frais Stripe), pas l'entreprise. L'entreprise voit un prix unique TTC sur le devis (le prix prestataire).

---

## Timeline typique

```
Jour 0  - Mission postee par l'entreprise
Jour 1  - Prestataire postule + envoie devis (TJM + preparation + additional fees)
        - Entreprise signe le devis (OTP)
          → Pre-auth Stripe : 499.70 EUR BLOQUES sur la CB (pas debites)
          → Facture commission initiale generee
Jour 3  - Mission terminee
        - Prestataire soumet son rapport (heures + final_adjustments)
          → Notification entreprise
Jour 4  - Entreprise valide le rapport
          → Capture du PaymentIntent initial (debit reel)
          → Pre-auth + capture supplementaire si final_adjustments != 0
          → Transfer vers compte Connect prestataire
          → Facture prestataire + commission finale generees + envoyees
Jour 5  - Prestataire recoit le virement (Stripe payout)
```

---

## Etats du paiement (payment_flows / profile_missions)

| `initial_status` / `final_status` | Description |
|--------|-------------|
| `pending` | Avant signature devis |
| `preauth_created` | PaymentIntent cree, en attente de capture |
| `initial_captured` | PaymentIntent initial capture (escrow libere) |
| `final_captured` | PaymentIntent supplementaire capture (si applicable) |
| `released` | Refund vers entreprise (annulation) |
| `failed` | Echec capture (cron retry) |
| `refunded` | Remboursement integral |

Champ aggrege : `payment_flows.payment_status_summary`.

---

## Lien avec les autres flux

- **Devis** : pre-authorisation declenchee par la signature du devis (voir `../contrats/fonctionnement.md`)
- **Facturation** : factures generees a la signature (commission initiale) puis a la capture finale (prestataire + commission finale) (voir `../facturation/fonctionnement.md`)
- **Disputes** : tout signalement met le payment en pause (voir glossaire `dispute`)
