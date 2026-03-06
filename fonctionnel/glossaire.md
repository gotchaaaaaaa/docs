# Glossaire - Gotcha

**Dernière mise à jour**: Janvier 2026

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
- Perçoit commission 12,5%
- Gère contrats et paiements

### Types de missions

**Mission payante**
- `benevole: false`
- Rémunération prestataire
- Paiement via Stripe
- Contrat de travail (CDD usages)

**Mission bénévole**
- `benevole: true`
- Aucune rémunération
- Accessible festivals/associations
- Avantages offerts (repas, accès événement)

### États mission

**Status mission** (`missions.status`):
- `open`: Ouverte aux candidatures
- `assigned`: Prestataire assigné
- `completed`: Terminée
- `canceled`: Annulée
- `closed`: Archivée

**State candidature** (`profile_missions.state`):
- `postule`: Candidature soumise
- `accepted`: Retenue par entreprise
- `confirmed`: Prestataire confirme
- `employer_signed`: Entreprise signe contrat
- `assigned`: Contrat signé (les deux)
- `completed`: Mission terminée
- `rejected`: Candidature refusée
- `expired`: Prestataire n'a pas répondu
- `canceled`: Annulée

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

**CDD usages**
- Contrat Durée Déterminée d'usage
- Template contrat Gotcha
- Signé par les deux parties (OTP)

### Termes financiers

**Pré-autorisation**
- Réservation montant carte (Stripe)
- Non débité immédiatement
- Expire après 7 jours
- Capture ultérieure montant réel

**Capture**
- Débit effectif carte
- Après validation rapport mission
- Montant = heures réelles

**Commission**
- 12,5% perçu par Gotcha
- Calculé sur montant base
- Prélevé automatiquement

**Tarif horaire**
- `price_hour`: Heures normales
- `price_hour_supp`: Heures supplémentaires
- Négocié par prestataire
- Peut varier par compétence

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
- Compte prestataires
- Transferts automatiques

---

**Fin du document - Glossaire**
