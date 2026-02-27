# Conformite facturation electronique

> **Date** : Fevrier 2026
> **Statut** : DECISION PRISE — Cas 17a (le prestataire emet sa propre facture)

---

## 1. La reforme

Toute facture B2B entre entreprises francaises devra transiter via une **Plateforme Agreee (PA)** au format structure (Factur-X, UBL ou CII). Un simple PDF ne sera plus conforme.

| Echeance | Obligation |
|----------|------------|
| **Sept. 2026** | Toutes les entreprises doivent **designer une PA** et pouvoir **recevoir** des e-factures. GE + ETI doivent **emettre** |
| **Sept. 2027** | PME, TPE, micro-entreprises, independants doivent **emettre** |

### Application a Gotcha

Les prestataires Gotcha sont majoritairement des **independants** (parfois non assujettis TVA) et au max des **PME**.

| Acteur | Sept. 2026 | Sept. 2027 |
|--------|-----------|-----------|
| **Gotcha** (SAS, TPE/PME) | Designer une PA (reception). Demarche admin, 5 min | Emettre F2 (commission) via PA |
| **Prestataires** (independants, PME) | Designer une PA (reception). Demarche admin, 5 min | Emettre F1 (prestation) via PA |
| **Entreprises clientes** | GE/ETI emettent des sept. 2026. Le reste en sept. 2027 | — |

**Ni Gotcha ni les prestataires n'ont d'obligation d'emettre via PA avant septembre 2027.** Le systeme actuel (PDF via PDFKit) reste legal pour l'emission jusqu'a cette date ([Art. 289 VII CGI](https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI000048827413)).

### Sanctions (a partir de l'obligation d'emission)

| Infraction | Sanction |
|------------|---------|
| Non-emission de e-facture | 50 EUR/facture, plafond 15 000 EUR/an |
| Pas de PA designee | 500 EUR puis 1 000 EUR/trimestre |
| Omission e-reporting | 500 EUR/omission, plafond 15 000 EUR/an |

Tolerance pour 1ere infraction si regularisation sous 30 jours.

---

## 2. Decision retenue : Cas 17a

> Norme AFNOR XP Z12-014, cas d'usage 17a : "Marketplace sans mandat de facturation"

**Le prestataire emet sa propre facture. Gotcha fournit les donnees, pas la facture.**

### Pourquoi

- Zero cout PA pour les F1 — Gotcha ne gere que sa propre F2 (commission)
- Pas de mandat de facturation, pas de 5 EUR/SIRET, pas de setup couteux
- Chaque prestataire gere sa propre conformite (obligatoire de toute facon en sept. 2027)
- Gotcha n'est pas responsable du contenu des factures prestataires
- Des PA gratuites existent (Tiime, Qonto, Pennylane)

### Message affiche au prestataire

> Gotcha ne prend pas en charge la creation de vos factures de prestation. A compter de septembre 2027, chaque prestataire devra emettre ses factures via une Plateforme Agreee. Pour vous simplifier la tache, nous mettons a votre disposition toutes les informations de la mission : il ne vous reste qu'a les copier dans votre logiciel de facturation. Si vous n'en avez pas encore, des solutions gratuites existent (Tiime, Qonto, Pennylane).

### Flux (a partir de sept. 2027)

```
Mission terminee + rapport d'heures valide
        |
        ├──► Prestataire :
        |      Ecran recap avec toutes les infos facture
        |      Bouton "Copier les informations"
        |      Il emet F1 via son propre logiciel/PA
        |      PA prestataire --> Annuaire PPF --> PA entreprise
        |
        ├──► Gotcha (F2 commission) :
        |      Emet F2 (12.5%) via sa PA
        |      PA Gotcha --> Annuaire PPF --> PA entreprise
        |
        └──► Paiement :
               Stripe capture (independant de F1)
```

### Donnees copiables pour le prestataire

| Champ | Source |
|-------|--------|
| Raison sociale, SIRET, adresse entreprise | `companies` |
| N° TVA entreprise | `companies.tva_number` |
| Intitule et date mission | `missions` |
| Heures de base + taux horaire | Rapport + contrat |
| Heures supp + taux supp (base x 1.25) | Rapport + calcul |
| Sous-total HT, TVA, Total TTC | Calcul |

---

## 3. Plan d'action

> **Decision validee** : Nathan & Nico, 26/02/2026

### Phase 1 : Maintenant → 31 aout 2026

**Statu quo + information**

| Action | Detail |
|--------|--------|
| Systeme actuel inchange | PDF via PDFKit + envoi email. 100% legal (Art. 289 VII CGI) |
| Informer les prestataires | Ajouter un message dans l'app mentionnant la reforme a venir |
| Designer une PA pour Gotcha | Inscrire Gotcha sur une PA gratuite (Qonto/Tiime/Pennylane) pour **recevoir** les factures de nos fournisseurs (Supabase, Stripe, etc.). Demarche admin, 5 min |

### Phase 2 : 1er sept. 2026 → 31 aout 2027

**Regime mixte — laisser le choix au prestataire**

