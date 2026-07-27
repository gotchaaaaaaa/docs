# Paiement (Stripe) - Documentation Technique

> **Derniere mise a jour** : Mai 2026 (commission absorbed 13% HT + acompte 30%/800 EUR conserve + frais Stripe absorbes par le prestataire)

---

## 1. Regles Metier (v2 — actuelles)

```javascript
// server/utils/payment-flow.js
PAYMENT_RULES = {
  COMMISSION_RATE_HT: 0.13,          // 13% HT (depuis avril 2026)
  GOTCHA_TVA_RATE: 0.20,
  DEPOSIT_RATE: 0.3,                 // Acompte 30% TTC a la signature
  DEPOSIT_THRESHOLD_HT: 800,         // Seuil declenchant l'acompte
  PROVIDER_TVA_RATE: 0.2,
  AUTO_VALIDATE_HOURS: 72,
  STRIPE_FEE_RATE: 0.015,
  STRIPE_FEE_FIXED_EUR: 0.25,
}

PAYMENT_RETRY_SCHEDULE_DAYS = [1, 3, 7];

// Modele *absorbed* (commit 42f78b7) :
// La commission Gotcha + les frais Stripe sont **deduits du transfer prestataire**
// via Stripe `application_fee_amount`.
// L'entreprise paie strictement le TTC prestataire (provider_total_ttc).
// Implementation : utils/payment-amounts.js → buildAbsorbedFeeChargeAmounts()

// Dispute auto-release
DISPUTE = {
  AUTO_RELEASE_DAYS: 31,             // disputes.auto_release_at = opened_at + 31j
}
```

### Flow Stripe en 2 phases

| Phase | When | `capture_method` | `application_fee_amount` | Amount |
|-------|------|-------------------|--------------------------|--------|
| 1 — Acompte | Signature devis (verify-otp) | `automatic` | **0** (acompte 100% au prestataire) | `deposit_ttc` (si `base_ht >= 800`, sinon 0) |
| 2 — Solde final | Validation rapport (`release-payment`) | `manual` (puis capture) | `commission_ttc + stripe_fee_ttc` | `provider_total_ttc - acompte` |
| 2bis — Supp | `final_adjustments_ht != 0` | `manual` | proportionnel | `final_adjustment_delta` |

---

## 2. Tables & Colonnes Cles

### `missions.payment_flows`

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | UUID | Identifiant unique |
| `profile_mission_id` | UUID (FK) | Reference vers `profile_missions` (1:1) |
| `initial_status` | TEXT | `pending` / `initial_preauthed` / `initial_captured` / `canceled` / `reversed` / `failed` |
| `final_status` | TEXT | `pending` / `final_preauthed` / `final_captured` / `final_not_required` / `recovery` / `canceled` / `failed` |
| `payment_status_summary` | TEXT | Resume combinant les 2 phases |
| `commission_rate_ht` | NUMERIC | Fixe a 0.13 (13% HT depuis avril 2026, anciennement `commission_rate_ttc = 0.125`) |
| `deposit_rate` | NUMERIC | Fixe a 0.30 (30% TTC, **toujours actif**) |
| `threshold_ht` | NUMERIC | Seuil declenchant l'acompte : 800 EUR HT (**toujours actif**) |
| `initial_amount_cents` | INTEGER | Montant initial total (acompte + commission) en centimes |
| `initial_provider_amount_cents` | INTEGER | Part prestataire de l'acompte |
| `initial_platform_amount_cents` | INTEGER | Commission plateforme |
| `final_amount_cents` | INTEGER | Montant final total (solde + commission supp) |
| `final_provider_amount_cents` | INTEGER | Solde prestataire |
| `final_platform_amount_cents` | INTEGER | Commission supplementaire |
| `deposit_captured_ttc_cents` | INTEGER | Acompte effectivement capture (TTC) |
| `commission_base_captured_ttc_cents` | INTEGER | Commission de base capturee |
| `commission_supp_captured_ttc_cents` | INTEGER | Commission supp capturee |
| `stripe_initial_payment_intent_id_enc` | TEXT | PI ID initial (chiffre) |
| `stripe_final_payment_intent_id_enc` | TEXT | PI ID final (chiffre) |
| `stripe_initial_charge_id_enc` | TEXT | Charge ID initial (chiffre) |
| `stripe_final_charge_id_enc` | TEXT | Charge ID final (chiffre) |
| `stripe_transfer_id_enc` | TEXT | Transfer ID (chiffre) |
| `retry_count` | INTEGER | Nombre de reessais en recovery |
| `next_retry_at` | TIMESTAMPTZ | Prochain reessai programme |
| `report_locked_at` | TIMESTAMPTZ | Date de verrouillage du rapport |
| `auto_validated_at` | TIMESTAMPTZ | Date d'auto-validation (seuil 72h) |
| `last_error_code` | TEXT | Dernier code erreur |
| `last_error_message` | TEXT | Dernier message erreur |

