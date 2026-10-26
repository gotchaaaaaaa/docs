# Glossaire - Gotcha

**Dernière mise à jour**: Mai 2026

## Termes métier

### Acteurs

**Prestataire / Candidat**
- Professionnel proposant ses services
- Postule aux missions
- Reçoit paiements après validation
- Synonyme: Provider (technique)

**Entreprise**
- Organisation publiant des missions
- Paie les prestataires
- Deux types: Festival/Association, Entreprise

**Gotcha**
- Plateforme de mise en relation
- Perçoit commission 13% HT (TVA 20% en sus)
- Gère contrats, devis, paiements escrow, disputes

### Types de missions

**Mission payante**
- `benevole: false`
- Rémunération prestataire
- Paiement via Stripe
- Document: **Devis** (signe par l'entreprise uniquement)

**Mission bénévole**
- `benevole: true`
- Aucune rémunération
- Accessible festivals/associations
- Avantages offerts (repas, accès événement)

### États mission

**Status mission** (`missions.missions.status`):
- `open` : Ouverte aux candidatures
- `assigned` : Un prestataire est assigne (devis signe ou convention signee)
- `unassigned` : Le prestataire assigne s'est desiste → la mission redevient candidatable (cf. `cancel_mission.sql`)
- `completed` : Terminee et payee
- `canceled` : Annulee definitivement par l'entreprise
- `closed` : Archivee

**Origin candidature** (`missions.profile_missions.origin`, distinct du `state`):
- `applied` : candidature spontanee du prestataire (via PostulerDrawer)
- `sourced` : sollicitation directe par l'entreprise (a partir d'un demarche, cf. `demarche_flow_refonte.sql:27`)

**State candidature** (`missions.profile_missions.state`):
- `demarche` : Sollicitation directe entreprise → prestataire (missions payantes uniquement, cf. `refonte_flow_candidature_payant.sql`)
- `postule` : Candidature soumise / devis envoye par le prestataire (peut faire suite a un `demarche`)
- `accepted` : Retenu par l'entreprise (benevoles uniquement, multi-accept possible)
- `confirmed` : Prestataire confirme sa disponibilite (benevoles uniquement, premier arrive gagne)
- `employer_signed` : Entreprise a signe la convention (benevoles uniquement)
- `assigned` : Mission attribuee (devis signe pour payantes, convention signee 2x pour benevoles)
- `completed` : Mission terminee et payee
- `rejected` : Candidature refusee
- `expired` : Timeout (pas de reponse au demarche OU signature benevole hors delai)
- `canceled` : Annulee (provider ou company, regle 24h minimum)

**Contract status** (`missions.contrats.status`):
- `pending_company` : En attente de signature entreprise
- `pending_provider` : En attente de signature prestataire
- `signed` : Les deux parties ont signe (cf. `fix_contract_status_signed.sql`)
- `expired` : Delai de signature depasse
- `canceled` : Annule

**Dispute status** (`missions.disputes.status`):
- `pending` : Ouvert, en attente
- `in_review` : En cours de revision (mediation)
- `resolved` : Resolu (avec `resolution_outcome` : `company_favor` / `provider_favor` / `compromise` / `canceled`)
- `closed` : Ferme/archive

**Payment status** (`profile_missions.payment_status_summary`):
- `pending` → `preauth_created` → `initial_captured` → `final_captured`
- Possibles : `released` (refund a l'entreprise), `refunded`, `failed`

### Documents légaux

**SIRET**
- 14 chiffres
- Numéro identification établissement
- Requis pour indépendants
- Vérification INSEE

**Avis situation SIREN**
- Document INSEE
- Justificatif activité entreprise
- Optionnel mais valorisé

**Attestation vigilance**
- Certification anti-fraude URSSAF
- Validité 6 mois
- Optionnel mais valorisé

**RIB/IBAN**
- Relevé Identité Bancaire
- Format européen (IBAN)
- Requis pour recevoir paiements

**Devis**
- Document commercial pour missions payantes
- Signe uniquement par l'entreprise (OTP)
- Declenche le paiement et l'assignation

**Convention de benevolat**
- Document pour missions benevoles
- Signe par les deux parties (entreprise puis prestataire, OTP)

### Termes financiers

**Charge directe initiale (acompte)**
- A la signature du devis, **charge directe** Stripe (`capture_method: 'automatic'`) de l'acompte si applicable
- Pas de pre-autorisation a ce stade : la carte est debitee immediatement
- L'acompte est integralement transfere au prestataire (pas d'`application_fee_amount`)

