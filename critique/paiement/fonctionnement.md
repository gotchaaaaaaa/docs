# Paiement - Guide Fonctionnel

> **Derniere mise a jour** : Fevrier 2026

---

## A quoi ca sert ?

Le systeme de paiement gere l'ensemble du flux financier entre l'entreprise (qui paye) et le prestataire (qui est paye), avec Gotcha comme intermediaire percevant une commission. Tout passe par **Stripe**, un prestataire de paiement en ligne securise.

---

## Comment ca marche ? (Vue d'ensemble)

Le paiement se fait en **deux temps** :

1. **A la signature du contrat** : un premier montant est reserve puis preleve (acompte + commission)
2. **Apres la mission** : le solde restant est preleve sur la base des heures reellement travaillees

---

## Les acteurs

| Acteur | Role dans le paiement |
|--------|----------------------|
| **Entreprise** | Paye pour la mission (carte bancaire) |
| **Prestataire** | Recoit le paiement (compte bancaire via Stripe) |
| **Gotcha** | Percoit une commission de 12.5% sur le montant HT |

---

## Les regles de calcul

### Commission Gotcha
- **12.5%** du montant HT (hors taxes), applicable sur les heures de base ET les heures supplementaires
- Exemple : mission a 1 000 EUR HT -> commission de 125 EUR

### Acompte
- Un **acompte de 30%** est demande si le montant total HT de la mission est **>= 800 EUR**
- En dessous de 800 EUR HT, pas d'acompte : seule la commission est prelevee a la signature

### TVA
- Si le prestataire est **assujetti a la TVA** : 20% de TVA est ajoute a ses montants
- Si le prestataire **n'est pas assujetti** : pas de TVA sur ses montants
- La commission Gotcha inclut **toujours** 20% de TVA (Gotcha est une societe assujettie)

### Frais Stripe
- Les **frais de transaction Stripe** (environ 1.5% + 0.25 EUR par transaction) s'ajoutent **en plus** de la commission Gotcha
- Ces frais sont a la charge de l'entreprise et apparaissent sur le releve Stripe, pas sur les factures Gotcha
- Ils ne sont pas inclus dans le calcul de la commission : la commission est calculee sur le montant HT, les frais Stripe sont preleves separement par Stripe sur le montant total de la transaction

### Heures supplementaires
- Taux supplementaire = taux de base x 1.25 (majoration de 25%)
- La commission s'applique aussi sur les heures supp

---

## Deroulement detaille

### Phase 1 : Reservation a la signature (entreprise signe le contrat)

Quand l'entreprise signe le contrat :

1. Le systeme calcule le montant a reserver : **acompte TTC + commission**
2. Ce montant est **reserve** sur la carte de l'entreprise (pas encore debite)
3. La reservation reste en attente de la signature du prestataire

**Exemple** : Mission de 40h a 25 EUR/h, prestataire avec TVA
```
Montant HT = 40h x 25 EUR = 1 000 EUR
Acompte HT = 1 000 x 30% = 300 EUR
Acompte TVA = 300 x 20% = 60 EUR
Acompte TTC = 360 EUR
Commission = 1 000 x 12.5% = 125 EUR
-----------------------------------------
Total reserve = 360 + 125 = 485 EUR
```

### Phase 2 : Prelevement a la signature (prestataire signe le contrat)

Quand le prestataire signe a son tour :

1. Le montant reserve est **effectivement debite** de la carte de l'entreprise
2. L'acompte est transfere vers le compte Stripe du prestataire
3. La commission est conservee par Gotcha

### Phase 3 : Rapport de mission (apres la mission)

Quand l'entreprise soumet le rapport de fin de mission :

1. Les heures reellement travaillees sont saisies (base + supplementaires si applicable)
2. Le systeme calcule le **solde restant** :
   - Montant total reel - acompte deja preleve = solde a payer
   - + commission supplementaire sur les heures supp
3. Le solde est **reserve** sur la carte de l'entreprise

**Exemple (suite)** : 38h base + 2h supp
```
Base reelle HT = 38h x 25 EUR = 950 EUR
Supp HT = 2h x 31.25 EUR = 62.50 EUR
Total HT = 1 012.50 EUR
TVA = 1 012.50 x 20% = 202.50 EUR
Total TTC = 1 215 EUR
Deja paye (acompte) = 360 EUR
Solde prestataire = 855 EUR
Commission supp = 62.50 x 12.5% = 7.81 EUR
-----------------------------------------
Total charge final = 855 + 7.81 = 862.81 EUR
```

### Phase 4 : Validation et prelevement final

Le prestataire a la possibilite de **valider le rapport** soumis par l'entreprise :

- **Validation manuelle** : le prestataire approuve les heures declarees
- **Validation automatique** : si le prestataire ne reagit pas dans les **72 heures**, le rapport est automatiquement valide

