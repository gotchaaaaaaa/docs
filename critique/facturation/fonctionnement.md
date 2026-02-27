# Facturation - Guide Fonctionnel

> **Derniere mise a jour** : Fevrier 2026

---

## A quoi ca sert ?

Apres chaque mission payante terminee, le systeme genere automatiquement les **factures** correspondantes. Ces factures servent de justificatifs comptables pour l'entreprise et le prestataire.

---

## Les deux types de factures

Pour chaque mission terminee, **deux factures distinctes** sont generees :

### 1. Facture de prestation
- **Emetteur** : le prestataire
- **Destinataire** : l'entreprise
- **Objet** : paiement des heures travaillees
- **Contenu** : heures de base, heures supp, taux horaires, TVA (si applicable), montant total

### 2. Facture de commission Gotcha
- **Emetteur** : GOTCHAAAA SAS
- **Destinataire** : l'entreprise
- **Objet** : frais de mise en relation (12.5% du montant HT)
- **Contenu** : commission HT, TVA (toujours 20%), montant total

---

## Quand sont generees les factures ?

Les factures sont generees **automatiquement** a la fin du processus de paiement :

```
Mission terminee
      |
      v
Entreprise soumet le rapport (heures travaillees)
      |
      v
Prestataire valide le rapport (ou auto-validation apres 72h)
      |
      v
Paiement final capture
      |
      v
Factures generees automatiquement   <-- c'est ici
      |
      v
Factures envoyees par email
```

Aucune action manuelle n'est necessaire : tout est automatique.

---

## Ce que contient une facture de prestation

| Information | Exemple |
|-------------|---------|
| Numero de facture | 000042 |
| Date d'emission | 24/02/2026 |
| Emetteur | Jean Dupont, SIRET 123 456 789, 10 rue de Paris 75001 |
| Destinataire | SAS MonEntreprise, SIRET 987 654 321 |
| Mission | "Agent de securite - Concert" |
| Heures de base | 38h x 25.00 EUR = 950.00 EUR |
| Heures supplementaires | 2h x 31.25 EUR = 62.50 EUR |
| Sous-total HT | 1 012.50 EUR |
| TVA (20%) | 202.50 EUR *(uniquement si prestataire assujetti)* |
| **Total TTC** | **1 215.00 EUR** |

---

## Ce que contient une facture de commission

| Information | Exemple |
|-------------|---------|
| Numero de facture | 000043 |
| Date d'emission | 24/02/2026 |
| Emetteur | GOTCHAAAA SAS, SIRET xxx, N° TVA FRxxx |
| Destinataire | SAS MonEntreprise, SIRET 987 654 321 |
| Description | Commission de mise en relation |
| Montant HT | 104.17 EUR |
| TVA (20%) | 20.83 EUR |
| **Total TTC** | **125.00 EUR** |

---

## Comment sont calculees les factures ?

### Facture de prestation

```
Heures de base x Taux horaire de base         = Montant base HT
Heures supp x Taux horaire supp (base x 1.25) = Montant supp HT
                                                 ─────────────────
                                                 Sous-total HT
+ TVA 20% (si prestataire assujetti)           = TVA
                                                 ─────────────────
                                                 Total TTC
```

### Facture de commission

```
Sous-total HT x 12.5% = Commission TTC (c'est le montant que Gotcha garde)
Commission TTC / 1.20  = Commission HT (Gotcha reverse la TVA a l'Etat)
Commission TTC - HT    = TVA
```

### TVA : comment ca marche ?

- **Prestataire assujetti** (`regime_tva = true`) : la facture de prestation inclut 20% de TVA
- **Prestataire non assujetti** : pas de TVA sur la facture de prestation, les montants sont en HT
- **Gotcha** : la facture de commission inclut toujours 20% de TVA

---

## Distribution par email

### L'entreprise recoit

Un **seul email** contenant :
- Les **2 factures en pieces jointes** (PDF)
- Un recap visuel : montant prestation + montant commission = total preleve
- Objet : "Gotcha! - Factures mission du [date]"

### Le prestataire recoit

