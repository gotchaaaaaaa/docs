# Roadmap Chiffrement CNIL - Lots 2 a 6

Ce document sert de reference pour les lots futurs de chiffrement. Le Lot 0 (infrastructure crypto) et le Lot 1 (otp_codes + audit_log) sont deja implementes.

Librairie crypto : `server/utils/crypto.js` (encryptField, decryptField, computeBlindIndex)
Pattern : migration SQL → les utils chiffrent directement (pas de phase transitoire)

---

## Lot 2 - missions.contrats (contrats signes) ✅ IMPLEMENTé

**Criticite** : TRES HAUTE - usurpation d'identite + fraude + litige judiciaire en cas de fuite

### Decisions prises

- `vars_data` : **SUPPRIMEE** (jamais lue par le frontend ni le serveur Node, le PDF fait foi)
- `markdown_content` : **SUPPRIMEE** (la RPC V2 retourne le markdown au lieu de le stocker)
- `provider_consent_at` / `company_consent_at` : **PAS chiffrees** (pas du PII, timestamps non identifiants)
- Wrapper centralise : `server/utils/contract-crypto.js`

### Colonnes chiffrees (5 colonnes _enc)

| Ancienne colonne | Nouvelle colonne | Domaine crypto |
|---|---|---|
| `signature_certificate_json` (jsonb) | `signature_certificate_json_enc` (text) | `contrat.signature_certificate_json` |
| `provider_signature_ip` (text) | `provider_signature_ip_enc` (text) | `contrat.provider_signature_ip` |
| `company_signature_ip` (text) | `company_signature_ip_enc` (text) | `contrat.company_signature_ip` |
| `provider_signature_user_agent` (text) | `provider_signature_user_agent_enc` (text) | `contrat.provider_signature_user_agent` |
| `company_signature_user_agent` (text) | `company_signature_user_agent_enc` (text) | `contrat.company_signature_user_agent` |

### Colonnes supprimees

| Colonne | Raison |
|---|---|
| `vars_data` | Jamais lue, redondant avec le PDF |
| `markdown_content` | Utilise une seule fois pour generer le PDF, la V2 RPC retourne le markdown |
| Anciennes colonnes en clair (5) | Remplacees par les colonnes `_enc` ci-dessus |

### RPCs V2 creees

| Nouvelle RPC | Remplace | Changements |
|---|---|---|
| `create_contract_for_company_v2` | `create_contract_for_company` | Ne stocke pas vars_data/markdown_content, retourne markdown dans la reponse, idempotent |
| `get_contract_for_company_v2` | `get_contract_for_company` | Supprime vars_data du JSON retourne |
| `get_contract_for_provider_v2` | `get_contract_for_provider` | Supprime vars_data du JSON retourne |

### Fichiers modifies

| Fichier | Modification |
|---|---|
| `server/utils/contract-crypto.js` | **NOUVEAU** - wrapper encrypt/decrypt pour les 5 colonnes |
| `server/api/contract/generate-pdf.post.js` | Utilise RPC V2, recoit markdown depuis la reponse |
| `server/api/contract/company/verify-otp.post.js` | Chiffre company_signature_ip/ua avant ecriture |
| `server/api/contract/provider/verify-otp.post.js` | Dechiffre company fields pour certificat, chiffre provider fields + certificate JSON |
| `pages/entreprise/contrat/[id].vue` | Appelle `get_contract_for_company_v2` |
| `pages/prestataire/contrat/[id].vue` | Appelle `get_contract_for_provider_v2` |
| `pages/missions/[id].vue` | Appelle `get_contract_for_provider_v2` |

### Fichiers NON modifies (verification faite)

`send-email.post.js`, `download-certificate.get.js`, `download-pdf.get.js`, `company/send-otp.post.js`, `provider/send-otp.post.js`, `cancel-expired-signatures.js`, `delete-account.post.js`, `certificate-generator.js` - aucun ne lit/ecrit les colonnes chiffrees directement.

### Migrations SQL

- `database/migrations/lot2_contrats_encryption.sql` - colonnes + RPCs V2
- `database/migrations/lot2_cleanup_old_rpcs.sql` - a executer apres validation (DROP anciennes RPCs)

---

## Lot 3 - missions.invoices (factures) ✅ IMPLEMENTE

**Criticite** : HAUTE - fraude fiscale, fausse declaration, ouverture compte pro

