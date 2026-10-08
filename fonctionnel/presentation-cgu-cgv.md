# GOTCHA - Présentation Complète du Projet
## Document de référence pour la rédaction des CGU et CGV

**Date de création:** Février 2026
**Dernière mise à jour:** Mai 2026 (commission 13&nbsp;% HT absorbed, acompte 30&nbsp;%/800&nbsp;€, escrow Stripe deux phases, signalements 31j)
**Version:** 2.0
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

Gotcha perçoit une **commission de 13&nbsp;% HT** sur chaque mission payante réalisée via la plateforme, augmentée de la TVA à 20&nbsp;%.

**Modèle *absorbed* (depuis avril-mai 2026, commit `42f78b7`) :**
- La commission est **supportée par le prestataire** et déduite de son versement final
- L'entreprise paie strictement le TTC prestataire convenu au devis — aucune ligne de commission Gotcha n'apparaît sur la facture de prestation
- Les **frais de transaction Stripe** (1,5&nbsp;% + 0,25&nbsp;€, + TVA 20&nbsp;%) sont également absorbés par le prestataire et figurent sur sa facture de commission Gotcha
- Implémentation Stripe Connect : `application_fee_amount` retenu sur le transfer lors de la capture finale (`utils/payment-amounts.js → buildAbsorbedFeeChargeAmounts`)

**Exception :** Les missions bénévoles (sans rémunération) ne génèrent aucun flux financier ni commission.

### 1.4 Zone Géographique

La plateforme opère actuellement en **France métropolitaine**.

---

## 2. LES ACTEURS DE LA PLATEFORME

### 2.1 L'Opérateur de la Plateforme

**GOTCHAAAA** (SAS — Société par Actions Simplifiée)
- Siège social : 78 avenue des Champs-Élysées, 75008 Paris, France
- RCS Paris — SIREN 104&nbsp;412&nbsp;648 — SIRET 104&nbsp;412&nbsp;648&nbsp;00016
- TVA intracommunautaire : FR27&nbsp;104412648
- Code NAF : 6312Z — Portails Internet
- Date d'immatriculation : 10 mai 2026
- Présidente : Charlotte BECHON
- Directeurs Généraux : Nathan DOLARD VILLARD, Nicolas SAGE
- Contact : hello@gotchaaaa.com
- **Rôle** : Éditeur et opérateur de la plateforme — intermédiaire technique de mise en relation
- **Statut** : **Non-employeur** des prestataires (plateforme de mise en relation B2B, le devis et la convention de bénévolat sont les seuls documents engageants entre les parties)

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

**Pour les missions payantes** (`state` du `profile_mission`) :
1. Le prestataire soumet un devis (via le PostulerDrawer) → `state = 'postule'`
2. L'entreprise consulte les candidats et leurs devis
3. **L'entreprise signe le devis du prestataire choisi** (via OTP) → `state = 'assigned'`, autres candidats automatiquement `rejected`
4. Les états `accepted`, `confirmed` et `employer_signed` **ne sont PAS utilisés** pour les missions payantes
5. Une seule signature suffit : c'est le **devis** qui fait office de document contractuel engageant

**Pour les missions bénévoles** (flow complet) :
1. L'entreprise peut **accepter plusieurs candidats** simultanément (`postule → accepted`)
2. Tous les candidats acceptés sont notifiés
3. **Le premier candidat à confirmer sa disponibilité remporte la mission** (`accepted → confirmed`)
4. Les autres candidats acceptés sont automatiquement rejetés

### 4.5 Confirmation (missions bénévoles uniquement)

Lorsqu'un prestataire est accepté pour une mission bénévole :
1. Il reçoit une notification
2. Il doit confirmer sa disponibilité
3. **Premier arrivé, premier servi** : le plus rapide à confirmer obtient la mission

---

## 5. SYSTÈME DE CONTRATS

### 5.1 Documents contractuels

Deux types de documents selon la nature de la mission :

| Type de mission | Document engageant | Signataires |
|-----------------|--------------------|-----------|
| **Payante** | **Devis** (généré à partir du PostulerDrawer du prestataire) | Entreprise uniquement (signature OTP) |
| **Bénévole** | **Convention de bénévolat** (contrat de prestation de services) | Entreprise puis prestataire (signature OTP des deux) |

