# Facturation - Documentation Technique

> **Derniere mise a jour** : Fevrier 2026

---

## 1. Tables & Colonnes Cles

### `missions.invoices`

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | UUID | Identifiant unique |
| `profile_mission_id` | UUID (FK) | Reference vers `profile_missions` |
| `mission_id` | UUID (FK) | Reference vers `missions` |
| `invoice_type` | TEXT | `provider_to_company` ou `gotcha_commission` |
| `issuer_type` | TEXT | `provider` ou `gotcha` |
| `issuer_id` | UUID (FK, nullable) | Reference vers `providers` (null pour gotcha) |
| `recipient_company_id` | UUID (FK) | Reference vers `companies` |
| `invoice_number` | INTEGER | Numero sequentiel unique |
| `invoice_date` | DATE | Date d'emission |
| `amount_ht` | NUMERIC | Montant hors taxes |
| `tva_rate` | NUMERIC | Taux de TVA (0 ou 20%) |
| `tva_amount` | NUMERIC | Montant TVA |
| `amount_ttc` | NUMERIC | Montant TTC |
| `mission_date` | TIMESTAMP | Date de la mission |
| `hours_worked` | NUMERIC | Heures de base |
| `hours_supp` | NUMERIC | Heures supplementaires |
| `hourly_rate` | NUMERIC | Taux horaire de base |
| `hourly_rate_supp` | NUMERIC | Taux horaire supp (1.25x base) |
| `description` | TEXT | Description de la facture |
| `pdf_storage_path` | TEXT | Chemin dans Supabase Storage (chiffre) |
| `pdf_generated_at` | TIMESTAMP | Date de generation du PDF |

**Champs chiffres :**

| Colonne | Type | Description |
|---------|------|-------------|
| `issuer_name_enc` | BYTEA | Nom de l'emetteur (chiffre) |
| `issuer_address_enc` | BYTEA | Adresse de l'emetteur |
| `issuer_siret_enc` | BYTEA | SIRET de l'emetteur |
| `issuer_tva_number_enc` | BYTEA | Numero TVA de l'emetteur |
| `recipient_name_enc` | BYTEA | Nom du destinataire |
| `recipient_address_enc` | BYTEA | Adresse du destinataire |
| `recipient_siret_enc` | BYTEA | SIRET du destinataire |
| `email_recipient_enc` | BYTEA | Email du destinataire (audit) |
| `issuer_siret_bidx` | TEXT | Blind index SIRET emetteur |
| `email_recipient_bidx` | TEXT | Blind index email |

### `missions.invoice_sequences`

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | BIGINT | Identifiant unique |
| `last_number` | BIGINT | Compteur de factures courant |

Seul le `service_role` peut gerer les sequences.

### Colonnes liees dans `missions.profile_missions`

| Colonne | Description |
|---------|-------------|
| `daily_rate` | TJM HT pour les heures de base (depuis `migrate_to_tjm.sql`) |
| `daily_rate_supp` | TJM HT supplementaire (defaut `daily_rate * 1.25`) |
| `billing_days` | Nombre de jours factures (regle half-day, cf. `update_billing_to_half_day_rule.sql`) |
| `preparation_hours` | Heures de preparation (au taux `daily_rate / 8`) |
| `additional_fee_lines` | JSONB array `[{description, amount_ht}]` (devis) — max 20 lignes |
| `additional_fees_ht` | Somme des frais additionnels HT |
| `final_adjustment_lines` | JSONB array (rapport post-mission) |
| `final_adjustments_ht` | Somme des ajustements finaux HT |
| `commission_amount` | Commission totale calculee |
| `commission_rate` | **13% HT** depuis avril 2026 (`provider_commission_model_13_percent.sql`) |
| `stripe_fee_amount` | Frais Stripe HT+TVA refactures (cf. `update_commission_invoice_transaction_fee_ht_tva.sql`) |
| `recipient_type` | `company` ou `provider` (split commission) |
| `recipient_provider_id` | UUID si facture vers prestataire |
| `provider_invoice_number` | Numero facture prestataire (cf. `add_provider_invoice_number.sql`) |
| `amount_ht` | Montant HT prestataire |
| `tva_amount` | TVA prestataire |
| `amount_ttc_provider` | Total TTC prestataire |

---

## 2. Calcul des Couts