### Decisions prises

- `issuer_name` : **AJOUTE au chiffrement** (PII - nom complet du prestataire, non prevu initialement)
- `invoice_get_generation_data` : **PAS modifie** (lit depuis providers/companies/profiles, sera adapte lots 4-5)
- `invoice-pdf.js` : **PAS modifie** (recoit les donnees en clair en parametre depuis generate.post.js)
- Wrapper centralise : `server/utils/invoice-crypto.js`

### Colonnes chiffrees (8 colonnes _enc + 4 colonnes _bidx)

| Ancienne colonne | Nouvelle colonne | Blind index | Domaine crypto |
|---|---|---|---|
| `issuer_name` (text) | `issuer_name_enc` (text) | Non | `invoice.issuer_name` |
| `issuer_address` (text) | `issuer_address_enc` (text) | Non | `invoice.issuer_address` |
| `issuer_siret` (text) | `issuer_siret_enc` (text) | `issuer_siret_bidx` | `invoice.issuer_siret` |
| `issuer_tva_number` (text) | `issuer_tva_number_enc` (text) | `issuer_tva_number_bidx` | `invoice.issuer_tva_number` |
| `recipient_name` (text) | `recipient_name_enc` (text) | Non | `invoice.recipient_name` |
| `recipient_address` (text) | `recipient_address_enc` (text) | Non | `invoice.recipient_address` |
| `recipient_siret` (text) | `recipient_siret_enc` (text) | `recipient_siret_bidx` | `invoice.recipient_siret` |
| `email_recipient` (text) | `email_recipient_enc` (text) | `email_recipient_bidx` | `invoice.email_recipient` |

### Colonnes supprimees

| Colonne | Raison |
|---|---|
| Anciennes colonnes en clair (8) | Remplacees par les colonnes `_enc` ci-dessus |

### RPCs V2 creees

| Nouvelle RPC | Remplace | Changements |
|---|---|---|
| `invoice_insert_v2` | `invoice_insert` | Ecrit dans colonnes _enc/_bidx, JSONB contient valeurs pre-chiffrees par Node |
| `invoice_list_for_user_v2` | `invoice_list_for_user` | Retourne _enc au lieu du clair, Node dechiffre |
| `invoice_get_email_data_v2` | `invoice_get_email_data` | Retourne invoices avec _enc, Node dechiffre issuer_name |
| `invoice_download_check_access_v2` | `invoice_download_check_access` | Retourne sous-ensemble avec _enc, plus de to_jsonb(*) |
| `invoice_mark_email_sent_v2` | `invoice_mark_email_sent` | Recoit _enc et _bidx en parametres separes |

### Fichiers modifies

| Fichier | Modification |
|---|---|
| `server/utils/invoice-crypto.js` | **NOUVEAU** - wrapper encrypt/decrypt pour les 8 colonnes |
| `server/api/invoices/generate.post.js` | Chiffre via encryptInvoiceFields() avant appel invoice_insert_v2 |
| `server/api/invoices/send-emails.post.js` | Dechiffre issuer_name_enc pour email template, chiffre email_recipient via invoice_mark_email_sent_v2 |
| `server/api/invoices/[id]/view-url.get.js` | Utilise invoice_download_check_access_v2, dechiffre issuer_name + recipient_name |
| `server/api/invoices/list.get.js` | Utilise invoice_list_for_user_v2, dechiffre recipient_name (provider) ou issuer_name (company) |
| `server/api/invoices/[id]/download.get.js` | Utilise invoice_download_check_access_v2 (ne lit que invoice_number + pdf_storage_path = non chiffres) |

### Fichiers NON modifies (verification faite)

`server/utils/invoice-pdf.js` - recoit les donnees en clair en parametre, aucun acces DB direct.
`invoice_get_generation_data` - lit depuis providers/companies/profiles (pas invoices), sera adapte lots 4-5.

### Migrations SQL

- `database/migrations/lot3_invoices_encryption.sql` - colonnes _enc/_bidx + RPCs V2 + drop clair
- `database/migrations/lot3_cleanup_old_rpcs.sql` - a executer apres validation (DROP anciennes RPCs)

---

## Lot 3bis - Chiffrement fichiers storage (invoices + contracts + certificates) ✅ IMPLEMENTE

**Criticite** : TRES HAUTE - documents contractuels et fiscaux stockes en cloud