Tous les champs `_enc` ont un `_bidx` correspondant (blind index pour recherche sans dechiffrement).

### `missions.payment_events` (Journal d'audit)

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | UUID | Identifiant unique |
| `payment_flow_id` | UUID (FK) | Reference vers `payment_flows` |
| `phase` | TEXT | `initial` / `final` / `recovery` / `cancel` |
| `action` | TEXT | `preauth` / `capture` / `refund` / `reversal` / `retry` / `void` |
| `status` | TEXT | `success` / `failed` |
| `amount_total_cents` | INTEGER | Montant total implique |
| `amount_provider_cents` | INTEGER | Part prestataire |
| `amount_platform_cents` | INTEGER | Part plateforme |
| `stripe_payment_intent_id_enc` | TEXT | PI ID (chiffre) |
| `stripe_charge_id_enc` | TEXT | Charge ID (chiffre) |
| `error_code` | TEXT | Code erreur si echec |
| `error_message` | TEXT | Details de l'erreur |
| `metadata` | JSONB | Contexte additionnel |

### Colonnes liees dans `missions.profile_missions`

| Colonne | Type | Description |
|---------|------|-------------|
| `payment_status` | TEXT | Miroir de payment_flows pour l'UI |
| `payment_captured_at` | TIMESTAMPTZ | Date de capture finale |
| `payment_amount` | NUMERIC | Montant total paye par l'entreprise |
| `provider_validation_status` | TEXT | `pending` / `approved` / `rejected` |
| `hours_worked` | NUMERIC | Heures de base rapportees |
| `hours_supp_worked` | NUMERIC | Heures supplementaires rapportees |
| `commission_amount` | NUMERIC | Commission totale capturee |
| `amount_ht` | NUMERIC | Montant HT total |
| `tva_amount` | NUMERIC | TVA si provider assujetti |
| `amount_ttc_provider` | NUMERIC | Total TTC pour le prestataire |

---

## 3. Exemple de Calcul

### Phase initiale (signature contrat entreprise)

Mission : 40 heures estimees a 25 EUR/h, prestataire assujetti TVA :

```
1. Montant HT base         = 40h x 25 EUR = 1 000 EUR HT
2. Acompte applicable       = Oui (1 000 >= 800 EUR)
   - Acompte HT            = 1 000 x 0.30 = 300 EUR HT
   - Acompte TVA           = 300 x 0.20 = 60 EUR
   - Acompte TTC           = 360 EUR
3. Commission (sur HT base) = 1 000 x 0.125 = 125 EUR
4. Total pre-autorise       = 360 + 125 = 485 EUR
   - Part prestataire       = 360 EUR
   - Part plateforme        = 125 EUR
```

### Phase finale (apres rapport)

Rapport : 38h base + 2h supplementaires a 31.25 EUR/h :