> Pour les missions payantes, **le prestataire ne signe rien** : c'est la signature OTP du devis par l'entreprise qui engage les deux parties et déclenche le prélèvement. Ce modèle évite tout risque de requalification du lien commercial.
>
> Pour les missions bénévoles, l'entreprise signe **en premier** (le prestataire ne reçoit le document à signer qu'une fois l'entreprise engagée), afin d'éliminer le risque de "promesse d'embauche non tenue" (art. L.1242-12 du Code du travail).

### 5.2 Contenu du document

Chaque document généré contient :
- Identité complète de l'entreprise (nom, SIRET, adresse, représentant)
- Identité complète du prestataire (nom, SIRET, adresse, régime TVA)
- Date(s), horaires et lieu de la mission (mono ou multi-jour avec planning détaillé)
- Nature de la prestation (compétence/métier)
- Rémunération : TJM, jours facturés, temps de préparation éventuel, frais additionnels, heures supplémentaires
- Mention CGV (jointes ou par référence)
- Clauses standards (confidentialité, responsabilité, etc.)

### 5.3 Signature Électronique (eIDAS)

#### 5.3.1 Processus

**Missions payantes — Signature unique (entreprise)**
1. L'entreprise visualise le devis complet (PDF)
2. Elle coche la case de consentement explicite (texte versionné, hashé, conservé)
3. Un **code OTP à 5 chiffres** est envoyé par email
4. Elle saisit le code → la signature est validée
5. Phase 1 du paiement déclenchée immédiatement (acompte si applicable)

**Missions bénévoles — Signatures successives**
1. L'entreprise signe en premier (même processus OTP que ci-dessus) → `state = 'employer_signed'`
2. Le prestataire est notifié et dispose d'un **délai limité** pour signer :
   - Si la mission est dans plus de 24h : délai de 24h
   - Si la mission est dans moins de 24h : délai = 50&nbsp;% du temps restant
3. Le prestataire effectue le même processus OTP → `state = 'assigned'`

#### 5.3.2 Sécurité de la Signature (eIDAS)

- Code OTP **haché** (bcrypt, jamais stocké en clair)
- Expiration du code : **5 minutes**
- Maximum **3 tentatives** de saisie
- **Adresse IP chiffrée** en base (AES-256-GCM) avec mention explicite à l'utilisateur
- **User Agent** (navigateur) enregistré
- **Horodatage** précis
- **Texte de consentement versionné** (cf. `shared/contract-signature-consent.js` : `CONTRACT_SIGNATURE_CONSENT_VERSION_ID`, `DEVIS_SIGNATURE_CONSENT_VERSION_ID`)
- **Certificat de signature** (trame `certificat_signature`) généré automatiquement et scellé quotidiennement (cron `seal-devis-evidence-daily`, `seal-contract-evidence-daily`)
- Rétention légale : **7 ans** par défaut, extensible via *legal hold*

#### 5.3.3 Expiration et Annulation Automatique

**Missions bénévoles** : si le prestataire ne signe pas dans le délai après `employer_signed` :
- Le contrat passe en `expired`
- La mission est remise en ligne
- Un **avis négatif automatique** est appliqué au prestataire (1/5 étoiles, motif `no_show_signature`)

**Missions payantes** : l'OTP de l'entreprise expire au bout de 5 minutes. Si la signature échoue (carte refusée, OTP expiré), aucune assignation n'est faite et le devis reste signable.

### 5.4 Archivage des Contrats

Tous les contrats signés sont archivés avec :
- Version HTML complète du contrat
- Métadonnées de signature (IP, timestamp, user agent)
- Preuves de vérification OTP

---

## 6. SYSTÈME DE PAIEMENT

### 6.1 Modèle Général (Stripe Connect, deux phases)

Gotcha utilise **Stripe Connect** en mode *absorbed* :
- L'entreprise paie strictement le TTC prestataire convenu au devis
- Le prestataire absorbe la commission Gotcha (13&nbsp;% HT + TVA) et les frais de transaction Stripe (1,5&nbsp;% + 0,25&nbsp;€ + TVA)
- Stripe retient ces montants via `application_fee_amount` lors du transfer vers le compte Connect du prestataire