### Decisions prises

- Scope limite a `invoices`, `contracts`, `certificates` (pas `documents`)
- Chiffrement applicatif AES-256-GCM avec cle dediee `FILE_ENCRYPTION_KEY`
- Format binaire v1: `GCHFILE1 + iv(12) + authTag(16) + ciphertext`
- Domain binding AAD:
  - `file.invoice_pdf`
  - `file.contract_pdf`
  - `file.contract_certificate`
- Nouveaux objets storage suffixes en `.pdf.enc`
- Compat legacy: si preambule `GCHFILE1` absent, lecture en clair (pas de migration historique)
- Fin des signed URLs pour lecture PDF chifree: lecture via endpoints API auth + stream binaire

### Changement d interfaces

- `GET /api/contract/download-pdf` retourne un PDF binaire (`application/pdf`)
- `GET /api/contract/download-certificate` retourne un PDF binaire (`application/pdf`)
- `GET /api/invoices/:id/view-url` deprecie, retourne `410 Gone`

### Fichiers crees

- `server/utils/file-crypto.js` - chiffrement/dechiffrement buffers fichiers + detection legacy

### Fichiers modifies

- Config/env:
  - `nuxt.config.ts` - ajout `runtimeConfig.fileEncryptionKey`
  - `server/plugins/validate-env.ts` - validation stricte `FILE_ENCRYPTION_KEY`
- Upload chiffre:
  - `server/utils/pdf-generator.js` - upload contrats en `.pdf.enc`
  - `server/utils/certificate-generator.js` - upload certificats en `.pdf.enc`
  - `server/api/invoices/generate.post.js` - upload factures en `.pdf.enc`
- Download/dechiffrement:
  - `server/api/invoices/[id]/download.get.js`
  - `server/api/invoices/send-emails.post.js`
  - `server/api/contract/download-pdf.get.js`
  - `server/api/contract/download-certificate.get.js`
  - `server/api/contract/send-email.post.js`
- Deprecation:
  - `server/api/invoices/[id]/view-url.get.js` -> `410 Gone`
- Frontend:
  - `components/shared/ContractPdfViewer.vue` - fetch binaire auth + blob URL
  - `components/shared/InvoicePdfViewer.vue` - fetch binaire auth + blob URL
  - `pages/prestataire/compte/mes-contrats.vue` - certificat via `authGetBlob`
  - `pages/entreprise/compte/mes-contrats.vue` - certificat via `authGetBlob`

### Notes

- Pas de migration SQL necessaire
- Les anciens fichiers de dev non chiffrés restent lisibles

---

## Lot 4 - providers.providers + companies.companies

**Criticite** : HAUTE - donnees d'identite entreprise + paiement

### Status Lot 4 companies.companies

✅ **IMPLEMENTE** (2026-02-14, complété 2026-02-16)

**Fichiers crees :**
- `server/utils/company-crypto.js` - wrapper encrypt/decrypt
- `database/migrations/lot4_companies_encryption.sql` - ADD colonnes _enc/_bidx + RPC V2
- `database/migrations/lot4_cleanup_companies.sql` - DROP colonnes clair + RPC V2 get_company_profile
- `server/api/company/profile.get.js` - **NOUVEAU** - fetch company dechiffre (remplace select('*') client)
- `server/api/company/save-onboarding.post.js` - **NOUVEAU** - ecriture onboarding avec chiffrement
- `server/api/company/check-siret.post.js` - **NOUVEAU** - unicite SIRET via blind index

**Fichiers modifies (11 fichiers) :**
- Stripe : `create-supp-hours-preauth.js`, `cron/create-pending-preauths.js`, `check-payment-method.js`, `create-payment-intent.js`, `create-setup-intent.js`
- Contract : `contract/company/verify-otp.post.js`, `contract/provider/verify-otp.post.js`
- Invoice : `invoices/generate.post.js`
- Frontend : `composables/useAuth.js` - fetch company via endpoint serveur au lieu de Supabase client
- Frontend : `composables/useCompanySignup.js` - ecriture SIRET via endpoint + unicite via blind index
- Frontend : `pages/prestataire/profil-entreprise/[id].vue` - SIRET supprime, utilise RPC V2

**Decisions prises (differentes de la roadmap) :**

