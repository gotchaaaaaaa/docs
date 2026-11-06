# Messagerie avant engagement

Plan de référence : demande utilisateur du 5 octobre 2026.

## Contraintes

Missions payantes uniquement. Design actuel conservé. Les historiques et les engagements existants restent accessibles.

## Livraison

- [ ] Droits centralisés, versions immuables et migrations transactionnelles.
- [ ] Modération canonique, concurrence, fil paginé et canaux privés.
- [ ] Page mission, conversations, propositions et signature directe.
- [ ] Navigation compatible, CGU et notifications.
- [ ] Tests unitaires, intégration Supabase, E2E Puppeteer et build Nuxt.
- [ ] Revue finale et corrections.

## Vérifications effectuées

- 14 cas unitaires de droits et modération ont été vus échouer avant implémentation, puis passer.
- La suite existante de 229 tests unitaires a passé après les premiers changements.
- 12 scénarios transactionnels Supabase passent dans des transactions annulées : droits, premier message, versions immuables, révision, pagination, résumés, invalidation de PDF, réservation et dernière place, archivage et réinvitation.
- La migration `database/migrations/20261005102404_pre_engagement_messaging.sql` a été créée avec la CLI Supabase, vérifiée dans une transaction annulée, puis appliquée au seul projet de test `hbvpiugxriirhzgrwrit` par l’API de gestion. Le projet de production `pvoicgldcuybsqwipejd` n’a pas été modifié.
- Le premier build Nuxt a passé (23 min 20 s). Il précède les dernières corrections et doit être relancé.
- Les essais Puppeteer avec cinq identités fictives passent pour les droits API, le refus d’abonnement privé pour un tiers, l’ouverture du dialogue par le message canonique, sa réception des deux côtés, la réponse prestataire, la révision sans ouverture et les dimensions desktop/mobile. Le paiement E2E est encore en cours de préparation : Stripe refuse `business_profile[url]=https://example.com` dans le fixture, à corriger avant de poursuivre.
- Le contrôle OTP est lié à la version de proposition et au hash du PDF. La sauvegarde d’un ancien PDF après modification de mission a été reproduite en échec puis bloquée en base, avec test d’intégration vert.
- Une requête Stripe et sa preuve de consentement sont persistées avant le débit, avec clé idempotente liée à une réservation durable. Une relance reprend cette requête ; passé 23 heures sans identifiant de paiement, elle exige une réconciliation sans nouveau débit.
- Les tests de modération passent pour les URLs espacées, les contacts sociaux formulés en phrases et le masquage déjà présent dans les frais. Les propositions courantes sont disponibles même hors de la page récente du fil ; les anciens messages déjà chargés sont rafraîchis par identifiant après masquage.

## Travail encore requis

- Terminer les contrôles de révision de mission lors de publication d’une offre et vérifier les compteurs horaires après modification du tarif.
- Ajouter un traitement serveur des paiements inconnus reçus via webhook et un suivi des réservations demandant réconciliation.
- Ajouter la modération des fragments répartis entre messages et textes de propositions, sans modifier les snapshots tarifaires.
- Compléter les scénarios API/Supabase : concurrence réelle, refus/RPC historiques, OTP remplacé, clôture, réinvitation et bénévolat.
- Terminer les scénarios Puppeteer de signature Stripe test, modification/reconfirmation, archivage, navigation, pagination et compteurs. Nettoyage des fixtures signés doit être testé.
- Relancer toute la suite, terminer le build, puis revue finale avec un agent.

## Revue du 5 octobre 2026 (corrections appliquées)

