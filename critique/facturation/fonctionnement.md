# Facturation - Guide Fonctionnel

> **Derniere mise a jour** : Mai 2026 (commission 13% HT, split invoices, additional fees)

---

## A quoi ca sert ?

Apres chaque mission payante terminee, le systeme genere automatiquement les **factures** correspondantes. Ces factures servent de justificatifs comptables pour l'entreprise et le prestataire.

---

## Les deux types de factures

Pour chaque mission terminee, **deux factures distinctes** sont generees :

### 1. Facture de prestation
- **Emetteur** : le prestataire
- **Destinataire** : l'entreprise
- **Objet** : paiement de la prestation
- **Contenu** : TJM × jours, heures de preparation, frais additionnels, heures supp, TVA (si regime_tva), montant total TTC

### 2. Facture de commission Gotcha
- **Emetteur** : GOTCHAAAA SAS
- **Destinataire** : **le prestataire** (depuis commit `42f78b7` "feat(commission): from company to providers")
- **Objet** : frais de mise en relation (13% HT du montant HT prestataire)
- **Contenu** : commission HT, TVA (toujours 20%), frais Stripe HT+TVA, montant total

> **Inversion du destinataire** : avant `42f78b7`, la facture de commission etait emise vers l'entreprise. Depuis, elle est emise vers le **prestataire** (qui absorbe la commission). Cf. colonnes `recipient_type` et `recipient_provider_id` sur `missions.invoices` (`add_split_commission_invoices.sql`).

---

## Quand sont generees les factures ?

Les factures sont generees **automatiquement** a la fin du processus de paiement :

```
Mission terminee
      |
      v
Prestataire soumet son rapport (heures travaillees + supp)
      |
      v
Entreprise voit le rapport et paye directement
      |
      v
Paiement final debite
      |
      v
Factures generees automatiquement   <-- c'est ici
      |
      v
Factures envoyees par email
```

Un **apercu de la facture** est disponible avant le paiement (cote prestataire et entreprise) via `/api/invoices/preview`.

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
| Heures de preparation | 2h x 25.00 EUR = 50.00 EUR *(si applicable)* |
| Heures supplementaires | 2h x 31.25 EUR = 62.50 EUR |
| Sous-total HT | 1 062.50 EUR |
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

### Facture de commission (modele 13% HT — depuis avril 2026)

```
Commission HT  = Sous-total HT x 13%       (depuis provider_commission_model_13_percent.sql)
Commission TVA = Commission HT x 20%
Commission TTC = Commission HT + Commission TVA

+ Frais de transaction Stripe :
  Stripe Fee HT  = (montant_ttc x 1.5%) + 0.25 EUR
  Stripe Fee TVA = Stripe Fee HT x 20%
  Stripe Fee TTC = Stripe Fee HT + Stripe Fee TVA
```

> **Migration historique** : auparavant la commission etait calculee en TTC (12.5%) puis splittee. Depuis avril 2026 (`acca872`, `provider_commission_model_13_percent.sql`), la commission est de **13% HT** et les frais Stripe sont factures en HT + TVA separement.

### Facture de commission FINALE (si ajustements post-mission)

Si le prestataire soumet des `final_adjustment_lines` (ajustements/frais supplementaires en fin de mission), une **2e facture de commission** est generee, calculee de la meme maniere sur `final_adjustments_ht`. Cf. `add_split_commission_invoices.sql` + `update_invoice_insert_v2_for_split_commission.sql`.

| Type facture | Quand | Base de calcul |
|--------------|-------|----------------|
| `COMMISSION_INITIAL` | A la signature du devis | Montant HT du devis (devis_total_ht) |
| `COMMISSION_FINAL` | A la validation du rapport, si `final_adjustments_ht != 0` | `final_adjustments_ht` |

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