1. **RPCs `get_company_for_stripe` et `update_company_stripe_customer` :**
   - Roadmap : creer les RPCs
   - **Decision : Acces direct a la table au lieu de creer des RPCs**
   - Raison : Simplifier, moins de RPCs a maintenir
   - Chiffrement/dechiffrement cote serveur Node via `company-crypto.js`

2. **`siret_gouv_infos` - Pas de split :**
   - Roadmap : split (infos publiques en clair + payload brut chiffre)
   - **Decision : Tout le JSON chiffre directement**
   - Raison : Plus simple, plus sur, aucune fuite d'info
   - Dechiffrement cote serveur Node quand necessaire

3. **`invoice_get_generation_data` :**
   - Cree une V2 (au lieu de modifier la V1)
   - V2 retourne `siret_enc`, `siret_gouv_infos_enc` (encrypted)
   - Node dechiffre avant utilisation
   - V1 sera supprimee dans cleanup

4. **Frontend fetch company :**
   - Le frontend ne lit plus `companies.companies` directement via Supabase client
   - `useAuth.js` appelle `GET /api/company/profile` qui dechiffre cote serveur
   - Les champs `siret`, `siret_gouv_infos`, `stripe_customer_id` arrivent en clair au frontend

5. **Ecriture onboarding :**
   - `useCompanySignup.js` appelle `POST /api/company/save-onboarding` pour les champs sensibles
   - Le serveur chiffre avant ecriture via `encryptCompanyFields()`
   - Les champs non sensibles (nom_commercial, description, etc.) restent en ecriture directe client

6. **SIRET provider :**
   - Le SIRET n'est plus affiche aux providers sur `profil-entreprise/[id]`
   - RPC `get_company_profile_v2` ne retourne plus le SIRET

**Pattern : Cutover direct, pas de dual-write**
- Pas de phase transitoire
- Chiffrement/dechiffrement cote serveur Node uniquement
- Pas de RPCs pour chiffrement (contrairement a Lot 2/3)

---

### Colonnes providers.providers

| Colonne | Strategie | Blind index |
|---------|-----------|-------------|
| `siret` | *_enc + *_bidx | Oui (lookup) |
| `adresse_facturation` | *_enc | Non |
| `zone_intervention_lat` | *_enc + colonne coarse clair | Special (voir geoloc) |
| `zone_intervention_lng` | *_enc + colonne coarse clair | Special (voir geoloc) |
| `stripe_id` | *_enc + *_bidx | Oui (lookup Stripe) |
| `tva_number` | *_enc + *_bidx | Oui (lookup fiscal) |

### Colonnes companies.companies (IMPLEMENTE)

| Colonne | Strategie | Blind index | Statut |
|---------|-----------|-------------|--------|
| `siret` | `siret_enc` + `siret_bidx` | Oui (lookup) | ✅ Fait |
| `siret_gouv_infos` | `siret_gouv_infos_enc` (full JSON) | Non | ✅ Fait (pas de split) |
| `stripe_customer_id` | `stripe_customer_id_enc` + `stripe_customer_id_bidx` | Oui (lookup Stripe) | ✅ Fait |

### Fichiers serveur a modifier (Lot 4 companies - Stripe)

**Modifies pour companies.companies :**

| Fichier | Operation | Colonnes | Statut |
|---------|-----------|----------|--------|
| `server/api/stripe/check-payment-method.js` | READ+WRITE | `stripe_customer_id_enc` | ✅ Modifié |
| `server/api/stripe/create-payment-intent.js` | READ | `stripe_customer_id_enc` | ✅ Modifié |
| `server/api/stripe/create-setup-intent.js` | READ+WRITE | `stripe_customer_id_enc` | ✅ Modifié |
| `server/api/stripe/create-supp-hours-preauth.js` | READ | `stripe_customer_id_enc` | ✅ Modifié |
| `server/api/cron/create-pending-preauths.js` | READ | `stripe_customer_id_enc` | ✅ Modifié |
| `server/api/contract/company/verify-otp.post.js` | READ | `stripe_customer_id_enc` | ✅ Modifié |

**Non modifies (providers.providers - TODO Lot 4 providers) :**

