# GT-342, integration partenaire par iframe

## Valeurs temporaires

La migration installe un partenaire de demonstration afin que le flux soit configurable avant de connaitre le domaine reel:

- nom: `Partenaire evenementiel`
- slug: `partenaire-evenementiel`
- origine: `https://partner.example.com`
- taux: `350` points de base, soit 3,5 %
- duree de session: 30 minutes
- cle initiale temporaire: `gt342-placeholder-secret-change-me`
- etat initial: inactif

La cle temporaire est volontairement inutilisable publiquement car le partenaire est cree inactif. L'origine peut rester factice jusqu'a reception de l'URL partenaire.

## Deploiement

1. Executer `database/migrations/gt342_partner_iframe_commissions.sql` dans Supabase.
   Si une version anterieure contient des commissions ou reglements non EUR, la validation s'arrete volontairement. Reconciler ces lignes avant de relancer la migration.
2. Dans Supabase, ajouter le schema `partners` aux schemas exposes par la Data API. Les roles `anon` et `authenticated` restent sans droits. Seul `service_role` a acces.
3. Verifier les variables serveur `SUPABASE_KEY`, `DATA_ENCRYPTION_KEY`, `BLIND_INDEX_KEY`, `SITE_URL` et `PARTNER_ADMIN_EMAILS`.
4. Faire tourner la cle partenaire avec `POST /api/admin/partners/{id}/api-key` et transmettre la nouvelle valeur une seule fois via un canal securise.
5. Remplacer l'origine factice avec `PATCH /api/admin/partners/{id}`.
6. Activer le partenaire uniquement apres la rotation de cle et la configuration de l'origine exacte.

Exemple de modification de l'origine et du pourcentage:

```http
PATCH /api/admin/partners/00000000-0000-0000-0000-000000000000
Authorization: Bearer <jeton-admin>
Content-Type: application/json

{
  "allowed_origins": ["https://plateforme-partenaire.example"],
  "partner_rate_bps": 425
}
```

Le taux accepte un entier compris entre `350` et `500`. Ainsi, `425` correspond a 4,25 %. Toute modification cree automatiquement une ligne dans `partners.partner_rate_history`. Les missions deja publiees conservent leur ancien taux.

## Creation d'une session iframe

L'appel doit etre fait par le serveur du partenaire. La cle ne doit jamais etre placee dans le navigateur.

```http
POST /api/partners/partenaire-evenementiel/sessions
Authorization: Bearer <cle-partenaire>
Content-Type: application/json

{
  "origin": "https://plateforme-partenaire.example"
}
```

Reponse:

```json
{
  "session_id": "uuid",
  "expires_at": "2026-08-31T14:30:00.000Z",
  "iframe_url": "https://gotchaaaa.example/embed/partenaire-evenementiel?session=jeton-opaque"
}
```

Le partenaire place ensuite `iframe_url` dans son iframe. Gotchaaaa échange immédiatement le jeton initial contre un cookie HttpOnly sécurisé et retire le jeton de l'URL. Il n'est jamais propagé aux pages suivantes. L'origine demandee doit correspondre exactement a une origine autorisee, protocole et port compris. Les wildcards, chemins, identifiants dans l'URL et query strings sont refuses.

## Iframe fixe, sans serveur cote partenaire

Pour un partenaire qui ne peut coller qu'un bloc HTML (inwink, CMS SaaS), l'iframe peut pointer directement sur `/embed/{slug}`, sans `?session`. Le middleware `server/middleware/partner-static-embed.ts` cree alors la session cote Gotchaaaa et redirige vers `/embed/{slug}?session=...`. La suite du parcours est identique.

Conditions de creation : partenaire actif et commence, requete GET chargee en iframe (`Sec-Fetch-Dest: iframe`), `Referer` absent ou appartenant aux origines autorisees. Sans `Referer` (inwink envoie `Referrer-Policy: no-referrer`), la session est creee avec la premiere origine autorisee : c'est une simple metadonnee, `frame-ancestors` autorise toujours toutes les origines du partenaire. Limite : 60 sessions par heure et par IP. Dans tous les autres cas, la page affiche l'ecran "Session partenaire invalide". `frame-ancestors` reste la protection principale : la page ne s'affiche que dans une origine autorisee.

