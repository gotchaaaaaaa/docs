# Signature de Contrats - Guide Fonctionnel

> **Derniere mise a jour** : 25 Fevrier 2026  
> **Niveau cible** : SES renforcee, minimum probatoire sans WORM

---

## 1. Objectif metier

Avant demarrage d’une mission:
1. le document contractuel est genere (contrat ou convention)
2. l’entreprise signe
3. le prestataire signe

La signature repose sur:
- OTP email
- consentement explicite
- preuves techniques serveur
- hash et chaine d’evenements

---

## 2. Parcours utilisateur

### 2.1 Signature entreprise

1. lecture du PDF
2. case de consentement
3. demande OTP
4. saisie OTP
5. validation

Effets:
- statut contrat `pending_provider`
- pre-autorisation paiement (missions payantes)
- notification prestataire
- deadline de signature prestataire
- retention probatoire 10 ans initialisee si absente

### 2.2 Signature prestataire

1. lecture du PDF
2. case de consentement
3. demande OTP
4. saisie OTP
5. validation

Effets:
- statut `signed` + `fully_signed`
- generation certificats
- capture paiement initial (missions payantes)
- envoi contrat/certificats
- mission `assigned`
- retention probatoire 10 ans assuree

---

## 3. Ce qui est refuse automatiquement

- OTP expire
- OTP invalide apres 3 tentatives
- signature prestataire hors deadline
- incoherence consentement (version/hash/texte)
- indisponibilite backend anti-bruteforce en production (fail-closed)
- echec generation certificat final

---

## 4. Dossier de preuve (fonctionnel)

Le dossier de preuve contient:
- hash du PDF
- horodatages des deux signatures
- consentement versionne (texte exact + hash + locale + ecran)
- preuves techniques capturees cote serveur (IP, user-agent, request_id, chaine proxy trusted)
- chainage des evenements de signature
- certificats PDF des signataires
- statut de verification d’integrite
- retention + legal hold

---

## 5. Audits internes disponibles

### 5.1 Check contrat

`GET /api/contract/evidence/:contract_id/check`

Usage:
- verifier rapidement si le dossier est coherent (`overall_passed`)

### 5.2 Export dossier probatoire

`GET /api/contract/evidence/:contract_id/export`

Usage:
- recuperer le manifeste JSON complet du dossier de preuve

### 5.3 Legal hold

`POST /api/contract/evidence/:contract_id/legal-hold`

Usage:
- geler/degeler un dossier en cas de litige

---

## 6. Gouvernance probatoire

### 6.1 Verification automatique

Cron incremental:
- `POST /api/cron/check-contract-evidence`

Actions:
- re-check des contrats fully-signed
- journalisation des checks
- alerte admin en cas d’incoherence

### 6.2 Scellage quotidien gratuit (interne)

Cron:
- `POST /api/cron/seal-contract-evidence-daily`

Actions:
- manifeste quotidien canonique
- hash SHA-256 + signature HMAC
- verification possible via `/api/contract/evidence/seal/:seal_date/check`

---

## 7. Retention (sans WORM)

Politique par defaut:
- conservation 10 ans (`evidence_retention_until`)
- suppression contractuelle bloquee avant echeance
- suppression toujours bloquee sous `legal_hold`

Limite connue:
- sans WORM, le risque d’alteration admin/systeme n’est pas nul; il est reduit par les controles ci-dessus.

---

## 8. Prerequis exploitation

- reverse proxy stable renseigne dans `TRUSTED_PROXY_IPS`
- auth interne HMAC active (`INTERNAL_API_SECRET`)
- crons techniques actifs (scan + scellage)
- procedure legal hold connue par l’equipe ops/support