Une fois valide :
1. Le solde reserve est **effectivement debite**
2. Le prestataire recoit le paiement sur son compte bancaire (via Stripe)
3. Les **factures** sont automatiquement generees et envoyees (voir `../facturation/fonctionnement.md`)
4. La mission passe en statut **"terminee"**

---

## Absence du prestataire (no-show)

Si le prestataire ne se presente pas a la mission, l'entreprise dispose d'un delai de **30 minutes** apres l'heure de debut prevue pour declarer l'absence.

### Comment ca marche ?

1. L'heure de debut de la mission est passee
2. L'entreprise constate que le prestataire n'est pas la
3. Elle a **30 minutes** pour signaler l'absence via l'application
4. Si elle declare un no-show :
   - La mission est annulee
   - Le paiement initial (acompte) est **rembourse** a l'entreprise
   - Le prestataire ne recoit rien
   - Un avertissement est enregistre sur le profil du prestataire
5. Passe les 30 minutes, si l'entreprise n'a rien signale, la mission est consideree comme ayant demarre normalement

---

## Cas des missions benevoles

Pour les missions marquees comme **benevoles** :
- Aucun paiement n'est effectue a aucune etape
- Pas de reservation, pas de prelevement, pas de commission
- Le systeme marque simplement le paiement comme "non requis"

---

## Inscription du prestataire a Stripe

Avant de pouvoir recevoir des paiements, le prestataire doit configurer un **compte Stripe Connect** :

1. Le prestataire fournit ses informations personnelles (identite, date de naissance)
2. Il renseigne son **IBAN** (coordonnees bancaires)
3. Il est redirige vers Stripe pour finaliser la verification
4. Une fois verifie, il peut recevoir des paiements

Les paiements arrivent directement sur son compte bancaire, generalement **le jour ouvrable suivant** le prelevement.

---

## Moyen de paiement de l'entreprise

L'entreprise doit avoir une **carte bancaire enregistree** avant de pouvoir signer un contrat payant. Le systeme verifie la presence d'un moyen de paiement valide avant de permettre la signature.

---

## En cas de probleme de paiement

### Echec du prelevement final

Si le prelevement final echoue (carte expiree, fonds insuffisants...) :

1. Le systeme passe en mode **"recouvrement"**
2. Des **reessais automatiques** sont programmes :
   - 1er reessai : apres **1 jour**
   - 2eme reessai : apres **3 jours**
   - 3eme reessai : apres **7 jours**
3. L'administrateur est alerte a chaque echec
4. Apres 3 echecs, une **intervention manuelle** est necessaire

### Litige (contestation de paiement)

Si l'entreprise conteste un prelevement aupres de sa banque :

- L'administrateur est immediatement alerte
- La mission est marquee comme **"en litige"**
- Si le litige est **gagne** par Gotcha : le paiement est finalise normalement
- Si le litige est **perdu** : la situation est marquee et une intervention manuelle est necessaire

---

## Recapitulatif des montants

### Ce que paye l'entreprise

| Moment | Montant |
|--------|---------|
| Signature du contrat | Acompte TTC (si >= 800 EUR HT) + Commission de base |
| Fin de mission | Solde TTC restant + Commission supplementaire (si heures supp) |

### Ce que recoit le prestataire

| Moment | Montant |
|--------|---------|
| Signature du contrat | Acompte TTC (si applicable) |
| Fin de mission | Solde TTC restant |

### Ce que garde Gotcha

| Moment | Montant |
|--------|---------|
| Signature du contrat | Commission de base (12.5% sur HT estime) |
| Fin de mission | Commission supplementaire (12.5% sur HT des heures supp) |

---

## Timeline typique

```
Jour 0  - Mission postee par l'entreprise

Jour 1  - Prestataire postule
        - Entreprise signe le contrat
          -> 485 EUR reserves sur la carte
        - Prestataire signe le contrat
          -> 485 EUR debites (360 EUR prestataire + 125 EUR Gotcha)

Jour 3  - Mission terminee
        - Entreprise soumet le rapport (38h + 2h supp)
          -> 862.81 EUR reserves sur la carte

Jour 6  - Auto-validation du rapport (72h)
          -> 862.81 EUR debites (855 EUR prestataire + 7.81 EUR Gotcha)
          -> Factures generees et envoyees

Jour 7  - Prestataire recoit le virement sur son compte bancaire
          Total recu : 1 215 EUR TTC
```

---

## Lien avec les autres flux

- **Contrats** : le paiement initial est declenche par la signature du contrat (voir `../contrats/fonctionnement.md`)
- **Facturation** : les factures sont generees automatiquement apres le prelevement final (voir `../facturation/fonctionnement.md`)
