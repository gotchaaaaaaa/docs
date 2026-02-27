# Contrats SES - Retention & Backup Operatoire

> **Derniere mise a jour** : 25 Fevrier 2026  
> **Perimetre** : preuves contractuelles SES (sans WORM)

---

## 1. Objectif

Assurer:
1. conservation probatoire 10 ans
2. recuperation rapide en cas d’incident
3. tracabilite des restaurations

---

## 2. Donnees couvertes

### 2.1 Base de donnees

Tables critiques:
- `missions.contrats`
- `public.contract_evidence_checks`
- `public.contract_evidence_daily_seals`
- `public.contract_evidence_scan_state`
- `public.audit_log`
- `public.api_rate_limits`

### 2.2 Stockage fichiers

Bucket `contracts`:
- PDFs contractuels chiffrés
- certificats chiffrés

---

## 3. Politique de retention

- `EVIDENCE_RETENTION_YEARS=10`
- `evidence_retention_until` calcule a la signature si absent
- suppression DB refusee avant echeance
- `evidence_legal_hold=true` bloque toute suppression

---

## 4. Strategie backup

### 4.1 Backups DB

- frequence:
  - snapshot complet quotidien
  - journal logique (PITR) active
- retention backup:
  - 35 jours pour snapshots quotidiens
  - archives mensuelles 12 mois
- chiffrement:
  - au repos (provider)
  - en transit TLS

### 4.2 Backups storage `contracts`

- replication/snapshot quotidien du bucket
- verification du nombre d’objets sauvegardes
- conservation minimale: 35 jours + archive mensuelle

### 4.3 Alignement applicatif

- les backups doivent inclure les tables de scellage (`contract_evidence_daily_seals`)
- conserver la coherente DB + fichiers du meme jour

---

## 5. Test de restauration (obligatoire)

Frequence:
- test partiel mensuel
- test complet trimestriel

Procedure minimum:
1. restaurer un snapshot DB de test
2. restaurer les objets `contracts` correspondants
3. executer `GET /api/contract/evidence/:contract_id/check`
4. verifier:
   - hash PDF
   - chaine evenements
   - certificats accessibles
   - scelle quotidien valide
5. documenter resultat et ecarts

---

## 6. Roles et responsabilites

- **Ops**:
  - planification backup/restauration
  - maintien des crons techniques
  - supervision des erreurs de sauvegarde
- **Engineering**:
  - maintien des endpoints probatoires
  - correction des ecarts d’integrite
- **Support/Juridique**:
  - gestion des demandes legal hold
  - validation des exports probatoires

---

## 7. Checklist operationnelle

- [ ] Crons `check-contract-evidence` et `seal-contract-evidence-daily` actifs
- [ ] Backups DB quotidiens verifies
- [ ] Backups bucket `contracts` verifies
- [ ] Test de restauration realise sur la periode
- [ ] Journal des incidents et restaurations mis a jour
- [ ] Revue trimestrielle de la retention et des legal holds