```
1. Base HT                  = 38h x 25 EUR = 950 EUR HT
2. Supp HT                  = 2h x 31.25 EUR = 62.50 EUR HT
3. Total HT prestataire     = 1 012.50 EUR (TJM + heures supp + prep + additional fees)
4. TVA prestataire          = 1 012.50 x 0.20 = 202.50 EUR (si regime_tva)
5. Total TTC                = 1 215 EUR
6. Deja paye (acompte)      = 360 EUR
7. Solde prestataire        = 1 215 - 360 = 855 EUR
8. Commission supp          = 62.50 x 0.125 = 7.81 EUR (sur HT supp)
9. Total charge final       = 855 + 7.81 = 862.81 EUR
```

---

## 4. Flux Complet en 4 Phases

### Phase 1 : Prelevement Initial (Signature Devis par l'Entreprise)

**Declencheur** : Verification OTP entreprise dans `/api/contract/company/verify-otp`

**Missions payantes** : Le devis est le document engageant. Seule l'entreprise signe.

1. OTP de l'entreprise verifie
2. Calcul des heures estimees + preparation -> `computeInitialPayment()`
3. Determination de l'acompte (si total HT >= 800 EUR) ou totalite
4. Creation du PaymentIntent Stripe (prelevement immediat) :
   ```javascript
   stripe.paymentIntents.create({
     amount: totalAmountCents,       // acompte TTC + commission (ou totalite + commission)
     currency: "eur",
     payment_method_types: ["card"],
     customer: stripeCustomerId,
     payment_method: defaultPaymentMethodId,
     confirm: true,
     off_session: true,
     application_fee_amount: platformAmountCents,  // commission Gotcha
     transfer_data: { destination: providerStripeId },
     metadata: { profile_mission_id, mission_id, phase: "initial", ... }
   })
   ```
5. Verifier le statut = `succeeded` (paiement immediat, pas de capture manuelle)
6. Creer l'enregistrement `payment_flows` : `initial_status = "initial_captured"`
7. Enregistrer le `payment_event`
8. `profile_missions.payment_status = "initial_captured"`, `state = "assigned"`
9. Tous les autres candidats passent a `rejected`

**Missions benevoles** : Convention de benevolat signee par les deux parties (entreprise puis prestataire). Pas de paiement.

### Phase 2 : Rapport de Mission par le Prestataire

**Declencheur** : Soumission du rapport dans `/api/missions/provider-submit-report`

Le **prestataire** declare ses heures apres la mission :

1. Verification : role provider, mission `state = assigned`, rapport pas deja soumis
2. Update direct `profile_missions` :
   ```javascript
   report_submitted_at: new Date().toISOString(),
   report_hours_worked: hoursWorked,
   report_hours_supp: hoursSupp,
   report_comment: comment,
   provider_validation_status: "approved"  // presta soumet lui-meme
   ```
3. `payment_status = "awaiting_company_payment"`
4. `popup_mission_finished = false` (reset pour re-afficher le popup entreprise)
5. Notification email + push a l'entreprise
6. Broadcast realtime `report_submitted` pour mise a jour temps reel

### Phase 3 : Paiement Direct par l'Entreprise

**Declencheur** : Entreprise glisse pour payer dans `/api/missions/company-direct-pay`

**Missions benevoles** : pas de paiement, `state -> completed` directement

**Missions payantes** :
1. Verification : role entreprise, rapport soumis, pas deja paye
2. Calcul du montant final : `computeFinalPayment()` avec heures du rapport
3. Paiement direct (pas de pre-autorisation) :
   ```javascript
   stripe.paymentIntents.create({
     amount: finalCalc.totalWithFeesAmountCents,
     currency: "eur",
     // PAS de capture_method: "manual" = paiement immediat
     payment_method_types: ["card"],
     customer: stripeCustomerId,
     payment_method: defaultPaymentMethodId,
     confirm: true,
     off_session: true,
     application_fee_amount: finalCalc.applicationFeeAmountCents,
     transfer_data: { destination: providerStripeId },
     metadata: { profile_mission_id, mission_id, phase: "final", ... }
   })
   ```
