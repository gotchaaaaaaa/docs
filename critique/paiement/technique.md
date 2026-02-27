# Paiement (Stripe) - Documentation Technique

> **Derniere mise a jour** : Fevrier 2026

---

## 1. Regles Metier

```javascript
PAYMENT_RULES = {
  COMMISSION_RATE_TTC: 0.125,      // 12.5% sur le HT
  DEPOSIT_RATE: 0.3,               // 30% d'acompte pour les grosses missions
  DEPOSIT_THRESHOLD_HT: 800,       // Acompte requis si >= 800 EUR HT
  PROVIDER_TVA_RATE: 0.2,          // 20% TVA pour les providers assujettis
  AUTO_VALIDATE_HOURS: 72,         // Auto-validation du rapport apres 72h
}

PAYMENT_RETRY_SCHEDULE_DAYS = [1, 3, 7];  // Reessais apres 1, 3, puis 7 jours

// Frais Stripe (preleves par Stripe en sus, pas inclus dans la commission)
STRIPE_FEES = {
  CARD_RATE: 0.015,         // ~1.5% par transaction carte europeenne
  CARD_FIXED: 0.25,         // +0.25 EUR par transaction
  // Ces frais sont debites automatiquement par Stripe sur le montant brut
  // Ils n'apparaissent PAS dans nos calculs ni sur les factures Gotcha
}

// No-show (absence du prestataire)
NO_SHOW = {
  DECLARATION_WINDOW_MINUTES: 30,  // 30 min apres debut mission pour declarer
}
```

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
| `deposit_rate` | NUMERIC | Fixe a 0.30 (30%) |
| `commission_rate_ttc` | NUMERIC | Fixe a 0.125 (12.5%) |
| `threshold_ht` | NUMERIC | Seuil acompte : 800 EUR HT |
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
3. Total HT                 = 1 012.50 EUR
4. TVA totale               = 1 012.50 x 0.20 = 202.50 EUR
5. Total TTC                = 1 215 EUR
6. Deja paye (acompte)      = 360 EUR
7. Solde prestataire        = 1 215 - 360 = 855 EUR
8. Commission supp          = 62.50 x 0.125 = 7.81 EUR (sur HT supp)
9. Total charge final       = 855 + 7.81 = 862.81 EUR
```

---

## 4. Flux Complet en 4 Phases

### Phase 1 : Paiement Initial (Signature Contrat Entreprise)

**Declencheur** : Verification OTP entreprise dans `/api/contract/company/verify-otp`

1. OTP de l'entreprise verifie
2. Calcul des heures estimees -> `computeInitialPayment()`
3. Determination de l'acompte (si HT >= 800 EUR)
4. Creation du PaymentIntent Stripe :
   ```javascript
   stripe.paymentIntents.create({
     amount: totalAmountCents,       // acompte + commission
     currency: "eur",
     capture_method: "manual",       // pre-auth, pas de capture
     payment_method_types: ["card"],
     customer: stripeCustomerId,
     payment_method: defaultPaymentMethodId,
     confirm: true,
     off_session: true,
     application_fee_amount: platformAmountCents,  // commission
     transfer_data: {
       destination: providerStripeId,
       amount: providerAmountCents     // acompte prestataire
     },
     metadata: { profile_mission_id, mission_id, phase: "initial", ... }
   })
   ```
5. Verifier le statut = `requires_capture`
6. Creer l'enregistrement `payment_flows` : `initial_status = "initial_preauthed"`
7. Enregistrer le `payment_event`
8. `profile_missions.payment_status = "initial_preauthed"`

### Phase 2 : Signature Prestataire & Capture Initiale

**Declencheur** : Verification OTP prestataire dans `/api/contract/provider/verify-otp`

- Le prestataire signe le contrat
- Le PaymentIntent initial est **capture** (`stripe.paymentIntents.capture()`)
- `payment_flows.initial_status -> "initial_captured"`
- `profile_missions.payment_status -> "initial_captured"`
- Contrat `status -> signed`

### Phase 3 : Rapport de Mission & Pre-auth Finale

**Declencheur** : Soumission du rapport dans `/api/missions/submit-report`

**Missions benevoles** (`benevole = true`) :
- Pas de paiement requis
- `payment_status = "final_not_required"`

**Missions payantes** :
1. Recuperer heures travaillees + heures supp
2. Calculer le paiement final : `computeFinalPayment()`
3. Si montant final <= 0 : `final_status = "final_not_required"`
4. Si montant final > 0 :
   - Creer un nouveau PaymentIntent (`capture_method: manual`)
   - Meme logique de split que la phase initiale
   - `payment_flows.final_status = "final_preauthed"`
   - `profile_missions.payment_status = "final_preauthed"`

**Gestion des erreurs** :
- Pas de moyen de paiement / echec PI -> declenchement du mecanisme de **recovery**

### Phase 4 : Validation & Capture Finale

**Declencheur** : Validation du prestataire OU auto-validation 72h

**Auto-validation** : Cron `/api/cron/auto-validate-reports`
- Cherche les rapports avec `provider_validation_status = "pending"` et `report_submitted_at` <= 72h
- Passe le statut a `"approved"`
- Appelle `release-payment`

**Release Payment** (`/api/stripe/release-payment`) :

1. **Pre-verifications** :
   - Autorisation utilisateur (entreprise ou appel interne)
   - Pas de litiges ouverts
   - Rapport soumis + prestataire a valide
   - Payment flow existe
   - Pas deja capture

2. **Normalisation du split** :
   ```javascript
   normalizeMoneySplit({ totalCents, providerCents, platformCents })
   // Assure la coherence d'arrondi (provider absorbe l'erreur)
   ```

3. **Capture du paiement principal** :
   - Si PI en `requires_capture` -> capture partielle ou totale
   - Si PI en `succeeded` -> deja capture (idempotent)

4. **Capture supplementaire** (si montant restant > 0) :
   - Creer un second PaymentIntent pour le reste
   - Confirmer et capturer immediatement
   - Split proportionnel

5. **Mise a jour BDD** :
   ```javascript
   // payment_flows
   final_status: "final_captured"
   final_amount_cents: totalCapturedCents
   commission_supp_captured_ttc_cents: ...

   // profile_missions
   payment_status: "final_captured"
   payment_captured_at: new Date()
   state: "completed"
   hours_worked, hours_supp_worked, commission_amount
   amount_ht, tva_amount, amount_ttc_provider
   ```

6. **Declenchement facturation** :
   - Appel `/api/invoices/generate` (auth interne)
   - Appel `/api/invoices/send-emails`

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
| `account.updated` | Auto-verifier le compte Connect du provider |
| `identity.verification_session.verified` | Marquer provider comme verifie |
| `payout.failed` | Alerter admin |

**Idempotence** : Table `stripe_webhook_events` pour tracker les evenements deja traites par `stripe_event_id`.

---

## 7. Stripe Connect (Onboarding Prestataire)

### Creation de compte (`/api/stripe/create-connect-account`)

1. Creer un token de compte (donnees personnelles individuelles)
2. Creer un token de compte bancaire (IBAN)
3. Creer un compte Custom :
   ```javascript
   stripe.accounts.create({
     type: "custom",
     country: "FR",
     account_token: tokenId,
     external_account: bankTokenId,
     capabilities: {
       card_payments: { requested: true },
       transfers: { requested: true }
     },
     business_profile: { mcc: "5734", url: providerWebsite }
   })
   ```
4. Chiffrer et stocker le Stripe account ID dans `providers.stripe_id_enc`

### Lien d'onboarding (`/api/stripe/create-account-link`)

- Recupere le Stripe account ID (dechiffre)
- Cree un AccountLink (`account_onboarding` ou `account_update`)
- Redirige vers l'interface Stripe puis retour dans l'app

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
| `/api/stripe/check-identity-status` | GET | Statut KYC Stripe Identity |
| `/api/stripe/create-verification-session` | POST | Session verification KYC |
| `/api/stripe/upload-id` | POST | Upload piece d'identite |
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
PHASE INITIALE :
  pending -> initial_preauthed -> initial_captured
          -> failed

PHASE FINALE (si necessaire) :
  pending -> final_preauthed -> final_captured
          -> final_not_required (si montant <= 0)
          -> recovery -> (reessai apres 1/3/7 jours)
          -> failed

ANNULATION :
  any -> canceled
```

