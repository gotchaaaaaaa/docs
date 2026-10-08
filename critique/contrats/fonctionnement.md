# Signature de Contrats - Guide Fonctionnel

> **Derniere mise a jour** : 18 Mars 2026
> **Niveau cible** : SES renforcee, minimum probatoire sans WORM

---

> **Perimetre** : ce document decrit le systeme de signature electronique des conventions de benevolat. Pour les missions payantes, le document engageant est un devis signe par l'entreprise.

## 1. Objectif metier

Avant demarrage d'une mission benevole:
1. la convention est generee
2. l'entreprise signe
3. le prestataire signe

La signature repose sur:
- OTP email
- consentement explicite
- preuves techniques serveur
- hash et chaine d'evenements

---

## 2. Effets des signatures

### 2.1 Signature entreprise

Effets:
- statut contrat `pending_provider`
- notification prestataire
- deadline de signature prestataire
- pas encore de dossier `legal.signed_documents`, car le document n'est pas encore pleinement signe

### 2.2 Signature prestataire

Effets:
- statut `signed` + `fully_signed`
- generation des certificats
- creation ou mise a jour du dossier `legal.signed_documents`
- retention probatoire 10 ans
- mission `assigned`

---

## 3. Dossier de preuve

Le dossier de preuve contient:
- hash du PDF
- horodatages des signatures
- consentement versionne
- preuves techniques serveur (IP, user-agent, request_id)
- chainage des evenements de signature
- certificats PDF
- statut de verification d'integrite
- retention + legal hold

Pour les missions payantes, le meme socle probatoire existe desormais aussi pour le devis:
- `GET /api/devis/evidence/:devis_id/check`
- `GET /api/devis/evidence/:devis_id/export`
- `POST /api/devis/evidence/:devis_id/legal-hold`
- `GET /api/devis/evidence/seal/:seal_date/check`

---

## 4. Gouvernance probatoire

Crons contrats:
- `POST /api/cron/check-contract-evidence`
- `POST /api/cron/seal-contract-evidence-daily`

Crons devis:
- `POST /api/cron/check-devis-evidence`
- `POST /api/cron/seal-devis-evidence-daily`

Les checks et scelles des contrats/conventions et des devis vivent maintenant dans `legal.*`.

---

## 5. Retention

Politique par defaut:
- conservation 10 ans via `legal.signed_documents.retention_until`
- suppression bloquee avant echeance
- suppression toujours bloquee sous `legal_hold`

Limite connue:
- sans WORM, le risque d'alteration admin/systeme n'est pas nul; il est reduit par les controles d'integrite et de scellage.

---

## 6. Lien avec le systeme de devis

Pour les missions payantes:
- le document signe est un devis
- seule l'entreprise signe
- la signature du devis declenche le paiement et l'assignation
- l'annulation raisonne sur le devis signe pour determiner si le prestataire doit etre paye
