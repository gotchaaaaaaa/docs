# Chiffrement applicatif des fichiers (Storage)

Ce document explique:
- ce qui est deja en place pour le chiffrement des fichiers
- comment reproduire localement
- comment ajouter un nouveau type de fichier chiffre (ex: `attestation_vigilance`, `avis_situation_siren`)

Ce guide est la reference implementation pour les futurs flows documents.

---

## 1) Etat actuel

Le chiffrement applicatif est actif pour:
- Factures (`invoices`)
- Contrats (`contracts`)
- Certificats de signature (`contracts/certificates`)

Les fichiers sont chiffres **avant upload** dans Supabase Storage, et dechiffres **au moment de la lecture** cote serveur.

Les nouveaux objets sont stockes avec suffixe:
- `*.pdf.enc`

Les anciens fichiers non chiffres restent lisibles (fallback legacy).

---

## 2) Variables d env

Variable obligatoire:
- `FILE_ENCRYPTION_KEY` = cle hex de 64 caracteres (32 bytes)

Generation:

```powershell
node -e "console.log('FILE_ENCRYPTION_KEY=' + require('crypto').randomBytes(32).toString('hex'))"
```

Configuration code:
- `nuxt.config.ts` -> `runtimeConfig.fileEncryptionKey`
- `server/plugins/validate-env.ts` -> validation stricte de la cle

---

## 3) Format crypto fichier

Implementation: `server/utils/file-crypto.js`

- Algo: `AES-256-GCM`
- Header binaire fixe: `GCHFILE1`
- Payload: `GCHFILE1 + iv(12) + authTag(16) + ciphertext`
- AAD (domain binding) selon type de fichier

Fonctions utilitaires:
- `encryptFileBuffer(buffer, domain)`
- `decryptFileBuffer(buffer, domain)`
- `decryptMaybeEncryptedFileBuffer(buffer, domain)` (fallback legacy)
- `isEncryptedFileBuffer(buffer)`

---

## 4) Domains AAD

Domains actuellement utilises:
- `file.invoice_pdf`
- `file.contract_pdf`
- `file.contract_certificate`

Regle:
- un domain par type fonctionnel de document
- ne pas reutiliser un domain "generic" pour tous les fichiers

---

## 5) Pattern upload / download a reproduire

### Upload (serveur)

1. Recevoir/generer le buffer clair
2. Chiffrer avec `encryptFileBuffer(..., domain)`
3. Uploader le buffer chiffre vers storage
4. Utiliser:
   - extension `.enc`
   - `contentType: 'application/octet-stream'`

Exemples en place:
- `server/api/invoices/generate.post.js`
- `server/utils/pdf-generator.js`
- `server/utils/certificate-generator.js`

### Download (serveur)

1. Verifier auth + autorisation metier
2. `storage.download(path)`
3. `decryptMaybeEncryptedFileBuffer(buffer, domain)`
4. Renvoyer le vrai fichier (ex: `application/pdf`)

Exemples en place:
- `server/api/invoices/[id]/download.get.js`
- `server/api/contract/download-pdf.get.js`
- `server/api/contract/download-certificate.get.js`
- `server/api/invoices/send-emails.post.js`
- `server/api/contract/send-email.post.js`

Important:
- Ne pas renvoyer de signed URL pour fichiers chiffres
- Renvoyer un flux binaire via endpoint API auth

Endpoint deprecie:
- `GET /api/invoices/:id/view-url` -> `410 Gone`

---

## 6) Frontend: mode lecture

Pattern frontend actuel:
- appel API avec `Authorization: Bearer ...`
- reception `Blob`
- `URL.createObjectURL(blob)` pour viewer/download
- `URL.revokeObjectURL(...)` au cleanup

Exemples:
- `components/shared/ContractPdfViewer.vue`
- `components/shared/InvoicePdfViewer.vue`
- `pages/prestataire/compte/mes-contrats.vue`
- `pages/entreprise/compte/mes-contrats.vue`

---

## 7) Reproduire localement (pas a pas)

### A. Setup

1. Ajouter `FILE_ENCRYPTION_KEY` dans `.env`
2. Redemarrer le serveur Nuxt

Option verification env stricte:

```powershell
$env:VALIDATE_ENV='true'
npm run dev
```

### B. Smoke test generation

1. Generer une facture
2. Generer un contrat et ses certificats
3. Verifier que les paths storage finissent par `.pdf.enc`

### C. Smoke test lecture

1. Ouvrir une facture dans UI
2. Ouvrir un contrat dans UI
3. Telecharger un certificat
4. Verifier que le fichier recu est bien lisible en PDF

### D. Test legacy

1. Prendre un ancien path non chiffre (sans header `GCHFILE1`)
2. Appeler endpoint download
3. Verifier que le fichier est encore servi correctement

### E. Test endpoint deprecie

1. Appeler `GET /api/invoices/:id/view-url`
2. Verifier HTTP `410`

---

## 8) Cas collegue: attestation de vigilance + avis de situation siren

Contexte:
- ces fichiers doivent etre chiffres aussi
- le flow actuel d upload documents sera refait

### Checklist implementation (a suivre)

1. **Choisir les domains AAD**
   - `file.provider.attestation_vigilance`
   - `file.provider.avis_situation_siren`

2. **Upload**
   - chiffrer le buffer juste avant `supabase.storage.upload`
   - stocker en `*.enc`
   - `contentType: application/octet-stream`

3. **Lecture**
   - passer uniquement par endpoint serveur auth
   - `decryptMaybeEncryptedFileBuffer(buffer, domain)`
   - renvoyer le MIME final adapte au fichier

4. **Aucun signed URL direct**
   - pas de `createSignedUrl` pour ces fichiers chiffres

5. **Compat legacy**
   - garder fallback pour fichiers historiques non chiffres

6. **Jobs secondaires**
   - si un cron/email/webhook lit ces fichiers, dechiffrer aussi a cet endroit

7. **Tests**
   - upload nouveau fichier -> storage `.enc`
   - lecture autorisee -> fichier lisible
   - lecture non autorisee -> 403
   - ancien fichier non chiffre -> toujours lisible

### Anti-patterns a eviter

- chiffrement cote frontend
- cle partagee avec `DATA_ENCRYPTION_KEY`
- path `.pdf` sans suffixe `.enc` pour un fichier chiffre
- endpoint qui expose le contenu chiffre sans dechiffrement

---

## 9) Fichiers de reference

- `server/utils/file-crypto.js`
- `server/utils/pdf-generator.js`
- `server/utils/certificate-generator.js`
- `server/api/invoices/generate.post.js`
- `server/api/invoices/[id]/download.get.js`
- `server/api/contract/download-pdf.get.js`
- `server/api/contract/download-certificate.get.js`
- `server/api/invoices/[id]/view-url.get.js` (deprecated)
- `server/middleware/security-headers.ts` (`connect-src` inclut `blob:` pour PDF.js)
