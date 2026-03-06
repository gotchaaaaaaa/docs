# Déploiement Gotcha

## Informations serveur

| Élément         | Valeur                      |
| --------------- | --------------------------- |
| IP              | `168.231.83.138`            |
| User            | `root`                      |
| Dossier         | `/var/www/gotchaaaa/Gotcha` |
| Port serveur    | `3001`                      |
| Package manager | `yarn`                      |
| Process manager | `PM2`                       |

---

## Déploiement automatique (CI/CD)

Le push sur `main` déclenche `.github/workflows/deploy.yml` qui exécute :

```bash
cd /var/www/gotchaaaa/Gotcha
git pull
yarn install
rm -rf .nuxt
NODE_OPTIONS="--max-old-space-size=4096" yarn build
pm2 stop gotcha || true
pm2 delete gotcha || true
PORT=3001 pm2 start /var/www/gotchaaaa/Gotcha/.output/server/index.mjs --name gotcha --update-env
pm2 save
```

> Le build s'exécute **avant** l'arrêt de PM2 pour éviter les 502 pendant le déploiement. Le downtime se limite à ~1-2s.

---

## Déploiement étape par étape

```bash
# 1. Connexion SSH
ssh root@168.231.83.138

# 2. Aller dans le dossier projet
cd /var/www/gotchaaaa/Gotcha

# 3. Récupérer les dernières modifications
git pull

# 4. Installer les dépendances
yarn install

# 5. Arrêter et supprimer le process PM2
pm2 stop gotcha || true
pm2 delete gotcha || true
sleep 2

# 6. Nettoyer et rebuild
rm -rf .output .nuxt
NODE_OPTIONS="--max-old-space-size=4096" yarn build

# 7. Relancer PM2
PORT=3001 pm2 start .output/server/index.mjs --name gotcha --update-env

# 7. Vérifier que ça marche
pm2 status
curl -s -o /dev/null -w '%{http_code}' http://localhost:3001
```

---

## Premier déploiement (ou après crash)

Si PM2 n'a pas de process "gotcha" :

```bash
ssh root@168.231.83.138 "cd /var/www/gotchaaaa/Gotcha && git pull && yarn install && yarn build && PORT=3001 pm2 start .output/server/index.mjs --name gotcha && pm2 save"
```

---

## Commandes utiles

```bash
# Status PM2
pm2 status

# Logs en temps réel
pm2 logs gotcha

# Redémarrer
PORT=3001 pm2 reload gotcha --update-env

# Arrêter
pm2 stop gotcha

# Supprimer
pm2 delete gotcha

# Sauvegarder config PM2 (pour auto-start au reboot)
pm2 save
```

---

## Dépannage

### Erreur 503 Apache

Le serveur Node n'est pas accessible. Vérifier :

1. `pm2 status` - le process doit être "online"
2. `curl http://localhost:3001` - doit retourner du HTML
3. Le port doit être **3001** (pas 3000)

### PM2 en crash loop (beaucoup de restarts)

```bash
pm2 delete gotcha
PORT=3001 pm2 start .output/server/index.mjs --name gotcha
pm2 save
```

### Erreur 502 Bad Gateway nginx

Le backend Node n'est pas accessible. Diagnostic :

```bash
# 1. Vérifier PM2
pm2 status

# 2. Voir les logs d'erreur
pm2 logs gotcha --lines 50

# 3. Tester le backend directement
curl -I http://localhost:3001
```

**Cause fréquente** : le fichier `.output/server/index.mjs` n'existe pas (build échoué ou manquant).

Solution : rebuild complet (voir ci-dessous).

### Build qui échoue (Killed / OOM)

Le build Nuxt/Nitro consomme ~3-4 Go de RAM. Si le serveur n'a pas assez de mémoire, le process est "Killed" (exit code 137).

**Vérifier la mémoire et le swap :**

```bash
free -h
swapon --show
```

**Si pas de swap, en créer un (2 Go) :**

```bash
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab
```

**Puis relancer le build :**

```bash
rm -rf node_modules .nuxt .output
yarn install
yarn build
```

### Déploiement landing page

cd /var/www && \
rm -rf landing-old && \
cp -r landing landing-new && \
cd landing-new && \
git pull && \
npm install && \
npm run build && \
mv ../landing ../landing-old && \
mv ../landing-new ../landing && \
pm2 reload landing
