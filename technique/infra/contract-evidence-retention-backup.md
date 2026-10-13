# Contrats SES - Retention & Backup Operatoire

> **Derniere mise a jour** : 18 Mars 2026
> **Perimetre** : preuves contractuelles SES et devis signes (sans WORM)

---

## 1. Objectif

Assurer:
1. conservation probatoire 10 ans
2. recuperation rapide en cas d'incident
3. tracabilite des restaurations

---

## 2. Donnees couvertes

### 2.1 Base de donnees

Tables critiques:
- `missions.contrats`
- `missions.devis`
- `legal.signed_documents`
- `legal.integrity_checks`
- `legal.daily_seals`
- `legal.scan_state`
- `public.audit_log`
- `public.api_rate_limits`

### 2.2 Stockage fichiers

Bucket `contracts`:
- PDFs signes chiffres
- certificats chiffres

---

## 3. Politique de retention

- `EVIDENCE_RETENTION_YEARS=10`
- `legal.signed_documents.retention_until` est calcule a la signature
- suppression DB refusee avant echeance
- `legal.signed_documents.legal_hold=true` bloque toute suppression

---

## 4. Strategie backup

### 4.1 Backups DB

- snapshot complet quotidien
- PITR active
- retention minimale 35 jours

### 4.2 Backups storage `contracts`

- replication ou snapshot quotidien du bucket
- verification du nombre d'objets sauvegardes
- conservation minimale 35 jours + archive mensuelle

### 4.3 Alignement applicatif

- les backups doivent inclure `legal.daily_seals`
- conserver la coherence DB + fichiers du meme jour

---

## 5. Test de restauration

Procedure minimum:
1. restaurer un snapshot DB de test
2. restaurer les objets `contracts` correspondants
3. executer `GET /api/contract/evidence/:contract_id/check`
4. executer `GET /api/devis/evidence/:devis_id/check` sur un devis signe si possible
5. verifier:
   - hash PDF
   - chaine d'evenements
   - certificats accessibles
   - scelle quotidien valide

---

## 6. Checklist operationnelle

- [ ] Crons `check-contract-evidence` et `seal-contract-evidence-daily` actifs
- [ ] Crons `check-devis-evidence` et `seal-devis-evidence-daily` actifs
- [ ] Backups DB quotidiens verifies
- [ ] Backups bucket `contracts` verifies
- [ ] Test de restauration realise sur la periode
- [ ] Revue trimestrielle de la retention et des legal holds