**Pre-autorisation finale + capture**
- A la validation du rapport (`POST /api/stripe/release-payment`)
- Nouveau `PaymentIntent` avec `capture_method: 'manual'` pour le **solde restant** (`provider_total_ttc - acompte`)
- `application_fee_amount = commission_ttc + stripe_fee_ttc` (Gotcha encaisse sa commission sur le HT total ici)
- Capture immediate, transfer vers compte Connect prestataire (Stripe deduit l'application fee)
- Migration : `add_escrow_payment_columns.sql`

**Pre-auth supplementaire (supp_hours)**
- Cree separement quand le rapport prestataire ajoute des `final_adjustment_lines` non nuls
- Endpoint integre dans `/api/missions/submit-report.post.js` (l'ancien `/api/stripe/create-supp-hours-preauth` est obsolete)
- Permet de capturer un montant additionnel sans alterer le PaymentIntent precedent
- Colonnes : `supp_hours_payment_intent_id`, `supp_hours_escrow_captured_at`, `supp_hours_transfer_id`

**Commission Gotcha (modele absorbed)**
- 13% HT du montant prestataire (HT) + TVA 20%
- **Absorbee par le prestataire** (modele inverse depuis commit `42f78b7` "from company to providers")
- L'entreprise paie strictement le TTC prestataire (pas de ligne commission ajoutee). C'est le prestataire qui finance la commission, retenue par Stripe via `application_fee_amount` au moment du transfer
- Facture de commission emise par Gotcha **vers le prestataire** (`recipient_type = 'provider'`)
- Calcul : `commission_ht = montant_prestataire_ht * 0.13`
- Cf. `utils/payment-amounts.js` (constante `GOTCHA_COMMISSION_RATE_HT = 0.13`, fonction `buildAbsorbedFeeChargeAmounts`)

**Frais de transaction Stripe**
- 1,5% du TTC + 0,25 EUR (frais HT) + TVA 20%
- **Egalement absorbes par le prestataire** : inclus dans `application_fee_amount` Stripe
- Apparaissent en ligne distincte sur la facture de commission (cf. `update_commission_invoice_transaction_fee_ht_tva.sql`, colonne `missions.invoices.stripe_fee_amount`)
- Cf. constantes `STRIPE_FEE_RATE = 0.015`, `STRIPE_FEE_FIXED_EUR = 0.25`

**Acompte 30% / seuil 800 EUR HT (toujours actif)**
- Si `base_ht >= 800 EUR HT` : l'entreprise paie 30% TTC du montant prestataire **a la signature du devis** (charge directe Stripe `capture_method: 'automatic'`)
- Sinon : aucun prelevement a la signature, tout est paye a la validation du rapport
- Cf. constantes `DEPOSIT_RATE = 0.3` et `DEPOSIT_THRESHOLD_HT = 800` dans `server/utils/payment-flow.js` (`PAYMENT_RULES`)
- L'acompte est integralement transfere au prestataire (pas d'application fee a ce stade)

**Tarif journalier (TJM)**
- Migration `migrate_to_tjm.sql` : passage du taux horaire au TJM HT
- `profile_missions.daily_rate` : TJM HT pour les heures normales
- `profile_missions.daily_rate_supp` : TJM HT pour les heures supplementaires (defaut = `daily_rate * 1.25`)
- Conversion : 1 jour = 8 heures de travail (`HOURS_PER_DAY` dans `utils/rate-calculation.js`)
- Negocie par le prestataire via le devis

**Regle demi-journee (half-day billing)**
- Migration : `update_billing_to_half_day_rule.sql` + `2f63c39`
- Formule : `billing_days = ceil(hours / 4) * 0.5`
- 1h-4h → 0,5j ; 4,5h-8h → 1j ; 8,5h-12h → 1,5j ; 12,5h-16h → 2j
- Le prestataire peut surcharger la valeur dans le PostulerDrawer (etape TJM) si la mission tombe sur un palier intermediaire
- Multi-jour : `billing_days = nombre de jours de mission` (la regle demi-journee s'applique au global)

**Frais additionnels (additional_fee_lines)**
- Lignes libres ajoutees au devis par le prestataire (etape 5 du PostulerDrawer)
- JSONB sur `missions.profile_missions.additional_fee_lines`
- Format : `[{ description: string, amount_ht: number }]`
- Limites : max 20 lignes, description max 160 caracteres, amount > 0, max 2 decimales
- Validation : `utils/additional-fees.js` (`validateAdditionalFeeLines`)
- Total : `additional_fees_ht`

**Ajustements finaux (final_adjustment_lines)**
- Lignes ajoutees par le prestataire lors de la soumission de son rapport (post-mission)
- Memes regles que les additional fees mais sur `final_adjustment_lines` / `final_adjustments_ht`
- Generent une **facture de commission finale** distincte (cf. `add_split_commission_invoices.sql`)
- Peuvent etre negatives (penalite/avoir)

**Temps de preparation (preparation_time)**
- Migration : `add_preparation_time.sql` + `update_create_mission_v2_preparation.sql`
- Option entreprise : `missions.has_preparation_time` + `preparation_hours`
- Option prestataire : surcharge dans le PostulerDrawer (etape 3)
- Tarif : meme TJM ramene a l'heure (`daily_rate / 8`)
- Ligne distincte sur le devis et la facture

**Mission multi-jour**
- Migration : `add_multi_day_missions.sql` + `67777a1`
- Flag `missions.is_multi_day` + table `missions.mission_schedules`
- `mission_schedules` : (`schedule_date`, `start_time`, `end_time`) avec UNIQUE(mission_id, schedule_date)
- Construit cote API par `server/utils/mission-create.js` + `shared/mission-schedule-utils.js`

**Escrow (sequestre Stripe)**
- Migration : `add_escrow_payment_columns.sql` + `add_non_escrow_payment_flows.sql`
- Modele actuel : pre-autorisation Stripe (`requires_capture`) au moment de la signature du devis, **capture differee** apres validation du rapport
- Colonnes cles sur `profile_missions` : `escrow_captured_at`, `escrow_amount`, `transfer_id`, `refund_amount`, `refund_id`, `supp_hours_payment_intent_id`, `supp_hours_escrow_captured_at`
- Pre-auth des heures supplementaires creee dans le flow `/api/missions/submit-report.post.js`
- Auto-release : 31 jours apres ouverture d'un signalement (`disputes.auto_release_at`)

### Zones géographiques

**Zone d'intervention**
- Rayon autour adresse prestataire
- 1-200 km
- Filtre missions visibles
- Géolocalisation (lat/lng)

**Haversine**
- Formule calcul distance sphérique
- Tient compte courbure Terre
- Précision au km près

### Système notifications

**Push notification**
- Notification navigateur
- Web Push API
- VAPID authentication
- Abonnement par device

**OTP (One-Time Password)**
- Code à usage unique
- 5 chiffres
- Expiration 5 minutes
- Signature contrats

### Signalements & disputes

**Signalement / dispute provider-initiated**
- Migration : `add_mission_report_and_disputes.sql` + `add_dispute_signalement_columns.sql` + commit `0cda107`
- Le prestataire peut ouvrir un signalement (`opened_by = 'provider'`) en cours ou en fin de mission
- L'entreprise peut egalement contester le rapport prestataire (`opened_by = 'company'`)
- Endpoint : `POST /api/missions/open-problem-report` + `POST /api/missions/dispute/[pmId]`
- Table : `missions.disputes` (cf. status ci-dessus)
- Rétention escrow : `auto_release_at = opened_at + 31 jours` ; au-dela liberation automatique si pas de resolution

**Rapport de mission (post-mission)**
- Flow actuel : c'est le **prestataire** qui soumet son rapport en premier (heures travaillees + heures supp + ajustements finaux)
- Endpoint : `POST /api/missions/provider-submit-report`
- L'entreprise consulte puis paye directement (`POST /api/missions/validate-report` puis `release-payment`)
- Si l'entreprise conteste, elle peut ouvrir un signalement et capturer le paiement via `/api/stripe/capture-on-dispute`
- Cron de relance : `/api/cron/company-report-followup` + `auto-validate-reports`

### Carte & matching

**Provider clustering (carte entreprise)**
- Commit `6f684e0` : regroupement des prestataires sur la carte
- Implementation : **custom pixel-based** dans `pages/map/search-provider.vue:505+` (PAS le clustering natif Mapbox GeoJSON)
- Seuil : `CLUSTER_PX_THRESHOLD = 50` pixels
- Algo : projette chaque provider en coordonnees ecran (`map.project()`) et regroupe ceux dont la distance < 50px
- Markers DOM custom (photos stackees + badge count), barycentre = moyenne lat/lng
- Click cluster → calcul du zoom auquel il se desagrege puis `map.flyTo()`
- RPC backend : `public.get_providers_for_map_v3` (renvoie `is_available_now`)

**Available now indicator**
- Migration : `add_provider_available_now_indicator.sql` + commit `c83af91`
- RPC : `providers.is_provider_available_now(p_provider_id, p_now)`
- Le prestataire est "disponible maintenant" si :
  - `profiles.available = true` ET `profiles.visible_on_map = true`
  - au moins un creneau `availabilities` couvre l'instant `p_now`
- Affichage badge vert "Disponible maintenant" sur les `ProviderCard` de la carte

**Top providers (homepage)**
- Migration : `add_top_provider_home_rpc.sql`
- Flag editorial `providers.providers.top_provider` (boolean)
- RPC : `public.get_top_providers_for_home()` (filtre `top_provider = true AND verified = true AND available = true`, tri par note)

### Sanctions

**Warning** (Avertissement)
- `warning_1`: 1ère annulation
- `warning_2`: 2ème annulation consécutive
- Aucune restriction

**Suspension**
- `suspended_7d`: 7 jours (3ème annulation)
- `suspended_30d`: 30 jours (4ème+)
- Invisible plateforme

**Badge vérifié**
- Icône ✓ verte
- Profil validé manuellement
- Documents vérifiés
- Bonnes notations

### Termes techniques

**RLS (Row Level Security)**
- Sécurité niveau ligne PostgreSQL
- Politiques d'accès granulaires
- Basé sur `auth.uid()`

**RPC (Remote Procedure Call)**
- Fonction SQL appelable depuis app
- Logique métier côté base
- Permissions Supabase

**Supabase Storage**
- Stockage fichiers (documents, photos)
- UUID noms fichiers
- Métadonnées en BDD

**Stripe Connect**
- Plateforme paiements multi-parties
- Compte Custom prestataire (MCC 5734)
- Onboarding via `/api/stripe/create-connect-account` (tokens cote client) + `/api/stripe/create-account-link`
- Verification d'identite : `/api/stripe/create-verification-session` + `check-identity-status`
- Transferts automatiques apres capture finale

**eIDAS / Preuve de signature**
- Migration : `add_otp_signature_fields.sql` + `008-legal-evidence-refactor.sql`
- Toute signature (devis, contrat, CGV entreprise) genere un **certificat de signature electronique** (trame `certificat_signature`)
- Donnees scellees : hash du document signe + IP **chiffree** + user-agent + horodatage + version de texte de consentement (`shared/contract-signature-consent.js`)
- Scellement quotidien : crons `seal-contract-evidence-daily`, `seal-devis-evidence-daily`, `seal-company-cgv-evidence-daily`
- Retention 7 ans par defaut, extensible via `legal-hold`
- Verification : endpoints `/api/contract/evidence/[contract_id]/check` + `/export`

**Trames PDF**
- Stockees dans `database/trames.json` (4 types) :
  - `contrat_prestation` (Markdown) — contrat / convention
  - `invoice_provider` (Layout JSON) — facture prestataire
  - `invoice_commission` (Layout JSON) — facture commission Gotcha
  - `certificat_signature` (Markdown) — certificat eIDAS

**Field whitelisting (mass-assignment)**
- Commit `f2ca900` (12/05/2026)
- Endpoints onboarding (`/api/auth/signup`, `/api/me/profile.patch`, `/api/provider/save-onboarding`, `/api/company/save-onboarding`, etc.) appliquent un **whitelist strict** des champs accepts
- Implementation **inline** dans chaque endpoint (pas de helper centralise), pattern `ALLOWED_FIELDS = [...]` + `Object.fromEntries(...).filter(...)`. Exemple : `server/api/provider/save-onboarding.post.js:42`
- Tout champ non liste est silencieusement ignore

**Blind index (recherche sur donnees chiffrees)**
- Colonnes `_bidx` (HMAC deterministe) pour permettre l'egalite exacte sur des donnees chiffrees AES-256-GCM
- Tables concernees : `providers.siret_bidx`, `companies.siret_bidx`, `providers.stripe_id_bidx`, `profile_missions.stripe_initial_payment_intent_id_bidx`, `stripe_final_payment_intent_id_bidx`, `messages.content_bidx`, etc.

---

**Fin du document - Glossaire**