### Hierarchie des tarifs (TJM)

1. **Source principale** : `profile_missions.daily_rate` / `daily_rate_supp` (devis signe)
2. Provenance : negocies via le `PostulerDrawer` (etape 4 — TJM avec clamp min/max)
3. Conversion horaire : `hourly_rate = daily_rate / 8`

### TJM supplementaire

Defaut : `daily_rate_supp = daily_rate * 1.25` (clampable via PostulerDrawer).

### Regle demi-journee

`utils/rate-calculation.js` :
- `billing_days = ceil(hours / 4) * 0.5` (mono-jour)
- `billing_days = nb_jours_mission` (multi-jour)
- Le prestataire peut overrider (cf. `canUpgradeBillingDays`)

### Exemple de calcul complet

```
Mission 1 jour, TJM 250 EUR HT, 2h prep, 50 EUR frais additionnels
Provider assujetti TVA (regime_tva = true)

Base HT                    = 250 x 1                = 250.00 EUR
Preparation HT             = 2 x (250/8)            =  62.50 EUR
Frais additionnels HT      = 50                     =  50.00 EUR
Sous-total HT prestataire  = 362.50 EUR
TVA (20%)                  = 362.50 x 0.20          =  72.50 EUR
Total TTC prestataire      = 435.00 EUR

Commission Gotcha HT       = 362.50 x 13%           =  47.13 EUR
Commission TVA             = 47.13 x 20%            =   9.43 EUR
Commission TTC             = 56.56 EUR

Frais Stripe HT            = (435 x 1.5%) + 0.25    =   6.78 EUR
Frais Stripe TVA           = 6.78 x 20%             =   1.36 EUR
Frais Stripe TTC           = 8.14 EUR
----------------------------------------------
TOTAL FACTURE ENTREPRISE   =                          435.00 EUR  (TTC prestataire)
RECU NET PAR PRESTATAIRE   = 435 - 56.56 - 8.14    = 370.30 EUR
GOTCHA ENCAISSE            =                          64.70 EUR (application_fee_amount)
```

> **Modele absorbed** (commit `42f78b7`) : l'entreprise paie strictement les 435 EUR TTC prestataire. La commission (56.56 EUR) et les frais Stripe (8.14 EUR) sont preleves automatiquement par Stripe via `application_fee_amount` sur le transfer vers le compte Connect du prestataire.

> **En presence d'un acompte (base_ht >= 800 EUR)** : phase 1 = 30% TTC preleve directement (transfere integralement au prestataire), phase 2 = solde TTC restant preleve + application_fee complet (commission sur HT total + frais Stripe sur le solde). Voir `documentation/critique/paiement/fonctionnement.md`.

### TVA

**Prestataire** (`providers.regime_tva`) :
- Si `true` : TVA 20% appliquee sur le montant prestataire
- Si `false` : Pas de TVA (prestataire non assujetti)

**Gotcha** :
- Toujours TVA 20% (societe assujettie)
- Appliquee sur la commission

**Commission** :
- **13% HT** calculee sur le HT prestataire complet (TJM × jours + prep + additional fees + final adjustments)
- TVA 20% en sus
- Cf. constantes `GOTCHA_COMMISSION_RATE_HT = 0.13` (`utils/payment-amounts.js`)
- Migration : `provider_commission_model_13_percent.sql` (avril 2026, anciennement 12.5% TTC)

---

## 3. Declenchement de la Facturation

**Point d'entree** : `/api/stripe/release-payment.js`

Les factures sont generees **automatiquement** apres la capture du paiement final :

```javascript
if (flow.final_status === "final_captured") {
    await $fetch("/api/invoices/generate", {
        method: "POST",
        headers: createInternalAuthHeaders(),
        body: { profile_mission_id }
    });
}
```

**Pre-requis** :
- `payment_status` en `final_captured` ou `transferred`
- `provider_validation_status = "approved"` (pas de litige en cours)
- Aucune facture deja generee pour cette mission

---

## 4. Flux de Generation

### `POST /api/invoices/generate` (auth interne HMAC)

**Fichier** : `server/api/invoices/generate.post.js`

#### Etape 1 : Charger les templates

```javascript
const [providerTemplate, commissionTemplate] = await Promise.all([
    supabase.from('trames').select('vars_schema').eq('key', 'invoice_provider').single(),
    supabase.from('trames').select('vars_schema').eq('key', 'invoice_commission').single()
]);
```

