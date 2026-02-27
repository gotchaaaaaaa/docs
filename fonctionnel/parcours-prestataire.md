# Workflows Prestataire - Gotcha

**Dernière mise à jour**: Janvier 2026
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
Configuration: `config/providersSignupStepsConfig.js`

### Parcours en 17 étapes (varie selon situation)

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

**⚠️ BIFURCATION**: Si "Indépendant" → Étapes 7-15 (documents, SIRET, IBAN, tarif)
Si autre situation → Saute directement à étape 16 (zone intervention)

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

#### Étapes indépendants uniquement (7-15)

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

**Étape 15: IBAN**
- Champ formaté avec validation checksum
- Format: FRXX XXXX XXXX XXXX XXXX XXXX XXX
- Validation IBAN européen
- Champs additionnels:
  - BIC (optionnel, auto-détecté si possible)
  - Titulaire du compte
- Stockage: `providers.iban`, `providers.bic`, `providers.titulaire_compte_banc`
- **Requis pour indépendants**

**Étape 16: Tarif horaire**
- Slider 0-1000€
- Valeur par défaut: 50€
- Suggestions rapides: 30€, 40€, 60€, 80€, 100€
- Impact: Tarif par défaut pour candidatures
- Note: Peut être différent par compétence (voir provider_jobs)
- Stockage: Tarif global (peut être override par compétence)
- **Requis pour indépendants**

---

#### Étapes finales (tous les profils)

**Étape 17: Zone d'intervention**
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

**Étape 18: Consentements**
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
Étapes 5-16              Étapes 5-8 (optionnels)
(avec docs + IBAN)               ↓
    ↓                    Skip étapes 9-16
Étape 17-18              Étape 17-18
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

### Formulaire en 4 étapes

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

#### Étape 3: Tarification (uniquement missions payantes)

**Champs**:

**Tarif horaire** (`price_hour`):
- Plage: 15-200€
- Valeur par défaut: Tarif compétence OU tarif global prestataire
- Suggestions: [mission_avg_rate - 20%, mission_avg_rate, mission_avg_rate + 20%]

**Tarif heure supplémentaire** (`price_hour_supp`):
- Plage: 20-200€
- Valeur par défaut: `price_hour × 1.25` (majoration 25%)

**Avertissements dynamiques**:

🔴 **Danger** (>20% en-dessous moyenne):
```
⚠️ Votre tarif est significativement inférieur à la moyenne
   pour ce type de mission (35€/h)
```

🟡 **Warning** (5-20% en-dessous moyenne):
```
ℹ️ Votre tarif est légèrement inférieur à la moyenne (32€/h)
```

**Affichage**: `average_hourly_rate` calculé pour comparaison

---

#### Étape 4: Récapitulatif

**Sections affichées**:

1. **Informations mission**:
   - Titre
   - Date et horaires (durée calculée)
   - Lieu (adresse complète + distance)
   - Compétence requise
   - Type (payant/bénévole)

2. **Votre proposition**:
   - Tarif horaire (si payant)
   - Tarif heure sup (si payant)
   - Disponibilité confirmée
   - Transport confirmé
   - Matériel confirmé

3. **Informations entreprise**:
   - Nom commercial
   - Notation moyenne
   - Badge vérifié (si applicable)

**Bouton**: "Soumettre ma candidature"

---

### Soumission

**Table**: `missions.profile_missions`

**Données insérées**:
- `profile`: ID profil prestataire
- `mission`: ID mission
- `provider`: ID provider (table providers.providers)
- `state`: 'postule'
- `origin`: 'applied' (candidature spontanée)
- `price_hour`: Tarif proposé
- `price_hour_supp`: Tarif sup proposé
- `items_confirmed`: true
- `created_at`: NOW()

**Notifications déclenchées**:
- ✉️ Email entreprise: "Nouvelle candidature pour votre mission"
- 🔔 Push entreprise: "X a postulé à votre mission Y"
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

### Après acceptation et confirmation

**États successifs**:
```
postule → accepted (par entreprise)
       → confirmed (par prestataire)
       → employer_signed (entreprise signe contrat)
       → assigned (prestataire signe contrat)
```

### Signature contrat prestataire

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
     - Si mission payante: Pré-autorisation Stripe déclenchée

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

### Après la mission

**Rapport entreprise**:
- Entreprise soumet heures travaillées + heures sup
- `profile_missions.provider_validation_status = 'pending'`

**Validation prestataire**:

**Option A: Approuver**
- Appel RPC `validate_mission_report(p_approved=true)`
- `provider_validated_at` = NOW()
- `provider_validation_status = 'approved'`
- **Déclenchement**: Capture paiement Stripe
- Notification: "Paiement en cours de traitement"

**Option B: Contester**
- Appel RPC `validate_mission_report(p_approved=false)`
- Ouverture formulaire de signalement de problème
- Motifs:
  - Désaccord sur heures travaillées
  - Problème paiement
  - Problème qualité mission
  - Non-respect conditions
  - Autre
- Création `missions.disputes`
- `provider_validation_status = 'disputed'`
- **Paiement sécurisé** pendant 31 jours max (fonds retenus chez Stripe — accord entre les parties)

---

### Finalisation

**Après validation**:
- Capture paiement effectuée
- Notification: "Paiement reçu pour la mission X"
- `profile_missions.state` → 'completed'
- Drawer notation entreprise s'ouvre

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
     - Contrats à signer
     - Rapports à valider
     - Entreprises à noter

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
- Signer contrat
- Ouvrir messagerie
- Valider rapport
- Noter entreprise
- Télécharger contrat
- Annuler (si >24h avant)

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

### Fonctions RPC clés
- `confirm_availability()` - Confirmation candidature
- `validate_mission_report()` - Validation rapport
- `get_provider_dashboard_missions()` - Missions dashboard

### API routes
- `/api/contract/provider/send-otp.post.js` - OTP signature
- `/api/contract/provider/verify-otp.post.js` - Vérification signature
- `/api/provider/sanctions` - Consultation sanctions

### Composants clés
- `PostulerDrawer.vue` - Formulaire candidature
- `MyMissionCard.vue` - Carte mission (prestataire)
- `SanctionBanner.vue` - Bannière sanctions
- `zoneIntervention.vue` - Configuration zone

### Composables
- `useProviderSignup.js` - Logique onboarding
- `useAvailabilities.js` - Gestion disponibilités
- `useProviderMissions.js` - Récupération missions

---

**Fin du document - Workflows Prestataire**