Un email contenant :
- **Sa facture de prestation** en piece jointe (PDF)
- Un recap : numero, mission, client, montant
- Objet : "Gotcha! - Facture [numero] envoyee"

Le prestataire ne recoit **pas** la facture de commission (elle ne le concerne pas).

---

## Consulter ses factures dans l'application

### Cote prestataire (`/prestataire/compte/factures`)

- Liste de toutes les factures emises, groupees par mois
- Pour chaque facture : date, entreprise, montant TTC
- Actions disponibles :
  - **Voir** : ouvre la facture dans une visionneuse PDF integree
  - **Telecharger** : sauvegarde le PDF sur l'appareil

### Cote entreprise (`/entreprise/compte/factures`)

- Liste de toutes les factures recues, groupees par mois
- Deux types affiches avec un badge couleur :
  - Badge bleu : "Prestation" (facture du prestataire)
  - Badge violet : "Commission" (facture Gotcha)
- Pour chaque facture : date, emetteur, type, montant TTC
- Memes actions : Voir et Telecharger

---

## Numerotation des factures

Chaque facture recoit un **numero sequentiel unique** qui ne peut pas etre modifie ni supprime. Cette numerotation est conforme aux obligations legales francaises de facturation.

---

## Securite & Confidentialite

- Les donnees sensibles sur les factures (SIRET, adresses, noms) sont **chiffrees** dans la base de donnees
- Les fichiers PDF sont **chiffres** avant d'etre stockes
- L'acces aux factures est **restreint** :
  - Le prestataire ne voit que ses propres factures emises
  - L'entreprise ne voit que les factures qui lui sont adressees
  - Personne d'autre ne peut y acceder

---

## Situations particulieres

| Situation | Ce qui se passe |
|-----------|----------------|
| Mission benevole | Pas de facturation (pas de paiement = pas de facture) |
| Pas d'heures supplementaires | Une seule ligne de detail sur la facture de prestation |
| Prestataire non assujetti TVA | Facture de prestation sans TVA (mention "TVA non applicable") |
| Email de facture non recu | Les factures restent accessibles dans l'espace compte |
| Erreur sur une facture | Les factures ne sont pas modifiables. Contacter le support si necessaire |

---

## Conformite legale : Plateforme Agreee (PA)

> **Statut : DECISION PRISE — Cas 17a (le prestataire emet sa propre facture)**
> Valide le 26/02/2026 (Nathan & Nico)

La legislation francaise (Loi de Finances 2024) impose le passage par une **Plateforme Agreee (PA)** pour emettre et recevoir des factures au format structure (Factur-X, UBL, CII).

### Calendrier

| Echeance | Obligation | Impact Gotcha |
|----------|-----------|---------------|
| **Sept. 2026** | Toutes les entreprises doivent **recevoir** via PA. GE/ETI doivent **emettre** | Gotcha designe une PA (reception). Les prestataires aussi |
| **Sept. 2027** | PME, TPE, micro, independants doivent **emettre** via PA | Gotcha emet F2 via PA. Les prestataires emettent F1 via leur PA |

### Notre strategie en 3 phases

1. **Maintenant → aout 2026** : PDF + email (systeme actuel, 100% legal). Informer les prestataires de la reforme
2. **Sept. 2026 → aout 2027** : Regime mixte — PDF + email **ou** infos pour la PA du prestataire (au choix). Nos factures de commission restent en PDF/email (legal tant qu'on est PME)
3. **A partir de sept. 2027** : Tout via PA. Gotcha fournit les infos, le prestataire emet via sa PA. Gotcha emet F2 via sa PA

### Sanctions (a partir de l'obligation d'emission)

- 50 EUR/facture non conforme (plafond 15 000 EUR/an)
- 500 EUR puis 1 000 EUR/trimestre sans PA designee
- Tolerance pour 1ere infraction si regularisation sous 30 jours

> **Analyse complete** : voir `./analyse-conformitee-facturation.md`

---

## Lien avec les autres flux

- **Paiement** : les factures sont generees automatiquement apres la capture finale du paiement (voir `../paiement/fonctionnement.md`)
- **Contrats** : le contrat determine le taux horaire et les conditions qui apparaissent sur la facture (voir `../contrats/fonctionnement.md`)