| Fichier | Operation | Colonnes | Statut |
|---------|-----------|----------|--------|
| `server/api/stripe/create-connect-account.js` | WRITE | providers.stripe_id | ⏳ Lot 4 providers |
| `server/api/stripe/webhook.js` | READ | providers.stripe_id | ⏳ Lot 4 providers |
| `server/api/stripe/release-payment.js` | READ | providers.stripe_id | ⏳ Lot 4 providers |
| `server/api/stripe/create-account-link.js` | READ | providers.stripe_id | ⏳ Lot 4 providers |
| `server/api/stripe/create-checkout-session.js` | READ | providers.stripe_id | ⏳ Lot 4 providers |
| `server/api/stripe/upload-id.js` | READ | providers.stripe_id | ⏳ Lot 4 providers |
| `server/api/stripe/account-requirements.get.js` | READ | providers.stripe_id | ⏳ Lot 4 providers |
| `server/api/stripe/check-identity-status.get.js` | READ | providers.stripe_id | ⏳ Lot 4 providers |
| `server/api/stripe/create-verification-session.post.js` | READ | providers.stripe_id | ⏳ Lot 4 providers |

### Fichiers serveur a modifier (Lot 4 companies - SIRET)

**Modifies pour companies.companies :**

| Fichier | Operation | Colonnes | Statut |
|---------|-----------|----------|--------|
| `server/api/invoices/generate.post.js` | READ | `siret_enc`, `siret_gouv_infos_enc` via RPC V2 | ✅ Modifié |
| `server/api/contract/provider/verify-otp.post.js` | READ | `siret_enc` | ✅ Modifié |

**Non modifies (providers.providers - TODO Lot 4 providers) :**

| Fichier | Operation | Colonnes | Statut |
|---------|-----------|----------|--------|
| `server/utils/certificate-generator.js` | READ | providers.siret | ⏳ Lot 4 providers |

### Fichiers serveur a modifier (Geoloc - TODO Lot 4 providers)

| Fichier | Operation | Colonnes | Statut |
|---------|-----------|----------|--------|
| `server/api/notifications/trigger-provider-available.post.js` | READ | zone_intervention_lat/lng | ⏳ Lot 4 providers |
| `server/api/cron/weekly-geolocation-reminder.js` | READ | zone_intervention_lat/lng | ⏳ Lot 4 providers |

### Fonctions RPC a adapter

**Lot 4 companies (IMPLEMENTE) :**

| Fonction | Impact | Statut |
|----------|--------|--------|
| `invoice_get_generation_data` | V2 créée : retourne `siret_enc`, `siret_gouv_infos_enc` | ✅ Créée |
| `get_company_for_stripe` | **Remplacée par accès direct table** | ✅ Pas créée (décision) |
| `update_company_stripe_customer` | **Remplacée par accès direct table** | ✅ Pas créée (décision) |

**Lot 4 providers (TODO) :**

| Fonction | Impact | Statut |
|----------|--------|--------|
| `get_candidate_profile` | READ zone_intervention_cp, zone_intervention_rayon | ⏳ Lot 4 providers |
| `cancel_mission_v2` | READ donnees provider (siret, etc.) | ⏳ Lot 4 providers |
| `find_providers_for_new_mission` | READ geoloc (Haversine) | ⏳ Lot 4 providers |
| `find_replacement_providers_for_mission` | READ geoloc | ⏳ Lot 4 providers |
| `find_open_missions_for_provider` | READ geoloc | ⏳ Lot 4 providers |
| `get_providers_for_map` | READ zone_intervention_lat/lng (Haversine + filtre rayon) | ✅ V2 créée (lot4_providers_encryption.sql) |

### Fichiers serveur a modifier (Map/BFF - Lot 4 providers)

| Fichier | Operation | Colonnes | Statut |
|---------|-----------|----------|--------|
| `server/api/map/search-providers.get.js` | **NOUVEAU** BFF endpoint | Appelle V2 RPC, déchiffre lat/lng, Haversine en Node | ✅ Créé |
| `pages/map/search-provider.vue` | READ (frontend) | Migré vers BFF au lieu de RPC direct | ✅ Migré |
| `pages/entreprise/search-provider-list.vue` | READ (frontend) | Migré vers BFF au lieu de RPC direct | ✅ Migré |

### Strategie geolocation (TODO Lot 4 providers)

Les fonctions RPC de matching utilisent des calculs Haversine sur `zone_intervention_lat/lng`. On ne peut pas faire de calcul geometrique sur des valeurs chiffrees.

