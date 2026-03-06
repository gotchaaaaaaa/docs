# Rotation des Clés et Secrets - Guide de Sécurité

## URGENT: Actions Requises

### 1. Clé Service Role Supabase Exposée

**Problème identifié:**
La clé `service_role` de Supabase est actuellement stockée dans le fichier `.env` avec la variable `SUPABASE_KEY`. Cette clé:
- Bypass TOUTES les politiques RLS (Row Level Security)
- Permet un accès illimité en lecture/écriture à toutes les tables
- Est potentiellement visible dans l'historique Git

**Impact potentiel:**
- Compromission totale de la base de données
- Accès non autorisé aux données des utilisateurs
- Modification ou suppression de données

---

## Procédure de Rotation des Clés Supabase

### Étape 1: Régénérer les clés dans Supabase Dashboard

1. Connectez-vous à [Supabase Dashboard](https://app.supabase.com)
2. Sélectionnez le projet `pvoicgldcuybsqwipejd`
3. Allez dans **Settings** > **API**
4. Cliquez sur **Regenerate** pour la clé `service_role`
5. Notez la nouvelle clé (elle ne sera plus visible après)

### Étape 2: Mettre à jour les environnements

**Sur le serveur de production:**
```bash
ssh root@168.231.83.138
cd /var/www/gotchaaaa/Gotcha

# Éditer le fichier .env
nano .env

# Remplacer SUPABASE_KEY par la nouvelle valeur
# SUPABASE_KEY=nouvelle_cle_ici

# Redémarrer l'application
pm2 restart gotcha
```

**En local (développement):**
```bash
# Éditer .env local
# Remplacer SUPABASE_KEY par la nouvelle valeur
```

### Étape 3: Vérifier le fonctionnement

```bash
# Sur le serveur
pm2 status
curl -s -o /dev/null -w '%{http_code}' http://localhost:3001

# Tester les fonctionnalités critiques:
# - Connexion utilisateur
# - Upload de fichiers
# - Paiements Stripe
```

---

## Nettoyage de l'Historique Git (Optionnel mais Recommandé)

**⚠️ ATTENTION:** Cette opération réécrit l'historique Git. Coordonnez avec l'équipe avant de l'exécuter.

### Méthode 1: Avec git-filter-repo (recommandé)

```bash
# Installer git-filter-repo
pip install git-filter-repo

# Faire une sauvegarde
git clone --mirror git@github.com:votre-repo.git backup-repo

# Supprimer .env de l'historique
git filter-repo --path .env --invert-paths

# Force push (ATTENTION: coordonner avec l'équipe)
git push origin --force --all
git push origin --force --tags
```

### Méthode 2: Avec BFG Repo Cleaner

```bash
# Télécharger BFG
# https://rtyley.github.io/bfg-repo-cleaner/

# Supprimer les fichiers sensibles
java -jar bfg.jar --delete-files .env

# Nettoyer
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Force push
git push origin --force --all
```

---

## Liste des Secrets à Gérer

| Variable | Description | Rotation Fréquence | Action Requise |
|----------|-------------|-------------------|----------------|
| `SUPABASE_KEY` | Clé service_role | **IMMÉDIAT** | Régénérer |
| `SUPABASE_ANON_KEY` | Clé anonyme | 6 mois | Optionnel |
| `STRIPE_SECRET_KEY` | Clé secrète Stripe | 6 mois | Via Dashboard Stripe |
| `STRIPE_WEBHOOK_SECRET` | Secret webhook | 6 mois | Via Dashboard Stripe |
| `VAPID_PRIVATE_KEY` | Clé push | 1 an | Régénérer avec web-push |
| `GOOGLE_CLIENT_ID` | OAuth Google | Selon besoin | Via Google Cloud Console |
| `INTERNAL_API_SECRET` | Secret API interne | 3 mois | Générer avec openssl |
| `DATA_ENCRYPTION_KEY` | Chiffrement champs probatoires | 6 mois | Rotation contrôlée + re-chiffrement |
| `FILE_ENCRYPTION_KEY` | Chiffrement fichiers probatoires | 6 mois | Rotation contrôlée + plan de migration |

---

## Génération de Nouveaux Secrets

### VAPID Keys (Push Notifications)
```bash
npx web-push generate-vapid-keys --json > vapid-keys.json
```

### Secret API Interne
```bash
openssl rand -hex 32
```

---

## Calendrier de Rotation (Preuves Contrats)

- `INTERNAL_API_SECRET`: tous les 3 mois (HMAC endpoints internes + scelles quotidiens)
- `SUPABASE_KEY`: tous les 3 mois, et immediate en cas de soupcon d'exposition
- `DATA_ENCRYPTION_KEY` et `FILE_ENCRYPTION_KEY`: tous les 6 mois avec plan de migration/re-chiffrement
- Revue mensuelle:
  - verifier les dates de derniere rotation
  - verifier l'etat des crons probatoires (`check-contract-evidence`, `seal-contract-evidence-daily`)
  - verifier l'absence d'erreurs d'auth interne HMAC

### Vérification d'un JWT Supabase
```bash
# Décoder un token pour vérifier son rôle
echo "VOTRE_TOKEN" | cut -d'.' -f2 | base64 -d 2>/dev/null | jq .role
```

---

## Bonnes Pratiques de Sécurité

### 1. Ne jamais committer de secrets
- `.env` doit être dans `.gitignore` (déjà fait)
- Utiliser des variables d'environnement sur le serveur
- Utiliser des secrets managers (ex: Vault, AWS Secrets Manager)

### 2. Principe du moindre privilège
- Utiliser `anon_key` côté client (soumis aux RLS)
- Utiliser `service_role` uniquement côté serveur
- Créer des comptes de service dédiés si possible

### 3. Rotation régulière
- Planifier une rotation tous les 3-6 mois
- Documenter chaque rotation
- Tester après chaque rotation
- Maintenir un registre daté des rotations des secrets probatoires

### 4. Surveillance
- Activer les logs Supabase
- Monitorer les accès API inhabituels
- Mettre en place des alertes

---

## Checklist Post-Rotation

- [ ] Nouvelle clé générée dans Supabase Dashboard
- [ ] `.env` mis à jour sur le serveur de production
- [ ] `.env` mis à jour en local
- [ ] Application redémarrée (`pm2 restart gotcha`)
- [ ] Tests fonctionnels passés
- [ ] Historique Git nettoyé (si applicable)
- [ ] Équipe informée de la rotation
- [ ] Documentation mise à jour
- [ ] Vérification des endpoints internes HMAC (`/api/cron/*`, `/api/contract/evidence/*`)
- [ ] Vérification du cron de scan et du cron de scellage quotidien

---

## Contacts d'Urgence

En cas de compromission suspectée:
1. Désactiver immédiatement les clés compromises
2. Vérifier les logs d'accès
3. Notifier l'équipe
4. Documenter l'incident

---

**Dernière mise à jour:** Janvier 2026
**Prochaine rotation planifiée:** 01 Avril 2026 (INTERNAL_API_SECRET + SUPABASE_KEY)
