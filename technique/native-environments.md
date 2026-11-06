# iOS Codemagic: test puis production

Le workflow `ios-capacitor-testflight` embarque deux profils publics. Il choisit le profil au demarrage complet de l'application:

- Avant le 2 novembre 2026 a 00:00, heure de Paris: test.
- A partir du 2 novembre 2026 a 00:00, heure de Paris: production.
- Valeur UTC: `2026-11-01T23:00:00Z` dans `CAP_PRODUCTION_STARTS_AT` de `codemagic.yaml`.

La date est comparee a l'horloge de l'iPhone. Une application deja ouverte reste sur son profil jusqu'au prochain demarrage complet. Cette regle evite de changer de base pendant une signature ou un paiement. Pour verifier la bascule, fermer completement puis relancer l'app, avec une date automatique correcte sur l'iPhone.

La selection porte ensemble sur Supabase Auth/BDD/Storage/Realtime, le backend API, Stripe et les liens vers les documents. Les sessions Supabase sont distinctes par projet. Les brouillons locaux de mission et redirections en attente sont effaces lors du changement de projet. Les comptes, documents et missions de test ne sont pas copies en production; une connexion a un compte de production sera necessaire apres la bascule.

## Avant le prochain build

1. Disposer de deux backends HTTPS distincts, executant la meme version du code: un backend de test et `https://app.gotchaaaa.com` pour la production. Un client Supabase de test avec une API de production ne fonctionne pas comme un environnement de test isole.
2. Deployer les modifications serveur sur les deux backends avant de lancer Codemagic. La nouvelle route publique `GET /api/public/native-environment` doit repondre sur chaque backend. Le build compare le projet Supabase et Stripe annonces par cette route avec les profils configures; une route absente ou une incoherence bloque le build.
3. Renseigner les variables ci-dessous dans le groupe Codemagic `capacitor_public_env`. Les anciennes variables `CAP_SUPABASE_URL`, `CAP_SUPABASE_ANON_KEY`, `CAP_API_BASE` et `CAP_STRIPE_PK` ne sont plus utilisees par ce workflow.
4. Preparer et tester les comptes de demonstration dans les deux bases, avec si possible les memes identifiants. Preparer aussi les missions et documents de demonstration dans les deux environnements. La suppression d'un compte doit etre testee avec un compte jetable distinct.
5. Choisir un numero de build iOS superieur au dernier build envoye dans App Store Connect (`CURRENT_PROJECT_VERSION` dans `ios/App/App.xcodeproj/project.pbxproj`, configurations Debug et Release). Envoyer cette revision dans le depot depuis lequel Codemagic construit l'app. Aucun push n'est effectue par l'agent. Lancer le workflow sur cette revision, installer le nouveau build via TestFlight et selectionner ce nouveau build pour App Review.
6. Filmer la version nouvellement soumise sur iPhone physique. Mettre a jour les Notes et la reponse Apple avec le texte du fichier `documentation/apple-review-response-en.txt`.

Les builds deja installes ou soumis ne recoivent pas cette modification automatiquement. Une nouvelle compilation est necessaire une premiere fois; le nouveau build contient ensuite les deux profils et la date.

## Variables publiques Codemagic

| Variable | Valeur |
| --- | --- |
| `CAP_TEST_API_BASE` | Origine HTTPS du backend de test, sans `/api` ni chemin |
| `CAP_TEST_SUPABASE_URL` | `https://hbvpiugxriirhzgrwrit.supabase.co` |
| `CAP_TEST_SUPABASE_ANON_KEY` | Cle publique `anon` ou `sb_publishable_` du projet de test |
| `CAP_TEST_STRIPE_PK` | Cle publique Stripe `pk_test_...` du backend de test |
| `CAP_PROD_API_BASE` | `https://app.gotchaaaa.com` |
| `CAP_PROD_SUPABASE_URL` | `https://pvoicgldcuybsqwipejd.supabase.co` |
| `CAP_PROD_SUPABASE_ANON_KEY` | Cle publique `anon` ou `sb_publishable_` du projet de production |
| `CAP_PROD_STRIPE_PK` | Cle publique Stripe `pk_live_...` du backend de production |
| `CAP_MAPBOX_TOKEN` | Token public Mapbox valide pour l'app native |
| `CAP_VAPID_PUBLIC` | Facultatif: cle publique Web Push commune |
| `CAP_TEST_VAPID_PUBLIC`, `CAP_PROD_VAPID_PUBLIC` | Facultatif: remplacement de la cle Web Push par profil |