**Solution envisagee** : modele "coarse clair + precis chiffre"
1. Ajouter `zone_intervention_geohash` (text, 5-6 chars) en clair → precision ~5km
2. Chiffrer lat/lng precis dans `zone_intervention_lat_enc` / `zone_intervention_lng_enc`
3. Les RPC SQL filtrent d'abord par geohash (grossier), puis le serveur Node affine avec les coordonnees dechiffrees

### Strategie siret_gouv_infos (IMPLEMENTE - Lot 4 companies)

Le champ `siret_gouv_infos` (JSONB) contient un snapshot complet de l'API gouv. Il peut contenir le nom du dirigeant.

**Solution appliquee** : **Tout le JSON chiffré**
- ❌ Pas de split (contrairement à la roadmap initiale)
- ✅ Plus simple : `siret_gouv_infos_enc` contient le JSON complet chiffré
- ✅ Plus sûr : aucune info ne fuit
- ✅ Déchiffrement côté serveur Node quand nécessaire (dans `invoices/generate.post.js`)

---

## Lot 5 - public.profiles (le plus gros)

**Criticite** : HAUTE - identite complete des utilisateurs

### Colonnes a chiffrer

| Colonne | Strategie | Blind index |
|---------|-----------|-------------|
| `email` | *_enc + *_bidx | Oui (login, lookups) |
| `first_name` | *_enc | Non |
| `last_name` | *_enc | Non |
| `birth_date` | *_enc | Non |
| `phone` | *_enc + *_bidx | Oui (lookup eventuel) |
| `nationality` | *_enc | Non |
| `address` | *_enc | Non |

### Impact majeur : profiles est lu partout

C'est la table la plus referencee du projet. L'email et les noms sont lus par quasiment tous les endpoints serveur.

### Fichiers serveur a modifier (~24 fichiers)

**Auth/User :**
- `server/api/auth/send-signup-otp.post.js` - READ email
- `server/api/auth/send-reset-otp.post.js` - READ email, first_name
- `server/api/auth/check-email.post.js` - READ email via RPC email_exists
- `server/api/user/delete-account.post.js` - READ email

**Contrats :**
- `server/api/contract/send-email.post.js` - READ first_name, last_name, email
- `server/api/contract/company/send-otp.post.js` - READ profile
- `server/api/contract/company/verify-otp.post.js` - READ profile
- `server/api/contract/provider/send-otp.post.js` - READ profile
- `server/api/contract/provider/verify-otp.post.js` - READ profile

**Notifications :**
- `server/api/notifications/trigger-provider-available.post.js` - READ profile
- `server/api/notifications/provider-canceled.post.js` - READ first_name
- `server/api/push/send.js` - READ email, first_name, last_name

**Stripe :**
- `server/api/stripe/create-setup-intent.js` - READ profile pour Stripe customer
- `server/api/stripe/webhook.js` - READ profile

**Missions :**
- `server/api/missions/confirm-availability.post.js` - READ profile
- `server/api/missions/submit-report.post.js` - READ profile

**Factures :**
- `server/api/invoices/send-emails.post.js` - READ email via RPC
- `server/api/invoices/generate.post.js` - READ first_name, last_name, email via RPC

**Cron :**
- `server/api/cron/company-report-followup.js` - READ profile via email alerts
- `server/api/cron/company-candidates-alerts.js` - READ profile via email alerts
- `server/api/cron/signature-deadline-reminder.js` - READ profile

**Utilitaires :**
- `server/utils/email-alerts.js` - READ email, first_name, last_name
- `server/utils/certificate-generator.js` - READ profile

### Fonctions RPC a adapter (~12+ fonctions)

| Fonction | Impact |
|----------|--------|
| `create_contract_for_company` | READ first_name, last_name, email, phone |
| `get_contract_for_company` | READ profile |
| `get_contract_for_provider` | READ profile |
| `get_candidate_profile` | READ first_name, last_name, phone, email, address |
| `cancel_mission` | READ first_name, last_name |
| `get_assigned_provider` | READ first_name, last_name |
| `invoice_get_generation_data` | READ first_name, last_name, email |
| `email_exists` | READ email |
| Tous les RPCs dashboard | READ first_name, last_name, email, phone |

### Strategie recommandee

Ce lot est le plus complexe et necessite probablement :

1. **Nouveaux endpoints BFF** (Backend For Frontend) :
   - `GET /api/me/profile` - retourne le profil dechiffre
   - `PATCH /api/me/profile` - met a jour avec chiffrement
   - Le front ne lit plus directement la table profiles via Supabase client

