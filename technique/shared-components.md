# Documentation des Composants Partagés

> **Répertoire:** `components/shared/`
> **Dernière mise à jour:** Décembre 2025

Cette documentation recense tous les composants réutilisables du projet Gotcha. **Consultez ce fichier avant de créer un nouveau composant** pour éviter les doublons.

---

## Table des matières

- [Composants Racine](#composants-racine)
  - [AddressAutocomplete](#addressautocomplete)
  - [ChoiceCards](#choicecards)
  - [DateFilter](#datefilter)
  - [displayDoc](#displaydoc)
  - [Footer](#footer)
  - [JobsSelect](#jobsselect)
  - [JobsSelectFiltered](#jobsselectfiltered)
  - [Map](#map)
  - [MissionCard](#missioncard)
  - [MobileOnly](#mobileonly)
  - [PostulerDrawer](#postulerdrawer)
  - [ProviderCard](#providercard)
  - [RatingCompany](#ratingcompany)
  - [RatingProvider](#ratingprovider)
  - [Spinner](#spinner)
  - [Toast](#toast)
- [Composants UI](#composants-ui)
  - [Button](#button)
  - [Checkbox](#checkbox)
  - [ConfirmModal](#confirmmodal)
  - [GlassTabs](#glasstabs)
  - [ImportNumber](#importnumber)
  - [InputCalendar](#inputcalendar)
  - [PhoneInput](#phoneinput)
  - [ProfileInfoRow](#profileinforow)
  - [SelectFile](#selectfile)
  - [SlideButton](#slidebutton)
  - [Switch](#switch)
  - [Tag](#tag)
  - [TimeInput](#timeinput)

---

## Composants Racine

### AddressAutocomplete

**Fichier:** `components/shared/AddressAutocomplete.vue`

**Description:** Champ d'autocomplétion d'adresse utilisant l'API française api-adresse.data.gouv.fr

**Props:**
| Prop | Type | Défaut | Description |
|------|------|--------|-------------|
| `modelValue` | String | - | Adresse sélectionnée |

**Events:**
| Event | Payload | Description |
|-------|---------|-------------|
| `update:modelValue` | String | Émis lors de la sélection d'une adresse |

**Caractéristiques:**
- Recherche avec debounce de 500ms
- Minimum 3 caractères pour déclencher la recherche
- Affiche label, ville, code postal et contexte

**Exemple:**
```vue
<AddressAutocomplete v-model="selectedAddress" />
```

---

### ChoiceCards

**Fichier:** `components/shared/ChoiceCards.vue`

**Description:** Grille de cartes sélectionnables avec icône et description

**Props:**
| Prop | Type | Défaut | Description |
|------|------|--------|-------------|
| `modelValue` | String/Number/Boolean | - | Valeur sélectionnée |
| `options` | Array | **requis** | `[{ value, label, description?, icon }]` |
| `vertical` | Boolean | false | Affichage en colonne unique |

**Events:**
| Event | Payload | Description |
|-------|---------|-------------|
| `update:modelValue` | any | Émis lors de la sélection d'une carte |

**Exemple:**
```vue
<ChoiceCards
  v-model="role"
  :options="[
    { value: 'provider', label: 'Candidat', icon: 'heroicons:user' },
    { value: 'company', label: 'Entreprise', icon: 'heroicons:building' }
  ]"
/>
```

---

### DateFilter

**Fichier:** `components/shared/DateFilter.vue`

**Description:** Filtre de plage de dates avec dropdown

**Props:**
| Prop | Type | Défaut | Description |
|------|------|--------|-------------|
| `dateDebut` | String | - | Date de début |
| `dateFin` | String | - | Date de fin |

**Events:**
| Event | Payload | Description |
|-------|---------|-------------|
| `update:dateDebut` | String | Changement date début |
| `update:dateFin` | String | Changement date fin |
| `apply` | - | Application du filtre |

**Exemple:**
```vue
<DateFilter
  v-model:dateDebut="startDate"
  v-model:dateFin="endDate"
  @apply="filterByDate"
/>
```

---

### displayDoc

**Fichier:** `components/shared/displayDoc.vue`

**Description:** Affichage de documents (images, PDF) depuis Supabase Storage

**Props:**
| Prop | Type | Défaut | Description |
|------|------|--------|-------------|
| `doc` | String | - | ID/chemin du document |
| `round` | Boolean | false | Bordure arrondie (9999px) |
| `width` | String | "50px" | Largeur |
| `height` | String | "50px" | Hauteur |

**Exemple:**
```vue
<displayDoc :doc="profilePhoto" round width="60px" height="60px" />
```

---

### Footer

**Fichier:** `components/shared/Footer.vue`

**Description:** Navigation fixe en bas de page avec onglets selon le rôle

**Caractéristiques:**
- Navigation différente pour provider vs company
- Position fixe en bas
- Affiche la photo de profil ou icône par défaut
- Onglets: Mes missions, Recherche, Compte

**Exemple:**
```vue
<Footer />
```

---

### JobsSelect

**Fichier:** `components/shared/JobsSelect.vue`

**Description:** Sélection multiple/simple de compétences avec recherche

**Props:**
| Prop | Type | Défaut | Description |
|------|------|--------|-------------|
| `modelValue` | Array/Object | - | Métier(s) sélectionné(s) |
| `options` | Array | - | Options prédéfinies (optionnel) |
| `multiple` | Boolean | true | Sélection multiple |
| `placeholder` | String | "Rechercher une compétence" | Placeholder |

**Events:**
| Event | Payload | Description |
|-------|---------|-------------|
| `update:modelValue` | Array/Object | Changement de sélection |

**Exemple:**
```vue
<JobsSelect v-model="selectedJobs" multiple />
```

---

### JobsSelectFiltered

**Fichier:** `components/shared/JobsSelectFiltered.vue`

**Description:** Sélection de métiers avec liste pré-filtrée

**Props:**
| Prop | Type | Défaut | Description |
|------|------|--------|-------------|
| `modelValue` | Array | - | Métiers sélectionnés |
| `filteredJobs` | Array | **requis** | Liste de métiers filtrés |

**Exemple:**
```vue
<JobsSelectFiltered v-model="jobs" :filteredJobs="availableJobs" />
```

---

### Map

**Fichier:** `components/shared/map/Map.vue`

**Description:** Carte Mapbox avec marqueurs interactifs pour les missions

**Props:**
| Prop | Type | Défaut | Description |
|------|------|--------|-------------|
| `missions` | Array | [] | Missions avec lat/long |

**Caractéristiques:**
- Marqueurs personnalisés avec photo de profil
- Auto-ajustement des limites (zoom max 13)
- Carte de mission sélectionnée en bas
- Bouton de recentrage sur position utilisateur
- Calcul de distance (formule Haversine)

**Exemple:**
```vue
<Map :missions="missionsWithCoordinates" />
```

---

### MissionCard

**Fichier:** `components/shared/MissionCard.vue`

**Description:** Carte d'affichage de mission avec infos entreprise et countdown

**Props:**
| Prop | Type | Défaut | Description |
|------|------|--------|-------------|
| `mission` | Object | **requis** | Données de la mission |
| `floating` | Boolean | false | Style avec ombre améliorée |
| `now` | Date | new Date() | Pour calcul du countdown |

**Caractéristiques:**
- Récupère et cache la note de l'entreprise
- Affiche titre, nom entreprise, badge vérifié
- Type de job, lieu, salaire/bénévolat
- Countdown: XjHHhMMmSSs

**Exemple:**
```vue
<MissionCard :mission="missionData" floating />
```

---

### MobileOnly

**Fichier:** `components/shared/MobileOnly.vue`

**Description:** Wrapper qui force l'affichage mobile uniquement

**Caractéristiques:**
- Affiche un message plein écran sur desktop (> 768px)
- Rend le contenu du slot uniquement sur mobile

**Exemple:**
```vue
<MobileOnly>
  <!-- Contenu mobile uniquement -->
</MobileOnly>
```

---

### PostulerDrawer

**Fichier:** `components/shared/PostulerDrawer.vue`

**Description:** Formulaire de candidature multi-étapes dans un drawer

**Props:**
| Prop | Type | Défaut | Description |
|------|------|--------|-------------|
| `modelValue` | Boolean | - | Visibilité du drawer |
| `mission` | Object | **requis** | Détails de la mission |

**Events:**
| Event | Payload | Description |
|-------|---------|-------------|
| `update:modelValue` | Boolean | Fermeture du drawer |
| `applied` | - | Candidature soumise |

**Étapes:**
1. Disponibilité & Transport
2. Objets à apporter
3. Taux horaire (missions payées)
4. Récapitulatif et soumission

**Exemple:**
```vue
<PostulerDrawer v-model="showForm" :mission="mission" @applied="onApplied" />
```

---

### ProviderCard

**Fichier:** `components/shared/ProviderCard.vue`

**Description:** Carte de profil prestataire avec option de flou

**Props:**
| Prop | Type | Défaut | Description |
|------|------|--------|-------------|
| `provider` | Object | **requis** | Données du prestataire |
| `isAuthenticated` | Boolean | true | Contrôle le flou |
| `showActions` | Boolean | false | Affiche les boutons CTA |

**Events:**
| Event | Payload | Description |
|-------|---------|-------------|
| `login` | - | Clic sur le bouton connexion |

**Exemple:**
```vue
<ProviderCard
  :provider="providerData"
  :isAuthenticated="isLoggedIn"
  @login="goToLogin"
/>
```

---

### RatingCompany

**Fichier:** `components/shared/RatingCompany.vue`

**Description:** Affichage des notes entreprise avec variantes

**Props:**
| Prop | Type | Défaut | Description |
|------|------|--------|-------------|
| `companyId` | String | **requis** | ID de l'entreprise |
| `companyName` | String | "Entreprise" | Nom affiché |
| `variant` | String | "card" | "small", "full", ou "card" |

**Exemple:**
```vue
<!-- Variante compacte -->
<RatingCompany companyId="co123" variant="small" />

<!-- Variante complète -->
<RatingCompany companyId="co123" variant="full" />

<!-- Variante carte -->
<RatingCompany companyId="co123" companyName="Acme Corp" />
```

---

### RatingProvider

**Fichier:** `components/shared/RatingProvider.vue`

**Description:** Affichage des notes prestataire avec drawer détaillé

**Props:**
| Prop | Type | Défaut | Description |
|------|------|--------|-------------|
| `profileId` | String | **requis** | ID du profil prestataire |
| `providerName` | String | "Prestataire" | Nom affiché |
| `isVerified` | Boolean | false | Badge vérifié |
| `initialRating` | Number | - | Note pré-chargée |
| `initialCount` | Number | - | Nombre d'avis pré-chargé |
| `initialRecentRatings` | Array | - | Avis récents pré-chargés |

**Exemple:**
```vue
<RatingProvider
  profileId="provider123"
  providerName="Jean Dupont"
  :isVerified="true"
/>
```

---

### Spinner

**Fichier:** `components/shared/Spinner.vue`

**Description:** Animation de chargement

**Caractéristiques:**
- Animation double-bounce
- Taille 60x60px
- Utilise la couleur primaire CSS

**Exemple:**
```vue
<Spinner />
```

---

### Toast

**Fichier:** `components/shared/Toast.vue`

**Description:** Système de notifications toast

**Caractéristiques:**
- Types: success, error, warning, info
- Auto-dismiss avec barre de progression
- Icônes et animations
- Lien d'action optionnel
- Position fixe en bas au-dessus du footer

**Utilisation:**
```vue
<!-- Dans le layout -->
<Toast />

<!-- Dans les composants -->
<script setup>
const { doToast } = useAppToast()
doToast('Succès', 'Opération effectuée', 'success')
</script>
```

---

## Composants UI

### Button

**Fichier:** `components/shared/UI/Button.vue`

**Description:** Bouton personnalisable avec plusieurs variantes

**Props:**
| Prop | Type | Défaut | Description |
|------|------|--------|-------------|
| `icon` | String | - | Nom d'icône Iconify |
| `label` | String | - | Texte du bouton |
| `disabled` | Boolean | false | Désactivé |
| `dark` | Boolean | false | Variante dégradé violet foncé |
| `white` | Boolean | false | Variante fond blanc |
| `pink` | Boolean | false | Variante bordure/ombre rose |
| `iconImg` | String | - | Chemin vers image icône |

**Exemple:**
```vue
<Button label="Valider" dark @click="submit" />
<Button label="Annuler" white />
<Button icon="heroicons:plus" label="Ajouter" />
```

---

### Checkbox

**Fichier:** `components/shared/UI/Checkbox.vue`

**Description:** Case à cocher personnalisée avec label

**Props:**
| Prop | Type | Défaut | Description |
|------|------|--------|-------------|
| `modelValue` | Boolean | false | État coché |
| `label` | String | - | Label principal |
| `disabled` | Boolean | false | Désactivé |
| `subLabel` | String | - | Label secondaire |

**Events:**
| Event | Payload | Description |
|-------|---------|-------------|
| `update:modelValue` | Boolean | Changement d'état |

**Exemple:**
```vue
<Checkbox
  v-model="agree"
  label="J'accepte les conditions"
  subLabel="Veuillez lire nos CGU"
/>
```

---

### ConfirmModal

**Fichier:** `components/shared/UI/ConfirmModal.vue`

**Description:** Modal de confirmation avec style selon variante

**Props:**
| Prop | Type | Défaut | Description |
|------|------|--------|-------------|
| `open` | Boolean | - | Visibilité |
| `title` | String | "Confirmer" | Titre |
| `message` | String | "Êtes-vous sûr ?" | Message |
| `confirmLabel` | String | "Confirmer" | Label bouton confirmer |
| `cancelLabel` | String | "Annuler" | Label bouton annuler |
| `variant` | String | "danger" | "danger", "warning", "info" |
| `icon` | String | - | Icône personnalisée |
| `loading` | Boolean | false | État de chargement |
| `error` | String | - | Message d'erreur |

**Events:**
| Event | Payload | Description |
|-------|---------|-------------|
| `update:open` | Boolean | Changement visibilité |
| `confirm` | - | Clic sur confirmer |
| `cancel` | - | Clic sur annuler |

**Exemple:**
```vue
<ConfirmModal
  v-model:open="showConfirm"
  title="Supprimer ?"
  message="Cette action est irréversible"
  variant="danger"
  @confirm="deleteItem"
/>
```

---

### GlassTabs

**Fichier:** `components/shared/UI/GlassTabs.vue`

**Description:** Onglets avec effet glass-morphism

**Props:**
| Prop | Type | Défaut | Description |
|------|------|--------|-------------|
| `tabs` | Array | **requis** | `[{ label, value, badge? }]` |
| `modelValue` | String | **requis** | Onglet actif |

**Events:**
| Event | Payload | Description |
|-------|---------|-------------|
| `update:modelValue` | String | Changement d'onglet |

**Exemple:**
```vue
<GlassTabs
  v-model="activeTab"
  :tabs="[
    { label: 'Infos', value: 'info' },
    { label: 'Avis', value: 'reviews', badge: 5 }
  ]"
/>
```

---

### ImportNumber

**Fichier:** `components/shared/UI/ImportNumber.vue`

**Description:** Saisie numérique avec boutons +/- et suggestions

**Props:**
| Prop | Type | Défaut | Description |
|------|------|--------|-------------|
| `modelValue` | Number | 0 | Valeur actuelle |
| `min` | Number | 0 | Valeur minimum |
| `max` | Number | 1000 | Valeur maximum |
| `step` | Number | 1 | Incrément |
| `defaultValue` | Number | - | Valeur si modelValue est null |
| `label` | String | - | Label principal |
| `description` | String | - | Description secondaire |
| `unit` | String | - | Unité affichée (ex: "€") |
| `on` | String | - | Suffixe (ex: "/ h") |
| `suggestions` | Array | - | Valeurs de suggestion rapide |
| `variant` | String | - | "danger" ou "warning" |

**Events:**
| Event | Payload | Description |
|-------|---------|-------------|
| `update:modelValue` | Number | Changement de valeur |

**Exemple:**
```vue
<ImportNumber
  v-model="hourlyRate"
  :min="15"
  :max="200"
  unit="€"
  on="/ h"
  :suggestions="[20, 30, 40]"
/>
```

---

### InputCalendar

**Fichier:** `components/shared/UI/InputCalendar.vue`

**Description:** Sélecteur de date avec calendrier

**Props:**
| Prop | Type | Défaut | Description |
|------|------|--------|-------------|
| `selectedDate` | Date | new Date() | Date sélectionnée |
| `label` | String | - | Label du calendrier |

**Events:**
| Event | Payload | Description |
|-------|---------|-------------|
| `update:selectedDate` | Date | Changement de date |

**Exemple:**
```vue
<InputCalendar
  :selectedDate="birthDate"
  label="Date de naissance"
  @update:selectedDate="d => birthDate = d"
/>
```

---

### PhoneInput

**Fichier:** `components/shared/UI/PhoneInput.vue`

**Description:** Saisie de numéro de téléphone international

**Props:**
| Prop | Type | Défaut | Description |
|------|------|--------|-------------|
| `modelValue` | String | - | Numéro au format E.164 |

**Events:**
| Event | Payload | Description |
|-------|---------|-------------|
| `update:modelValue` | String | Numéro formaté E.164 |

**Caractéristiques:**
- Dropdown avec drapeaux des pays
- Par défaut: France (+33)
- Suppression automatique du zéro initial

**Exemple:**
```vue
<PhoneInput v-model="phoneNumber" />
```

---

### ProfileInfoRow

**Fichier:** `components/shared/UI/ProfileInfoRow.vue`

**Description:** Ligne d'information de profil avec édition optionnelle

**Props:**
| Prop | Type | Défaut | Description |
|------|------|--------|-------------|
| `label` | String | - | Label à gauche |
| `value` | String/Number | - | Valeur affichée |
| `editable` | Boolean | false | Affiche icône d'édition |
| `placeholder` | String | "-" | Placeholder si pas de valeur |

**Events:**
| Event | Payload | Description |
|-------|---------|-------------|
| `edit` | - | Clic sur icône d'édition |

**Exemple:**
```vue
<ProfileInfoRow
  label="Email"
  value="john@example.com"
  editable
  @edit="editEmail"
/>
```

---

### SelectFile

**Fichier:** `components/shared/UI/SelectFile.vue`

**Description:** Upload de fichier avec prévisualisation

**Props:**
| Prop | Type | Défaut | Description |
|------|------|--------|-------------|
| `modelValue` | String | - | ID du fichier |
| `schema` | String | "public" | Schéma Supabase |
| `table` | String | - | Table cible pour métadonnées |
| `column` | String | "id" | Colonne clé étrangère |
| `onCol` | String | "id" | Colonne à matcher avec onID |
| `onID` | String | - | ID de l'enregistrement associé |
| `acceptedTypes` | String | "*/*" | Types MIME acceptés |
| `label` | String | - | Label du bouton |
| `rounded` | Boolean | false | Affichage circulaire |

**Caractéristiques:**
- Drag-drop ou clic pour upload
- Prévisualisation image ou PDF
- Limite 5MB
- Intégration Supabase Storage

**Exemple:**
```vue
<SelectFile
  v-model="documentId"
  acceptedTypes="image/*"
  rounded
  table="profiles"
  :onID="profileId"
/>
```

---

### SlideButton

**Fichier:** `components/shared/UI/SlideButton.vue`

**Description:** Bouton de confirmation par glissement

**Props:**
| Prop | Type | Défaut | Description |
|------|------|--------|-------------|
| `text` | String | "Glisser pour confirmer" | Texte affiché |
| `disabled` | Boolean | false | Désactivé |

**Events:**
| Event | Payload | Description |
|-------|---------|-------------|
| `confirmed` | - | Glissement complété (80%) |

**Méthodes exposées:**
| Méthode | Description |
|---------|-------------|
| `reset()` | Réinitialise l'état complété |

**Exemple:**
```vue
<SlideButton ref="slider" text="Confirmer" @confirmed="submitForm" />
```

---

### Switch

**Fichier:** `components/shared/UI/Switch.vue`

**Description:** Toggle à deux options avec slider

**Props:**
| Prop | Type | Défaut | Description |
|------|------|--------|-------------|
| `modelValue` | String/Number/Boolean | **requis** | Valeur actuelle |
| `options` | Array | **requis** | Exactement 2 options `[{ value, label, icon? }]` |

**Events:**
| Event | Payload | Description |
|-------|---------|-------------|
| `update:modelValue` | any | Nouvelle valeur sélectionnée |

**Exemple:**
```vue
<Switch
  v-model="mode"
  :options="[
    { value: 'online', label: 'En ligne' },
    { value: 'offline', label: 'Hors ligne' }
  ]"
/>
```

---

### Tag

**Fichier:** `components/shared/UI/Tag.vue`

**Description:** Étiquette pill avec suppression optionnelle

**Props:**
| Prop | Type | Défaut | Description |
|------|------|--------|-------------|
| `label` | String | **requis** | Texte de l'étiquette |
| `clearable` | Boolean | false | Affiche icône de suppression |
| `description` | String | - | Description dans la modal de confirmation |

**Events:**
| Event | Payload | Description |
|-------|---------|-------------|
| `clear` | - | Suppression confirmée |

**Exemple:**
```vue
<Tag label="JavaScript" clearable @clear="removeSkill" />
```

---

### TimeInput

**Fichier:** `components/shared/UI/TimeInput.vue`

**Description:** Sélecteur d'heure avec dropdowns

**Props:**
| Prop | Type | Défaut | Description |
|------|------|--------|-------------|
| `selectedTime` | String | "08:30" | Heure au format HH:mm |

**Events:**
| Event | Payload | Description |
|-------|---------|-------------|
| `update:selectedTime` | String | Nouvelle heure HH:mm |

**Caractéristiques:**
- Dropdown heures (0-23)
- Dropdown minutes (0-59, par incréments de 5)
- Grande police (28px)

**Exemple:**
```vue
<TimeInput
  v-model:selected-time="startTime"
/>
```

---

## Résumé

### Statistiques

| Catégorie | Nombre |
|-----------|--------|
| **Composants racine** | 16 |
| **Composants UI** | 13 |
| **Total** | 29 |

### Par type de composant

| Type | Composants |
|------|------------|
| **Input** | AddressAutocomplete, DateFilter, PhoneInput, SelectFile, ImportNumber, InputCalendar, TimeInput |
| **Affichage** | MissionCard, ProviderCard, RatingProvider, RatingCompany, Footer, Spinner, displayDoc, ProfileInfoRow |
| **Interaction** | ChoiceCards, JobsSelect, JobsSelectFiltered, SlideButton, Switch, Checkbox, GlassTabs, Toast |
| **Formulaire** | Button, Tag, ConfirmModal, PostulerDrawer |
| **Utilitaire** | MobileOnly, Map |

### Conventions de design

- **Couleur primaire:** Dégradé violet (#6600ff → #3d0099)
- **Framework CSS:** Tailwind CSS avec effets glass-morphism
- **Composants de base:** Nuxt UI
- **Icônes:** Iconify
- **API:** Composition API Vue 3 avec `<script setup>`
- **Locale:** Français (fr-FR)
- **Design:** Mobile-first