Templates dans `public.trames` controlent : labels (texte francais), couleurs, polices, sections du layout.

#### Etape 2 : Recuperer les donnees

```javascript
const { data: generationData } = await supabase
    .schema('missions')
    .rpc('invoice_get_generation_data_v4', { p_profile_mission_id });
```

Retourne : `profile_mission`, `mission`, `provider`, `company`, `existing_invoices`.

#### Etape 3 : Dechiffrer les champs sensibles

```javascript
const decryptedProviderProfile = decryptProfileFields(providerProfile);
const decryptedCompanyProfile = decryptProfileFields(companyProfile);
const decryptedCompanyFields = decryptCompanyFields({ siret_enc, siret_gouv_infos_enc });
const decryptedProviderFields = decryptProviderFields({ siret_enc, adresse_facturation_enc, tva_number_enc });
```

#### Etape 4 : Generer la facture prestataire

**Calcul des montants** :
```javascript
const baseAmount = hoursWorked * hourlyRate;
const suppAmount = hoursSupp * hourlyRateSupp;
const providerAmountHt = baseAmount + suppAmount;

const providerTvaRate = provider.regime_tva ? 20 : 0;
const providerTvaAmount = providerAmountHt * (providerTvaRate / 100);
const providerAmountTtc = providerAmountHt + providerTvaAmount;
```

**Donnees de la facture** :
```javascript
{
    invoiceNumber: <auto-genere>,
    invoiceDate: <now>,
    issuer: {
        name: "prenom nom du prestataire",
        address: provider.adresse_facturation,
        siret: provider.siret,
        tvaNumber: provider.tva_number || null
    },
    recipient: {
        name: company.nom_commercial,
        address: <extraite de siret_gouv_infos>,
        siret: company.siret
    },
    missionTitle, missionDate,
    hoursWorked, hoursSupp,
    hourlyRate, hourlyRateSupp,
    baseAmount, suppAmount,
    amountHt, tvaRate, tvaAmount, amountTtc
}
```

**Generation et stockage du PDF** :
```javascript
const providerPdfBuffer = await generateProviderInvoicePdf(providerInvoiceData, providerTemplate);
const encryptedBuffer = encryptFileBuffer(providerPdfBuffer, 'file.invoice_pdf');
await supabase.storage.from('invoices').upload(`invoices/${invoiceNumber}.pdf.enc`, encryptedBuffer);
```

**Insertion en BDD** via RPC `invoice_insert_v2`.

#### Etape 5 : Generer la facture commission Gotcha

**Calcul** :
```javascript
const commissionTtc = pmData.commission_amount || (providerAmountHt * 0.125);
const gotchaTvaRate = 20;  // Gotcha toujours assujettie
const commissionHt = commissionTtc / (1 + gotchaTvaRate / 100);
const gotchaTvaAmount = commissionTtc - commissionHt;
```

**Donnees** :
```javascript
{
    issuer: {
        name: 'GOTCHAAAA SAS',
        address: config.gotchaAddress,
        siret: config.gotchaSiret,
        tvaNumber: config.gotchaTvaNumber
    },
    recipient: { ... },  // meme entreprise
    description: 'Commission de mise en relation - ...',
    amountHt: commissionHt,
    tvaRate: 20,
    tvaAmount: gotchaTvaAmount,
    amountTtc: commissionTtc
}
```

---

## 5. Distribution par Email

### `POST /api/invoices/send-emails` (auth interne HMAC)

**Fichier** : `server/api/invoices/send-emails.post.js`

**Declencheur** : Appele automatiquement apres la generation des factures.

#### Recuperation des donnees

```javascript
const { data: emailData } = await supabase
    .schema('missions')
    .rpc('invoice_get_email_data_v3', { p_profile_mission_id });
```

#### Email consolide a l'entreprise

**Objet** : `Gotcha! - Factures mission du [date]`

**Contenu** :
- Logo + "Vos factures sont pretes"
- Carte facture prestataire (bordure violette) : numero, nom prestataire, titre mission, montant TTC
- Carte facture commission (bordure violette) : numero, "Frais de mise en relation (13% HT)", montant TTC, ligne frais Stripe
- Section **Total preleve** (grand format)
- Info pieces jointes
- "Retrouvez toutes vos factures dans votre compte Gotcha!"

