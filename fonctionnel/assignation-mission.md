# Flow d'assignation des missions

## Contexte juridique

L'ordre de signature des contrats CDD d'usage est crucial pour éviter les risques de requalification en CDI ou de demande de dommages-intérêts pour promesse d'embauche non tenue (art. L.1242-12 du Code du travail).

**Principe retenu :** L'entreprise signe toujours en premier. Le prestataire ne reçoit le contrat à signer qu'une fois l'entreprise engagée. Ainsi :
- Pas de contrat signé unilatéralement par le prestataire
- L'entreprise s'engage avant le prestataire
- Zéro risque de "promesse d'embauche non tenue" côté plateforme

---

## Statuts disponibles

| Statut | Description |
|--------|-------------|
| `applied` | Le prestataire a postulé à la mission |
| `accepted` | L'entreprise a accepté la candidature (peut accepter plusieurs candidats) |
| `confirmed` | Le prestataire confirme sa disponibilité - **premier arrivé, premier servi** |
| `employer_signed` | L'entreprise a signé le contrat, en attente de signature prestataire |
| `rejected` | Candidature refusée (par l'entreprise, le prestataire, expiré, ou autre candidat confirmé avant) |
| `expired` | Le prestataire n'a pas signé dans les délais après `employer_signed` → **avis négatif automatique** |
| `assigned` | Contrat signé par les deux parties, mission assignée |
| `completed` | Mission terminée |

---

## Règles de compétition multi-candidats

### Principe : Premier confirmé, premier servi

Une mission peut avoir **plusieurs candidatures acceptées** (`accepted`) en parallèle. Le **premier prestataire à confirmer sa disponibilité** (`confirmed`) remporte la mission.

```
Mission X
    │
    ├── Candidat A : accepted → confirme en 1er → confirmed ✅ → suite du flow
    ├── Candidat B : accepted → n'a pas encore confirmé → rejected (autre confirmé)
    └── Candidat C : accepted → n'a pas encore confirmé → rejected (autre confirmé)
```

### Délai de signature après `employer_signed`

Une fois l'entreprise ayant signé (`employer_signed`), le prestataire dispose d'un **délai limité** pour signer (ex: 24h ou jusqu'à X heures avant le début de la mission).

**Si le prestataire ne signe pas dans les temps :**
1. Son statut passe à `expired`
2. Un **avis négatif automatique** est créé sur son profil
3. La mission redevient disponible pour les autres candidats `accepted`

```
Presta confirme → Entreprise signe → employer_signed
                                          │
                    ┌─────────────────────┴─────────────────────┐
                    │                                           │
                    ▼                                           ▼
            Presta signe                              Délai expiré
            dans les temps                            (pas de signature)
                    │                                           │
                    ▼                                           ▼
               assigned                                     expired
                                                    + avis négatif auto
                                                    + mission réouverte
```

### Réouverture après expiration

Quand un prestataire passe en `expired` :
1. Les autres candidats `accepted` peuvent à nouveau confirmer
2. Si aucun autre candidat : la mission repasse en recherche de candidats

---

## Flow 1 : Candidature du prestataire

**Origin : `applied`**

```
┌─────────────────┐
│  PRESTATAIRES   │
│    postulent    │
│  (plusieurs)    │
└────────┬────────┘
         │
         ▼
    ┌─────────┐
    │ applied │  ← Plusieurs prestas peuvent postuler
    └────┬────┘
         │
         ▼
┌───────────────────┐
│   ENTREPRISE      │
│ examine les profils│
│ (accepte plusieurs)│
└────────┬──────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌────────┐ ┌────────┐
│accepted│ │rejected│
└───┬────┘ └────────┘
    │
    │  ← Plusieurs prestas peuvent être "accepted" en parallèle
    ▼
┌───────────────────────┐
│     PRESTATAIRES      │
│    confirment dispo   │
│ PREMIER ARRIVÉ GAGNE  │
└────────┬──────────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌─────────┐ ┌────────┐
│confirmed│ │rejected│ (presta décline OU autre a confirmé avant)
└────┬────┘ └────────┘
     │
     │  ← Un seul presta peut être "confirmed" par mission
     ▼
┌─────────────────┐
│   ENTREPRISE    │
│ signe le contrat│
│   EN PREMIER    │
└────────┬────────┘
         │
    ┌────┴────────────┐
    │                 │
    ▼                 ▼
┌───────────────┐ ┌────────┐
│employer_signed│ │rejected│ (entreprise annule)
└───────┬───────┘ └────────┘
        │
        │  ← Délai limité pour signer (ex: 24h)
        ▼
┌─────────────────────┐
│    PRESTATAIRE      │
│  signe le contrat   │
│     EN SECOND       │
└────────┬────────────┘
         │
    ┌────┴────────────────┐
    │         │           │
    ▼         ▼           ▼
┌────────┐ ┌────────┐ ┌───────┐
│assigned│ │rejected│ │expired│ (délai dépassé)
└───┬────┘ └────────┘ └───┬───┘
    │                     │
    │                     ▼
    │              ┌──────────────┐
    │              │ Avis négatif │
    │              │ automatique  │
    │              └──────┬───────┘
    │                     │
    │                     ▼
    │              ┌──────────────┐
    │              │   Mission    │
    │              │  réouverte   │
    │              │ (autres accepted)│
    │              └──────────────┘
    ▼
┌─────────────────┐
│ Mission réalisée│
└────────┬────────┘
         │
         ▼
   ┌──────────┐
   │completed │
   └──────────┘
```

> **Note juridique :** Le contrat n'est formé qu'à la signature des deux parties. L'entreprise s'engage en premier, éliminant le risque de promesse d'embauche non tenue si elle annule avant de signer.

> **Note compétition :** Dès qu'un prestataire passe en `confirmed`, tous les autres `accepted` passent automatiquement en `rejected`.

---

## Flow 2 : Sollicitation directe par l'entreprise

**Origin : `sourced`**

L'entreprise contacte directement un prestataire (pas de phase de candidature).

```
┌─────────────────┐
│   ENTREPRISE    │
│ sollicite presta│
└────────┬────────┘
         │
         ▼
    ┌─────────┐
    │ sourced │ (équivalent à applied, sans postulation)
    └────┬────┘
         │
         ▼
    ┌─────────┐
    │accepted │ (auto, entreprise a choisi ce presta)
    └────┬────┘
         │
         ▼
┌─────────────────┐
│   PRESTATAIRE   │
│ confirme dispo  │
│ (pas de signature)│
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌─────────┐ ┌────────┐
│confirmed│ │rejected│ (presta décline)
└────┬────┘ └────────┘
     │
     ▼
┌─────────────────┐
│   ENTREPRISE    │
│ signe le contrat│
│   EN PREMIER    │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌───────────────┐ ┌────────┐
│employer_signed│ │rejected│ (entreprise annule)
└───────┬───────┘ └────────┘
        │
        ▼
┌─────────────────┐
│   PRESTATAIRE   │
│ signe le contrat│
│   EN SECOND     │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌────────┐ ┌────────┐
│assigned│ │rejected│ (presta refuse de signer)
└───┬────┘ └────────┘
    │
    ▼
┌─────────────────┐
│ Mission réalisée│
└────────┬────────┘
         │
         ▼
   ┌──────────┐
   │completed │
   └──────────┘
```

---

## Résumé des transitions

| De | Vers | Acteur | Action |
|----|------|--------|--------|
| - | `applied` | Prestataire | Postule à une mission |
| - | `sourced` | Entreprise | Sollicite un prestataire |
| `applied`/`sourced` | `accepted` | Entreprise | Accepte la candidature (peut en accepter plusieurs) |
| `applied`/`sourced` | `rejected` | Entreprise | Refuse la candidature |
| `accepted` | `confirmed` | Prestataire | Confirme sa disponibilité (1er arrivé gagne) |
| `accepted` | `rejected` | Prestataire | Décline la mission |
| `accepted` | `rejected` | Système | Autre candidat a confirmé avant |
| `confirmed` | `employer_signed` | Entreprise | Signe le contrat (1ère signature) |
| `confirmed` | `rejected` | Entreprise | Annule avant de signer (aucun risque juridique) |
| `employer_signed` | `assigned` | Prestataire | Signe le contrat (2ème signature) |
| `employer_signed` | `rejected` | Prestataire | Refuse de signer |
| `employer_signed` | `expired` | Système | Délai de signature dépassé → **avis négatif auto** |
| `expired` | - | Système | Mission réouverte aux autres `accepted` |
| `assigned` | `completed` | Système | Mission terminée |

---

## Avis négatif automatique

### Déclencheur

Un avis négatif est automatiquement créé sur le profil du prestataire quand :

1. **Statut `expired`** : Le presta a confirmé sa dispo, l'entreprise a signé, mais le presta n'a pas signé dans les délais

### Contenu de l'avis automatique

| Champ | Valeur |
|-------|--------|
| Note | 1/5 |
| Auteur | Système (ou entreprise concernée) |
| Commentaire | "Le prestataire n'a pas signé le contrat dans les délais après avoir confirmé sa disponibilité." |
| Type | `no_show_signature` |
| Visible | Oui |

### Impact

- Baisse de la note moyenne du prestataire
- Visible par les entreprises
- Historique conservé

### Cas où l'avis n'est PAS créé

- Le presta décline à l'étape `accepted` → `rejected` (normal, il a le droit)
- L'entreprise annule avant de signer → `rejected` (pas la faute du presta)
- Le presta refuse de signer après `employer_signed` → `rejected` (avis négatif ? à définir)

---

## Sécurité juridique

### Pourquoi ce flow protège la plateforme et l'entreprise

1. **Avant `employer_signed`** : L'entreprise peut annuler sans risque. Aucun contrat n'existe, aucune promesse d'embauche formalisée.

2. **À partir de `employer_signed`** : L'entreprise est engagée. Si le prestataire signe, le contrat est formé. Si le prestataire refuse de signer de mauvaise foi, c'est lui qui porte le risque (jurisprudence Cass. soc. 7 mars 2012).

3. **Traçabilité** : Conserver tous les logs (horodatage création contrat, signatures, confirmations, annulations).

### Clause recommandée dans le contrat généré

```
« Le présent contrat ne prendra effet qu'à la date de signature
électronique des deux parties. La signature de l'employeur vaut
offre ferme de contrat. La signature du salarié vaut acceptation
et formation définitive du contrat. »
```

### En cas d'annulation par l'entreprise après `confirmed` mais avant signature

Envoyer une notification formelle :
- Motif factuel de l'annulation
- Confirmation qu'aucun contrat n'a été signé
- Conservation de la preuve (logs, horodatage)

---

## Comparaison ancien vs nouveau flow

### Ancien flow (risqué)
```
Presta postule → Entreprise accepte → PRESTA SIGNE → Entreprise signe
                                          ↑
                              RISQUE : si entreprise n'a plus besoin,
                              contrat signé unilatéralement = promesse non tenue
```

### Nouveau flow (sécurisé)
```
Presta postule → Entreprise accepte → Presta confirme → ENTREPRISE SIGNE → Presta signe
                                            ↑                    ↑
                                    Pas d'engagement      Entreprise engagée
                                    Annulation libre      Presta peut accepter ou refuser
```