- Bénévolat : une modification de mission ne fait plus passer les candidatures bénévoles `postule` en `revision_requested` (triggers mission et créneaux limités aux missions payantes).
- `devis_signature_claims` : clés étrangères en `ON DELETE CASCADE`, sinon `delete_mission` échouait après toute tentative de signature.
- Messagerie engagée : le statut `closed` (posé par `update_expired_missions` à la fin de chaque mission) ne ferme plus le fil engagé, comme avec `send_message_v3`. Le passage en `closed` n'est plus bloqué par une réservation active (mise à jour en masse du cron).
- Changement d'avis après déclin d'une invitation (`provider_declined` → proposition) rétabli côté API et trigger.
- Refus de carte : la réservation passe en `failed` immédiatement (elle bloquait annulation, modification et dernière place).
- Webhook Stripe : pas de reprise d'une réservation de moins de 5 minutes (doublons de push, alertes et `payment_events` avec la requête en cours). Le cron `reconcile-devis-signatures` est ajouté à `crontab.md`.
- `/api/devis/reject` : refus bénévole sans motif rétabli, push rétabli, clés `rejectionReasonCode`/`rejectionMotif` du template restaurées. Push rétablis pour nouvelle proposition et demande de révision (la clé email `counter_proposal_received` n'avait pas de template).
- Realtime : la page mission ne rouvre plus `conversation-inbox:<uid>`, partagé avec le badge global ; elle s'abonne via `onConversationInboxChange`.
- Modération : faux positifs corrigés (« point de rendez-vous », « permis de conduire B », « passeport à jour », plages de dates, « sur instagram tous les jours ») ; « snap jeanD75 » est désormais masqué.

## Retours du 5 octobre 2026 (soir)

- Signature depuis la conversation : la page devis régénère le PDF quand la ligne `devis` existe mais que son PDF a été invalidé (nouvelle version de proposition ou mission modifiée), au lieu d'afficher « Le PDF du devis n'est pas encore disponible ». Un échec de génération s'affiche avec « Réessayer ».
- Email « nouveau message » : prénom du prestataire seulement.
- Liens de visio : avant signature, l'entreprise (et elle seule) peut partager un lien de réunion Google Meet ou Microsoft Teams (`utils/meeting-links.js` : formats de réunion stricts, pas de lien de chat Teams, aucun `@` ni coordonnée dans les paramètres, sinon le lien entier est masqué). Le fil les affiche avec un bouton « Rejoindre la réunion ». **À aligner : l'article 8 des CGU interdit encore tout « lien externe » avant engagement.**
- Fil de conversation : bloc proposition au style du récapitulatif devis (`ContractRecap`), rangé du côté du prestataire, versions précédentes repliées ; demande de révision et rejet affichés en carte reliée à la proposition visée (l'événement `request_revision` en double n'est plus affiché) ; présentation du prestataire en mini-profil (photo ronde, badges, statistiques, « Voir le profil complet »).
- Profil prestataire `?mission=` : le bandeau n'a plus que « Voir la proposition », qui ouvre `/entreprise/mission/<id>?pm=<pm>&focus=proposal` centré sur la proposition courante.

## Dépendances et documents

Les trois bibliothèques de modération sont épinglées dans les deux lockfiles. Le lockfile npm existant est antérieur à plusieurs dépendances déjà déclarées dans package.json ; Yarn est utilisé pour restaurer les dépendances existantes avec son lockfile gelé, sans mise à jour des autres packages.

Les CGU affichées et documentaires partagent le texte de l’article 8. `scripts/generate-pre-engagement-cgu.mjs` synchronise le Markdown depuis la page et produit `public/legal/cgu-2026-10-05.pdf`. Les anciens documents restent disponibles ; la nouvelle acceptation référence cette version immuable.

## Décisions

La branche de travail existante est `test`, avec un arbre propre au démarrage. Les modifications restent dans cet espace partagé et ne sont pas poussées.

Les tests de base de données devront utiliser le projet configuré dans `.env`, distinct du projet de production configuré dans `.env.prod`. Aucun secret ne doit apparaître dans les sorties de test.

Les règles de droits sont partagées par le serveur et leurs tests, mais seul le serveur autorise les écritures. L'interface consomme les permissions retournées.

Ruling: les anciennes offres signées reprennent les montants du devis conservé ; les offres ouvertes migrées gardent leur date historique pour appliquer leur vraie expiration. Ce choix évite de prolonger silencieusement un devis ancien ; les candidats devront reconfirmer une offre expirée.

Les traces locales sont ignorées par Git et par la surveillance Nuxt. Le harness E2E lance son propre serveur, reçoit les emails sur un SMTP local, n’utilise que le projet Supabase de test et vérifie le préfixe Stripe `sk_test_`. Les commandes de nettoyage ne visent que ses UUIDs et ses comptes `conversation-<uuid>-<prenom>@example.invalid`.

## Correction du 6 octobre 2026

- La production conservait les droits historiques de `missions.messages`, accessible uniquement via les RPCs : `service_role` ne pouvait pas lire directement la table. Les nouveaux parcours de rechargement, de réponse après envoi et de comptage direct échouaient avec `42501`.
- La migration `20261006093025_messages_server_read_access.sql` accorde uniquement `SELECT` à `service_role`. Elle a été appliquée aux projets de test et de production ; les droits des clients et la RLS restent inchangés.
- Le nouveau test d’intégration reproduit les droits historiques dans une transaction annulée et vérifie la lecture serveur sans ajouter d’accès client ni d’écriture. Les 38 tests ciblés passent, dont les deux tests d’intégration Supabase.
- La requête Supabase de l’alerte du 6 octobre récupère les trois messages avec un statut 200 ; la lecture individuelle utilisée dans la réponse après envoi réussit également.

## Activation définitive du 7 octobre 2026

- Le flag `PRE_ENGAGEMENT_MESSAGING_ENABLED` est supprimé : la messagerie avant engagement est toujours active (missions payantes). En production, `NUXT_PRE_ENGAGEMENT_MESSAGING_ENABLED` n'était jamais lu, car PM2 lance `.output/server/index.mjs` sans charger `.env`. Le flag restait donc à `false` et l'entreprise voyait « La messagerie sera disponible après engagement confirmé » même après une proposition ou une demande de révision.
- `send_message_v4` garde son paramètre `p_pre_engagement_enabled`, auquel le serveur passe toujours `true` : aucune migration n'est nécessaire.