```html
<iframe src="https://app.gotchaaaa.com/embed/{slug}" width="100%" height="760" style="border:0" allow="clipboard-write" referrerpolicy="strict-origin-when-cross-origin"></iframe>
```

## Connexion dans l'iframe (Google et session)

Google refuse d'afficher sa page de connexion dans une iframe (erreur 403). Dans l'iframe, « Continuer avec Google » ouvre donc une popup (`utils/oauth-popup.js`) :

1. l'iframe ouvre la popup au clic, puis la dirige vers l'URL OAuth Supabase avec `redirectTo = /auth/callback?redirect=...&oauth_popup=1` ;
2. au retour, `plugins/00.oauth-popup-relay.client.js` s'execute avant Supabase : il transmet le fragment `#access_token=...` a l'iframe par `postMessage` (meme origine uniquement), efface l'URL et ferme la popup. Aucune session n'est ouverte cote app.gotchaaaa.com ;
3. l'iframe charge `/auth/callback?redirect=...#access_token=...`, exactement comme le retour web classique.

Si la popup est bloquee ou fermee, la page de connexion affiche un message et propose l'e-mail. Sans `window.opener`, la popup poursuit le parcours web normal.

Dans une iframe cross-site, le navigateur ignore les cookies `SameSite=Lax` ecrits par `document.cookie`. `supabase.js` le detecte et stocke alors la session dans `localStorage` (partitionne par site parent), sous la cle dediee `sb-gotchaaaa-embed-auth-token`. Hors iframe, rien ne change.

Le partenaire ne doit pas mettre `sandbox` sur l'iframe, ou alors avec `allow-popups allow-popups-to-escape-sandbox allow-scripts allow-same-origin allow-forms`.

## Attribution et commission

Une attribution est creee uniquement si la mission est publiee pendant une session valide et depuis le parcours partenaire actif. Le cookie seul ne suffit pas, afin qu'une mission ouverte directement apres avoir quitte l'iframe ne soit jamais attribuee. Une inscription seule ne cree aucune attribution. Le jeton partenaire ne remplace jamais l'authentification utilisateur.

La commission utilise la meme base HT finale que la commission Gotchaaaa de 13 %:

```text
commission Gotchaaaa brute = base HT x 13 %
part partenaire = base HT x taux partenaire
Gotchaaaa net = commission Gotchaaaa brute - part partenaire
```

Tous les montants sont arrondis et stockes en centimes EUR. L'ecriture devient `due` apres capture reelle du paiement. Un remboursement partiel produit uniquement le delta non encore comptabilise. Un remboursement total avant reglement inverse la commission et conserve un evenement d'ajustement `void` dans le mois du remboursement. Apres reglement, il cree un ajustement negatif pour le prochain releve.

## Administration

Toutes les routes ci-dessous exigent un utilisateur Supabase dont l'adresse email figure dans la liste serveur `PARTNER_ADMIN_EMAILS`, séparée par des virgules. Sans variable dédiée, `ADMIN_EMAIL` est utilisé.

- `GET /api/admin/partners`
- `PATCH /api/admin/partners/{id}`
- `POST /api/admin/partners/{id}/api-key`
- `GET /api/admin/partners/{id}/report?month=2026-08`
- `GET /api/admin/partners/{id}/report.csv?month=2026-08`
- `POST /api/admin/partners/{id}/settlements`

Exemple de reglement manuel:

```json
{
  "month": "2026-08",
  "commission_ids": ["uuid-commission"],
  "adjustment_ids": ["uuid-ajustement"],
  "reference": "VIR-2026-08-PARTENAIRE"
}
```

La fonction SQL verrouille les lignes, verifie leur appartenance au partenaire et au mois demande ainsi que leur statut encore du, calcule le montant net et marque les ecritures payees dans la meme transaction. Les changements de configuration, rotations de cle et reglements sont aussi traces transactionnellement dans `partners.admin_audit_events`, sans enregistrer la cle elle-meme.

## Verification

```powershell
node --test tests/*.test.js
npm run test:partner:browser
npm run build
```

Le test navigateur utilise le Chrome installe sur Windows ou `PUPPETEER_EXECUTABLE_PATH`. Sur une machine sans navigateur, installer le navigateur epingle par Puppeteer avant de lancer le test.
