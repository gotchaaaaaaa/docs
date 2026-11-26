# Etat d'Implementation - Sujets Critiques

> **Derniere mise a jour** : Mars 2026

---

## Resume

| Sujet | Implemente | Non implemente | Obsolete a nettoyer |
|-------|:----------:|:--------------:|:-------------------:|
| **Contrats** | 18/18 | 0 | 0 |
| **Paiement** | 24 | 1 | 0 |
| **Facturation** | 12 | 1 | 0 |

---

## 1. Contrats - COMPLET

Toutes les fonctionnalites documentees sont implementees et operationnelles.

| Fonctionnalite | Statut | Fichiers |
|----------------|--------|----------|
| Generation PDF (idempotent) | OK | `server/api/contract/generate-pdf.post.js` |
| Hash SHA-256 du document | OK | `server/api/contract/generate-pdf.post.js` |
| Upload PDF Supabase Storage | OK | `server/api/contract/generate-pdf.post.js` |
| Envoi OTP entreprise | OK | `server/api/contract/company/send-otp.post.js` |
| Verification OTP entreprise | OK | `server/api/contract/company/verify-otp.post.js` |
| Envoi OTP prestataire | OK | `server/api/contract/provider/send-otp.post.js` |
| Verification OTP prestataire | OK | `server/api/contract/provider/verify-otp.post.js` |
| Chiffrement IP + User-Agent (AES-256-GCM) | OK | Tous les endpoints verify-otp |
| Rate limiting OTP (3/h envoi, 10/15min verif) | OK | Tous les endpoints OTP |
| Cooldown 60s entre envois | OK | Endpoints send-otp |
| Bcrypt hash OTP (rounds=10) | OK | Endpoints send-otp |
| Max 3 tentatives OTP | OK | Endpoints verify-otp |
| Generation certificats de signature | OK | `server/api/contract/provider/verify-otp.post.js` |
| Pre-autorisation Stripe (signature entreprise) | OK | `server/api/contract/company/verify-otp.post.js` |
| Capture paiement (signature prestataire) | OK | `server/api/contract/provider/verify-otp.post.js` |
| Calcul deadline prestataire | OK | `server/api/contract/company/verify-otp.post.js` |
| Telechargement PDF + certificats | OK | `server/api/contract/download-pdf.get.js`, `download-certificate.get.js` |
| Envoi email contrat signe | OK | `server/api/contract/send-email.post.js` |

---

## 2. Paiement - 1 manquant

### Fonctionnalites implementees

