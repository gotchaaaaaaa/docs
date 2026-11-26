# Signature de Contrats - Documentation Technique

> **Derniere mise a jour** : 18 Mars 2026
> **Perimetre** : SES renforcee (B2B France, sans WORM immediat)

---

## 1. Modele de donnees

### 1.1 Tables metier

`missions.contrats`
- document bilateral pour contrats et conventions de benevolat
- conserve le PDF, les consentements, les traces techniques, la chaine d'evenements et les certificats

`missions.devis`
- document unilateral pour les missions payantes
- conserve le PDF, les consentements entreprise, les traces techniques, la chaine d'evenements et le certificat

### 1.2 Schema `legal`

Le schema `legal` porte desormais toute la couche probatoire commune aux contrats/conventions et aux devis:

- `legal.signed_documents`
  - cle d'autorite par document signe
  - `document_kind = 'contract' | 'devis'`
  - retention, legal hold, dernier statut d'integrite
- `legal.integrity_checks`
  - historique des verifications
- `legal.daily_seals`
  - scelles quotidiens HMAC
- `legal.scan_state`
  - curseur incremental par `document_kind`

`companies.*` reste inchange pour les CGV entreprise.

### 1.3 Guard rails retention

Triggers `BEFORE DELETE` sur:
- `missions.contrats`
- `missions.devis`

La suppression est refusee si:
- `legal.signed_documents.legal_hold = true`, ou
- `now() < legal.signed_documents.retention_until`

### 1.4 Bucket `contracts`

Le bucket `contracts` reste le bucket d'artefacts signes:
- PDF chiffrés
- certificats chiffrés

Les acces directs `anon/authenticated` restent bloques; la lecture passe par les endpoints backend controles.

---

## 2. Securite transversale

`verifyInternalAuth(event)` accepte uniquement:
- `x-internal-timestamp`
- `x-internal-signature`

Le fallback `x-internal-secret` est supprime.

Fenetre anti-replay: 60s.

Le contexte IP proxy/trusted continue de passer par `server/utils/client-network-context.js`.

---

## 3. API interne probatoire

### 3.1 Contrats / conventions

- `GET /api/contract/evidence/:contract_id/check`
- `GET /api/contract/evidence/:contract_id/export`
- `POST /api/contract/evidence/:contract_id/legal-hold`
- `GET /api/contract/evidence/seal/:seal_date/check`

### 3.2 Devis

- `GET /api/devis/evidence/:devis_id/check`
- `GET /api/devis/evidence/:devis_id/export`
- `POST /api/devis/evidence/:devis_id/legal-hold`
- `GET /api/devis/evidence/seal/:seal_date/check`

Les exports restent en `export_version: v1` et exposent:
- metadonnees document
- preuves consentement / techniques / chaine
- statut d'integrite
- retention / legal hold
- dernier scan et dernier scelle si disponibles

---

## 4. Crons probatoires

### 4.1 Contrats

- `POST /api/cron/check-contract-evidence`
  - lit `legal.scan_state` pour `document_kind='contract'`
  - scanne `legal.signed_documents`
  - ecrit `legal.integrity_checks`
  - met a jour `legal.signed_documents.last_integrity_*`
- `POST /api/cron/seal-contract-evidence-daily`
  - agrege les `signed_documents` contrat du jour cible
  - construit le manifeste
  - calcule `manifest_hash`
  - signe par HMAC
  - stocke dans `legal.daily_seals`

### 4.2 Devis

- `POST /api/cron/check-devis-evidence`
- `POST /api/cron/seal-devis-evidence-daily`

Meme principe que les contrats, mais avec `document_kind='devis'`.

---

## 5. Retention

Par defaut:
- `EVIDENCE_RETENTION_YEARS=10`
- `legal.signed_documents.retention_until` est alimente a la signature

Gel litige:
- `legal.signed_documents.legal_hold=true` bloque toute suppression

---

## 6. Migrations de reference

- `database/migrations/008-legal-evidence-refactor.sql`
  - creation du schema `legal`
  - backfill contrats/devis signes
  - migration des checks/scelles contrats existants
  - triggers de retention sur `missions.contrats` et `missions.devis`
- `database/migrations/009-cancel-mission-document-aware.sql`
  - `missions.cancel_mission_v2` aware of `devis` pour les missions payantes

---

## 7. Fichiers de reference

| Fichier | Role |
|---------|------|
| `server/utils/legal/signed-documents.js` | Helper central `legal.signed_documents` |
| `server/utils/legal/contract-evidence-check.js` | Verification probatoire contrats |
| `server/utils/legal/devis-evidence-check.js` | Verification probatoire devis |
| `server/utils/legal/contract-evidence-seal.js` | Scellage contrats |
| `server/utils/legal/devis-evidence-seal.js` | Scellage devis |
| `server/api/contract/evidence/[contract_id]/check.get.js` | Check contrat |
| `server/api/contract/evidence/[contract_id]/export.get.js` | Export contrat |
| `server/api/contract/evidence/[contract_id]/legal-hold.post.js` | Legal hold contrat |
| `server/api/contract/evidence/seal/[seal_date]/check.get.js` | Verification scelle contrat |
| `server/api/devis/evidence/[devis_id]/check.get.js` | Check devis |
| `server/api/devis/evidence/[devis_id]/export.get.js` | Export devis |
| `server/api/devis/evidence/[devis_id]/legal-hold.post.js` | Legal hold devis |
| `server/api/devis/evidence/seal/[seal_date]/check.get.js` | Verification scelle devis |
| `server/api/cron/check-contract-evidence.js` | Scan incremental contrats |
| `server/api/cron/seal-contract-evidence-daily.js` | Scellage quotidien contrats |
| `server/api/cron/check-devis-evidence.js` | Scan incremental devis |
| `server/api/cron/seal-devis-evidence-daily.js` | Scellage quotidien devis |