**Pieces jointes** : Les 2 PDFs

#### Email copie au prestataire

**Objet** : `Gotcha! - Facture [numero] envoyee`

**Contenu** :
- Logo + "Facture envoyee"
- Carte details (bordure verte) : numero, titre mission, date, client, montant TTC
- Info : "Cette facture est jointe a cet email..."

**Piece jointe** : Facture prestataire uniquement

#### Processus d'envoi

```javascript
// 1. Telecharger et dechiffrer les PDFs
const pdfBuffer = decryptMaybeEncryptedFileBuffer(storageBuffer, 'file.invoice_pdf');

// 2. Envoyer l'email consolide a l'entreprise (2 pieces jointes)
await transport.sendMail({ to: companyEmail, attachments: [providerPDF, commissionPDF] });

// 3. Envoyer la copie au prestataire (1 piece jointe)
await transport.sendMail({ to: providerEmail, attachments: [providerPDF] });

// 4. Marquer les emails comme envoyes en BDD
await supabase.schema('missions').rpc('invoice_mark_email_sent_v2', { ... });
```

---

## 6. Consultation & Telechargement

### Liste des factures (`GET /api/invoices/list`)

**Fichier** : `server/api/invoices/list.get.js`

**Parametre** : `role` (query param) : `provider` ou `company`

**Processus** :
1. Authentification
2. Appel RPC `invoice_list_for_user_v2` (filtre par role via RLS)
3. Dechiffrement des noms pour affichage
4. Groupement par mois

**Reponse** :
```json
{
  "success": true,
  "invoices": [...],
  "grouped": [
    {
      "label": "Fevrier 2026",
      "key": "2026-02",
      "invoices": [...]
    }
  ],
  "total": 5
}
```

### Telechargement (`GET /api/invoices/[id]/download`)

**Fichier** : `server/api/invoices/[id]/download.get.js`

1. Authentification
2. Verification d'acces via RPC `invoice_download_check_access_v2`
3. Telechargement depuis Supabase Storage
4. Dechiffrement du PDF
5. Retour avec headers `Content-Type: application/pdf`

---

## 7. Pages Frontend

### Page Factures Prestataire

**Fichier** : `pages/prestataire/compte/factures.vue`

- Liste toutes les factures emises par le prestataire
- Groupees par mois
- Affiche : date, entreprise destinataire, montant TTC
- Actions : Voir (modal), Telecharger
- Etat vide si aucune facture

### Page Factures Entreprise

**Fichier** : `pages/entreprise/compte/factures.vue`

- Liste les factures prestation ET commission
- Groupees par mois
- Badge couleur : Bleu "Prestation", Violet "Commission"
- Affiche : date, nom emetteur, type, montant TTC
- Actions : Voir, Telecharger

### Visionneuse PDF

**Fichier** : `components/shared/InvoicePdfViewer.vue`

- Modal overlay (position fixe, fond floute)
- Rendu PDF avec PDF.js (`SharedPdfJsScrollViewer`)
- Boutons zoom +/-
- Bouton telechargement
- Etats de chargement et d'erreur

---

## 8. Fonctions SQL (RPCs)

| Fonction | Description |
|----------|-------------|
| `get_next_invoice_number()` | Numero sequentiel suivant (depuis la sequence) |
| `invoice_get_generation_data_v4(p_profile_mission_id)` | Toutes les donnees pour la generation |
| `invoice_insert_v2(p_invoice_data)` | Insertion avec champs chiffres |
| `invoice_get_email_data_v3(p_profile_mission_id)` | Donnees pour l'envoi email |
| `invoice_mark_email_sent_v2(p_invoice_id, ...)` | Marquer email envoye (audit) |
| `invoice_list_for_user_v2(p_user_id, p_role)` | Liste pour un utilisateur (role-aware) |
| `invoice_download_check_access_v2(p_invoice_id, p_user_id)` | Verification d'acces |
| `update_invoices_updated_at()` | Trigger auto-update `updated_at` |

---

## 9. Securite

### Politiques RLS sur `missions.invoices`

