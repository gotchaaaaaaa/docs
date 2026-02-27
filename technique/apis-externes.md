# APIs & Services Externes

> **Derniere mise a jour** : Fevrier 2026

---

## Resume des couts

| Service | Usage | Cout | Remarque |
|---------|-------|------|----------|
| **Supabase** | BDD, Auth, Storage | **Gratuit** (plan Free) | Limite : 500 MB BDD, 1 GB storage, 50K auth users |
| **Stripe** | Paiements | **1.5% + 0.25 EUR/tx** | Pas d'abonnement, commission par transaction |
| **Stripe Identity** | Verification identite | **1.50 EUR/verification** | Uniquement quand un prestataire s'inscrit |
| **Mapbox** | Cartes interactives | **Gratuit** jusqu'a 50K chargements/mois | Puis ~0.50 EUR / 1000 chargements |
| **Google Calendar API** | Sync disponibilites | **Gratuit** | Quota : 1M requetes/jour |
| **api-adresse.data.gouv.fr** | Autocompletion adresse | **Gratuit** | API gouvernementale francaise, pas de limite connue |
| **Umami Cloud** | Analytics | **Gratuit** (plan Hobby) | Limite : 100K events/mois |
| **SMTP (email)** | Envoi emails | **Variable** | Depend du fournisseur (ex: Brevo gratuit jusqu'a 300/jour) |
| **Web Push (VAPID)** | Notifications push | **Gratuit** | Standard web, pas de service tiers |
| **Iconify** | Icones | **Gratuit** | CDN public |

---

## 1. Supabase

| | |
|---|---|
| **Type** | Backend-as-a-Service (PostgreSQL + Auth + Storage) |
| **Package** | `@supabase/supabase-js` v2.50.3 |
| **URL** | `https://pvoicgldcuybsqwipejd.supabase.co` |
| **Utilise pour** | Base de donnees, authentification, stockage fichiers |

### Fonctionnalites utilisees
- **PostgreSQL** avec PostGIS (geolocalisation)
- **Auth** : email/password, OAuth
- **Storage** : documents, photos, PDFs (factures, contrats)
- **RPC** : fonctions SQL cote serveur
- **RLS** : politiques de securite par role

### Fichiers cles
- `server/utils/supabase.js` - Client Supabase
- `composables/useAuth.js` - Logique auth
- `plugins/auth.client.js` - Listener auth

### Variables d'environnement
- `SUPABASE_URL`
- `SUPABASE_KEY` (service role, bypass RLS)
- `SUPABASE_ANON_KEY` (cle publique, soumise RLS)

### Tarification
| Plan | Prix | BDD | Storage | Auth |
|------|------|-----|---------|------|
| Free | 0 EUR | 500 MB | 1 GB | 50K users |
| Pro | 25 USD/mois | 8 GB | 100 GB | 100K users |

---

## 2. Stripe

| | |
|---|---|
| **Type** | Paiement en ligne |
| **Packages** | `stripe` v19.1.0 (serveur), `@stripe/stripe-js` v7.4.0 (client) |
| **Utilise pour** | Paiements, virements prestataires, verification identite |

### Fonctionnalites utilisees
- **Payment Intents** : pre-autorisation + capture
- **Connect Custom** : comptes prestataires pour recevoir les virements
- **Identity** : verification d'identite (piece d'identite)
- **Webhooks** : evenements paiement, litiges

### Fichiers cles
- `server/api/stripe/` - 17+ endpoints
- `composables/useStripeAccount.js`

### Variables d'environnement
- `STRIPE_PUBLISHABLE_KEY`
- `STRIPE_SECRET_KEY`
- `STRIPE_WEBHOOK_SECRET`

### Tarification
| Service | Cout |
|---------|------|
| Paiement par carte (EU) | 1.5% + 0.25 EUR par transaction |
| Paiement par carte (hors EU) | 2.9% + 0.25 EUR par transaction |
| Virement Connect | 0.25 EUR par virement |
| Verification identite | 1.50 EUR par verification |
| Litiges (dispute) | 15 EUR par litige (rembourse si gagne) |

---

## 3. Mapbox

| | |
|---|---|
| **Type** | Cartes interactives |
| **Package** | `mapbox-gl` v3.13.0 |
| **Utilise pour** | Affichage missions sur carte, zones prestataires |

### Fonctionnalites utilisees
- Carte interactive (zoom, pan)
- Markers GeoJSON (missions, prestataires)
- Cercles de zone d'intervention

### Fichiers cles
- `components/shared/map/Map.vue`
- `composables/useMapInstance.js`
- `pages/prestataire/carte.vue`
- `pages/entreprise/carte.vue`

### Variables d'environnement
- `NUXT_PUBLIC_MAPBOX_TOKEN`

### Tarification
| Chargements carte/mois | Cout |
|-------------------------|------|
| 0 - 50 000 | Gratuit |
| 50 001 - 100 000 | 0.50 EUR / 1000 |
| 100 001+ | 0.40 EUR / 1000 |

---

## 4. Google Calendar API

| | |
|---|---|
| **Type** | Synchronisation calendrier |
| **Utilise pour** | Importer les disponibilites des prestataires depuis Google Calendar |

### Fonctionnalites utilisees
- OAuth 2.0 (connexion compte Google)
- Lecture des evenements du calendrier principal
- Sync automatique (cron job)
- Detection creneaux libres/occupes

### Fichiers cles
- `server/api/google/auth-url.get.js` - URL OAuth
- `server/api/google/callback.get.js` - Callback OAuth
- `server/utils/googleCalendarSync.js` - Logique sync
- `server/api/cron/sync-google-calendars.js` - Cron

