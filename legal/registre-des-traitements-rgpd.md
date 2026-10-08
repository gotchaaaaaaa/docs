# Registre des traitements RGPD / CNIL - Gotcha

> Document interne de gouvernance RGPD - registre des activités de traitement au sens de l'article 30 du RGPD  
> Dernière mise à jour : Mai 2026 (immatriculation GOTCHAAAA SAS au RCS Paris)  
> Périmètre : application Gotcha, documentation fonctionnelle et technique du dépôt, architecture BDD et principaux flux serveur documentés

## 1. Objet et périmètre

- Le présent document recense les principaux traitements de données personnelles identifiés dans le dépôt Gotcha pour les flux prestataire, entreprise, mission, paiement, facturation, contractualisation, notifications, sécurité et analytics.
- Il s'agit d'un document de gouvernance interne, distinct de la politique de confidentialité publiée au public dans `pages/politique-de-confidentialite.vue`.
- Le registre couvre les fonctionnalités documentées comme actives ou implémentées au 9 avril 2026.
- Lorsqu'une durée de conservation retenue ci-dessous correspond à une position de gouvernance juridiquement défendable, mais qu'aucune purge automatisée n'est encore explicitement documentée dans le code, elle doit être comprise comme une **durée cible à mettre en œuvre**.
- Lorsqu'une information n'est pas explicitement documentée dans le dépôt ni confirmée par une source officielle, la mention `À formaliser` est conservée.
- Le mécanisme `no-show` reste documenté comme non finalisé ; il n'est donc pas traité ici comme traitement autonome en production.
- L'intégration future avec une plateforme agréée / PDP pour la facturation électronique est exclue du présent registre tant qu'aucun service n'est réellement intégré dans le code courant.

## 2. Sources utilisées