4. Verification : `paymentIntent.status === "succeeded"`
5. Mise a jour BDD :
   ```javascript
   // payment_flows
   final_status: "final_captured"
   final_amount_cents: totalCents

   // profile_missions
   payment_status: "final_captured"
   payment_captured_at: new Date()
   state: "completed"
   provider_validation_status: "approved"
   hours_worked, hours_supp_worked, commission_amount
   amount_ht, tva_amount, amount_ttc_provider
   ```
6. Declenchement facturation :
   - Appel `/api/invoices/generate` (auth interne)
   - Appel `/api/invoices/send-emails`

**Apercu de facture** : Avant de payer, l'entreprise (et le prestataire dans son recap) peuvent voir un apercu PDF via `/api/invoices/preview`

---

## 5. Mecanisme de Recovery

```javascript
async function scheduleRecovery({
  supabase, profileMissionId, flow, error, amounts...
}) {
  // Incrementer retry_count
  // Calculer next_retry_at selon PAYMENT_RETRY_SCHEDULE_DAYS [1, 3, 7]
  // payment_flows.final_status = "recovery"
  // Enregistrer payment_event avec erreur
  // profile_missions.payment_status = "recovery"
  // Envoyer alerte admin
}
```

**Planning de reessais** : 1 jour -> 3 jours -> 7 jours
Apres 3 tentatives echouees -> intervention manuelle requise

**Cron de reessai** : `/api/cron/retry-final-payments` (toutes les heures)

---

## 6. Webhook Stripe

**Fichier** : `/server/api/stripe/webhook.js`

| Evenement | Action |
|-----------|--------|
| `payment_intent.succeeded` | Mettre a jour payment_flows + profile_missions, ajouter payment_event |
| `payment_intent.payment_failed` | Declencher recovery si initial, ou retry si final |
| `payment_intent.canceled` | Enregistrer evenement de reversal |
| `charge.refunded` | Enregistrer evenement de remboursement |
| `charge.dispute.created` | Alerter admin, marquer en litige |
| `charge.dispute.closed` | Gagne : `final_captured` / Perdu : `dispute_lost` |
| `account.updated` | Mettre a jour `providers.verified` depuis l'etat des virements Connect |
| `payout.failed` | Alerter admin |

**Idempotence** : Table `stripe_webhook_events` pour tracker les evenements deja traites par `stripe_event_id`.

---

## 7. Stripe Connect (Onboarding Prestataire)

### Creation de compte (`/api/stripe/create-connect-account`)

1. Creer un token de compte avec les donnees personnelles fiables (sans adresse de facturation)
2. Creer un compte Custom :
   ```javascript
   stripe.accounts.create({
     type: "custom",
     country: "FR",
     account_token: tokenId,
     capabilities: {
       transfers: { requested: true }
     },
     business_profile: { mcc: "5734", url: providerWebsite }
   })
   ```
3. Chiffrer et stocker le Stripe account ID dans `providers.stripe_id_enc`
4. Laisser l'onboarding hosted Stripe collecter l'adresse personnelle, l'IBAN et les documents KYC

Le token client impose `business_type: "individual"`. Avant toute ecriture en base, le serveur verifie le type du compte retourne par Stripe et supprime immediatement tout compte non individuel.

### Lien d'onboarding (`/api/stripe/create-account-link`)

- Recupere le Stripe account ID (dechiffre)
- Cree un AccountLink `account_onboarding` pour les informations manquantes ou `account_update` pour corriger les donnees existantes
- Redirige vers l'interface Stripe puis retour dans l'app

La collecte des comptes bancaires externes doit etre activee dans les reglages Connect Stripe. Gotcha ne collecte ni ne stocke l'IBAN.

### Statut de versement (`/api/stripe/account-requirements`)

- `payoutStatus` distingue `missing`, `restricted`, `pending` et `ready`
- `isPayoutReady` vaut `true` uniquement si `capabilities.transfers === "active"` et `payouts_enabled === true`
- `availableActions` indique s'il faut ouvrir `account_onboarding`, `account_update`, attendre ou contacter le support
- `issues` expose le code Stripe, le champ concerne et une resolution en francais
- `upcomingRequirements` contient les exigences futures, affichees sans bloquer les missions ni les paiements
- `isFullyVerified` et l'ancien `status` restent des alias temporaires de compatibilite

