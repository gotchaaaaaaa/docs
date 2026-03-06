# GOTCHA - Présentation Complète du Projet
## Document de référence pour la rédaction des CGU et CGV

**Date de création:** Février 2026
**Version:** 1.0
**Usage:** Ce document est destiné à servir de base pour la rédaction des Conditions Générales d'Utilisation (CGU) et des Conditions Générales de Vente (CGV) de la plateforme Gotcha.

---

## TABLE DES MATIÈRES

1. [Présentation Générale](#1-présentation-générale)
2. [Les Acteurs de la Plateforme](#2-les-acteurs-de-la-plateforme)
3. [Inscription et Création de Compte](#3-inscription-et-création-de-compte)
4. [Fonctionnement des Missions](#4-fonctionnement-des-missions)
5. [Système de Contrats](#5-système-de-contrats)
6. [Système de Paiement](#6-système-de-paiement)
7. [Politique d'Annulation et Sanctions](#7-politique-dannulation-et-sanctions)
8. [Système de Notation](#8-système-de-notation)
9. [Données Personnelles Collectées](#9-données-personnelles-collectées)
10. [Propriété Intellectuelle](#10-propriété-intellectuelle)
11. [Responsabilités](#11-responsabilités)
12. [Prestataires Techniques Tiers](#12-prestataires-techniques-tiers)

---

## 1. PRÉSENTATION GÉNÉRALE

### 1.1 Nature de la Plateforme

**Gotcha** est une application web progressive (PWA) de mise en relation entre :
- Des **prestataires de services** (appelés "candidats" ou "providers") proposant leurs compétences
- Des **entreprises** (appelés "entreprises" ou "companies") ayant des besoins en personnel temporaire

La plateforme opère sur le modèle d'une **marketplace de services** avec mise en relation géolocalisée pour des missions ponctuelles et urgentes.

### 1.2 Secteurs d'Activité Couverts

Les missions proposées sur Gotcha concernent principalement :
- **Événementiel** (festivals, salons, séminaires)
- **Restauration/Hôtellerie** (service, cuisine, plonge)
- **Sécurité** (agents de sécurité événementielle)
- **Logistique** (manutention, inventaire)
- **Accueil** (hôtesses, agents d'accueil)
- Et autres métiers de services temporaires

### 1.3 Modèle Économique

Gotcha perçoit une **commission de 12,5%** sur chaque mission payante réalisée via la plateforme.

**Répartition des sommes :**
- 100% de la mission versées au prestataire
- 12,5% en plus par Gotcha (commission plateforme), sur la facture entreprise.

**Exception :** Les missions bénévoles (sans rémunération) ne génèrent aucune commission.

### 1.4 Zone Géographique

La plateforme opère actuellement en **France métropolitaine**.

---

## 2. LES ACTEURS DE LA PLATEFORME

### 2.1 L'Opérateur de la Plateforme

**Gotcha** (dénomination commerciale)
- Rôle : Éditeur et opérateur de la plateforme
- Fonction : Intermédiaire technique de mise en relation
- Statut : **Non-employeur** des prestataires

### 2.2 Les Prestataires (Candidats)

#### 2.2.1 Définition
Personne physique majeure (18 ans minimum) proposant ses services professionnels via la plateforme.

#### 2.2.2 Statuts Acceptés

**A. Prestataires Indépendants**
- Auto-entrepreneurs
- Micro-entrepreneurs
- Entrepreneurs individuels
- Gérants de société (EURL, SASU, etc.)

**Obligations spécifiques :**
- Numéro SIRET valide et actif
- Assurance responsabilité civile professionnelle
- IBAN européen pour les paiements
- Documents justificatifs à jour

**B. Non-Indépendants**
-> ne sont acceptés que s'ils optent pour le bénévolat
-> Limitations :
- Peuvent uniquement postuler aux missions **bénévoles**
- Aucune obligation de documents professionnels

### 2.3 Les Entreprises

#### 2.3.1 Types d'Entreprises

**A. Entreprises Commerciales (type "entreprise")**
- Sociétés commerciales (SARL, SAS, SA, etc.)
- Entreprises individuelles
- Peuvent publier des missions **payantes** et **bénévoles**
- Doivent configurer un moyen de paiement (Stripe)

**B. Associations/Festivals (type "festival")**
- Associations loi 1901
- Organisateurs d'événements non-lucratifs
- Peuvent **uniquement** publier des missions **bénévoles**
- Aucune obligation de paiement en ligne

#### 2.3.2 Obligations Communes
- Numéro SIRET valide et actif (vérifié via l'API INSEE)
- Acceptation des CGU
- Respect du droit du travail français

---

## 3. INSCRIPTION ET CRÉATION DE COMPTE

### 3.1 Inscription des Prestataires

#### 3.1.1 Processus en 17 Étapes

**Phase 1 : Informations Personnelles**
1. Création du compte (email, mot de passe)
2. Date de naissance (vérification majorité 18 ans)
3. Photo de profil (optionnelle)

**Phase 2 : Situation Professionnelle**
4. Situation actuelle (salarié, étudiant, indépendant, etc.)
5. Possession d'un véhicule personnel
6. Préférence bénévolat (si non-indépendant)

**Phase 3 : Compétences**
7. Sélection des compétences/métiers
8. Diplômes associés (optionnel)
9. Expériences professionnelles (optionnel)
10. Description personnelle (optionnel)

**Phase 4 : Documents Professionnels (Indépendants uniquement)**
11. Numéro SIRET (validation INSEE en temps réel)
12. Attestation de situation SIRET (optionnel)
13. Attestation de vigilance (optionnel, validité 6 mois)
14. Adresse de facturation (optionnel)
15. Régime TVA (optionnel)
16. Attestation d'assurance RC professionnelle (**obligatoire**)
17. Coordonnées bancaires IBAN (**obligatoire**)
18. Taux horaire souhaité

**Phase 5 : Zone d'Intervention**
19. Adresse de référence
20. Rayon d'intervention (1 à 200 km)

**Phase 6 : Consentements**
21. Acceptation des CGU (**obligatoire**)
22. Autorisation de géolocalisation (optionnel)
23. Notifications push (optionnel)

#### 3.1.2 Validation du Compte

Le compte est **activé immédiatement** après complétion de l'inscription.

Un **badge "Vérifié"** peut être obtenu après :
- Vérification manuelle des documents d'identité
- Vérification de l'assurance (indépendants)
- Vérification du SIRET (indépendants)
- Minimum 3 missions complétées avec succès
- Note moyenne ≥ 4/5

### 3.2 Inscription des Entreprises

#### 3.2.1 Processus en 6 Étapes

1. **Type d'organisation** : Entreprise OU Festival/Association
2. **Numéro SIRET** : Validation via API INSEE
3. **Nom commercial** : Peut différer du nom légal SIRET
4. **Photo/Logo** : Optionnel
5. **Description** : Optionnel
6. **Acceptation des CGU** : Obligatoire

#### 3.2.2 Configuration Paiement (Entreprises commerciales)

Pour publier des missions payantes, l'entreprise doit :
- Enregistrer une carte bancaire via Stripe
- La carte est tokenisée (non stockée sur Gotcha)

---

## 4. FONCTIONNEMENT DES MISSIONS

### 4.1 Création d'une Mission (par l'Entreprise)

#### 4.1.1 Informations Requises

**Informations de base :**
- Titre de la mission
- Date et horaires (début/fin)
- Adresse précise (géolocalisée automatiquement)
- Compétence/métier requis
- Description détaillée

**Options supplémentaires :**
- Nécessité d'un véhicule personnel
- Liste d'équipements à apporter
- Nombre de postes à pourvoir

**Pour les missions payantes :**
- Taux horaire proposé
- Taux horaire supplémentaire (heures sup)

**Pour les missions bénévoles :**
- Nombre de bénévoles recherchés
- Avantages offerts (repas, transports, etc.)

### 4.2 Matching et Notifications

#### 4.2.1 Algorithme de Matching

Lorsqu'une mission est publiée, la plateforme identifie automatiquement les prestataires correspondants selon :

1. **Correspondance compétence** : Le prestataire possède la compétence requise
2. **Zone géographique** : La mission est dans le rayon d'intervention du prestataire
3. **Disponibilité** : Le prestataire est marqué comme disponible
4. **Éligibilité** : Le prestataire n'est pas suspendu et a complété son inscription

#### 4.2.2 Notifications

Les prestataires correspondants reçoivent une **notification push** avec :
- Titre de la mission
- Distance depuis leur position
- Taux horaire (si payant)
- Compétence requise

### 4.3 Candidature (par le Prestataire)

#### 4.3.1 Formulaire de Candidature en 4 Étapes

1. **Confirmation de disponibilité**
   - Confirmer sa disponibilité aux dates/heures
   - Confirmer possession véhicule (si requis)

2. **Équipements**
   - Cocher tous les équipements demandés comme disponibles

3. **Tarification** (missions payantes uniquement)
   - Taux horaire proposé (€/h)
   - Taux horaire supplémentaire (€/h)
   - Avertissement si tarif inférieur à la moyenne

4. **Récapitulatif et validation**

### 4.4 Sélection des Candidats (par l'Entreprise)

#### 4.4.1 Réception des Candidatures

L'entreprise visualise pour chaque candidat :
- Photo et nom
- Note moyenne et nombre d'avis
- Distance par rapport à la mission
- Taux horaire proposé
- Compétences et véhicule

#### 4.4.2 Processus de Sélection

1. L'entreprise peut **accepter plusieurs candidats** simultanément
2. Tous les candidats acceptés passent en statut "accepté"
3. **Le premier candidat à confirmer sa disponibilité remporte la mission**
4. Les autres candidats acceptés sont automatiquement notifiés du refus

### 4.5 Confirmation (par le Prestataire)

Lorsqu'un prestataire est accepté :
1. Il reçoit une notification
2. Il doit confirmer sa disponibilité
3. **Premier arrivé, premier servi** : le plus rapide à confirmer obtient la mission

---

## 5. SYSTÈME DE CONTRATS

### 5.1 Type de Contrat

La plateforme génère des **Contrat de Prestation de Services** conformément au droit du travail français entre l'entreprise et le prestataire.

### 5.2 Contenu du Contrat

Chaque contrat généré contient :
- Identité complète de l'entreprise (nom, SIRET, adresse)
- Identité complète du prestataire
- Date, horaires et lieu de la mission
- Nature de la prestation (compétence)
- Rémunération (taux horaire, heures supplémentaires)
- Durée prévisionnelle
- Autres clauses ...

### 5.3 Signature Électronique

#### 5.3.1 Processus de Signature

**Étape 1 : Signature par l'Entreprise**
1. L'entreprise visualise le contrat complet
2. Elle clique sur "Signer le contrat"
3. Un **code OTP à 5 chiffres** est envoyé par email
4. L'entreprise saisit le code pour valider sa signature
5. **Pré-autorisation bancaire** créée (montant bloqué sur la carte)

**Étape 2 : Signature par le Prestataire**
1. Le prestataire est notifié
2. Il dispose d'un **délai limité** pour signer :
   - Si mission dans >24h : délai de 24h
   - Si mission dans <24h : délai = 50% du temps restant
3. Même processus OTP par email
4. **Capture du paiement** en séquestre à la signature

#### 5.3.2 Sécurité de la Signature

- Code OTP **haché** (bcrypt, jamais stocké en clair)
- Expiration du code : **5 minutes**
- Maximum **5 tentatives** de saisie
- **Adresse IP** enregistrée
- **User Agent** (navigateur) enregistré
- **Horodatage** précis

#### 5.3.3 Expiration et Annulation Automatique

Si le prestataire ne signe pas dans le délai :
- Le contrat expire automatiquement
- La pré-autorisation bancaire est annulée
- La mission est remise en ligne
- Une **sanction** peut être appliquée au prestataire

### 5.4 Archivage des Contrats

Tous les contrats signés sont archivés avec :
- Version HTML complète du contrat
- Métadonnées de signature (IP, timestamp, user agent)
- Preuves de vérification OTP

---

## 6. SYSTÈME DE PAIEMENT

### 6.1 Modèle de Séquestre (Escrow)

Gotcha utilise un **modèle de séquestre** pour sécuriser les paiements :

```
Entreprise → Gotcha (séquestre) → Prestataire
```

### 6.2 Flux de Paiement Détaillé

#### 6.2.1 Pré-autorisation (Signature Entreprise)

Lorsque l'entreprise signe le contrat :
- **Montant bloqué** = (Heures estimées × Taux horaire) + 12,5% commission
- L'argent reste sur la carte de l'entreprise
- Aucun débit effectif à ce stade
- **Validité** : 7 jours maximum

#### 6.2.2 Capture en Séquestre (Signature Prestataire)

Lorsque le prestataire signe le contrat :
- **Capture immédiate** du montant pré-autorisé
- L'argent est transféré vers le compte Gotcha (séquestre)
- Statut : "En séquestre"

#### 6.2.3 Rapport de Mission (Post-Mission)

Après la mission, l'entreprise soumet un rapport :
- Heures réellement travaillées
- Heures supplémentaires effectuées
- Commentaire optionnel

**Si heures supplémentaires :**
- Nouvelle pré-autorisation créée et capturée immédiatement
- Montant = (Heures sup × Taux sup) + 12,5% commission

#### 6.2.4 Validation et Libération du Paiement

Le prestataire doit **valider** le rapport :

**Option A : Approbation**
- Calcul du montant final
- **Transfert** vers le compte Stripe du prestataire
- Commission (12,5%) retenue par Gotcha
- **Remboursement** si heures < estimation initiale

**Option B : Signalement de problème**
- Ouverture d'un **signalement**
- Paiement **sécurisé** jusqu'à 31 jours (fonds retenus chez Stripe, pas chez Gotcha)
- Aucune décision de Gotcha sur le fond — accord entre les parties

### 6.3 Calcul des Montants

#### 6.3.1 Mission Standard (4h à 24€/h)

```
Pré-autorisation : 4h × 24€ = 96€ + 12€ (12,5%) = 108€
Capture séquestre : 108€
Heures travaillées : 4h
Versement prestataire : 96€ (87,5%)
Commission Gotcha : 12€ (12,5%)
```

#### 6.3.2 Mission avec Heures Supplémentaires

```
Base : 4h × 24€ = 96€ → Préautorisé 108€
Heures sup : 2h × 30€ (25% de majoration) = 60€ → Capturé 67,50€
Total prestataire : 96€ + 60€ = 156€
Total commission : 12€ + 7,50€ = 19,50€
Total facturé entreprise : 108€ + 67,50€ = 175,50€
```

#### 6.3.3 Mission avec Moins d'Heures

```
Estimation : 4h × 24€ = 96€ → Préautorisé 108€
Réel : 3h × 24€ = 72€
Remboursement entreprise : 108€ - (72€ + 9€ commission) = 27€
Versement prestataire : 72€
Commission Gotcha : 9€
```

### 6.4 Missions Bénévoles

- **Aucun paiement** traité par la plateforme
- Pas de commission
- Pas de configuration Stripe requise

### 6.5 Délais de Paiement

- **Capture** : Immédiate à la signature du prestataire
- **Validation** : Après soumission du rapport par l'entreprise
- **Transfert** : Immédiat après validation par le prestataire
- **Crédit sur compte bancaire** : 2-7 jours ouvrés (selon banque Stripe)

---

## 7. POLITIQUE D'ANNULATION ET SANCTIONS

### 7.1 Annulation par le Prestataire

#### 7.1.1 Conditions d'Annulation

Le prestataire peut annuler une mission à tout moment **avant le début de celle-ci**.

#### 7.1.2 Sanctions selon le Délai

| Délai avant mission | Sanction |
|---------------------|----------|
| ≥ 48 heures | Aucune sanction |
| < 48 heures | Sanction progressive |

#### 7.1.3 Système de Sanctions Progressives

| Annulation | Sanction | Impact |
|------------|----------|--------|
| 1ère | Avertissement 1 | Notification uniquement |
| 2ème | Avertissement 2 | Notification renforcée |
| 3ème | **Suspension 7 jours** | Invisible aux entreprises pendant 7 jours |
| 4ème+ | **Suspension 30 jours** | Invisible aux entreprises pendant 30 jours |

#### 7.1.4 Remise à Zéro

Le compteur d'annulations consécutives est **remis à zéro** après chaque mission **complétée avec succès**.

#### 7.1.5 Traçabilité

Chaque annulation est enregistrée avec :
- Date et heure de l'annulation
- Heures restantes avant la mission
- État du contrat (signé ou non)
- Raison de l'annulation
- Sanction appliquée

### 7.2 Annulation par l'Entreprise

#### 7.2.1 Avant Signature Complète du Contrat

- **≥ 48h avant la mission** : Annulation libre, aucun frais
- **< 48h ET prestataire a signé** : Annulation **interdite**

#### 7.2.2 Après Signature Complète (Deux Parties)

Si l'entreprise annule après que les deux parties ont signé :
- **Indemnisation du prestataire à 100%** du montant prévu
- Le paiement est capturé et transféré intégralement au prestataire
- Commission Gotcha prélevée normalement

### 7.3 Remplacement Automatique

Lorsqu'un prestataire annule après avoir été sélectionné :

1. La mission est **remise en ligne** automatiquement
2. L'algorithme recherche des **prestataires de remplacement**
3. Jusqu'à **5 candidats** sont suggérés à l'entreprise
4. Critères de sélection : badge vérifié, note élevée, proximité

---

## 8. SYSTÈME DE NOTATION

### 8.1 Notation Bidirectionnelle

Après chaque mission complétée, les deux parties peuvent se noter mutuellement.

### 8.2 Critères de Notation (4 critères, 5 étoiles chacun)

#### 8.2.1 Notation du Prestataire par l'Entreprise

1. **Ponctualité** : Respect des horaires
2. **Compréhension du brief** : Compréhension des consignes
3. **Application des compétences** : Maîtrise technique
4. **Communication** : Professionnalisme et réactivité

#### 8.2.2 Notation de l'Entreprise par le Prestataire

Mêmes 4 critères appliqués à l'entreprise.

### 8.3 Calcul de la Note Globale

**Note globale** = Moyenne des 4 critères

Exemple : (5 + 4 + 5 + 4) / 4 = **4,5/5**

### 8.4 Affichage et Impact

- Notes visibles sur les profils publics
- Historique des 3 derniers avis visible
- **Impact sur le classement** dans les recherches :
  - Prestataires mieux notés apparaissent en premier
  - Notes élevées favorisent l'obtention du badge "Vérifié"

### 8.5 Commentaires

- Commentaire optionnel (max 300 caractères)
- Visible publiquement sur le profil

---

## 9. DONNÉES PERSONNELLES COLLECTÉES

### 9.1 Données des Prestataires

#### 9.1.1 Données d'Identification
- Nom et prénom
- Date de naissance
- Adresse email
- Numéro de téléphone (optionnel)
- Photo de profil (optionnel)

#### 9.1.2 Données Professionnelles
- Situation professionnelle (salarié, étudiant, indépendant, etc.)
- Compétences/métiers
- Diplômes et formations
- Expériences professionnelles
- Description personnelle

#### 9.1.3 Documents (Indépendants)
- Numéro SIRET
- Attestation SIRET (document PDF)
- Attestation de vigilance (document PDF)
- Attestation d'assurance RC professionnelle (document PDF)
- Coordonnées bancaires (IBAN, BIC, titulaire)

#### 9.1.4 Données de Géolocalisation
- Adresse de référence
- Rayon d'intervention
- Coordonnées GPS (latitude, longitude)

#### 9.1.5 Données d'Activité
- Historique des candidatures
- Historique des missions
- Notes reçues et données
- Historique des sanctions

### 9.2 Données des Entreprises

#### 9.2.1 Données d'Identification
- Numéro SIRET
- Données INSEE (nom légal, code APE, effectif, adresse)
- Nom commercial
- Logo/photo
- Description
- Email et téléphone

#### 9.2.2 Données Financières
- Identifiant client Stripe
- Historique des paiements

#### 9.2.3 Données d'Activité
- Missions créées
- Notes données
- Historique des contrats

### 9.3 Données de Contrat et Paiement

- Contrats signés (HTML archivé)
- Métadonnées de signature (IP, horodatage, navigateur)
- Montants des transactions
- Identifiants de paiement Stripe

### 9.4 Finalités du Traitement

Les données sont collectées pour :
1. **Exécution du contrat** : Mise en relation, paiements, contrats
2. **Intérêt légitime** : Amélioration du service, prévention fraude
3. **Obligation légale** : Conservation des contrats, facturation
4. **Consentement** : Notifications push, géolocalisation temps réel

### 9.5 Durée de Conservation

| Type de données | Durée |
|-----------------|-------|
| Compte utilisateur | Jusqu'à suppression du compte |
| Contrats signés | 10 ans (obligation légale) |
| Données de paiement | 10 ans (obligation légale) |
| Logs de connexion | 1 an |
| Données de géolocalisation | Session uniquement |

---

## 10. PROPRIÉTÉ INTELLECTUELLE

### 10.1 Propriété de la Plateforme

Gotcha est propriétaire de :
- Le code source de l'application
- L'interface utilisateur et le design
- Les algorithmes de matching
- Les templates de contrats
- La marque "Gotcha" et le logo

### 10.2 Contenu Utilisateur

Les utilisateurs conservent la propriété de :
- Leurs photos de profil
- Leurs descriptions
- Leurs documents téléchargés

En publiant du contenu, l'utilisateur accorde à Gotcha une **licence non-exclusive** pour :
- Afficher le contenu sur la plateforme
- Utiliser les données pour l'amélioration du service

### 10.3 Contrats Générés

Les contrats générés par la plateforme :
- Utilisent des templates propriétaires Gotcha
- Sont personnalisés avec les données des parties
- Restent accessibles aux parties signataires

---

## 11. RESPONSABILITÉS

### 11.1 Rôle de Gotcha

Gotcha agit en qualité d'**intermédiaire technique** :
- Met en relation prestataires et entreprises
- Fournit les outils de gestion (contrats, paiements, messagerie)
- Sécurise les transactions financières
- Archive les documents contractuels

### 11.2 Ce que Gotcha N'est PAS

Gotcha n'est **pas** :
- L'employeur des prestataires
- Le donneur d'ordre des missions
- Responsable de la qualité des prestations
- Garant de la disponibilité des prestataires

### 11.3 Responsabilités de l'Entreprise

L'entreprise s'engage à :
- Fournir des informations exactes sur les missions
- Respecter le droit du travail français
- Payer les prestations convenues
- Évaluer honnêtement les prestataires
- Ne pas discriminer les candidats

### 11.4 Responsabilités du Prestataire

Le prestataire s'engage à :
- Fournir des informations exactes sur son profil
- Détenir les qualifications déclarées
- Respecter ses engagements (présence, horaires)
- Disposer des assurances requises (indépendants)
- Respecter les consignes de la mission

### 11.5 Limitation de Responsabilité

Gotcha ne peut être tenu responsable :
- Des dommages causés pendant une mission
- De la qualité ou non-exécution d'une prestation
- Des litiges directs entre prestataire et entreprise
- Des pannes ou indisponibilités techniques temporaires

### 11.6 Résolution des Différends

En cas de problème survenu lors d'une mission, Gotcha agit en tant que plateforme de mise en relation (trust & safety), non comme médiateur :
1. **Signalement** : Les parties peuvent soumettre un signalement via la plateforme — le paiement est alors sécurisé (fonds retenus chez Stripe) pendant 31 jours maximum
2. **Accord amiable** : Gotcha ne tranche pas sur le fond — les parties trouvent un accord entre elles
3. **Médiation externe** : Les parties peuvent recourir à un médiateur agréé (ex. CNPM — cnpm-mediation-nationale.fr)
4. **Sanctions CGU** : Gotcha peut suspendre ou bannir tout compte en cas de violation avérée de ses CGU
5. **Juridiction** : À défaut d'accord, les tribunaux compétents

---

## 12. PRESTATAIRES TECHNIQUES TIERS

### 12.1 Services Utilisés

| Service | Usage | Données partagées |
|---------|-------|-------------------|
| **Supabase** | Hébergement base de données et authentification | Toutes les données utilisateur |
| **Stripe** | Paiements et transferts | Données financières, identité |
| **Mapbox** | Cartographie et géolocalisation | Coordonnées GPS |
| **API Adresse (data.gouv.fr)** | Autocomplétion adresses | Adresses saisies |
| **API INSEE** | Vérification SIRET | Numéros SIRET |

### 12.2 Localisation des Données

- **Base de données** : Union Européenne (via Supabase)
- **Paiements** : Union Européenne et États-Unis (Stripe)
- **Cartographie** : États-Unis (Mapbox)

### 12.3 Conformité RGPD

Tous les prestataires sont conformes au RGPD ou disposent de clauses contractuelles types pour les transferts hors UE.

---

## ANNEXES

### Annexe A : Glossaire

| Terme | Définition |
|-------|------------|
| **Candidat/Prestataire** | Personne proposant ses services via la plateforme |
| **Entreprise** | Organisation publiant des missions |
| **Mission** | Prestation de service ponctuelle |
| **OTP** | One-Time Password (code à usage unique) |
| **Séquestre/Escrow** | Conservation temporaire des fonds par un tiers |
| **Badge Vérifié** | Certification d'un profil complet et validé |

### Annexe B : Flux Simplifié d'une Mission

```
1. Entreprise crée mission
         ↓
2. Prestataires notifiés
         ↓
3. Candidatures reçues
         ↓
4. Entreprise sélectionne
         ↓
5. Prestataire confirme
         ↓
6. Entreprise signe contrat (pré-autorisation)
         ↓
7. Prestataire signe contrat (capture séquestre)
         ↓
8. Mission exécutée
         ↓
9. Entreprise soumet rapport
         ↓
10. Prestataire valide
         ↓
11. Paiement transféré
         ↓
12. Notes mutuelles
```

### Annexe C : Barème des Sanctions

| Annulation | < 48h avant mission | Sanction |
|------------|---------------------|----------|
| 1ère | Oui | Avertissement 1 |
| 2ème | Oui | Avertissement 2 |
| 3ème | Oui | Suspension 7 jours |
| 4ème+ | Oui | Suspension 30 jours |

*Toute annulation ≥ 48h avant la mission n'entraîne aucune sanction.*

---

## NOTES POUR LA RÉDACTION DES CGU/CGV

### Points Clés à Couvrir dans les CGU

1. **Objet et champ d'application**
2. **Définitions**
3. **Conditions d'accès et d'inscription**
4. **Fonctionnement de la plateforme**
5. **Obligations des utilisateurs**
6. **Système de contrats**
7. **Politique d'annulation et sanctions**
8. **Données personnelles et RGPD**
9. **Propriété intellectuelle**
10. **Responsabilités et garanties**
11. **Modification des CGU**
12. **Droit applicable et juridiction**

### Points Clés à Couvrir dans les CGV

1. **Commission et tarification**
2. **Modalités de paiement**
3. **Facturation**
4. **Conditions d'annulation et remboursement**
5. **Réclamations et signalements de problèmes**
6. **Droit de rétractation (si applicable)**

### Spécificités Légales à Vérifier

- Conformité avec le Code du Travail
- Conformité RGPD
- Obligations des plateformes d'intermédiation
- Régime fiscal des commissions

---

**Fin du document**

*Document généré automatiquement - Février 2026*