```sql
-- Prestataires voient leurs factures emises
CREATE POLICY "Providers can view their issued invoices" ON missions.invoices
    FOR SELECT USING (issuer_id IN (
        SELECT id FROM providers.providers WHERE profile = auth.uid()
    ));

-- Entreprises voient leurs factures recues
CREATE POLICY "Companies can view their received invoices" ON missions.invoices
    FOR SELECT USING (recipient_company_id IN (
        SELECT id FROM companies.companies WHERE profile = auth.uid()
    ));

-- Seul service_role peut inserer (API backend)
CREATE POLICY "Allow insert for service role" ON missions.invoices
    FOR INSERT TO service_role WITH CHECK (true);
```

### Chiffrement

**Champs** : `issuer_name_enc`, `issuer_address_enc`, `issuer_siret_enc`, `issuer_tva_number_enc`, `recipient_name_enc`, `recipient_address_enc`, `recipient_siret_enc`, `email_recipient_enc`

**Fichiers PDF** : Chiffres avec `encryptFileBuffer()` (AES-256-GCM) avant stockage. Dechiffres a la volee pour telechargement via `decryptMaybeEncryptedFileBuffer()` (retrocompatibilite si non chiffre).

### Middleware

- Pages prestataire : `middleware: ['auth', 'is-candidat']`
- Pages entreprise : `middleware: ['auth', 'is-entreprise']`
- API generation/envoi : auth interne HMAC uniquement

---

## 10. Generation PDF & Templates

### Bibliotheque : PDFKit

**Fichier** : `server/utils/invoice-pdf.js`

1. Creer un `PDFDocument`
2. Appliquer les settings du template (couleurs, polices)
3. Dessiner le header (logo, type de facture)
4. Blocs emetteur/destinataire
5. Tableau detaille (heures x taux = montant)
6. Section totaux (HT, TVA, TTC)
7. Footer (conditions, signatures, dates)
8. Retourner le buffer

### Templates dans `public.trames`

```javascript
{
    key: 'invoice_provider' | 'invoice_commission',
    vars_schema: {
        settings: {
            colors: { primary: '#6600ff', text: '#111827', border: '#E5E7EB' },
            fonts: { regular: 'Helvetica', bold: 'Helvetica-Bold' }
        },
        sections: { header, recipient, table, totals, payment, footer }
    }
}
```

Fallback vers des valeurs par defaut codees en dur si le template est absent.

---

## 11. Gestion des Erreurs

| Situation | Code | Gestion |
|-----------|------|---------|
| `payment_status` pas `final_captured`/`transferred` | 400 | Mission pas eligible a la facturation |
| `provider_validation_status` != `approved` | 400 | Litige en cours ou validation en attente |
| Factures deja generees | 400 | Prevention des doublons |
| Template absent | Warn | Continue avec style par defaut |
| Upload PDF echoue | Warn | Facture sauvegardee sans PDF (path null) |
| Erreur RPC | 500 | Transaction annulee |
| Utilisateur non authentifie | 401 | Login requis |
| Facture non trouvee | 404 | ID invalide |
| Acces refuse (RLS) | 403 | Ni emetteur ni destinataire |
| Fichier PDF supprime | 404 | Chemin storage casse |
| Dechiffrement echoue | 500 | Log erreur, message generique |

---

## 12. Diagramme du Flux Complet

```
1. MISSION TERMINEE
   +-- Entreprise soumet le rapport (heures travaillees/supp)
   +-- Prestataire valide le rapport (ou auto 72h)

2. CAPTURE DU PAIEMENT (voir ../paiement/technique.md)
   +-- release-payment capture le paiement final
   +-- payment_status = "final_captured"

3. GENERATION DES FACTURES (declenchement automatique)
   +-- POST /api/invoices/generate (auth interne)
       |-- Charger les templates depuis public.trames
       |-- Recuperer les donnees via RPC
       |-- Dechiffrer les champs sensibles
       |-- Generer 2 PDFs :
       |   |-- Facture prestataire (HT + TVA)
       |   +-- Facture commission Gotcha (commission HT + TVA)
       |-- Chiffrer et stocker dans Supabase Storage
       |-- Sauvegarder les enregistrements (chiffres)
       +-- Appeler POST /api/invoices/send-emails

4. DISTRIBUTION PAR EMAIL
   +-- POST /api/invoices/send-emails (auth interne)
       |-- Telecharger et dechiffrer les PDFs
       |-- Envoyer a l'entreprise : email consolide avec les 2 factures
       +-- Envoyer au prestataire : copie de sa facture uniquement

5. CONSULTATION (Frontend)
   +-- Prestataire : GET /api/invoices/list?role=provider
       +-- pages/prestataire/compte/factures.vue
   +-- Entreprise : GET /api/invoices/list?role=company
       +-- pages/entreprise/compte/factures.vue

6. TELECHARGEMENT
   +-- GET /api/invoices/[id]/download
       |-- Verification auth + acces RLS
       |-- Telechargement depuis Storage
       |-- Dechiffrement du PDF
       +-- Retour au client (application/pdf)
```

