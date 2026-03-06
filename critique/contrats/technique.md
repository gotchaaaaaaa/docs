# Signature de Contrats - Documentation Technique

> **Derniere mise a jour** : 25 Fevrier 2026  
> **Perimetre** : SES renforcee (B2B France, sans WORM immediat)

---

## 1. Modele de donnees

### 1.1 `missions.contrats` (preuves SES)

Colonnes clefs:
- etat: `status`, `signature_status`
- document: `pdf_file_path`, `document_hash`, `pdf_generated_at`
- consentement versionne: `company/provider_consent_*`
- traces techniques: `company/provider_signature_*`
- chaine probatoire: `*_signature_payload_hash`, `*_signature_prev_event_hash`, `*_signature_event_hash`
- certificats: `company_certificate_pdf_path`, `provider_certificate_pdf_path`, `signature_certificate_generated_at`
- retention: `evidence_retention_until`, `evidence_legal_hold`, `evidence_legal_hold_reason`
- monitoring: `evidence_last_integrity_check_at`, `evidence_last_integrity_status`

### 1.2 Anti-abus distribue

Table `public.api_rate_limits`:
- PK `(namespace, rate_key_hash)`
- compteur `request_count`
- fenetre `reset_at`
- cleanup via `public.cleanup_expired_api_rate_limits()`

Fonction atomique:
- `public.check_and_increment_rate_limit(...)`

### 1.3 Monitoring / scellage

Tables:
- `public.contract_evidence_scan_state` (curseur incremental)
- `public.contract_evidence_checks` (historique de verification)
- `public.contract_evidence_daily_seals` (scelles quotidiens HMAC)

### 1.4 Guard rails retention

- trigger DB `BEFORE DELETE` sur `missions.contrats`
- suppression refusee si:
  - `evidence_legal_hold = true`, ou
  - `now() < evidence_retention_until`

### 1.5 Policies storage bucket `contracts`

Migration appliquee:
- write/delete `contracts`: service_role uniquement
- acces direct `anon/authenticated` sur `contracts`: bloque
- lecture utilisateur maintenue via endpoints backend controles

---

## 2. Securite interne (HMAC strict)

`verifyInternalAuth(event)` accepte uniquement:
- `x-internal-timestamp`
- `x-internal-signature`

Le fallback `x-internal-secret` est supprime.

Fenetre anti-replay: 60s.

---

## 3. Proxy trust / IP

Nouvelle util: `server/utils/client-network-context.js`

Regles:
1. l’IP client issue des headers proxy n’est acceptee que si `remoteAddress` appartient a `TRUSTED_PROXY_IPS`.
2. sinon, on ignore `x-forwarded-for`/`x-real-ip` et on prend `remoteAddress`.
3. ce contexte est utilise par:
   - `request-evidence`
   - `rate-limit`
   - `audit-log`

---

## 4. Rate-limit OTP (fail-closed prod)

`checkDistributedRateLimit(...)`:
- backend nominal: DB (`check_and_increment_rate_limit`)
- en production avec `RATE_LIMIT_FAIL_CLOSED_PROD=true`:
  - si DB indisponible -> requete bloquee (`backend_unavailable`)
- hors production: fallback memoire conserve

Endpoints OTP (`send-otp`, `verify-otp` company/provider):
- message homogène si backend anti-abus indisponible.

---

## 5. API interne probatoire

### 5.1 Verification unitaire

`GET /api/contract/evidence/:contract_id/check`

Retourne:
- checks PDF / consentement / traces techniques / chaine / certificats
- `overall_passed`
- `failure_reasons`

### 5.2 Export dossier de preuve

`GET /api/contract/evidence/:contract_id/export`

Retourne `export_version: v1` avec:
- metadonnees contrat
- preuves consentement/techniques/chaine
- resultats integrite
- retention/legal hold
- references scan et scelle quotidien (si present)

### 5.3 Legal hold

`POST /api/contract/evidence/:contract_id/legal-hold`

Body:
```json
{
  "legal_hold": true,
  "reason": "litige client #123"
}
```

### 5.4 Verification scelle quotidien

`GET /api/contract/evidence/seal/:seal_date/check`

`seal_date` format: `YYYY-MM-DD`.

---

## 6. Crons probatoires

### 6.1 Scan incremental

`POST /api/cron/check-contract-evidence`

Fonction:
- lit le curseur `contract_evidence_scan_state`
- scanne incrementalement les `fully_signed` modifies
- ecrit `contract_evidence_checks`
- met a jour `missions.contrats.evidence_last_integrity_*`
- envoie alerte admin si echecs

### 6.2 Scellage quotidien (SHOULD gratuit)

`POST /api/cron/seal-contract-evidence-daily`

Fonction:
- agrège les contrats fully-signed du jour cible
- construit un manifeste canonique
- calcule `manifest_hash` SHA-256
- signe par HMAC (`manifest_hmac`)
- stocke dans `contract_evidence_daily_seals`

---

## 7. Rention / conservation

Par defaut:
- `EVIDENCE_RETENTION_YEARS=10`
- `evidence_retention_until` alimente a la signature (si absent)

Gel litige:
- `evidence_legal_hold=true` bloque toute suppression

---

## 8. Variables d’environnement

- `RATE_LIMIT_FAIL_CLOSED_PROD=true`
- `TRUSTED_PROXY_IPS=ip1,ip2,...`
- `EVIDENCE_RETENTION_YEARS=10`
- `EVIDENCE_SCAN_BATCH_SIZE=200`
- `EVIDENCE_SEAL_ENABLED=true`

---

## 9. Fichiers de reference

| Fichier | Role |
|---------|------|
| `database/migrations/strengthen_ses_evidence_and_rate_limits.sql` | Schema SES, retention, monitoring, policies |
| `server/utils/internal-auth.js` | Auth interne HMAC strict |
| `server/utils/client-network-context.js` | Contexte IP/proxy trusted |
| `server/utils/distributed-rate-limit.js` | Rate-limit distribue fail-closed prod |
| `server/utils/contract-evidence-check.js` | Moteur central de verification probatoire |
| `server/utils/evidence-seal.js` | Canonicalisation/hash/HMAC des scelles |
| `server/api/contract/evidence/[contract_id]/check.get.js` | Check unitaire |
| `server/api/contract/evidence/[contract_id]/export.get.js` | Export dossier preuve |
| `server/api/contract/evidence/[contract_id]/legal-hold.post.js` | Gestion legal hold |
| `server/api/contract/evidence/seal/[seal_date]/check.get.js` | Verification scelle |
| `server/api/cron/check-contract-evidence.js` | Scan incremental integrite |
| `server/api/cron/seal-contract-evidence-daily.js` | Scellage quotidien |