| Acteur | Obligation | Ce qu'on fait |
|--------|-----------|---------------|
| **Gotcha** (PME) | Recevoir via PA | Notre PA est en place (phase 1). Emission F2 (commission) toujours en PDF/email — legal tant qu'on reste PME |
| **Prestataires** (independants, micro, PME) | Recevoir via PA | Deux options dans l'app : |
| | | **Option A** : On genere le PDF et on envoie par email (comme avant) |
| | | **Option B** : Si le prestataire a deja une PA, on lui fournit toutes les infos necessaires pour remplir sa facture dans son logiciel |
| **Entreprises clientes** (GE/ETI) | Emettre via PA | Elles emettent deja — pas d'impact pour nous |

### Phase 3 : A partir du 1er sept. 2027

**Tout le monde emet via PA**

| Action | Detail |
|--------|--------|
| Arret generation PDF F1 | Plus de facture prestataire generee par Gotcha |
| Ecran recap post-mission | Bouton "Copier les informations" + message PA |
| Emission F2 via PA | Integrer l'emission F2 (commission Gotcha) via notre PA |
| Evolution eventuelle | Evaluer cas 17b (mandat + Iopole) si le volume le justifie |

### Resume calendrier

| Phase | Quand | F1 (prestation) | F2 (commission Gotcha) |
|-------|-------|-----------------|------------------------|
| **1** | → aout 2026 | PDF + email | PDF + email |
| **2** | sept. 2026 → aout 2027 | PDF + email **ou** infos pour PA prestataire (au choix) | PDF + email (legal, on est PME) |
| **3** | sept. 2027 → | Prestataire emet via sa PA (on fournit les infos) | Gotcha emet via sa PA |

### Actions dev par phase

| Phase | Action dev | Priorite |
|-------|-----------|----------|
| **1** | Ajouter banniere/message info reforme dans l'app | Basse |
| **2** | Ajouter option "J'ai une PA" dans le profil prestataire | Moyenne |
| **2** | Ecran recap infos facture (si PA) a cote du PDF actuel | Moyenne |
| **3** | Ecran recap post-mission + bouton "Copier les infos" | Haute |
| **3** | Integration emission F2 via API PA Gotcha | Haute |
| **3** | Suppression generation PDF F1 | Haute |

### PA recommandees

| Pour | Solution | Cout |
|------|----------|------|
| **Gotcha** (reception + emission F2) | Qonto, Tiime ou Pennylane | Gratuit |
| **Prestataires** (F1 prestation) | Tiime, Qonto ou Pennylane — a recommander dans l'app | Gratuit |

---

## 4. Alternative ecartee : le mandat de facturation (cas 17b)

Le mandat (Art. 289 I-2 CGI) permettrait a Gotcha d'emettre les F1 au nom des prestataires. Ecarte car :

- Chaque SIRET prestataire doit quand meme etre inscrit dans l'annuaire PPF
- Cout Iopole : 2 000 EUR setup + 199 EUR/mois + 5 EUR/SIRET one-shot
- Gotcha porte la responsabilite juridique des factures
- Complexite : numerotation distincte par prestataire, mention obligatoire, code BT-3 = 389

Reste envisageable a terme si le volume le justifie.

---

## 5. Pricing Iopole (reference, call fev. 2026)

| Poste | Cout | Frequence |
|-------|------|-----------|
| Setup | 2 000 EUR | One-shot |
| Abonnement Starter (< 3 000 factures) | 199 EUR/mois | Mensuel |
| Par SIRET emetteur | 5 EUR/SIRET | One-shot |
| Archivage 10 ans | ~200 EUR / 6 000-10 000 factures | Ponctuel |

---

## Sources

### Textes officiels
- [Art. 289 CGI](https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI000048827413) — regime actuel, PDF legal
- [Art. 289 bis CGI](https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI000046195635) — reforme sept. 2026/2027
- [BOFIP BOI-TVA-DECLA-30-20-30-20](https://bofip.impots.gouv.fr/bofip/8865-PGP.html) — PAF, validite du PDF
- [economie.gouv.fr](https://www.economie.gouv.fr/tout-savoir-sur-la-facturation-electronique-pour-les-entreprises) — facturation electronique
- [Liste des PA](https://www.impots.gouv.fr/liste-des-plateformes-agreees-immatriculees) — 108 au 13/02/2026

### Normes et cas d'usage
- [AFNOR XP Z12-014 v1.2](https://fnfe-mpe.org/wp-content/uploads/2025/11/XP_Z12-014_CAS_USAGE_Annexe_A_V1.2.pdf) — cas d'usage 17a/19a

### Videos explicatives (recherche Nathan, fev. 2026)
- https://www.youtube.com/watch?v=t2CPFFQOL6M
- https://www.youtube.com/watch?v=Wu-auBDfiV0 (14:50 a 27:01 notamment)
- https://www.youtube.com/watch?v=FoXJq-GfFrg&t=208s

### Prestataires
- [iopole.com](https://www.iopole.com/) — 5 EUR/SIRET one-shot
- PA gratuites : [qonto.com](https://qonto.com/fr/invoicing/e-invoicing), [tiime.fr](https://www.tiime.fr/plateforme-dematerialisation-partenaire-pdp), [pennylane.com](https://www.pennylane.com/fr/logiciel-facturation-electronique)