Seul le webhook `account.updated` met a jour `providers.verified`.

---

## 8. Endpoints API

### Stripe

| Endpoint | Methode | Description |
|----------|---------|-------------|
| `/api/stripe/create-connect-account` | POST | Creation compte Connect prestataire |
| `/api/stripe/create-account-link` | POST | Lien d'onboarding Stripe |
| `/api/stripe/check-payment-method` | GET | Verifier que l'entreprise a une carte |
| `/api/stripe/release-payment` | POST | Capture finale du paiement |
| `/api/stripe/webhook` | POST | Reception evenements Stripe |
| `/api/stripe/check-identity-status` | GET | Adaptateur historique vers le statut KYC Connect |
| `/api/stripe/create-verification-session` | POST | Adaptateur historique vers l'onboarding Connect |
| `/api/stripe/upload-id` | POST | Endpoint retire (HTTP 410, upload chez Stripe) |
| `/api/stripe/account-requirements` | GET | Exigences d'onboarding restantes |

### Missions & Paiement

| Endpoint | Methode | Description |
|----------|---------|-------------|
| `/api/missions/submit-report` | POST | Soumission rapport + pre-auth finale |
| `/api/missions/[id]/payment-status` | GET | Statut du flux de paiement |

### Crons

| Endpoint | Methode | Description | Frequence |
|----------|---------|-------------|-----------|
| `/api/cron/auto-validate-reports` | POST | Auto-validation rapports apres 72h | Toutes les heures |
| `/api/cron/retry-final-payments` | POST | Reessai des captures echouees | Toutes les heures |
| `/api/cron/cancel-expired-signatures` | POST | Nettoyage deadlines expirees | Toutes les heures |

---

## 9. Machine a Etats

### Statuts du payment_flow

```
PHASE INITIALE (signature devis entreprise) :
  pending -> initial_captured (prelevement immediat)
          -> failed

PHASE FINALE (paiement direct entreprise apres rapport) :
  pending -> final_captured (prelevement immediat)
          -> final_not_required (si montant <= 0)
          -> recovery -> (reessai apres 1/3/7 jours)
          -> failed

ANNULATION :
  any -> canceled

Note : les etats "initial_preauthed" et "final_preauthed" existent
dans le schema DB (ancien flow pre-auth/capture) mais ne sont plus
utilises par le flux actuel (prelevement immediat).
```

### Statuts profile_missions.payment_status

```
null -> initial_captured (signature devis)
     -> awaiting_company_payment (rapport soumis)
     -> final_captured (entreprise paye)
     -> recovery (si echec paiement, boucle de reessai)
     -> dispute (revue admin)
     -> disputed / dispute_lost
```

### Validation rapport

```
Prestataire soumet son rapport -> provider_validation_status = "approved"
  -> payment_status = "awaiting_company_payment"
  -> Entreprise paye ou conteste
```

---

## 10. Chiffrement

| Champ | Description |
|-------|-------------|
| `providers.stripe_id_enc` | Stripe Connect account ID du prestataire |
| `companies.stripe_customer_id_enc` | Stripe Customer ID de l'entreprise |
| `payment_flows.stripe_*_intent_id_enc` | PaymentIntent IDs |
| `payment_flows.stripe_*_charge_id_enc` | Charge IDs |
| `payment_flows.stripe_transfer_id_enc` | Transfer ID |
| `payment_events.stripe_*_id_enc` | IDs Stripe au niveau evenement |

Tous les champs chiffres ont un **blind index** (`_bidx`) pour des recherches rapides sans dechiffrement (utilise dans le webhook).

---

## 11. Gestion des Cas Limites

