# Workflows Prestataire - Gotcha

**Dernière mise à jour**: Mai 2026 (TJM, half-day billing, additional fees, photo HEIC, signalement, tutorial)
**Audience**: Équipe interne (Product, Business, Dev)

## Table des matières

1. [Inscription et onboarding](#inscription-et-onboarding)
2. [Système de compétences](#système-de-compétences)
3. [Zone d'intervention](#zone-dintervention)
4. [Système de disponibilité](#système-de-disponibilité)
5. [Processus de candidature](#processus-de-candidature)
6. [Documents requis](#documents-requis)
7. [Badge de vérification](#badge-de-vérification)
8. [Exécution de mission](#exécution-de-mission)
9. [Gestion du compte](#gestion-du-compte)

---

## Inscription et onboarding

Page: `pages/prestataire/inscription/`
Composable: `composables/useProviderSignup.js`

### Parcours en 19 étapes (varie selon situation)

#### Informations personnelles (2 étapes)

**Étape 1: Date de naissance**
- Champ: `birth_date` (date picker)
- Validation: Âge minimum 18 ans
- Format: YYYY-MM-DD
- Stockage: `profiles.birth_date`

**Étape 2: Photo de profil** (optionnel)
- Upload image (JPG, PNG, WebP)
- Limite: 5MB
- Recadrage circulaire automatique
- Stockage: `profiles.photo` (Supabase Storage ID)
- **Peut être complété plus tard**

---

#### Informations professionnelles (15 étapes)

**Étape 3: Véhicule/Transport**
- Question: "Possédez-vous un véhicule ?"
- Champ: `vehicule` (boolean)
- Impact: Affecte visibilité pour missions avec mobilité requise

**Étape 4: Situation & Bénévolat**
- **Situation professionnelle**:
  - CDI (Contrat Durée Indéterminée)
  - CDD (Contrat Durée Déterminée)
  - Sans emploi
  - Étudiant
  - **Indépendant** ⚠️ (déclenche étapes financières)
  - Autre
- **Bénévolat**: Toggle (obligatoire pour non-indépendants)
- Stockage: `providers.situation`, `providers.benevolat`

**⚠️ BIFURCATION**: Si "Indépendant" → Étapes 7-16 (documents, SIRET, CGV, IBAN, tarif)
Si autre situation → Saute directement à étape 18 (zone intervention)

---

**Étape 5: Compétences** (optionnel pour bénévoles, requis pour indépendants)
- Sélection multiple compétences
- Composant: `JobsSelect.vue`
- Recherche temps réel dans catalogue
- Hiérarchie: Domaine > Catégorie > Métier
- Stockage: `providers.provider_jobs` (table de liaison)
- **Peut être complété plus tard**

**Étape 6: Diplômes** (optionnel)
- Liste éditable (ajout/suppression)
- Champs par diplôme:
  - Intitulé
  - Date d'obtention
  - Compétence associée (lien vers provider_jobs)
- Stockage: `providers.diplomes`
- **Peut être complété plus tard**

**Étape 7: Expériences** (optionnel)
- Liste éditable
- Champs par expérience:
  - Intitulé poste
  - Date début
  - Date fin (optionnel si en cours)
  - Description
  - Compétence associée
- Stockage: `providers.experiences`
- **Peut être complété plus tard**

**Étape 8: Description** (optionnel)
- Zone de texte libre
- Présentation personnelle
- Atouts, expériences marquantes
- Stockage: `providers.more`
- **Peut être complété plus tard**

---

#### Étapes indépendants uniquement (7-17)

**Étape 9: SIRET**
- Numéro 14 chiffres
- Validation: Format + API INSEE
- Unicité vérifiée
- Stockage: `providers.siret`
- **Requis pour indépendants**

**Étape 10: Avis situation SIREN**
- Upload document PDF/image
- Justificatif INSEE
- Stockage: `providers.avis_situ_siren` (Supabase Storage)
- **Optionnel** mais recommandé

**Étape 11: Attestation vigilance**
- Upload document PDF/image
- Certification anti-fraude
- Validité 6 mois
- Stockage: `providers.attestation_vigilance`
- **Optionnel** mais recommandé

**Étape 12: Adresse de facturation**
- Champ texte libre
- Format adresse complète
- Stockage: `providers.adresse_facturation`
- **Optionnel**

**Étape 13: Régime TVA**
- Dropdown sélection:
  - Franchise en base
  - TVA normale
  - Micro-entreprise
  - Autre
- Stockage: `providers.regime_tva`
- **Optionnel**

**Étape 14: Assurance professionnelle**
- Question booléenne: "Possédez-vous une assurance professionnelle ?"
- Upload attestation
- Stockage: `providers.assurance_pro` (boolean)
- **Requis pour indépendants**

**Étape 15: Conditions Générales de Vente** (skippable)
- 2 options :
  - "Utiliser les CGV par défaut de Gotcha" (avec bouton preview)
  - "Uploader mes propres CGV" (upload PDF, max 5MB)
- Ce step est skippable (si skip → CGV par défaut utilisées)
- Stockage: `providers.cgv_file_path` (NULL = CGV par défaut)
- **Peut être complété plus tard** (dans les réglages)

**Étape 16: IBAN**
- Champ formaté avec validation checksum
- Format: FRXX XXXX XXXX XXXX XXXX XXXX XXX
- Validation IBAN européen
- Champs additionnels:
  - BIC (optionnel, auto-détecté si possible)
  - Titulaire du compte
- Stockage: `providers.iban`, `providers.bic`, `providers.titulaire_compte_banc`
- **Requis pour indépendants**

**Étape 17: Tarif Journalier Moyen (TJM)**
- Migration `migrate_to_tjm.sql` : facturation au TJM HT (1 jour = 8h, cf. `HOURS_PER_DAY`)
- Saisie via composant `ImportNumber` avec suggestions, `reference-price` et `floor-multiplier`
- TJM par defaut pour candidatures
- Heures supplementaires : `daily_rate_supp = daily_rate * 1.25` (modifiable)
- Note: Peut être différent par compétence (voir `providers.provider_jobs.daily_rate`)
- Stockage: TJM global + override par compétence
- **Requis pour indépendants**

---

#### Étapes finales (tous les profils)

**Étape 18: Zone d'intervention**
- Champ adresse avec autocomplete (API française)
- Rayon: 1-200 km (slider)
- Prévisualisation carte Mapbox avec cercle
- Géolocalisation automatique (lat/lng)
- Stockage:
  - `providers.zone_intervention_cp` (code postal)
  - `providers.zone_intervention_rayon` (km)
  - `providers.zone_intervention_lat` (latitude)
  - `providers.zone_intervention_lng` (longitude)
- **Requis pour tous**

**Étape 19: Consentements**
- ✅ **CGU** (obligatoire)
- ⬜ Géolocalisation (optionnel, affecte visibilité)
- ⬜ Notifications push (optionnel)
- ⬜ Newsletter (optionnel)
- Stockage: `providers.accept_cgu`, `accept_geoloc`, `accept_notifications`, `accept_newsletter`

---

### Logique de parcours

```
Étapes 1-4: Tous
    ↓
Situation = "Indépendant" ?
    ↓ OUI                    ↓ NON
Étapes 5-17              Étapes 5-8 (optionnels)
(avec docs + CGV + IBAN)         ↓
    ↓                    Skip étapes 9-17
Étapes 18-19             Étapes 18-19
    ↓                            ↓
  Onboarding complet
```

### Validation finale

**Flag**: `providers.done_onboarding = true`

**Conditions pour `true`**:
- Étapes obligatoires complétées selon situation
- Si indépendant: SIRET, assurance, IBAN requis
- Zone intervention définie
- CGU acceptées

**Effet**:
- Accès complet plateforme
- Visible pour entreprises (si géoloc activée)
- Peut postuler aux missions

---

## Système de compétences

### Structure hiérarchique

**Catalogue Jobs** (`jobs` schema):

```
Domaine (ex: Restauration)
  └── Catégorie (ex: Service)
      └── Métier (ex: Serveur)
          └── Compétences associées
```

### Association prestataire-compétence

**Table**: `providers.provider_jobs`

**Colonnes**:
- `id`: UUID
- `provider`: ID provider (FK `providers.providers`)
- `job`: ID job (FK `jobs.jobs`)
- `hourly_rate`: Tarif horaire pour CETTE compétence (peut différer du tarif global)

### Sélection multiple

Un prestataire peut avoir **plusieurs compétences** avec des tarifs différents:

**Exemple**:
```
Prestataire: Jean Dupont
├── Serveur: 25€/h
├── Barman: 30€/h
└── Plongeur: 20€/h
```

### Utilisation dans candidatures

- Mission demande UNE compétence spécifique
- Prestataire postule avec le tarif de CETTE compétence
- Si compétence non dans son profil: impossible de postuler
- Matching automatique: `mission.job IN prestataire.provider_jobs`

### Modification post-inscription

Page: `/prestataire/compte/profil.vue` section "Compétences"

Actions:
- Ajouter nouvelle compétence avec tarif
- Modifier tarif existant
- Supprimer compétence (si aucune mission active)

---

## Zone d'intervention

### Configuration

Page: `/prestataire/compte/mode-disponible.vue`

**Composant**: `zoneIntervention.vue` avec Mapbox

### Paramètres

**Adresse de référence**:
- Autocomplete API française (api-adresse.data.gouv.fr)
- Géolocalisation automatique
- Stockage coordonnées GPS exactes

**Rayon d'intervention**:
- Slider 1-200 km
- Visualisation cercle sur carte
- Couleur: violet #6600FF avec 30% opacité
- Auto-zoom selon rayon

### Calcul de matching

**Formule Haversine** (distance sphérique):
```
distance = 6371 × acos(
  cos(lat1) × cos(lat2) × cos(lng2 - lng1) +
  sin(lat1) × sin(lat2)
)
```

**Résultat**: Distance en kilomètres entre deux points GPS

**Filtrage**:
- Mission dans zone prestataire: `distance ≤ rayon`
- Affichage distance exacte sur cartes missions

### Impact

**Visibilité missions**:
- Prestataire voit UNIQUEMENT missions dans sa zone
- Notifications UNIQUEMENT pour missions dans zone
- Exception: Missions bénévoles (rayon élargi possible)

**Visibilité prestataire**:
- Entreprise voit prestataires dans zone de la mission
- Tri par distance croissante (plus proches en premier)

### Modification

- Changement adresse: Recalcul automatique lat/lng
- Changement rayon: Prévisualisation immédiate sur carte
- Déclenchement: Recherche nouvelles missions correspondantes + notifications

---

## Système de disponibilité

### Deux niveaux

#### 1. Toggle global (`providers.available`)

**Fonction**: `useAvailabilities.toggleAvailability()`

**États**:
- ✅ Disponible (vert): Visible sur carte entreprises, reçoit notifications
- ❌ Indisponible (gris): Invisible, aucune notification

**Affichage**: Widget dashboard avec switch rapide

**Effet immédiat**:
- Si passe à "disponible": Recherche missions ouvertes + notifications entreprises
- Si passe à "indisponible": Disparaît des résultats recherche

---

#### 2. Créneaux horaires (`providers.availabilities`)

**Table**: Créneaux de disponibilité détaillés

**Colonnes**:
- `provider`: ID provider
- `start_date`: Date début (YYYY-MM-DD)
- `end_date`: Date fin (YYYY-MM-DD, optionnel si récurrent)
- `start_time`: Heure début (HH:MM)
- `end_time`: Heure fin (HH:MM)
- `type`: 'available' (peut être étendu: 'busy', 'tentative')
- `note`: Note personnelle
- `is_recurring`: Boolean (se répète chaque semaine)
- `weekdays`: Array de jours si récurrent [0,1,2,3,4,5,6] (0=dimanche)

**Exemple créneaux**:
```
Lundi-Vendredi 9h-17h (récurrent)
├── start_time: "09:00"
├── end_time: "17:00"
├── is_recurring: true
└── weekdays: [1,2,3,4,5]

Samedi 15 janvier 14h-22h (ponctuel)
├── start_date: "2026-01-15"
├── start_time: "14:00"
└── end_time: "22:00"
```

### Gestion créneaux

**Fonctions** (`useAvailabilities`):

- `fetchAvailabilities()`: Récupération tous créneaux
- `createAvailability(creneauData)`: Ajout nouveau
- `updateAvailability(id, updates)`: Modification
- `deleteAvailability(id)`: Suppression
- `saveAvailability(creneauData)`: Create OU Update

### Synchronisation Google Calendar

**Fonction**: `syncWithGoogleCalendar()`

**Processus**:
1. Authentification OAuth Google
2. Récupération événements calendrier (30 jours)
3. **Suppression** tous créneaux existants
4. Analyse plages libres entre événements
5. Création créneaux "available" pour temps libre
6. Stockage dans `providers.availabilities`

**⚠️ Attention**: Écrase tous créneaux manuels existants

---

## Processus de candidature

**Composant**: `components/shared/PostulerDrawer.vue`

### Missions payantes — 7 étapes (refonte Mai 2026)

| Étape | Contenu | Condition | Skippable |
|-------|---------|-----------|-----------|
| 1 | Disponibilité & Transport | Toujours | Non |
| 2 | Matériel à apporter | Si `mission.items_to_bring.length > 0` | Non |
| 3 | Temps de préparation | Toujours (toggle si mission sans prep) | Oui |
| 4 | TJM (clamp min/max, choix `billing_days`) | Toujours | Non |
| 5 | **Frais additionnels** (`additional_fee_lines`) | Toujours | Oui |
| 6 | CGV | Toujours | Non |
| 7 | Récapitulatif avec preview devis PDF | Toujours | Non |

> Etape 4 (TJM) : `daily_rate` est clampe par defaut au minimum du prestataire (commit `7973f2e`). Le palier `billing_days` peut etre override (commit `d2fec2c`) — si la mission tombe sur un demi-palier (ex: 1.5j), choix entre 1j et 1.5j.

> Etape 5 (additional fees) : tableau de lignes `{description, amount_ht}`, max 20, description 160 chars, montant > 0, max 2 decimales. Validation : `utils/additional-fees.js`.

### Missions bénévoles — 4 étapes (inchangé)

| Étape | Contenu | Condition |
|-------|---------|-----------|
| 1 | Disponibilité & Transport | Toujours |
| 2 | Matériel à apporter | Si `mission.items_to_bring.length > 0` |
| 3 | ~~Taux horaire~~ | **SKIP** (bénévoles) |
| 4 | Récapitulatif | Toujours |

---

#### Étape 1: Disponibilité & Transport

**Questions**:
1. "Confirmez-vous votre disponibilité pour cette mission ?"
   - Requis: OUI pour continuer

2. "Possédez-vous un moyen de transport ?" (si `mission.requires_mobility = true`)
   - Requis: OUI pour continuer
   - Comparé avec `providers.vehicule`
   - Si pas de véhicule ET requis: Avertissement affiché

**Bloquant**: Impossible de continuer sans confirmer les deux

---

#### Étape 2: Matériel à apporter

**Affichage**: Liste items définis par entreprise (`mission.items_to_bring`)

**Format**: Checklist avec cases à cocher

**Exemple**:
```
☐ Tenue noire (chemise + pantalon)
☐ Chaussures de ville fermées
☐ Tablier blanc
```

**Validation**: TOUS les items doivent être cochés

**Stockage**: `profile_missions.items_confirmed = true`

---

#### Étape 3 (payant) — Temps de préparation

- Si la mission a `has_preparation_time = true` : affiche l'estimation entreprise + input modifiable
- Si la mission n'a pas de temps de prep : toggle "Souhaitez-vous ajouter un temps de préparation ?" + input
- Tarif applique = `daily_rate / 8` (HOURS_PER_DAY)
- Les heures de préparation apparaissent comme ligne séparée sur le devis

---

#### Étape 4 — TJM (Tarif Journalier Moyen)

**Champs** (composant `ImportNumber`) :

**TJM HT** (`daily_rate`) :
- Clampe au minimum du prestataire (`reference-price` + `floor-multiplier`)
- Affichage de l'avis TVA 20% (TTC pour info)
- Suggestions calculees vs marche

**TJM heures supplementaires** (`daily_rate_supp`) :
- Defaut : `daily_rate * 1.25`
- Modifiable

**Choix du palier `billing_days`** :
- Calcule via `billingDaysFromHours(missionHours, override, missionDays)` (`utils/rate-calculation.js`)
- Mono-jour : `ceil(hours / 4) * 0.5` (0.5j, 1j, 1.5j, 2j...)
- Multi-jour : nombre de jours de la mission
- Si le calcul tombe sur un demi-palier, l'utilisateur peut choisir d'upgrader (cf. `canUpgradeBillingDays`)

---

#### Étape 5 (payant) — Frais additionnels

- Tableau dynamique de lignes `{description, amount_ht}`
- Limites (validees cote client + serveur) : max 20 lignes, description 160 chars max, amount > 0, max 2 decimales
- Affichage du total `additional_fees_ht`
- Stockage : `profile_missions.additional_fee_lines` JSONB + `additional_fees_ht`

---

#### Étape 5 (payant) — CGV

- Composant: `CgvSelector.vue`
- Affiche les CGV actuelles du prestataire (custom ou par défaut)
- Bouton "Voir mes CGV" (ouvre le PDF)
- Option de changer les CGV ou d'en uploader de nouvelles

---

#### Étape 6 (payant) — Récapitulatif / Preview devis

- Appel API `/api/devis/preview` pour générer un PDF temporaire
- Affichage dans `SharedContractPdfViewer`
- Mention de l'acompte si applicable : "Acompte de X EUR TTC sera prélevé à l'acceptation"
- Mention CGV jointes
- Bouton "Envoyer ma proposition" (SlideButton)

---

### Soumission

- **Missions payantes** → POST `/api/missions/apply` (BFF) — insère dans `missions.profile_missions` avec state `postule`, `origin: 'applied'`, `daily_rate`, `daily_rate_supp`, `billing_days`, `preparation_hours`, `additional_fee_lines`, `additional_fees_ht`, `cgv_file_path`, `devis_number`
- **Missions bénévoles** → même endpoint, sans les champs tarification

**Notifications déclenchées**:
- Email entreprise: "Nouvelle candidature pour votre mission"
- Push entreprise: "X a postulé à votre mission Y"
- Badge compteur sur dashboard entreprise

---

## Documents requis

### Pour tous les prestataires

**Pièce d'identité** (`profiles.doc_identite`):
- Types acceptés: CNI, Passeport, Titre de séjour
- Format: Image ou PDF
- Stockage: Supabase Storage
- Vérification manuelle par équipe

---

### Pour indépendants uniquement

**1. SIRET** (`providers.siret`):
- 14 chiffres
- Validation API INSEE
- Unicité vérifiée
- Stockage: Texte

**2. Avis situation SIREN** (`providers.avis_situ_siren`):
- Document INSEE officiel
- Format: PDF recommandé
- Optionnel mais valorisé
- Stockage: Supabase Storage

**3. Attestation vigilance** (`providers.attestation_vigilance`):
- Certification anti-fraude
- Validité: 6 mois
- Obtention: URSSAF
- Format: PDF
- Optionnel mais valorisé
- Stockage: Supabase Storage

**4. Attestation assurance professionnelle** (`providers.assurance_pro`):
- Responsabilité civile professionnelle
- Requis pour certaines compétences (sécurité, santé)
- Format: PDF
- Stockage: Supabase Storage

**5. IBAN** (`providers.iban`):
- Format européen validé (checksum)
- Champs associés: BIC, titulaire compte
- Requis pour recevoir paiements
- Stockage: Texte (chiffré côté DB si sensible)

---

### Upload documents

**Composant**: `SelectFile.vue`

**Fonctionnalités**:
- Drag & drop OU clic pour sélection
- Limite: 5MB par fichier
- Types acceptés: image/* (JPG, PNG), application/pdf
- Prévisualisation immédiate (image) ou icône PDF
- Upload Supabase Storage avec métadonnées

**Métadonnées stockées**:
- Nom fichier original
- Type MIME
- Taille
- Date upload
- Lien vers table (`profiles` ou `providers`)
- Colonne cible (`doc_identite`, `avis_situ_siren`, etc.)

---

## Badge de vérification

### Critères d'obtention

**Champ**: `providers.verified` (boolean)

**Conditions cumulatives**:

1. ✅ Profil 100% complet:
   - Toutes infos personnelles renseignées
   - Photo de profil uploadée
   - Description remplie

2. ✅ Documents validés manuellement:
   - Pièce d'identité vérifiée
   - Si indépendant: SIRET + assurance validés

3. ✅ Premières missions réussies:
   - Minimum 3 missions complétées
   - Notation moyenne ≥ 4/5
   - Aucune annulation récente

4. ✅ Aucune sanction active:
   - `suspension_status` pas en suspended_7d/30d/banned
   - Pas de warnings multiples récents

**Processus**: Vérification manuelle par équipe + automatisations futures

---

### Avantages badge vérifié

**Visibilité**:
- Affiché avec icône ✓ verte sur profil
- Tri prioritaire dans recherches entreprise
- Mis en avant dans suggestions remplacement

**Confiance**:
- Signal qualité pour entreprises
- Peut commander tarifs plus élevés
- Accès missions premium (futures)

**Révocation**:
- Si sanction suspension ≥7 jours
- Si notation descend <3/5
- Si documents expirés non renouvelés

---

## Exécution de mission

### Missions payantes

```
postule → assigned (direct, via signature devis entreprise)
```

Après soumission de la candidature (`postule`) :
1. L'entreprise consulte le devis sur `/entreprise/profil-prestataire/{providerId}?mission=X&pm=Y`
2. Si l'entreprise accepte : redirigée vers `/entreprise/devis/{pmId}` pour signer le devis
3. L'entreprise signe via OTP → débit Stripe direct → state passe à `assigned`, autres candidats rejetés
4. **Le prestataire ne signe rien** pour les missions payantes

Après `assigned` :
- Le prestataire peut consulter son devis signé à `/prestataire/mes-devis/{pmId}`
- Le prestataire peut télécharger le PDF du devis et le certificat eIDAS

---

### Missions bénévoles — Signature convention

> Ce flux s'applique uniquement aux missions bénévoles.

**États successifs** :
```
postule → accepted (entreprise) → confirmed (prestataire) → employer_signed (entreprise signe) → assigned (prestataire signe)
```

Page: `/prestataire/contrat/[id].vue`

**Étapes**:

1. **Récapitulatif**:
   - Détails mission
   - Détails entreprise
   - Tarifs convenus
   - Heures et dates
   - Lieu
   - Bouton "Consulter le contrat"

2. **Consultation contrat**:
   - Affichage HTML complet (généré côté entreprise)
   - Lecture défilante
   - Bouton "Signer le contrat" en bas

3. **Demande OTP**:
   - API: POST `/api/contract/provider/send-otp.post.js`
   - Code 5 chiffres envoyé par email
   - Expiration: 5 minutes
   - Rate limit: 1 OTP / 60 secondes

4. **Vérification OTP**:
   - API: POST `/api/contract/provider/verify-otp.post.js`
   - Saisie code dans modal
   - Vérification hash bcrypt
   - Si OK:
     - `provider_signed_at` = NOW()
     - `provider_signature_ip` = IP prestataire
     - `provider_signature_user_agent` = Navigateur
     - `profile_missions.state` → 'assigned'
     - `missions.status` → 'assigned'

5. **Confirmation**:
   - Message succès
   - "La mission est confirmée ! L'entreprise vous contactera."
   - Lien vers dashboard

---

### Pendant la mission

**Aucun tracking temps réel** (actuellement)

**Communication**: Messagerie intégrée avec entreprise

**Statut**: `state = 'assigned'` stable

---

### Apres la mission

**Rapport du prestataire** (nouveau flow Mars 2026):
- Le **prestataire** soumet son rapport avec heures travaillees + heures supp eventuelles
- Il voit un recapitulatif avec **apercu de la facture** avant envoi
- `provider_validation_status = 'approved'` (le presta soumet lui-meme)
- `payment_status = 'awaiting_company_payment'`
- Notification envoyee a l'entreprise

**Paiement par l'entreprise**:
- L'entreprise recoit le rapport du prestataire
- Elle voit le recapitulatif + apercu de la facture
- Elle paye directement (pas de pre-autorisation)
- `payment_status = 'final_captured'`
- Factures generees et envoyees automatiquement

**Contestation** (par l'entreprise):
- Si l'entreprise conteste les heures declarees
- Ouverture formulaire de signalement de probleme
- Motifs: desaccord heures, probleme paiement, qualite mission, autre
- Creation `missions.disputes`

---

### Finalisation

**Apres paiement**:
- Paiement direct effectue
- Notification: "Paiement recu pour la mission X"
- `profile_missions.state` -> 'completed'
- Drawer notation entreprise s'ouvre (cote presta)
- Drawer notation prestataire s'ouvre (cote entreprise)

**Reset sanctions**:
- `consecutive_cancellations = 0`
- `last_successful_mission_at = NOW()`
- Warnings effacés

---

## Gestion du compte

### Dashboard (`/prestataire/dashboard.vue`)

**Widgets**:

1. **Bannière sanctions** (si applicable):
   - Affichage niveau warning/danger/error
   - Compte à rebours si suspension
   - Icône selon gravité
   - Dismissible temporairement

2. **Toggle disponibilité**:
   - Switch rapide disponible/indisponible
   - Affichage état actuel
   - Clic = bascule immédiate

3. **Onglets missions**:
   - **Toutes**: Toutes missions
   - **Actions requises**:
     - Propositions à soumettre (démarchages entreprise, `state = 'demarche'`)
     - Devis signés à consulter
     - Rapports a soumettre (missions terminees)
     - Entreprises a noter
     - Contrats à signer (missions bénévoles uniquement)

4. **Cartes missions** (`MyMissionCard.vue`):
   - Photo entreprise
   - Titre mission
   - Date et horaires
   - État (badges colorés)
   - Actions selon état

---

### Profil (`/prestataire/compte/profil.vue`)

**Sections éditables**:

1. **Informations personnelles**:
   - Photo (upload/changement)
   - Nom, prénom
   - Date naissance
   - Genre
   - Téléphone
   - Adresse

2. **Informations professionnelles**:
   - Situation
   - Compétences (ajout/suppression/tarifs)
   - Diplômes
   - Expériences
   - Description

3. **Documents**:
   - CNI
   - SIRET (si indépendant)
   - Assurance
   - Attestations

4. **Paramètres**:
   - Zone intervention
   - Disponibilités (créneaux)
   - Notifications
   - CGU, géolocalisation

**Badge profil complet**:
- Barre de progression (%)
- Sections manquantes listées
- Lien vers complétion

---

### Disponibilités (`/prestataire/compte/mode-disponible.vue`)

**Gestion zone**:
- Modification adresse référence
- Ajustement rayon
- Prévisualisation carte temps réel

**Gestion créneaux**:
- Liste créneaux existants
- Ajout nouveau créneau (ponctuel/récurrent)
- Modification créneaux
- Suppression
- Synchronisation Google Calendar

---

### Mes missions (`/prestataire/mes-missions.vue`)

**Filtres**:
- Par état (postulé, confirmé, en cours, terminé)
- Par période
- Par entreprise

**Tri**:
- Plus récentes
- Date mission
- Alphabétique

**Actions par mission**:
- Voir détails
- Soumettre une proposition (pour `state = 'demarche'`)
- Consulter le devis (missions payantes assignées)
- Signer contrat (missions bénévoles uniquement)
- Ouvrir messagerie
- Soumettre rapport de fin de mission
- Noter entreprise
- Télécharger contrat (bénévoles uniquement)
- Annuler (si >24h avant)

---

### Mes devis (`/prestataire/compte/mes-devis.vue` + `/prestataire/mes-devis/[pmId].vue`)

Liste des devis signés (missions payantes uniquement).

**Page liste** : Tableau des devis avec date de signature, entreprise, montant, état

**Page détail** (`/prestataire/mes-devis/{pmId}`) :
- Affichage PDF du devis signé dans `SharedContractPdfViewer`
- Bouton "Télécharger le devis" (PDF)
- Bouton "Télécharger le certificat eIDAS"
- Informations : date de signature entreprise, montants (HT, TVA, TTC, acompte)

---

### Mes documents (`/prestataire/mes-documents.vue`)

**Gestion centralisée**:
- Upload nouveaux documents
- Remplacement documents expirés
- Téléchargement copies
- Statuts validation (en attente, validé, refusé)

---

### Paramètres (`/prestataire/compte/reglages.vue`)

**Notifications**:
- Nouvelles missions correspondantes
- Notifications contractuelles (obligatoire)
- Messages entreprises
- Actualités plateforme

**Préférences**:
- Langue (FR/EN - stub)
- Unités (km/miles)

**Conditions Générales de Vente** :
- Affiche : "CGV par défaut Gotcha" ou "CGV personnalisées"
- Boutons : "Voir mes CGV", "Changer" (upload/switch vers défaut)

---

## Références techniques

### Tables principales
- `profiles` - Compte utilisateur
- `providers.providers` - Données prestataire
- `providers.provider_jobs` - Compétences avec tarifs
- `providers.diplomes` - Diplômes
- `providers.experiences` - Expériences
- `providers.availabilities` - Créneaux disponibilité
- `missions.profile_missions` - Candidatures/missions

### Fonctions RPC cles
- `confirm_availability()` - Confirmation candidature
- `get_provider_dashboard_missions()` - Missions dashboard
- `get_finished_missions_popup_provider()` - Popup fin de mission
- `missions.create_demarche_application()` - Creation d'un demarchage
- `missions.respond_to_demarche()` - Reponse prestataire au demarchage

### API routes
- `/api/contract/provider/send-otp.post.js` - OTP signature (benevoles)
- `/api/contract/provider/verify-otp.post.js` - Verification signature (benevoles)
- `/api/missions/provider-submit-report.post.js` - Soumission rapport fin de mission
- `/api/invoices/preview.post.js` - Apercu facture PDF
- `/api/provider/sanctions` - Consultation sanctions
- `/api/missions/apply.post.js` - Soumission candidature (payant + benevole)
- `/api/missions/respond-demarche.post.js` - Reponse a un demarchage
- `/api/missions/decline-demarche.post.js` - Declin d'un demarchage
- `/api/devis/preview.post.js` - Preview PDF devis
- `/api/cgv/upload.post.js` - Upload CGV personnalisees
- `/api/cgv/provider/[providerId].get.js` - Recuperation CGV

### Composants cles
- `PostulerDrawer.vue` - Formulaire candidature
- `MyMissionCard.vue` - Carte mission (prestataire)
- `SuccessPopup.vue` - Base popup succes (partagee)
- `ProviderReportRecapDrawer.vue` - Recap rapport + apercu facture
- `InvoicePdfViewer.vue` - Viewer PDF factures (mode DB + mode preview)
- `SanctionBanner.vue` - Banniere sanctions
- `zoneIntervention.vue` - Configuration zone
- `CgvSelector.vue` - Selection/upload CGV dans PostulerDrawer
- `SharedContractPdfViewer.vue` - Viewer PDF (devis + contrats)

### Composables
- `useProviderSignup.js` - Logique onboarding
- `useAvailabilities.js` - Gestion disponibilités
- `useProviderMissions.js` - Récupération missions

---

**Fin du document - Workflows Prestataire**