### Variables d'environnement
- `GOOGLE_CLIENT_ID`
- `GOOGLE_CLIENT_SECRET`
- `GOOGLE_REDIRECT_URI`
- `GOOGLE_TOKEN_ENCRYPTION_KEY`

### Tarification
Gratuit. Quota : 1 000 000 requetes/jour.

---

## 5. api-adresse.data.gouv.fr

| | |
|---|---|
| **Type** | API gouvernementale francaise |
| **Utilise pour** | Autocompletion des adresses (inscription, creation mission) |

### Fichiers cles
- `components/shared/AddressAutocomplete.vue`

### Endpoint
`https://api-adresse.data.gouv.fr/search/?q={query}`

### Tarification
Gratuit. Pas de cle API requise. Pas de limite documentee.

---

## 6. Umami Analytics

| | |
|---|---|
| **Type** | Analytics respectueux de la vie privee |
| **Utilise pour** | Suivi des pages vues et comportement utilisateur |

### Integration
Script injecte dans `nuxt.config.ts` :
```
src: https://cloud.umami.is/script.js
data-website-id: 7a3cf340-94f3-47b6-afc8-ab11d4aa86e5
```

### Tarification
| Plan | Prix | Events/mois |
|------|------|-------------|
| Hobby | Gratuit | 100K |
| Growth | 20 USD/mois | 1M |
| Business | 50 USD/mois | 5M |

---

## 7. SMTP (Nodemailer)

| | |
|---|---|
| **Type** | Envoi d'emails |
| **Package** | `nodemailer` v7.0.12 |
| **Utilise pour** | OTP, contrats, factures, alertes admin |

### Emails envoyes
- OTP signature contrat (entreprise + prestataire)
- Contrat PDF signe
- Factures PDF
- Reset mot de passe
- Alertes admin (echec paiement, litiges)

### Fichiers cles
- `server/utils/email.js` - Envoi + templates
- `server/utils/email-alerts.js` - Alertes
- `server/api/auth/send-reset-otp.post.js`
- `server/api/auth/send-signup-otp.post.js`

### Variables d'environnement
- `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS`
- `SMTP_FROM` (defaut: hello@gotchaaaa.com)
- `ADMIN_EMAIL` (defaut: hello@gotchaaaa.com)

### Tarification
Depend du fournisseur SMTP choisi :
| Fournisseur | Gratuit | Payant |
|-------------|---------|--------|
| Brevo (ex-Sendinblue) | 300 emails/jour | 9 EUR/mois pour 5K/mois |
| Mailgun | 100 emails/jour (1 mois) | 35 USD/mois pour 50K |
| Amazon SES | 0 | 0.10 USD / 1000 emails |

---

## 8. Web Push (VAPID)

| | |
|---|---|
| **Type** | Notifications push navigateur |
| **Package** | `web-push` v3.6.7 |
| **Utilise pour** | Notifications temps reel (missions, contrats, messages) |

### Fichiers cles
- `plugins/pwa-push.client.js` - Souscription
- `server/utils/web-push.js` - Envoi
- `server/api/push/subscribe.js` - Endpoint souscription
- `server/api/push/send.js` - Endpoint envoi
- `public/sw.js` - Service worker

### Variables d'environnement
- `VAPID_PUBLIC_KEY`
- `VAPID_PRIVATE_KEY`

### Tarification
Gratuit. Protocole web standard, pas de service tiers.

---

## 9. Autres librairies notables

| Librairie | Package | Usage | Cout |
|-----------|---------|-------|------|
| **Sharp** | `sharp` v0.33.5 | Compression images serveur | Gratuit (open-source) |
| **PDFKit** | `pdfkit` v0.17.2 | Generation PDF (contrats, factures) | Gratuit (open-source) |
| **pdf.js** | `pdfjs-dist` v4.0.269 | Visionneuse PDF client | Gratuit (open-source) |
| **Fuse.js** | `fuse.js` v7.1.0 | Recherche floue | Gratuit (open-source) |
| **ngeohash** | `ngeohash` v0.6.3 | Geohashing coordonnees | Gratuit (open-source) |
| **Iconify** | `@iconify/vue` v5.0.0 | Icones (CDN) | Gratuit |

---

## Estimation des couts mensuels

### Scenario : 100 missions/mois

| Service | Estimation | Cout |
|---------|------------|------|
| Supabase | Plan Free suffit | 0 EUR |
| Stripe (transactions) | ~100 tx, montant moyen 500 EUR | ~100 EUR |
| Stripe (virements) | ~100 virements | ~25 EUR |
| Stripe Identity | ~20 nouveaux prestataires | ~30 EUR |
| Mapbox | < 50K chargements | 0 EUR |
| Google Calendar | Gratuit | 0 EUR |
| Adresse gouv | Gratuit | 0 EUR |
| Umami | < 100K events | 0 EUR |
| SMTP (Brevo) | < 300/jour | 0 EUR |
| Web Push | Gratuit | 0 EUR |
| **Total estime** | | **~155 EUR/mois** |

### Scenario : 1000 missions/mois

| Service | Estimation | Cout |
|---------|------------|------|
| Supabase | Plan Pro | ~25 EUR |
| Stripe (transactions) | ~1000 tx | ~1 000 EUR |
| Stripe (virements) | ~1000 virements | ~250 EUR |
| Stripe Identity | ~100 nouveaux prestataires | ~150 EUR |
| Mapbox | ~200K chargements | ~75 EUR |
| SMTP | Plan payant | ~9 EUR |
| Umami | Plan Growth | ~20 EUR |
| **Total estime** | | **~1 529 EUR/mois** |

> Note : les couts Stripe sont recuperes via la commission de 12.5% sur les entreprises.