| Situation | Comportement |
|-----------|-------------|
| Mission benevole (`benevole = true`) | Aucun paiement, marque `not_required` |
| Heures supp rapportees | Final pre-auth calcule avec solde + commission supp |
| Litige (dispute) | Webhook alerte admin, marque comme `disputed` |
| Litige gagne | Auto-complete vers `final_captured` |
| Litige perdu | Marque `dispute_lost`, intervention manuelle |
| Fonds insuffisants / capture echouee | Entre en `recovery`, reessai a 1, 3, 7 jours |
| Apres 3 tentatives echouees | Intervention manuelle requise |
| Deadline signature depasse | Contrat expire, annulation possible par l'entreprise |
| Provider sans regime TVA | Pas de TVA appliquee, montants en HT |
| Provider avec regime TVA | TVA 20% ajoutee a tous les montants |
| No-show (presta absent) | Entreprise a 30 min pour declarer -> remboursement initial, annulation mission, avertissement presta |
| Frais Stripe | Preleves par Stripe en sus (~1.5% + 0.25 EUR/tx), non inclus dans la commission Gotcha |

---

## 12. Variables d'Environnement

```bash
# Stripe
STRIPE_SECRET_KEY=sk_test_...
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Chiffrement
DATA_ENCRYPTION_KEY=...
BLIND_INDEX_KEY=...

# Notifications admin
ADMIN_EMAIL=hello@gotchaaaa.com
SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS
```

---

## 13. Timeline Exemple

```
Jour 0 - Mission postee
  Mission 40h @ 25 EUR/h, provider avec TVA
  Montant estime : 485 EUR (360 EUR acompte + 125 EUR commission)

Jour 1 - Candidature & Signature du devis
  10:00  Provider postule (PostulerDrawer, 6 etapes)
  11:00  Entreprise signe le devis (OTP)
         -> Prelevement immediat : 485 EUR
         -> payment_flows: initial_status = "initial_captured"
         -> profile_missions.state = "assigned"
         -> Autres candidats rejetes

Jour 3 - Mission terminee
  17:00  Prestataire soumet son rapport : 38h base + 2h supp
         -> payment_status = "awaiting_company_payment"
         -> Notification entreprise (email + push)

Jour 4 - Paiement par l'entreprise
  10:00  Entreprise consulte le rapport + apercu facture
         Entreprise glisse pour payer
         -> Prelevement immediat : 862.81 EUR (855 solde + 7.81 commission supp)
         -> payment_flows: final_status = "final_captured"
         -> profile_missions.state = "completed"
         -> Facturation declenchee (2 factures generees + envoyees)

Jour 5
  Provider recoit le paiement Stripe (payout quotidien)
  Total recu prestataire   : 360 + 855 = 1 215 EUR TTC
  Total garde plateforme   : 125 + 7.81 = 132.81 EUR
  Total facture entreprise : 485 + 862.81 = 1 347.81 EUR
```

---

## 14. Fichiers Cles

| Fichier | Lignes | Description |
|---------|--------|-------------|
| `server/api/stripe/release-payment.js` | ~694 | Capture finale avec recovery |
| `server/api/stripe/webhook.js` | ~401 | Traitement evenements Stripe |
| `server/api/stripe/create-connect-account.js` | ~224 | Creation compte Connect |
| `server/api/contract/company/verify-otp.post.js` | ~300 | Signature entreprise + pre-auth initiale |
| `server/api/contract/provider/verify-otp.post.js` | ~300 | Signature prestataire |
| `server/api/missions/submit-report.post.js` | ~300 | Pre-auth finale + verrouillage rapport |
| `server/utils/payment-flow.js` | ~117 | Regles metier & calculs |
| `server/utils/payment-flow-store.js` | ~117 | CRUD BDD pour payment_flows |
| `server/utils/payment-crypto.js` | - | Chiffrement Stripe IDs |
| `components/entreprise/PaymentRecapDrawer.vue` | ~739 | UI recap paiement |
| `database/migrations/add_non_escrow_payment_flows.sql` | ~172 | Schema payment_flows |