| Fonctionnalite | Statut | Fichiers |
|----------------|--------|----------|
| Prelevement immediat (signature devis entreprise) | OK | `server/api/contract/company/verify-otp.post.js` |
| Signature convention benevole (prestataire) | OK | `server/api/contract/provider/verify-otp.post.js` |
| Soumission rapport prestataire | OK | `server/api/missions/provider-submit-report.post.js` |
| Paiement direct entreprise (solde final) | OK | `server/api/missions/company-direct-pay.post.js` |
| Capture via release-payment | OK | `server/api/stripe/release-payment.js` |
| Validation rapport par prestataire | OK | Inclus dans provider-submit-report |
| Auto-validation 72h (cron) | OK | `server/api/cron/auto-validate-reports.js` |
| Calcul commission 13% HT | OK | Endpoints paiement |
| Calcul acompte 30% si >= 800 EUR HT | **TOUJOURS ACTIF** | `server/utils/payment-flow.js` (`DEPOSIT_RATE = 0.3`, `DEPOSIT_THRESHOLD_HT = 800`) |
| Charge directe (acompte) a la signature du devis | OK | `server/api/devis/company/verify-otp.post.js` (`capture_method: 'automatic'`) |
| Pre-auth Stripe + capture finale apres validation rapport | OK | `server/api/stripe/release-payment.js` (`capture_method: 'manual'`) |
| Pre-auth + capture heures supp (`final_adjustments`) | OK (flow integre) | `server/api/missions/submit-report.post.js` (l'endpoint `/api/stripe/create-supp-hours-preauth` est **obsolete** et renvoie une erreur) |
| Commission absorbed par le prestataire (inversion `42f78b7`) | OK | `utils/payment-amounts.js` (`buildAbsorbedFeeChargeAmounts`) |
| Facture commission emise vers le prestataire | OK | `server/api/invoices/generate.post.js` (`recipient_type: "provider"`) |
| Frais Stripe absorbes par le prestataire (inclus dans `application_fee_amount`) | OK | `update_commission_invoice_transaction_fee_ht_tva.sql` |
| Field whitelisting onboarding (anti mass-assignment) | OK | Inline dans chaque endpoint (commit `f2ca900`), ex. `server/api/provider/save-onboarding.post.js:42` |
| Multi-day missions (mission_schedules) | OK | `add_multi_day_missions.sql`, `shared/mission-schedule-utils.js` |
| Half-day billing rule | OK | `update_billing_to_half_day_rule.sql`, `utils/rate-calculation.js` |
| Additional fees (devis + final adjustments) | OK | `utils/additional-fees.js` |
| Provider can open dispute | OK | `server/api/missions/open-problem-report.post.js` (`0cda107`) |
| Document-aware cancellation | OK | `009-cancel-mission-document-aware.sql`, `providers.cancellation_logs` |
| Provider clustering on map (custom pixel-based, pas Mapbox native) | OK | `pages/map/search-provider.vue:505+` (`CLUSTER_PX_THRESHOLD = 50`, commit `6f684e0`) |
| Available now indicator | OK | `add_provider_available_now_indicator.sql`, RPC `is_provider_available_now` |
| Tutorial completed | OK | `add_tutorial_completed.sql`, `composables/useTutorial.js` |
| IP de signature chiffree | OK | `ac6ebba` |
| Gestion TVA (assujetti / non assujetti) | OK | Endpoints paiement |
| Heures supplementaires (x1.25) | OK | `server/api/stripe/submit-report.post.js` |
| Stripe Connect onboarding | OK | `server/api/stripe/create-connect-account.js` |
| Stripe Connect account link | OK | `server/api/stripe/create-account-link.js` |
| Verification compte Stripe | OK | `server/api/stripe/account-requirements.get.js` |
| Webhook Stripe | OK | `server/api/stripe/webhook.js` |
| Transfert vers prestataire | OK | `server/api/stripe/release-payment.js` |
| Table payment_flows | OK | Schema missions |
| Table payment_events | OK | Schema missions |
| Missions benevoles (pas de paiement) | OK | Detection via `missions.benevole` |
| Remboursement annulation | OK | `server/api/missions/cancel.post.js` |
| Mecanisme de recouvrement (retry 1/3/7 jours) | OK | `server/api/cron/retry-final-payments.js` |
| Cron pre-auth en attente | OK | `server/api/cron/create-pending-preauths.js` |
| Frais Stripe en sus de la commission | OK | Factures a l'entreprise (pas sur factures Gotcha) |
| Gestion litiges (webhook dispute) | OK | `server/api/stripe/webhook.post.js` |

### NON IMPLEMENTE

| Fonctionnalite | Statut | Detail |
|----------------|--------|--------|
| **Absence prestataire (no-show)** | A FAIRE | Mecanisme de declaration d'absence dans les 30 min apres le debut de mission. Necessite : endpoint API, logique de remboursement, notification, avertissement profil prestataire. Documente dans `paiement/fonctionnement.md` |

### Ancien flux escrow (nettoye)

Les endpoints obsoletes de l'ancien flux escrow (`create-payment-intent`, `escrow-payment`, `refund-payment`) ont ete supprimes.

`release-payment.js` est toujours actif et utilise pour la capture finale dans certains scenarios.

---

## 3. Facturation - 1 manquant

### Fonctionnalites implementees

| Fonctionnalite | Statut | Fichiers |
|----------------|--------|----------|
| Generation facture prestation (provider_to_company) | OK | `server/api/invoices/generate.post.js` |
| Generation facture commission (gotcha_commission) | OK | `server/api/invoices/generate.post.js` |
| PDF via PDFKit depuis templates (trames) | OK | Generation interne |
| Numerotation sequentielle unique | OK | Table `missions.invoices` |
| Chiffrement PDF avant stockage | OK | Supabase Storage |
| Envoi email entreprise (2 factures) | OK | Email automatique post-capture |
| Envoi email prestataire (1 facture) | OK | Email automatique post-capture |
| Telechargement factures | OK | `server/api/invoices/[id]/download.get.js` |
| Page factures prestataire | OK | `/pages/prestataire/compte/factures.vue` |
| Page factures entreprise | OK | `/pages/entreprise/compte/factures.vue` |
| Calcul TVA conditionnel (regime prestataire) | OK | Logic generation factures |
| Calcul commission 13% HT avec TVA 20% | OK | Logic generation factures |

### NON IMPLEMENTE

| Fonctionnalite | Statut | Detail |
|----------------|--------|--------|
| **Organisme de facturation certifie (NF525)** | EN ATTENTE | La legislation francaise impose un logiciel certifie. Deux solutions en evaluation : **Iopole** et **Billit**. Comparaison des prix en cours. Le systeme actuel genere les factures en interne via PDFKit. Migration prevue avant obligation legale. |

---

## Actions recommandees

### Priorite haute
1. **Implementer le mecanisme no-show** : endpoint API + logique remboursement + frontend (bouton declaration absence dans les 30 min)

### Priorite moyenne
2. **Comparer Iopole vs Billit** : choisir un organisme certifie NF525 pour la facturation

### Priorite basse
3. **Monitoring** : ajouter des alertes sur les echecs de paiement et les litiges