---

## 13. Variables d'Environnement

```bash
# Chiffrement
DATA_ENCRYPTION_KEY=...
BLIND_INDEX_KEY=...

# Email
SMTP_HOST=...
SMTP_PORT=...
SMTP_USER=...
SMTP_PASS=...
SMTP_FROM=hello@gotchaaaa.com

# Gotcha (informations emetteur pour facture commission)
GOTCHA_COMPANY_NAME=GOTCHAAAA SAS
GOTCHA_SIRET=...
GOTCHA_ADDRESS=...
GOTCHA_TVA_NUMBER=...
```

---

## 14. Evolution vers Plateforme Agreee (PA)

> **Statut : PLANIFIE — 3 phases jusqu'a sept. 2027**
> Decision : Cas 17a (prestataire emet sa propre facture). Voir `analyse-conformitee-facturation.md`

### Phase 1 : Maintenant → aout 2026 — Aucun changement technique

Le systeme actuel (PDFKit + email) reste legal et inchange.

### Phase 2 : Sept. 2026 → aout 2027 — Regime mixte

**Modifications techniques a prevoir :**
- Ajouter un champ `has_billing_platform` (ou equivalent) dans le profil prestataire
- Si le prestataire a une PA : afficher un ecran recap avec toutes les infos facture (copier/coller)
- Si le prestataire n'a pas de PA : continuer a generer le PDF + envoi email (comme avant)
- F2 (commission Gotcha) : toujours PDF + email (legal, on est PME)

### Phase 3 : A partir de sept. 2027 — Tout via PA

**Modifications techniques :**
- Supprimer la generation PDF pour F1 (`server/utils/invoice-pdf.js` cote prestataire)
- Ecran recap post-mission avec bouton "Copier les informations" (toujours via `invoice_get_generation_data_v4`)
- Integrer l'emission F2 (commission) via l'API de la PA de Gotcha
- Adapter `server/api/invoices/generate.post.js` pour envoyer les donnees F2 a la PA au lieu de generer le PDF localement
- Conserver la table `missions.invoices` comme miroir local (numero, montants, references)

### PA recommandees (gratuites)

| Solution | URL |
|----------|-----|
| Qonto | qonto.com/fr/invoicing/e-invoicing |
| Tiime | tiime.fr/plateforme-dematerialisation-partenaire-pdp |
| Pennylane | pennylane.com/fr/logiciel-facturation-electronique |

### Alternative ecartee : Iopole (cas 17b, mandat)

Cout : 2 000 EUR setup + 199 EUR/mois + 5 EUR/SIRET. Ecarte pour l'instant, envisageable si le volume le justifie.

---

## 15. Fichiers Cles

| Fichier | Description |
|---------|-------------|
| `server/api/invoices/generate.post.js` | Generateur principal (2 factures, PDFs, chiffrement) |
| `server/api/invoices/list.get.js` | Liste des factures (filtrage par role, dechiffrement, groupement) |
| `server/api/invoices/send-emails.post.js` | Distribution email (templates HTML, pieces jointes) |
| `server/api/invoices/[id]/download.get.js` | Telechargement PDF (controle d'acces, dechiffrement) |
| `server/utils/invoice-pdf.js` | Generation PDF (PDFKit, templates) |
| `server/utils/invoice-crypto.js` | Chiffrement/dechiffrement des champs |
| `server/utils/file-crypto.js` | Chiffrement des buffers PDF |
| `pages/prestataire/compte/factures.vue` | UI factures prestataire |
| `pages/entreprise/compte/factures.vue` | UI factures entreprise |
| `components/shared/InvoicePdfViewer.vue` | Modal visionneuse PDF |
| `server/api/stripe/release-payment.js` | Declencheur de la facturation |
