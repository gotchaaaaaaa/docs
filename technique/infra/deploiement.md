# Déploiement Gotcha

## Informations serveur

| Élément         | Valeur                      |
| --------------- | --------------------------- |
| Hébergeur       | Hostinger (KVM 1, 4 Go RAM, Paris) |
| IP              | `168.231.83.138`            |
| Hostname        | `srv1026506.hstgr.cloud`    |
| User            | `root`                      |
| Port SSH        | **`2222`** (le 22 est ouvert mais réservé) |
| Auth SSH        | clé ed25519 (pas de password) |
| Dossier projet  | `/var/www/gotchaaaa/Gotcha` |
| Port app        | `3001` (proxy nginx 443 → 3001) |
| Process manager | PM2                         |
| Web server      | nginx (Let's Encrypt via certbot) |

```bash
# Connexion SSH
ssh -p 2222 root@168.231.83.138
```

---

## Architecture du déploiement

Depuis mai 2026, le déploiement passe par un **webhook HTTPS** (et non plus SSH direct) parce que Hostinger route mal les paquets venant de certaines IPs Azure du runner GitHub Actions, ce qui faisait planter aléatoirement les deploys avec des `i/o timeout`.

```
┌──────────────────┐     push main      ┌────────────────────┐
│ Dev (git push)   │ ─────────────────▶ │ GitHub Actions     │
└──────────────────┘                     │ deploy.yml         │
                                         └────────┬───────────┘
                                                  │ POST /deploy-hook
                                                  │ HMAC-SHA256(body)
                                                  ▼
                                         ┌────────────────────┐
                                         │ nginx :443         │
                                         │ app.gotchaaaa.com  │
                                         └────────┬───────────┘
                                                  │ proxy_pass
                                                  ▼
                                         ┌────────────────────┐
                                         │ deploy-webhook     │
                                         │ (PM2, Node 22)     │
                                         │ 127.0.0.1:9001     │
                                         └────────┬───────────┘
                                                  │ spawn bash
                                                  ▼
                                         ┌────────────────────┐
                                         │ /var/www/gotchaaaa │
                                         │ /deploy.sh         │
                                         │ git pull + build   │
                                         │ pm2 reload gotcha  │
                                         └────────────────────┘
```

**Flow** : push GitHub → workflow envoie un `curl POST` signé HMAC → nginx proxie sur le webhook Node local → vérification de signature → déclenchement de `deploy.sh` en arrière-plan → réponse HTTP 202 instantanée à GitHub Actions → build de ~3-4 min sur le VPS.

### Fichiers en jeu

| Emplacement | Rôle |
|-------------|------|
| `.github/workflows/deploy.yml` | déclenche le webhook (curl signé) |
| `/var/www/gotchaaaa/deploy.sh` | script bash exécuté à chaque deploy |
| `/var/www/gotchaaaa/deploy-webhook.mjs` | listener Node sur 127.0.0.1:9001 |
| `/etc/gotcha-deploy.env` | secret HMAC (mode 600 root) |
| `/etc/nginx/sites-enabled/app-gotchaaaa.conf` | vhost avec `location /deploy-hook` |
| `/var/log/gotcha-deploy.log` | log unifié de tous les deploys |
| Process PM2 `deploy-webhook` | listener auto-démarré au boot |

### Secret partagé

Le secret HMAC vit à 2 endroits qui doivent matcher :

- **VPS** : `/etc/gotcha-deploy.env` (chargé par PM2 dans l'env du process)
- **GitHub** : repo Settings → Secrets → `DEPLOY_WEBHOOK_SECRET`

Pour régénérer (rotation) :

```bash
# Sur le VPS
NEW=$(openssl rand -hex 32)
echo "DEPLOY_WEBHOOK_SECRET=$NEW" > /etc/gotcha-deploy.env
chmod 600 /etc/gotcha-deploy.env
pm2 restart deploy-webhook --update-env

# Puis sur GitHub : Settings → Secrets → DEPLOY_WEBHOOK_SECRET → Update
```

---

## Suivre un déploiement

### Pendant le build (live)

```bash
ssh -p 2222 root@168.231.83.138 "tail -f /var/log/gotcha-deploy.log"
```

Tu verras défiler le `git pull`, le `yarn install`, le `vite build`, puis :

```
[deploy] OK
[2026-05-03T16:12:57.231Z] deploy exit code=0
```

Si exit code différent de 0 → le build a échoué, le site reste sur l'ancienne version.

### Après coup (dernier deploy + status)

```bash
ssh -p 2222 root@168.231.83.138 "tail -50 /var/log/gotcha-deploy.log; pm2 status"
```

### Le site est-il bien up ?

```bash
curl -s -o /dev/null -w "HTTP %{http_code} (%{time_total}s)\n" https://app.gotchaaaa.com/
```

---

## Déploiement manuel via webhook

Pratique pour redéployer sans push (rollback non, mais re-build oui) ou tester depuis un autre environnement.

```bash
SECRET="<contenu de DEPLOY_WEBHOOK_SECRET>"
BODY='{"trigger":"manual"}'
SIG="sha256=$(printf '%s' "$BODY" | openssl dgst -sha256 -hmac "$SECRET" -hex | awk '{print $2}')"

curl -X POST https://app.gotchaaaa.com/deploy-hook \
  -H "Content-Type: application/json" \
  -H "X-Signature: $SIG" \
  -d "$BODY"
# → 202 accepted
```

Réponses possibles :
- `202 accepted` → deploy lancé, suivre via `tail -f /var/log/gotcha-deploy.log`
- `401 unauthorized` → mauvaise signature (secret faux ou body modifié)
- `409 already running` → un deploy est en cours, attends qu'il se termine

---

## Déploiement manuel SSH (fallback)

Si le webhook est cassé, tu peux toujours déployer en direct :

```bash
ssh -p 2222 root@168.231.83.138 "/var/www/gotchaaaa/deploy.sh"
```

Ou step by step :

```bash
ssh -p 2222 root@168.231.83.138
cd /var/www/gotchaaaa/Gotcha
git pull
yarn install
rm -rf .nuxt .output
NODE_OPTIONS="--max-old-space-size=3072" yarn build
PORT=3001 pm2 reload gotcha --update-env
pm2 save
exit
```

> Le `--max-old-space-size=3072` est requis sur 4 Go RAM, sinon OOM (exit 137). Si vraiment ça cale, voir « Build OOM » plus bas.

---

## Apps PM2 sur le VPS

| App | Path | Port | Description |
|-----|------|------|-------------|
| `gotcha` | `/var/www/gotchaaaa/Gotcha/.output/server/index.mjs` | 3001 | App Nuxt principale (app.gotchaaaa.com) |
| `landing` | `/var/www/landing-gotchaaaa` | 4000 | Landing Next.js (gotchaaaa.com) |
| `deploy-webhook` | `/var/www/gotchaaaa/deploy-webhook.mjs` | 9001 (localhost) | Listener webhook deploy |

### Commandes PM2 courantes

```bash
pm2 status                          # vue d'ensemble
pm2 logs gotcha                     # logs Nuxt en temps réel
pm2 logs deploy-webhook --nostream  # logs webhook (instant)
pm2 reload gotcha --update-env      # reload zero-downtime (avec env du shell)
pm2 restart gotcha                  # restart classique (~1s downtime)
pm2 save                            # persiste la liste pour auto-start au boot
pm2 startup                         # configure le service systemd (déjà fait)
```

---

## Dépannage

### SSH refuse les connexions ou timeout

Vérifier d'abord que SSH écoute :

```bash
# Via la console VNC Hostinger (hPanel → VPS → Console) si SSH externe down :
systemctl status ssh.socket ssh.service
ss -tlnp | grep -E ':22|:2222'
```

Si rien n'écoute :

```bash
systemctl enable --now ssh.socket
systemctl start ssh.service
```

> **Antécédent** : le 30 avril 2026, ssh.service a été stoppé via SIGTERM (probablement un script anti-bruteforce qui a paniqué après une vague d'essais). Les units étaient `disabled` donc pas relancées au boot. `systemctl enable --now` corrige ce comportement à l'avenir.

### Webhook renvoie 401

Le secret HMAC ne matche pas. Vérifier que `/etc/gotcha-deploy.env` sur le VPS et le secret GitHub `DEPLOY_WEBHOOK_SECRET` sont identiques. Le moindre espace ou retour ligne casse tout.

### Webhook renvoie 502 ou nginx ne route pas

```bash
ssh -p 2222 root@168.231.83.138 "
  curl -sS -o /dev/null -w 'localhost:9001 HTTP %{http_code}\n' \
    -X POST http://127.0.0.1:9001/deploy-hook -H 'X-Signature: x' -d '{}'
  pm2 status deploy-webhook
  nginx -t
"
```

Si `localhost:9001` ne répond pas → `pm2 restart deploy-webhook`.
Si nginx ne route pas → vérifier le bloc `location = /deploy-hook` dans `/etc/nginx/sites-enabled/app-gotchaaaa.conf` puis `systemctl reload nginx`.

### GitHub Actions → "i/o timeout" sur curl

Hostinger filtre certaines IPs Azure (peering merdique entre AS Hostinger et MS). Le webhook reste fonctionnel, c'est juste le runner GitHub qui est aveugle au VPS sur ce run.

**Workaround immédiat** : re-run le job depuis l'UI Actions, GitHub assigne une autre IP au runner et ça passe.

**Solution propre** : déclencher manuellement (`/deploy-status` curl depuis ton poste) ou self-hosted runner.

### Erreur 502 Bad Gateway nginx

Le backend Node (port 3001) ne répond pas. Diagnostic :

```bash
pm2 status                          # gotcha doit être "online"
pm2 logs gotcha --lines 50          # voir l'erreur
curl -I http://localhost:3001       # tester direct
ls -la .output/server/index.mjs     # vérifier que le build existe
```

**Cause fréquente** : `.output/server/index.mjs` absent (build échoué). Solution :

```bash
cd /var/www/gotchaaaa/Gotcha
rm -rf node_modules .nuxt .output
yarn install
NODE_OPTIONS="--max-old-space-size=3072" yarn build
pm2 reload gotcha --update-env
```

### Build OOM (exit code 137 / "Killed")

Nuxt + Nitro consomment 3-4 Go pendant le build. Sur 4 Go de RAM, sans swap c'est tendu. Vérifier le swap :

```bash
free -h
swapon --show
```

Si pas de swap, en créer 2 Go :

```bash
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab
```

### PM2 en crash loop

```bash
pm2 logs gotcha --lines 100   # repérer la cause (port pris, erreur runtime, etc.)
pm2 delete gotcha
PORT=3001 pm2 start .output/server/index.mjs --name gotcha --update-env
pm2 save
```

### Restart du webhook

```bash
ssh -p 2222 root@168.231.83.138 "pm2 restart deploy-webhook --update-env && pm2 logs deploy-webhook --nostream --lines 5"
```

---

## Déploiement de la landing page (gotchaaaa.com)

```bash
ssh -p 2222 root@168.231.83.138 "
  cd /var/www && rm -rf landing-old && cp -r landing landing-new && \
  cd landing-new && git pull && npm install && npm run build && \
  mv ../landing ../landing-old && mv ../landing-new ../landing && \
  pm2 reload landing
"
```