```
Entreprise paie  ───►  Stripe (transfert direct au prestataire avec retenue application_fee)
                                     │
                                     ├──► Prestataire (TTC − commission − frais Stripe)
                                     └──► Gotcha (commission + TVA + frais Stripe + TVA)
```

### 6.2 Flux de Paiement Détaillé

#### 6.2.1 Phase 1 — Acompte à la signature du devis (Entreprise)

Pour les missions payantes, **seule l'entreprise signe** le devis (signature électronique par OTP). Le prestataire ne signe rien (cf. section 5 — Système de contrats).

À la signature OTP du devis par l'entreprise :
- **Si le montant HT &geq; 800&nbsp;€** : un **acompte de 30&nbsp;% TTC** du montant prestataire est prélevé **immédiatement** (charge directe Stripe, `capture_method: 'automatic'`)
- **Sinon** : aucun prélèvement à cette étape
- L'acompte éventuel est **intégralement transféré** au prestataire (`application_fee_amount = 0` à ce stade — Gotcha ne prélève aucune commission ici)
- `profile_missions.state` passe à `assigned`, les autres candidatures sont automatiquement rejetées

#### 6.2.2 Phase 2 — Solde final à la validation du rapport

C'est le **prestataire** qui soumet en premier son rapport de fin de mission :
- Heures réellement travaillées (base + heures supplémentaires)
- `final_adjustment_lines` éventuels (frais kilométriques, matériel consommé, remise, etc.)
- Aperçu de la facture avant soumission

L'entreprise reçoit alors le rapport et choisit :

**Option A — Validation**
- Création d'une pré-autorisation Stripe (`capture_method: 'manual'`) pour le solde = `provider_total_ttc − acompte`
- `application_fee_amount = commission_ttc + stripe_fee_ttc` (13&nbsp;% HT + TVA + frais Stripe HT + TVA)
- Capture immédiate
- Si `final_adjustments_ht != 0` : une pré-autorisation supplémentaire est créée et capturée dans le même flow (`/api/missions/submit-report`)
- Transfert net au prestataire + génération automatique des factures (PROVIDER, COMMISSION_INITIAL, COMMISSION_FINAL le cas échéant)

**Option B — Auto-validation (silence)**
- Si l'entreprise ne valide pas sous **72 heures** → auto-validation par cron + capture finale automatique

**Option C — Contestation**
- Ouverture d'un **signalement** (`missions.disputes` avec `opened_by = 'company'`)
- Capture du paiement final via `/api/stripe/capture-on-dispute` (sans transfer vers le prestataire)
- Les fonds restent sécurisés jusqu'à résolution ou auto-release à J+31

### 6.3 Calcul des Montants

#### 6.3.1 Mission Standard (1 jour, TJM 250&nbsp;€ HT, sans acompte car < 800&nbsp;€)

```
Provider HT  = 250 × 1 jour       = 250,00 €
Provider TTC (regime_tva = false) = 250,00 €

Commission HT  = 250 × 13 %        =  32,50 €
Commission TVA = 32,50 × 20 %      =   6,50 €
Frais Stripe HT  = 250 × 1,5% + 0,25 =  4,00 €
Frais Stripe TVA = 4,00 × 20 %     =   0,80 €

→ Entreprise paie     : 250,00 € (à la validation du rapport, pas d'acompte)
→ Prestataire reçoit  : 250 − 32,50 − 6,50 − 4,00 − 0,80 = 206,20 €
→ Gotcha encaisse net : 32,50 + 6,50 + 4,00 + 0,80 = 43,80 €
```

#### 6.3.2 Mission avec Acompte (TJM 1000&nbsp;€ HT, prestataire assujetti TVA, 2h prep, 50&nbsp;€ frais additionnels)