- [Présentation du projet](../fonctionnel/presentation-cgu-cgv.md)
- [Parcours prestataire](../fonctionnel/parcours-prestataire.md)
- [Assignation des missions](../fonctionnel/assignation-mission.md)
- [APIs externes & coûts](../technique/apis-externes.md)
- [Notifications push / PWA](../technique/notifications-push-pwa.md)
- [Contrats - Fonctionnement](../critique/contrats/fonctionnement.md)
- [Contrats - Technique](../critique/contrats/technique.md)
- [Paiement - Fonctionnement](../critique/paiement/fonctionnement.md)
- [Paiement - Technique](../critique/paiement/technique.md)
- [Facturation - Fonctionnement](../critique/facturation/fonctionnement.md)
- [Facturation - Technique](../critique/facturation/technique.md)
- [Roadmap chiffrement](../technique/securite/encryption-roadmap.md)
- [Rétention & backup contrats](../technique/infra/contract-evidence-retention-backup.md)
- [Architecture BDD](../technique/bdd/database-architecture.json)
- Références code complémentaires : `server/api/user/delete-account.post.js`, `server/utils/googleCalendarSync.js`, `server/api/waitlist/subscribe.post.js`, `server/utils/audit-log.js`, `server/plugins/error-notifier.js`, `server/api/google/*`, `server/api/company/cgv/*`
- Sources externes officielles vérifiées le 9 avril 2026 :
  - [CNIL - La prospection commerciale](https://www.cnil.fr/la-prospection-commerciale)
  - [CNIL - La mesure d'audience ("analytics")](https://www.cnil.fr/fr/definition/mesure-daudience-analytics)
  - [Légifrance - Article 2224 du code civil](https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI000019017112)
  - [Supabase - Available regions](https://supabase.com/docs/guides/platform/regions)
  - [Supabase - Data Processing Addendum](https://supabase.com/downloads/docs/Supabase%2BDPA%2B250805.pdf)
  - [Stripe - Data Processing Agreement](https://stripe.com/legal/dpa)
  - [Stripe - Data Transfers Addendum](https://stripe.com/legal/data-transfers-addendum)
  - [Mapbox - Product privacy / privacy information](https://www.mapbox.com/legal/privacy)
  - [Mapbox - Notice of certification under the Data Privacy Framework](https://www.mapbox.com/legal/notice-of-certification)
  - [Google - Legal frameworks for data transfers](https://policies.google.com/privacy/frameworks?hl=en)
  - [Umami Cloud - Sign up / data region](https://docs.umami.is/docs/cloud/sign-up)
  - [Umami - Data Processing Agreement](https://umami.is/umami-dpa.pdf)
  - [Hostinger - Privacy Policy](https://www.hostinger.com/legal/privacy-policy)
  - [Hostinger - Data Processing Addendum](https://www.hostinger.com/legal/dpa)
  - [Hostinger - Registrar information](https://www.hostinger.com/legal/registrar-information)

## 3. Fiche d'identité du registre

| Élément | Valeur |
|---|---|
| Responsable de traitement | **GOTCHAAAA**, SAS (Société par Actions Simplifiée) |
| Représentant légal | Charlotte BECHON, Présidente |
| Directeurs Généraux | Nathan DOLARD VILLARD, Nicolas SAGE |
| Siège social | 78 avenue des Champs-Élysées, 75008 Paris, France |
| Immatriculation | RCS Paris — SIREN 104&nbsp;412&nbsp;648 — SIRET 104&nbsp;412&nbsp;648&nbsp;00016 |
| TVA intracommunautaire | FR27&nbsp;104412648 |
| Code NAF / APE | 6312Z — Portails Internet |
| Date d'immatriculation | 10 mai 2026 |
| Contact principal | `hello@gotchaaaa.com` |
| Contact RGPD / DPO opérationnel | `hello@gotchaaaa.com` |
| Statut DPO | Aucun DPO distinct désigné à ce stade ; le point de contact RGPD retenu est `hello@gotchaaaa.com` |
| Périmètre géographique du service | France et Union européenne, avec certains services tiers susceptibles d'entraîner des transferts hors UE (Mapbox / Google sous EU-US Data Privacy Framework) |
| Personnes concernées | Prestataires, entreprises, utilisateurs authentifiés, prospects en liste d'attente, interlocuteurs support/admin, signataires de documents |
| Macro-finalités | Mise en relation, contractualisation, paiement, facturation, communication, sécurité, preuve, analytics |
| Informations sociétaires encore non documentées dans le dépôt | Capital social, région Umami Cloud effectivement retenue |

## 4. Tableau synthétique des traitements

| ID | Traitement | Finalité principale | Personnes concernées | Base(s) légale(s) dominante(s) | Services tiers principaux | Durée de référence |
|---|---|---|---|---|---|---|
| T01 | Comptes, authentification, OTP, suppression | Ouvrir et sécuriser l'accès au service | Prestataires, entreprises, utilisateurs | Exécution du contrat, intérêt légitime, obligation légale | Supabase, Hostinger Mail | Compte actif puis suppression sous 30 jours sauf obligation légale ; logs de connexion 1 an |
| T02 | Onboarding prestataire et conformité documentaire | Constituer un profil exploitable et vérifier l'éligibilité | Prestataires | Mesures précontractuelles, exécution du contrat, intérêt légitime, obligations applicables | Supabase, API INSEE, Stripe, Stripe Identity | Compte actif puis suppression sous 30 jours ; dossier incomplet ou refusé : 12 mois max après dernière activité |
| T03 | Onboarding entreprise, SIRET/INSEE, paiement, CGV entreprise | Ouvrir un compte entreprise, vérifier l'identité légale et préparer la publication | Entreprises | Mesures précontractuelles, exécution du contrat, intérêt légitime, obligations applicables | Supabase, API INSEE, Stripe | Compte actif puis suppression sous 30 jours ; preuves CGV et données de paiement : 10 ans |
| T04 | Missions, matching, géolocalisation, candidatures | Publier une mission et apparier les bons profils | Prestataires, entreprises | Mesures précontractuelles, exécution du contrat, consentement pour la géolocalisation terminal | Supabase, Mapbox, API Adresse | Géolocalisation terminal : session ; candidatures non retenues : 2 ans max ; dossiers mission : 5 ans |
| T05 | Disponibilités et synchronisation Google Calendar | Alimenter les créneaux et automatiser la disponibilité | Prestataires | Exécution du contrat, consentement pour la connexion Google | Supabase, Google OAuth, Google Calendar API | Lecture des événements sur 31 jours ; tokens tant que la synchro est active puis suppression à la déconnexion |
| T06 | Devis, contrats, CGV entreprise, archivage probatoire | Conclure, signer et conserver la preuve documentaire | Prestataires, entreprises, signataires | Exécution du contrat, obligation légale, intérêt légitime | Supabase, Hostinger Mail | Devis, contrats et preuves CGV : 10 ans |
| T07 | Paiements, transferts, recovery, fraude, litiges Stripe | Encaisser, transférer, journaliser et traiter les incidents de paiement | Prestataires, entreprises | Exécution du contrat, obligation légale, intérêt légitime | Stripe, Stripe Identity, Supabase, Hostinger Mail | Données de paiement : 10 ans |
| T08 | Facturation et diffusion des factures | Générer, stocker et transmettre les justificatifs comptables | Prestataires, entreprises | Obligation légale, exécution du contrat | Supabase, Hostinger Mail | 10 ans |
| T09 | Messagerie, emails transactionnels, notifications push | Permettre les échanges et alertes de service | Prestataires, entreprises | Exécution du contrat, intérêt légitime, consentement pour le push | Hostinger Mail, Web Push / VAPID, Supabase | Messages mission : 5 ans max ; push : jusqu'au retrait ou à la suppression du compte ; logs email : 12 mois |
| T10 | Évaluations, sanctions, annulations, litiges opérationnels | Qualifier la fiabilité des acteurs et traiter les conflits métier | Prestataires, entreprises | Exécution du contrat, intérêt légitime | Supabase | Notes : vie du compte + 12 mois max ; litiges et sanctions : 5 ans |
| T11 | Waitlist / préinscription publique | Recueillir des prospects à recontacter | Prospects, entreprises, prestataires potentiels | Mesures précontractuelles à la demande, consentement à être recontacté | Supabase | 3 ans à compter de la collecte ou du dernier contact émanant du prospect |
| T12 | Sécurité opérationnelle, journaux techniques, anti-abus | Auditer, limiter les abus, tracer les erreurs et incidents | Tous utilisateurs, admins | Intérêt légitime, obligation légale selon le type de trace | Supabase, Hostinger Mail | Données de connexion : 1 an ; `api_rate_limits` : purge technique après expiration + 1 jour |
| T13 | Mesure d'audience et analytics | Suivre l'usage et améliorer le service | Visiteurs et utilisateurs | Intérêt légitime sous conditions CNIL d'exemption ; à défaut, ou par prudence tant que la configuration n'est pas documentée, consentement | Umami Cloud | Traceurs : 13 mois max ; données de mesure d'audience : cible 13 mois, plafond 25 mois si régime CNIL d'exemption documenté |

## 5. Fiches détaillées des traitements

### T01 - Gestion des comptes, authentification, OTP et suppression de compte

- **Finalité** : créer et gérer les comptes, authentifier les utilisateurs, protéger les flux sensibles, gérer les OTP d'inscription / réinitialisation / signature et orchestrer la suppression du compte.
- **Personnes concernées** : prestataires, entreprises, utilisateurs authentifiés ou en cours d'inscription.
- **Catégories de données** : nom, prénom, email, téléphone, date de naissance, rôle, photo, état de compte, OTP haché, email chiffré ou indexé, adresse IP et user-agent associés à certains flux de sécurité, statut de suppression.
- **Sources / tables / flux** : `public.profiles`, `public.otp_codes`, Supabase Auth, `server/api/auth/send-signup-otp.post.js`, `server/api/auth/send-reset-otp.post.js`, `server/api/user/delete-account.post.js`.
- **Base(s) légale(s)** : exécution du contrat ou mesures précontractuelles, intérêt légitime de sécurisation du service, obligation légale lorsque certaines données doivent être conservées.
- **Destinataires** : équipes internes habilitées, hébergeur / service d'authentification, service email transactionnel, autorités sur demande légale.
- **Sous-traitants / services tiers** : Supabase ; Hostinger Mail pour l'envoi d'emails transactionnels ; `nodemailer` n'est qu'une bibliothèque technique locale.
- **Transferts hors UE** : Supabase est documenté en région UE ; Hostinger indique dans sa politique de confidentialité que certains serveurs peuvent être situés hors EEE selon le service et la configuration.
- **Durées de conservation** :
  - compte utilisateur : pendant la durée d'utilisation du compte ;
  - après demande de suppression : suppression sous 30 jours sauf obligation légale ou rétention probatoire / paiement ;
  - OTP : durée opérationnelle courte pilotée par `expires_at`, avec cible de purge technique sous 30 jours après expiration ;
  - données de connexion : 1 an selon `pages/politique-de-confidentialite.vue`.
- **Mesures de sécurité** : chiffrement applicatif de plusieurs champs du profil, blind indexes sur email et téléphone, OTP hachés, rate limiting, contrôle `service_role` sur `public.otp_codes`, suppression de compte bloquée lorsqu'il existe des obligations en cours.
- **Observations** : la suppression n'est pas immédiate lorsqu'il subsiste des missions, paiements, devis / contrats retenus ou un `legal_hold`.

### T02 - Onboarding prestataire et conformité documentaire

- **Finalité** : constituer un profil prestataire exploitable, vérifier l'éligibilité à la plateforme, collecter les justificatifs nécessaires et préparer la réception de paiements.
- **Personnes concernées** : prestataires, y compris indépendants et bénévoles selon leur situation.
- **Catégories de données** : date de naissance, photo, véhicule, situation professionnelle, compétences, diplômes, expériences, description, SIRET, documents d'identité et documents légaux, adresse de facturation, régime TVA, IBAN / BIC / titulaire de compte, identifiant Stripe Connect, statut de vérification.
- **Sources / tables / flux** : `public.profiles`, `public.documents`, `providers.providers`, `providers.provider_jobs`, `providers.diplomes`, `providers.experiences`, `providers.availabilities`, `documentation/fonctionnel/parcours-prestataire.md`, `docs/superpowers/specs/2026-03-25-identity-verification-status-design.md`.
- **Base(s) légale(s)** : mesures précontractuelles à la demande du prestataire, exécution du contrat, intérêt légitime de prévention de la fraude et de fiabilisation de la place de marché, obligations applicables selon les flux de paiement et de facturation.
- **Destinataires** : équipes internes habilitées, entreprises dans la limite des informations rendues visibles, prestataires techniques de stockage, de vérification et de paiement.
- **Sous-traitants / services tiers** : Supabase, API INSEE, Stripe Connect, Stripe Identity.
- **Transferts hors UE** : Supabase documenté en UE ; Stripe est documenté avec un périmètre UE / États-Unis ; les flux Stripe Identity relèvent du cadre contractuel Stripe.
- **Durées de conservation** :
  - données de profil : compte actif puis suppression sous 30 jours sauf obligation légale ;
  - dossier d'onboarding incomplet, abandonné ou refusé : 12 mois maximum après la dernière activité du prestataire ;
  - attestation de vigilance : validité métier de 6 mois ; conserver uniquement la version en cours et, si nécessaire pour la piste d'audit, la version précédente pendant 12 mois maximum ;
  - autres justificatifs locaux : pendant la relation active si le document reste nécessaire, puis suppression sous 30 jours après suppression du compte ou disparition du besoin.
- **Mesures de sécurité** : stockage des documents dans Supabase Storage, chiffrement de champs sensibles en base, blind indexes, séparation entre documents locaux et vérifications Stripe Identity, contrôles d'accès par rôle.
- **Observations** : la doctrine la plus protectrice consiste à privilégier Stripe Identity dès que possible et à purger les copies locales devenues inutiles. En cas de suppression de compte, un export peut être fourni sur demande avant suppression, mais il n'est pas recommandé d'envoyer automatiquement tous les justificatifs par email.

### T03 - Onboarding entreprise, vérification SIRET/INSEE, configuration paiement et acceptation des CGV entreprise

- **Finalité** : ouvrir un compte entreprise, vérifier l'existence légale via le SIRET, configurer le moyen de paiement et tracer l'acceptation des CGV entreprise avant publication.
- **Personnes concernées** : entreprises, représentants légaux ou utilisateurs opérant pour le compte d'une entreprise.
- **Catégories de données** : SIRET, données INSEE, nom commercial, description, logo, email, téléphone, identifiant client Stripe, traces d'acceptation des CGV (case à cocher, texte de consentement, horodatage, email snapshot, IP, user-agent, certificat et PDF associés).
- **Sources / tables / flux** : `companies.companies`, `companies.cgv_signatures`, `companies.cgv_versions`, `pages/entreprise/inscription/signup-company.vue`, `server/api/company/save-onboarding.post.js`, `server/api/company/profile.get.js`, `server/api/company/cgv/*`.
- **Base(s) légale(s)** : mesures précontractuelles, exécution du contrat, intérêt légitime de preuve et de sécurisation des engagements, obligations applicables en matière de paiement et de facturation.
- **Destinataires** : équipes internes habilitées, prestataire de paiement, services publics consultés pour la vérification SIRET.
- **Sous-traitants / services tiers** : Supabase, API INSEE, Stripe.
- **Transferts hors UE** : Supabase documenté en UE ; Stripe documenté UE / États-Unis ; API INSEE = service public français.
- **Durées de conservation** :
  - données de compte entreprise : pendant la vie du compte puis suppression sous 30 jours sauf obligation légale ;
  - onboarding non finalisé : 12 mois maximum après la dernière activité ;
  - données de paiement : 10 ans lorsqu'elles relèvent des flux comptables et de paiement ;
  - preuve CGV entreprise : 10 ans à compter de la signature, en cohérence avec `buildEvidenceRetentionIso()` et les champs `evidence_retention_until` / `evidence_legal_hold`.
- **Mesures de sécurité** : chiffrement du SIRET, du snapshot `siret_gouv_infos` et de `stripe_customer_id`, blind indexes, BFF serveur pour lecture / écriture des champs sensibles, OTP et traces techniques pour la signature des CGV.
- **Observations** : éditeur identifié comme GOTCHAAAA SAS, 78 avenue des Champs-Élysées 75008 Paris, RCS Paris SIREN 104 412 648, immatriculée le 10 mai 2026.

### T04 - Publication des missions, matching, géolocalisation, candidatures et sélection

- **Finalité** : permettre à l'entreprise de publier une mission et au système de trouver les prestataires pertinents selon la zone, les disponibilités et le profil.
- **Personnes concernées** : entreprises et prestataires candidats.
- **Catégories de données** : titre et description de mission, horaires, lieu, code postal, ville, coordonnées GPS, rayon d'intervention, disponibilité, véhicule, compétences, taux horaire, temps de préparation, données de candidature et de sélection.
- **Sources / tables / flux** : `missions.missions`, `missions.profile_missions`, `missions.mission_schedules`, `providers.providers`, `providers.availabilities`, `components/shared/AddressAutocomplete.vue`, `pages/prestataire/carte.vue`, `pages/entreprise/carte.vue`, `documentation/fonctionnel/assignation-mission.md`.
- **Base(s) légale(s)** : mesures précontractuelles et exécution du contrat ; consentement lorsque la géolocalisation du terminal est utilisée pour aider à la saisie ou à la mise à jour de l'adresse.
- **Destinataires** : entreprises publiant des missions, prestataires situés dans la zone, équipes internes habilitées.
- **Sous-traitants / services tiers** : Supabase, Mapbox, `api-adresse.data.gouv.fr`.
- **Transferts hors UE** : Mapbox est un service américain ; l'API Adresse est un service public français ; Supabase est documenté en UE.
- **Durées de conservation** :
  - géolocalisation du terminal : session uniquement, selon la politique de confidentialité ;
  - candidatures non retenues et matching non abouti : 2 ans maximum après clôture de la mission ou dernier contact utile ;
  - données de mission, d'assignation et d'exécution : 5 ans après la fin ou l'annulation de la mission, hors pièces comptables et probatoires traitées ailleurs.
- **Mesures de sécurité** : chiffrement progressif des coordonnées précises prestataire, géohash / données agrégées pour certains usages, endpoints BFF pour certains calculs, restrictions d'accès par rôle.
- **Observations** : les informations visibles par les entreprises et les prestataires doivent rester strictement limitées aux besoins de la mise en relation. Mapbox indique supprimer en principe les adresses IP sous 30 jours, mais reste un destinataire hors UE à encadrer contractuellement.

### T05 - Gestion des disponibilités et synchronisation Google Calendar

- **Finalité** : permettre au prestataire de gérer ses disponibilités manuellement ou via une synchronisation avec Google Calendar.
- **Personnes concernées** : prestataires connectant leur agenda Google.
- **Catégories de données** : tokens OAuth Google, `calendar_id`, état de synchronisation, horaires de journée, erreurs de synchro, timestamps de synchro, événements occupés sur 31 jours et créneaux libres dérivés.
- **Sources / tables / flux** : `providers.google_tokens`, `providers.availabilities`, `server/api/google/auth-url.get.js`, `server/api/google/callback.get.js`, `server/api/google/status.get.js`, `server/api/google/disconnect.delete.js`, `server/api/google/sync.post.js`, `server/utils/googleCalendarSync.js`, `server/api/cron/sync-google-calendars.js`.
- **Base(s) légale(s)** : exécution du contrat pour la gestion des disponibilités ; consentement pour la connexion d'un compte Google et la lecture du calendrier.
- **Destinataires** : prestataire, équipes internes habilitées pour le support, Google en qualité de fournisseur d'API.
- **Sous-traitants / services tiers** : Supabase, Google OAuth, Google Calendar API.
- **Transferts hors UE** : Google opère une infrastructure mondiale ; des transferts hors UE sont donc possibles. Google documente des mécanismes de transfert incluant notamment le Data Privacy Framework pour Google LLC.
- **Durées de conservation** :
  - fenêtre de lecture des événements : 31 jours ;
  - tokens et métadonnées de synchronisation : tant que `sync_enabled = true`, puis suppression immédiate à la déconnexion et, au plus tard, sous 30 jours si la synchronisation est désactivée ou révoquée ;
  - disponibilités synchronisées : conservation pendant la relation active ; purge à la suppression du compte, ou à la déconnexion si l'utilisateur choisit de ne pas les conserver.
- **Mesures de sécurité** : chiffrement AES-256-GCM des tokens Google avec clé dédiée, révocation à la déconnexion, cron interne protégé par HMAC, désactivation de `sync_enabled` en cas de token révoqué.
- **Observations** : la synchronisation supprime d'abord les disponibilités existantes avant de recréer des créneaux dérivés. Le registre retient comme bonne pratique une minimisation stricte des scopes OAuth et l'absence de conservation durable des événements Google eux-mêmes.

### T06 - Génération, signature électronique et archivage probatoire des devis, contrats et CGV entreprise

- **Finalité** : générer les documents contractuels, collecter les consentements et signatures, conserver les preuves et assurer leur intégrité dans le temps.
- **Personnes concernées** : entreprises, prestataires, signataires et interlocuteurs qui téléchargent les documents.
- **Catégories de données** : PDF, certificats, hashes documentaires, textes et versions de consentement, horodatages, IP, user-agent, chaîne `forwarded`, email du signataire, SIRET, statut d'intégrité, `legal_hold`, rétention probatoire.
- **Sources / tables / flux** : `missions.devis`, `missions.contrats`, `legal.signed_documents`, `legal.integrity_checks`, `legal.daily_seals`, `companies.cgv_signatures`, `companies.cgv_evidence_checks`, `companies.cgv_evidence_daily_seals`, `server/api/contract/*`, `server/api/devis/*`, `server/api/company/cgv/*`, `documentation/critique/contrats/technique.md`.
- **Base(s) légale(s)** : exécution du contrat, obligation légale de conservation / probation, intérêt légitime de gestion du risque contentieux.
- **Destinataires** : parties signataires, équipes internes habilitées (ops, legal, support), autorités ou juridictions en cas de contentieux.
- **Sous-traitants / services tiers** : Supabase, Hostinger Mail pour l'envoi des documents par email.
- **Transferts hors UE** : Supabase documenté en UE ; transferts hors UE possibles côté Hostinger selon le service et la configuration retenue.
- **Durées de conservation** :
  - contrats et devis signés : 10 ans via `legal.signed_documents.retention_until` ;
  - CGV entreprise signées : 10 ans, par alignement juridique et technique avec les autres preuves de consentement et de signature ;
  - `integrity_checks` et `daily_seals` : 10 ans minimum, ou aussi longtemps que le document principal auquel ils se rattachent reste lui-même retenu.
- **Mesures de sécurité** : OTP hachés, rate limiting, chiffrement des IP / user-agent / certificats, chiffrement des PDF et certificats en storage, accès backend uniquement aux buckets contractuels, scellés quotidiens HMAC, checks d'intégrité, `legal_hold`, triggers interdisant certaines suppressions avant la fin de rétention.
- **Observations** : pour les missions payantes, le document engageant est le devis signé par l'entreprise ; pour les missions bénévoles, la convention est bilatérale. La même logique de rétention longue est retenue pour les preuves CGV entreprise.

### T07 - Paiements, transferts, recovery, fraude et litiges Stripe

- **Finalité** : encaisser les montants dus, transférer la part prestataire, calculer la commission, gérer les échecs, litiges et traces de paiement.
- **Personnes concernées** : entreprises payeuses, prestataires payés, administrateurs finance / ops.
- **Catégories de données** : montants, TVA, acomptes, commissions, statuts de paiement, identifiants Stripe (`customer`, `account`, `payment_intent`, `charge`, `transfer`), webhooks, erreurs de paiement, sessions Stripe Identity, alertes admin.
- **Sources / tables / flux** : `missions.payment_flows`, `missions.payment_events`, `public.stripe_webhook_events`, `companies.companies`, `providers.providers`, `server/api/stripe/*`, `documentation/critique/paiement/technique.md`.
- **Base(s) légale(s)** : exécution du contrat, obligation légale en matière comptable et fiscale, intérêt légitime de prévention de la fraude, recouvrement et gestion des incidents.
- **Destinataires** : équipes internes habilitées, Stripe en qualité de prestataire de paiement et de vérification d'identité, autorités ou conseils en cas de litige.
- **Sous-traitants / services tiers** : Stripe, Stripe Identity, Supabase, Hostinger Mail pour certaines alertes admin.
- **Transferts hors UE** : la documentation projet indique `UE et États-Unis` pour Stripe ; Stripe documente un DPA et un Data Transfers Addendum fondés notamment sur les SCC et le Data Privacy Framework.
- **Durées de conservation** : données de paiement 10 ans selon la documentation fonctionnelle et la logique comptable.
- **Mesures de sécurité** : chiffrement des identifiants Stripe en base, blind indexes, webhook secret, table d'idempotence `stripe_webhook_events`, HMAC pour appels internes, recovery avec retries 1 / 3 / 7 jours, alertes admin.
- **Observations** : Stripe peut cumuler un rôle contractuel de sous-traitant et des obligations propres de prestataire de paiement régulé ; cette qualification doit être conservée dans le dossier juridique fournisseur.

### T08 - Facturation et diffusion des factures

- **Finalité** : générer les factures, les stocker, les rendre consultables et les transmettre par email aux parties concernées.
- **Personnes concernées** : prestataires, entreprises, équipe finance.
- **Catégories de données** : noms, adresses, SIRET, numéro TVA, emails de destination, numéros de facture, lignes de mission, montants HT / TVA / TTC, PDF de facture, métadonnées d'envoi.
- **Sources / tables / flux** : `missions.invoices`, `missions.invoice_sequences`, `public.trames`, `server/api/invoices/generate.post.js`, `server/api/invoices/send-emails.post.js`, `server/api/invoices/list.get.js`, `server/api/invoices/[id]/download.get.js`, `documentation/critique/facturation/technique.md`.
- **Base(s) légale(s)** : obligation légale de facturation et d'archivage comptable ; exécution du contrat.
- **Destinataires** : émetteurs et destinataires des factures, équipe finance, autorités fiscales si nécessaire.
- **Sous-traitants / services tiers** : Supabase, Hostinger Mail.
- **Transferts hors UE** : Supabase documenté en UE ; transferts hors UE possibles côté Hostinger selon le service et la configuration.
- **Durées de conservation** : 10 ans.
- **Mesures de sécurité** : chiffrement des champs sensibles en BDD, chiffrement des PDF avant stockage, contrôles d'accès via RLS et endpoints authentifiés, abandon des signed URLs pour la lecture des documents chiffrés.
- **Observations** : l'intégration future PDP / PA devra être ajoutée au registre lorsqu'elle deviendra un traitement actif.

### T09 - Messagerie, emails transactionnels, notifications push et alertes automatiques

- **Finalité** : permettre les échanges entre parties et notifier les étapes critiques du service (mission, signature, paiement, facture, message, alerte).
- **Personnes concernées** : prestataires, entreprises, administrateurs recevant certaines alertes.
- **Catégories de données** : contenu de message chiffré, identifiants d'expéditeur et de thread, emails transactionnels, pièces jointes documentaires, endpoint push, clés `keys` de souscription, métadonnées d'alerte et de déduplication.
- **Sources / tables / flux** : `missions.messages`, `public.push_subscriptions`, `public.email_alert_logs`, `server/api/messages/[pmId].get.js`, `server/api/messages/[pmId].post.js`, `server/api/push/*`, `server/utils/email.js`, `server/utils/email-alerts.js`.
- **Base(s) légale(s)** : exécution du contrat pour les communications transactionnelles ; intérêt légitime pour certaines alertes opérationnelles ; consentement pour l'activation des notifications push.
- **Destinataires** : contreparties d'une mission, équipes internes habilitées, Hostinger Mail, écosystème push du navigateur.
- **Sous-traitants / services tiers** : Hostinger Mail, Web Push / VAPID, Supabase.
- **Transferts hors UE** : dépend du fournisseur email et, pour le push, des services associés au navigateur ; aucun prestataire push unique n'est documenté contractuellement dans le dépôt.
- **Durées de conservation** :
  - messagerie liée aux missions : 5 ans maximum à compter de la fin de la mission ou de la clôture du litige associé, puis suppression ou anonymisation ;
  - `push_subscriptions` : jusqu'au retrait du consentement, à l'invalidation technique de l'endpoint ou à la suppression du compte, avec purge sous 30 jours si la suppression n'est pas immédiate ;
  - `email_alert_logs` : 12 mois.
- **Mesures de sécurité** : chiffrement du contenu des messages (`content_enc`), notifications push génériques sans extrait du message dans certains cas, politiques RLS sur `push_subscriptions`, endpoints authentifiés pour la lecture et le téléchargement des pièces jointes.
- **Observations** : le flux de suppression de compte purge déjà certaines données. Il faudra aligner techniquement cette purge avec la durée cible retenue lorsque la conservation de certains échanges reste nécessaire à la défense des droits.

### T10 - Évaluations, sanctions, annulations et litiges opérationnels

- **Finalité** : documenter les expériences de mission, calculer les sanctions opérationnelles et tracer les litiges métier entre utilisateurs.
- **Personnes concernées** : prestataires, entreprises, équipe support / ops.
- **Catégories de données** : notes, commentaires, identifiants de mission, historique des annulations, nombre d'annulations consécutives, statut de suspension, durée de suspension, litiges opérationnels et utilisateur ayant résolu le dossier.
- **Sources / tables / flux** : `companies.ratings`, `providers.ratings`, `providers.cancellation_logs`, `missions.disputes`, fonction SQL `providers.apply_cancellation_sanction`, `documentation/fonctionnel/assignation-mission.md`, `documentation/legal/dispute-policy.md`.
- **Base(s) légale(s)** : exécution du contrat et intérêt légitime de fiabilisation de la place de marché, de modération et de prévention des abus.
- **Destinataires** : utilisateurs lorsque certaines notes sont rendues visibles sur le profil, équipe interne en charge de la modération et des litiges.
- **Sous-traitants / services tiers** : principalement Supabase ; aucun autre service tiers n'est documenté comme spécifique à ce traitement.
- **Transferts hors UE** : aucun transfert supplémentaire propre à ce traitement n'est documenté, hors infrastructure générale du service.
- **Durées de conservation** :
  - suspension opérationnelle : 7 jours ou 30 jours selon les cas documentés ;
  - notes et commentaires : pendant la vie du compte et, au maximum, 12 mois après suppression du compte ou retrait de visibilité publique pour gérer les contestations ;
  - `cancellation_logs` et `missions.disputes` : 5 ans à compter de la clôture du dossier ou de l'expiration de la sanction, prolongeables si un contentieux est en cours.
- **Mesures de sécurité** : contrôles d'accès applicatifs, journalisation structurée, séparation entre litiges métier et litiges Stripe.
- **Observations** : le flux `no-show` n'étant pas encore finalisé, il n'est pas traité ici comme traitement autonome en production.

### T11 - Waitlist / préinscription publique

- **Finalité** : recueillir des demandes de contact et des préinscriptions avant ou en complément de l'ouverture d'un compte.
- **Personnes concernées** : prospects, prestataires potentiels, entreprises potentielles.
- **Catégories de données** : email, hash email, prénom, nom, rôle, métier, nom d'entreprise, localisation.
- **Sources / tables / flux** : `public.waitlist`, `pages/liste-attente.vue`, `server/api/waitlist/subscribe.post.js`.
- **Base(s) légale(s)** : mesures précontractuelles à la demande de la personne ; consentement à être recontacté.
- **Destinataires** : équipe interne produit / business habilitée et hébergeur.
- **Sous-traitants / services tiers** : Supabase.
- **Transferts hors UE** : aucun transfert hors UE spécifique n'est documenté pour ce flux, Supabase étant documenté en UE.
- **Durées de conservation** : 3 ans à compter de la collecte ou du dernier contact émanant du prospect, conformément à la pratique CNIL en matière de prospection.
- **Mesures de sécurité** : email hash pour l'unicité, chiffrement AES des données de contact, endpoint public restreint à l'insertion.
- **Observations** : aucun CRM ou outil d'emailing marketing tiers n'est documenté dans le dépôt pour l'exploitation ultérieure de la waitlist.

### T12 - Sécurité opérationnelle, journaux techniques, anti-abus et audit

- **Finalité** : tracer les actions sensibles, limiter les abus, suivre les erreurs serveur, dédoublonner certaines alertes et documenter les incidents.
- **Personnes concernées** : tous les utilisateurs et, indirectement, les administrateurs qui reçoivent les alertes.
- **Catégories de données** : actions et ressources auditées, IP et user-agent, hash de clé de rate limit, compteurs de requêtes, erreurs applicatives, URL / méthode / statut, métadonnées d'email alert.
- **Sources / tables / flux** : `public.audit_log`, `public.api_rate_limits`, `system.server_errors`, `public.email_alert_logs`, `server/utils/audit-log.js`, `server/utils/distributed-rate-limit.js`, `server/plugins/error-notifier.js`, `documentation/technique/infra/SECURITY-ROTATION.md`.
- **Base(s) légale(s)** : intérêt légitime de sécurisation du service, de prévention de la fraude et de supervision ; obligation légale pour les traces qualifiées de données de connexion lorsqu'applicable.
- **Destinataires** : équipe sécurité / admin / support, hébergeur, Hostinger Mail pour certaines alertes, autorités sur demande.
- **Sous-traitants / services tiers** : Supabase, Hostinger Mail.
- **Transferts hors UE** : dépend notamment du fournisseur email ; aucun autre transfert spécifique n'est documenté ici.
- **Durées de conservation** :
  - données de connexion : 1 an comme référence documentaire générale ;
  - `public.api_rate_limits` : purge technique via `cleanup_expired_api_rate_limits()` lorsque `reset_at < now() - 1 day` ;
  - `public.audit_log` : 12 mois, sauf extraction ponctuelle dans un dossier d'incident ou de contentieux ;
  - `system.server_errors` : 12 mois ;
  - `public.email_alert_logs` : 12 mois.
- **Mesures de sécurité** : `service_role only` sur plusieurs tables de sécurité, chiffrement de l'IP et du user-agent dans `audit_log`, cooldown des emails d'erreur, secrets HMAC pour endpoints internes, rotation documentaire des secrets.
- **Observations** : `system.server_errors` stocke encore `ip` et `user_agent` en clair dans le schéma ; une revue de minimisation reste recommandée.

### T13 - Mesure d'audience et analytics

- **Finalité** : mesurer l'usage de la plateforme et aider à l'amélioration du produit.
- **Personnes concernées** : visiteurs et utilisateurs de la plateforme.
- **Catégories de données** : pages vues, referrer, type de navigateur, terminal, langue, résolution d'écran, événements d'usage si activés ultérieurement, données techniques de navigation nécessaires au service analytics ; aucun tracking personnalisé Umami n'est documenté dans le dépôt à ce stade.
- **Sources / tables / flux** : script Umami injecté dans `nuxt.config.ts`, `documentation/technique/apis-externes.md`, `pages/politique-de-confidentialite.vue`.
- **Base(s) légale(s)** : intérêt légitime si, et seulement si, la configuration Umami retenue respecte les critères CNIL d'exemption pour la mesure d'audience ; à défaut, ou tant que cette démonstration n'est pas formellement documentée, consentement préalable.
- **Destinataires** : équipe produit / marketing habilitée, Umami Cloud.
- **Sous-traitants / services tiers** : Umami Cloud.
- **Transferts hors UE** : Umami Cloud est fourni par une société américaine. La documentation officielle indique un choix de région de données `Europe` ou `United States`, mais la région effectivement retenue pour Gotcha n'est pas documentée à ce jour.
- **Durées de conservation** :
  - traceurs / cookies : 13 mois maximum selon la politique de confidentialité ;
  - données de mesure d'audience : cible 13 mois ; en tout état de cause, ne pas dépasser 25 mois si Gotcha entend se placer dans le cadre CNIL de l'exemption.
- **Mesures de sécurité** : script unique documenté dans `nuxt.config.ts`, absence de tracking personnalisé Umami dans le dépôt, nécessité de documenter la région de données et la gouvernance cookie / consentement.
- **Observations** : Umami ne figure pas parmi les solutions explicitement évaluées par la CNIL dans son programme d'exemption. En l'état, la position la plus prudente consiste à prévoir un recueil de consentement tant que la région de données, la configuration exacte et l'absence de réutilisation des données par le fournisseur ne sont pas formellement documentées.

## 6. Annexe - Services tiers et qualification RGPD

| Service | Rôle dans Gotcha | Données potentiellement concernées | Localisation / transferts | Qualification RGPD pratique | Observations |
|---|---|---|---|---|---|
| Supabase | BDD, Auth, Storage, RPC | Quasi toutes les données utilisateur et documentaires | Régions UE disponibles et retenues par la documentation projet | Sous-traitant technique principal | DPA officiel disponible ; conserver l'acceptation contractuelle hors dépôt |
| Stripe | Paiement, transferts, webhooks, litiges | Données financières, identifiants de paiement, compte entreprise, compte prestataire | `UE et États-Unis` selon la doc projet et les mécanismes Stripe | Prestataire de paiement ; qualification précise à apprécier selon l'opération | DPA + Data Transfers Addendum documentés par Stripe ; Stripe, LLC se prévaut du Data Privacy Framework pour certains transferts |
| Stripe Identity | Vérification d'identité | Sessions KYC, éventuelles données ou documents d'identité via le flow Stripe | Même cadre Stripe, `UE et États-Unis` | Service spécialisé de vérification d'identité | Le dépôt indique que les documents Stripe Identity ne sont pas conservés localement par Gotcha |
| Mapbox | Cartographie et affichage des zones | Coordonnées GPS, positions de missions, zones prestataires, métadonnées réseau | États-Unis | Service technique de cartographie, avec traitement propre de certaines données produit | Mapbox indique supprimer en principe les IP sous 30 jours ; certification DPF et documentation privacy disponibles |
| Google OAuth / Google Calendar API | Connexion d'agenda et lecture des événements | Tokens OAuth, calendrier, événements occupés, horaires dérivés | Transferts potentiels hors UE via l'infrastructure Google | Service tiers activé à la demande de l'utilisateur | Traitement déclenché sur consentement du prestataire ; scopes à minimiser et dossier de transfert à archiver |
| `api-adresse.data.gouv.fr` | Autocomplétion et reverse geocoding | Adresses saisies, parfois coordonnées de recherche inverse | France | Service public consulté | Pas de clé API documentée |
| API INSEE | Vérification SIRET | Numéro SIRET et données légales retournées | France | Service public consulté | Le snapshot `siret_gouv_infos` peut contenir des données détaillées d'établissement |
| Umami Cloud | Analytics | Métriques d'usage, données techniques de navigation, éventuels traceurs | Région `Europe` ou `United States` sélectionnable selon la doc Umami Cloud | Sous-traitant analytics | Région effectivement choisie pour Gotcha à formaliser ; en l'absence de documentation suffisante, traiter l'outil comme soumis au consentement par prudence |
| Hostinger Mail | Envoi d'emails transactionnels et alertes | Emails, contenu transactionnel, pièces jointes documentaires, alertes admin | Hostinger documente des services couverts par son DPA, y compris `Email Services` ; sa privacy policy indique que certains serveurs peuvent être situés hors EEE selon le service et la configuration | Sous-traitant email | L'application utilise `nodemailer` pour le transport côté code, mais le prestataire RGPD est bien Hostinger |
| Web Push / VAPID | Acheminement technique des notifications navigateur | Endpoint push, clés de souscription, métadonnées de notification | Dépend du navigateur et du service push associé | Pas de sous-traitant contractuel unique documenté | Ne pas présenter comme un prestataire unique tant qu'aucun fournisseur central n'est contractuellement documenté |

## 7. Annexe - Règles transverses de gouvernance et de sécurité

- **Suppression de compte** : suppression possible sous 30 jours après demande, sauf obligations en cours ; le code bloque la suppression si des missions, paiements ou documents sous rétention / `legal_hold` restent actifs.
- **Export avant suppression** : un export d'accès / portabilité peut être fourni sur demande avant suppression définitive ; l'envoi automatique de tous les documents par email n'est pas retenu comme doctrine par défaut.
- **Legal hold et rétention** : les contrats, devis et preuves CGV signées sont retenus 10 ans avec possibilité de `legal_hold` bloquant toute suppression.
- **Chiffrement** :
  - champs sensibles chiffrés en base avec domaines crypto dédiés ;
  - fichiers contractuels et fiscaux chiffrés avant stockage ;
  - tokens Google chiffrés avec une clé dédiée ;
  - OTP et certains secrets non stockés en clair.
- **Minimisation** : plusieurs colonnes historiques en clair ou devenues inutiles ont été supprimées d'après la roadmap chiffrement (`vars_data`, `markdown_content`, contenu plaintext des messages, anciennes signed URLs de lecture PDF).
- **Contrôle d'accès** : usage de Supabase RLS, endpoints BFF authentifiés, `service_role` sur les tables sensibles, buckets contractuels non accessibles directement en lecture par `anon` / `authenticated`.
- **Auth interne et crons** : les endpoints internes critiques (`/api/cron/*`, evidence checks, scellés) sont protégés par une signature HMAC et non plus par un simple secret statique.
- **Journalisation** : `audit_log`, `payment_events`, `stripe_webhook_events`, `server_errors`, `email_alert_logs` et `api_rate_limits` documentent différents niveaux de trace ; la doctrine retenue est 12 mois pour les journaux techniques ordinaires, hors extraction dans un dossier d'incident ou de contentieux.
- **Sauvegardes** : la documentation d'infrastructure impose une rétention minimale de 35 jours pour les sauvegardes DB et storage des artefacts contractuels, avec archive mensuelle pour les contrats.
- **Droits des personnes** : le point de contact documenté est `hello@gotchaaaa.com` ; l'exercice des droits doit tenir compte des obligations légales, comptables et probatoires qui limitent parfois l'effacement immédiat.
- **Analytics / cookies** : l'usage d'Umami Cloud sans consentement ne doit être retenu que si la configuration et le contrat respectent effectivement les critères CNIL d'exemption ; tant que ce point n'est pas démontré, Gotcha doit déployer un recueil de consentement adapté.

## 8. Points à formaliser en priorité

- Adresse postale et immatriculation exacte du responsable de traitement.
- Région Umami Cloud effectivement sélectionnée pour Gotcha.
- Dossier contractuel centralisé des sous-traitants et partenaires critiques : Supabase, Stripe, Stripe Identity, Mapbox, Google, Umami, Hostinger.
- Alignement technique des purges avec les durées cibles retenues dans ce registre, notamment pour `missions.messages`, `providers.google_tokens` et les journaux techniques.
- Revue de minimisation sur les traces techniques qui contiennent encore IP / user-agent en clair dans `system.server_errors`.
- Alignement de `pages/politique-de-confidentialite.vue` avec le régime analytics réellement retenu : exemption documentée ou consentement.

## 9. Règle de maintenance du registre

- Toute nouvelle intégration tierce ou tout nouveau traitement significatif doit être ajouté au registre avant mise en production.
- Toute évolution des durées de conservation doit être alignée entre ce registre, la politique de confidentialité et la documentation technique.
- Toute nouvelle fonctionnalité de preuve, paiement, géolocalisation, messaging ou analytics doit faire l'objet d'une revue RGPD courte avant publication.