### Statuts profile_missions.payment_status

```
null -> initial_preauthed -> [attente rapport] -> final_preauthed
     -> final_captured -> completed
     -> recovery -> (boucle de reessai)
     -> dispute -> (revue admin)
     -> disputed / dispute_lost
```

### Validation prestataire

```
pending -> [72h auto ou validation manuelle] -> approved -> release-payment
        -> rejected
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

Jour 1 - Candidature & Signature du contrat
  10:00  Provider postule
  11:00  Entreprise signe le contrat
         -> PaymentIntent cree : 485 EUR (requires_capture)
         -> payment_flows: initial_status = "initial_preauthed"
  11:30  Provider signe le contrat
         -> Capture du PI initial : 485 EUR
         -> payment_flows: initial_status = "initial_captured"

Jour 3 - Mission terminee & Rapport soumis
  17:00  Provider marque la mission comme terminee
         Entreprise soumet le rapport : 38h + 2h supp
         -> Calcul final : 855 EUR solde + 7.81 EUR commission supp = 862.81 EUR
         -> PaymentIntent cree : 862.81 EUR (requires_capture)
         -> payment_flows: final_status = "final_preauthed"
  18:00  Validation prestataire en attente (ou auto dans 72h)

Jour 6 - Auto-validation (72h apres rapport)
  17:00  Cron auto-validate-reports
         -> provider_validation_status: approved
  17:01  release-payment appele
         -> Capture 862.81 EUR final
         -> payment_flows: final_status = "final_captured"
         -> Facturation declenchee

Jour 7
  Provider recoit le paiement Stripe (payout quotidien par defaut)
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
