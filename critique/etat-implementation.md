# Etat d'Implementation - Sujets Critiques

> **Derniere mise a jour** : Fevrier 2026

---

## Resume

| Sujet | Implemente | Non implemente | Obsolete a nettoyer |
|-------|:----------:|:--------------:|:-------------------:|
| **Contrats** | 18/18 | 0 | 0 |
| **Paiement** | 24 | 1 | 4 |
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

## 2. Paiement - 1 manquant, 4 obsoletes

### Fonctionnalites implementees

| Fonctionnalite | Statut | Fichiers |
|----------------|--------|----------|
| Pre-autorisation initiale (signature entreprise) | OK | `server/api/contract/company/verify-otp.post.js` |
| Capture initiale (signature prestataire) | OK | `server/api/contract/provider/verify-otp.post.js` |
| Soumission rapport entreprise | OK | `server/api/stripe/submit-report.post.js` |
| Pre-autorisation finale (rapport soumis) | OK | `server/api/stripe/submit-report.post.js` |
| Capture finale (rapport valide) | OK | `server/api/stripe/capture-final-payment.post.js` |
| Validation rapport par prestataire | OK | `server/api/stripe/validate-report.post.js` |
| Auto-validation 72h (cron) | OK | `server/api/cron/auto-validate-reports.post.js` |
| Calcul commission 12.5% HT | OK | Endpoints paiement |
| Calcul acompte 30% si >= 800 EUR HT | OK | `server/api/contract/company/verify-otp.post.js` |
| Gestion TVA (assujetti / non assujetti) | OK | Endpoints paiement |
| Heures supplementaires (x1.25) | OK | `server/api/stripe/submit-report.post.js` |
| Stripe Connect onboarding | OK | `server/api/stripe/create-connect-account.post.js` |
| Stripe Connect account link | OK | `server/api/stripe/create-account-link.post.js` |
| Verification compte Stripe | OK | `server/api/stripe/check-account-status.get.js` |
| Webhook Stripe | OK | `server/api/stripe/webhook.post.js` |
| Transfert vers prestataire | OK | `server/api/stripe/capture-final-payment.post.js` |
| Table payment_flows | OK | Schema missions |
| Table payment_events | OK | Schema missions |
| Missions benevoles (pas de paiement) | OK | Detection via `missions.benevole` |
| Remboursement annulation | OK | `server/api/stripe/cancel-mission-payment.post.js` |
| Mecanisme de recouvrement (retry 1/3/7 jours) | OK | `server/api/cron/retry-failed-payments.post.js` |
| Cron nettoyage pre-auth expirees | OK | `server/api/cron/cleanup-expired-preauths.post.js` |
| Frais Stripe en sus de la commission | OK | Factures a l'entreprise (pas sur factures Gotcha) |
| Gestion litiges (webhook dispute) | OK | `server/api/stripe/webhook.post.js` |

### NON IMPLEMENTE

| Fonctionnalite | Statut | Detail |
|----------------|--------|--------|
| **Absence prestataire (no-show)** | A FAIRE | Mecanisme de declaration d'absence dans les 30 min apres le debut de mission. Necessite : endpoint API, logique de remboursement, notification, avertissement profil prestataire. Documente dans `paiement/fonctionnement.md` |

### Endpoints obsoletes (ancien flux escrow)

Ces endpoints retournent un statut `{ status: 'obsolete' }` mais sont encore presents dans le code :

| Endpoint | Fichier |
|----------|---------|
| `POST /api/stripe/create-payment-intent` | `server/api/stripe/create-payment-intent.post.js` |
| `POST /api/stripe/escrow-payment` | `server/api/stripe/escrow-payment.post.js` |
| `POST /api/stripe/release-payment` | `server/api/stripe/release-payment.post.js` |
| `POST /api/stripe/refund-payment` | `server/api/stripe/refund-payment.post.js` |

> Ces fichiers peuvent etre supprimes en toute securite. Ils ne sont plus appeles par le frontend.

---

## 3. Facturation - 1 manquant

### Fonctionnalites implementees

| Fonctionnalite | Statut | Fichiers |
|----------------|--------|----------|
| Generation facture prestation (provider_to_company) | OK | `server/api/stripe/capture-final-payment.post.js` |
| Generation facture commission (gotcha_commission) | OK | `server/api/stripe/capture-final-payment.post.js` |
| PDF via PDFKit depuis templates (trames) | OK | Generation interne |
| Numerotation sequentielle unique | OK | Table `missions.invoices` |
| Chiffrement PDF avant stockage | OK | Supabase Storage |
| Envoi email entreprise (2 factures) | OK | Email automatique post-capture |
| Envoi email prestataire (1 facture) | OK | Email automatique post-capture |
| Telechargement factures | OK | `server/api/invoice/download.get.js` |
| Page factures prestataire | OK | `/pages/prestataire/compte/factures.vue` |
| Page factures entreprise | OK | `/pages/entreprise/compte/factures.vue` |
| Calcul TVA conditionnel (regime prestataire) | OK | Logic generation factures |
| Calcul commission 12.5% HT avec TVA 20% | OK | Logic generation factures |

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
3. **Supprimer les 4 endpoints obsoletes** : ancien flux escrow qui retournent `{ status: 'obsolete' }`

### Priorite basse
4. **Monitoring** : ajouter des alertes sur les echecs de paiement et les litiges