`CAP_ENVIRONMENT_MODE=scheduled` et la date sont explicites dans le YAML. Pour de futurs builds definitivement en production, remplacer le mode par `production`; les variables de test ne sont alors plus requises. Le mode `test` permet un build de test fixe. Les builds web et les anciens builds natifs a profil fixe gardent leur configuration habituelle.

Le generateur ne copie que des valeurs publiques dans `.env.capacitor`. Ne jamais mettre de cle `service_role`, de cle `sb_secret_`, de cle Stripe privee ou de mot de passe dans ces variables client. Marquer une variable comme secrete dans Codemagic ne la rend pas secrete une fois embarquee dans l'app.

## Configuration des serveurs

Ces valeurs sont configurees dans l'environnement de chaque processus serveur, pas dans Codemagic:

| Variable serveur | Backend test | Backend production |
| --- | --- | --- |
| `SUPABASE_URL` | Projet de test | Projet de production |
| `SUPABASE_ANON_KEY` | Cle publique du projet de test | Cle publique du projet de production |
| `SUPABASE_KEY` | Cle serveur du projet de test | Cle serveur du projet de production |
| `STRIPE_PUBLISHABLE_KEY` | `pk_test_...` | `pk_live_...` |
| `STRIPE_SECRET_KEY` | `sk_test_...` | `sk_live_...` |
| `STRIPE_WEBHOOK_SECRET`, `STRIPE_WEBHOOK_SECRET_CONNECT` | Webhooks Stripe test, vers le backend test | Webhooks Stripe live, vers le backend production |
| `SITE_URL`, `NUXT_PUBLIC_API_BASE` | Origine HTTPS test | Origine HTTPS production |
| `REVIEW_LOGIN_BYPASS_EMAILS` | Emails des comptes de demonstration de test | Emails des comptes de demonstration de production |

Configurer aussi les cles de chiffrement qui correspondent aux donnees et fichiers de chaque base, les emails SMTP, les autorisations OAuth et les URLs de retour. Conserver les origins CORS natives `capacitor://localhost` et `https://localhost` sur les deux backends. Les deux projets Supabase doivent autoriser le retour OAuth `com.gotchaaaa.app://auth/callback` et disposer des providers utilises, schemas, RPC, politiques RLS, buckets et documents necessaires.

Les fichiers locaux `.env` et `.env.prod` inspectes le 26 octobre contenaient tous les deux des cles Stripe de test. Cela ne prouve pas le mode du serveur distant. Verifier les vraies cles de production dans Stripe et sur le serveur; ne pas copier aveuglement `.env.prod` pour renseigner les cles live.

Dans l'environnement test configure en Stripe test, utiliser la carte `4242 4242 4242 4242`, une expiration future et un CVC a trois chiffres. Apres la bascule en production, les paiements sont reels et cette carte de test ne fonctionne pas. Ne pas utiliser de vrais documents personnels pour les demonstrations de verification d'identite dans Stripe test.

## Verification avant App Review

- Installer le build Codemagic exact sur iPhone, avec l'heure automatique.
- Avant la date: inscription, connexion, missions, messages, documents et suppression utilisent exclusivement le backend et le projet de test. Verifier les journaux du backend de test et l'absence de nouveaux enregistrements correspondants en production.
- Les tests automatises couvrent les instants avant et apres la bascule, ainsi que le maintien d'un profil dans une app deja ouverte. Pour tester physiquement chaque environnement avant cette date, produire au besoin des builds de controle avec `CAP_ENVIRONMENT_MODE=test` puis `production`, en conservant l'heure automatique. Soumettre finalement le build `scheduled`. Une connexion au compte de production doit etre demandee; les donnees de test ne doivent pas apparaitre.
- Le profil production utilise des paiements reels. Controler les ecrans de paiement sans valider une nouvelle transaction pour ce test.
- Tester les retours Google/LinkedIn, les codes email, les signatures et les retours Stripe sur les deux backends.
- Fournir a Apple les identifiants des deux environnements, ou les memes identifiants provisionnes dans les deux bases, pour permettre la revue apres le 2 novembre.
- La fonctionnalite reste identique avant et apres la bascule. Les Notes expliquent ce changement d'environnement. Si la revue se prolonge, les comptes de production de demonstration doivent rester accessibles.
- Prevoir une publication manuelle apres la bascule pour que les premiers clients publics accedent directement a la production.