2. **Migration progressive du front** :
   - D'abord les pages critiques (profil, settings)
   - Puis les pages secondaires (dashboard, etc.)

3. **Adaptation des RPC** :
   - Les RPC retourneront du ciphertext
   - Le serveur Node dechiffre avant d'envoyer au front ou d'utiliser les donnees

---

## Ordre d'execution recommande

```
Lot 1 (FAIT) → Lot 2 (contrats) → Lot 3 (factures) → Lot 4 (providers/companies) → Lot 5 (profiles)
```

Chaque lot suit le meme pattern :
1. Migration SQL : ajouter colonnes *_enc / *_bidx
2. Code : dual-write (flag WRITE)
3. Backfill des anciennes lignes
4. Code : dual-read (flag READ)
5. Cutover : drop colonnes clair

Les lots 2 et 3 sont relativement isoles (peu de fichiers). Le lot 4 est plus large a cause de Stripe + geoloc. Le lot 5 est le plus impactant car profiles est reference partout.

---

## Lot 6 - missions.messages (messagerie) - IMPLEMENTE

**Criticite** : HAUTE - echanges libres de donnees sensibles entre entreprise et prestataire

### Decisions prises

- Scope: messages user + system chiffres
- Environnement dev: pas de backfill
- Push privacy: notification generique (aucun extrait de message)
- Cutover: direct vers `POST /api/messages/:pmId`
- Realtime: broadcast conserve
- Transition SQL: RPC V3 + blocage immediat des RPC plaintext

### Schema et colonnes

| Table | Changement |
|---|---|
| `missions.messages` | Ajout `content_enc` (text) |
| `missions.messages.content` | `NOT NULL` retire (phase transitoire) |
| `missions.messages` | Contrainte transitoire: `content IS NOT NULL OR content_enc IS NOT NULL` |

### Domaine crypto

| Type de message | Domaine AAD |
|---|---|
| user | `message.user.content` |
| system | `message.system.content` |

### RPCs V3 creees

| RPC | But |
|---|---|
| `send_message_v3` | Ecriture message user avec `p_content_enc` |
| `get_messages_v3` | Lecture messages avec `content_enc` |
| `insert_system_message_v3` | Ecriture message system avec `p_content_enc` |

### Securite transitoire

- REVOKE EXECUTE sur:
  - `missions.send_message(uuid,text)`
  - `missions.get_messages_v2(uuid,integer,integer)`
  - `missions.insert_system_message(uuid,text,text)`
- Revocation etendue a `PUBLIC` pour eviter tout heritage implicite de droits.
- Les roles client (`authenticated`, `anon`) ne peuvent plus appeler les RPC plaintext.
- Garde-fous format ciphertext:
  - contrainte SQL `content_enc LIKE 'v1:%'`
  - validation RPC V3 sur `p_content_enc` (`non vide` + prefixe `v1:`)

### Fichiers crees

| Fichier | Modification |
|---|---|
| `server/utils/message-crypto.js` | NOUVEAU - wrapper encrypt/decrypt message content |
| `server/api/messages/[pmId].post.js` | NOUVEAU - envoi message chiffre via RPC V3 |
| `database/migrations/lot6_messages_encryption.sql` | NOUVEAU - schema + RPC V3 + revoke legacy |
| `database/migrations/lot6_cleanup_messages_plaintext.sql` | NOUVEAU - cleanup final apres QA |

### Fichiers modifies

| Fichier | Modification |
|---|---|
| `server/api/messages/[pmId].get.js` | Passe a `get_messages_v3`, dechiffre `content_enc` + `sender_first_name_enc` |
| `server/api/messages/company/threads-summary.post.js` | Passe a `get_messages_v3`, dechiffre `content_enc` pour les previews |
| `server/api/push/send-message-notification.js` | Push generique sans `message_preview` |
| `composables/useMessaging.js` | Cutover envoi: RPC client -> `POST /api/messages/:pmId` |

### Cleanup apres validation QA

- Executer `database/migrations/lot6_cleanup_messages_plaintext.sql`:
  - DROP anciennes RPC plaintext (`send_message`, `get_messages_v2`, `insert_system_message`)
  - DROP colonne `content`
  - `content_enc` passe `NOT NULL`