```
Base HT  = 1000 + 2 × (1000/8) + 50 = 1 300,00 €
TVA       = 1300 × 20 %              =   260,00 €
TTC       = 1 560,00 €

Phase 1 (signature devis, base_ht >= 800 →) :
  Acompte TTC = 1560 × 30 %         =   468,00 €
  → Entreprise prélevée immédiatement de 468 €
  → Prestataire reçoit 468 € (transfer intégral, application_fee = 0)

Phase 2 (validation rapport, pas d'ajustement) :
  Solde TTC dû par l'entreprise = 1560 − 468 = 1 092,00 €
  Commission HT  = 1300 × 13 %     =   169,00 €
  Commission TVA =                       33,80 €
  Frais Stripe HT  = 1092 × 1,5% + 0,25 = 16,63 €
  Frais Stripe TVA =                       3,33 €
  application_fee_amount = 222,76 €

  → Entreprise prélevée de 1092 €
  → Prestataire reçoit 1092 − 222,76 = 869,24 €
  → Gotcha encaisse 222,76 €

Totaux :
  Entreprise paie total     : 468 + 1092       = 1 560,00 € (= TTC prestataire)
  Prestataire reçoit total  : 468 + 869,24     = 1 337,24 €
  Gotcha encaisse net       : 222,76 €
```

#### 6.3.3 Mission avec ajustements finaux (`final_adjustment_lines`)

Exemple : devis 250&nbsp;€ HT, rapport ajoute 50&nbsp;€ HT de frais kilométriques.

```
HT final           = 250 + 50 = 300,00 €
Commission HT      = 300 × 13 % = 39,00 €
Commission TVA     = 7,80 €

→ Une 2e facture de commission ("COMMISSION_FINAL") est émise par Gotcha au prestataire pour la commission sur les 50 € ajoutés
→ Une pré-auth supplémentaire Stripe est créée et capturée dans la foulée de la validation
```

### 6.4 Missions Bénévoles

- **Aucun flux financier** traité par la plateforme
- Pas de commission
- Pas de configuration Stripe requise
- Flow de signature spécifique : **convention de bénévolat** signée par les deux parties (entreprise en premier, puis prestataire) avec signature OTP

### 6.5 Règle demi-journée (`billing_days`)

Le TJM est multiplié par un nombre de jours facturés calculé selon la règle :

```
mono-jour : billing_days = ceil(hours / 4) × 0.5
            (1h-4h = 0.5j, 4.5h-8h = 1j, 8.5h-12h = 1.5j, etc.)
multi-jour : billing_days = nombre de jours de mission
```

Le prestataire peut surcharger le palier dans le PostulerDrawer si la mission tombe sur un demi-palier.

### 6.6 Délais

- **Acompte (phase 1)** : prélèvement immédiat à la signature OTP du devis
- **Solde final (phase 2)** : capture à la validation du rapport par l'entreprise (ou auto-validation à 72h)
- **Échec de capture finale** : relances automatiques à J+1, J+3, J+7
- **Virement sur le compte bancaire du prestataire** (via Stripe Connect) : 2 à 7 jours ouvrés selon la banque

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

> Implémentation : RPC `missions.cancel_mission_v2` (`cancellation_system_v2.sql`) avec règle 48h et snapshot document-aware (`009-cancel-mission-document-aware.sql`).

#### 7.2.1 Avant assignation (avant signature OTP du devis/convention)

- **≥ 48h avant la mission** : annulation libre, aucun frais, remboursement intégral éventuel
- **< 48h ET le prestataire s'est déjà engagé** (devis signé / `state = 'assigned'`) : annulation **interdite**

#### 7.2.2 Après assignation (devis signé pour payante / convention signée pour bénévole)

Si l'entreprise annule alors que la mission est assignée :
- **Indemnisation du prestataire à 100&nbsp;%** du montant prévu au devis (l'acompte versé est conservé, le solde est capturé à la validation/auto-validation)
- Commission Gotcha prélevée normalement sur la somme due au prestataire
- Un enregistrement complet (`providers.cancellation_logs`) est créé avec snapshot du contrat, du devis et du *payment_flow* pour traçabilité juridique

### 7.3 Remplacement automatique

Lorsqu'un prestataire annule après avoir été assigné :

1. La mission repasse à `unassigned` (cf. `missions.missions.status`) et redevient candidatable
2. L'algorithme recherche des **prestataires de remplacement** dans la zone d'intervention
3. Jusqu'à **5 candidats** sont suggérés à l'entreprise via le `ReplacementProvidersDrawer`
4. Critères de sélection : badge vérifié, note élevée, proximité géographique, disponibilité immédiate

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
