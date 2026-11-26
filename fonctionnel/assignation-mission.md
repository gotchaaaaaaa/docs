# Flow d'assignation des missions

> Derniere mise a jour : Mai 2026



## Contexte juridique

L'ordre de signature et la nature du document contractuel varient selon le type de mission.

**Missions payantes :** Le devis est le document contractuellement engageant. Seule l'entreprise le signe (via OTP). La signature déclenche immédiatement le paiement Stripe et l'assignation. Ce modèle évite tout risque de requalification du lien commercial.

**Missions bénévoles :** La convention de bénévolat est signée par les deux parties. L'entreprise signe en premier — le prestataire ne reçoit le document à signer qu'une fois l'entreprise engagée. Cela élimine tout risque de "promesse d'embauche non tenue" (art. L.1242-12 du Code du travail).

---

## Deux flows distincts selon le type de mission

### Missions payantes (`is_paid: true`)

**Machine d'états simplifiée :**

```
[sollicitation directe]        [candidature spontanée]
          |                              |
          v                              v
       demarche                       postule
          |                              |
          |-- [PostulerDrawer] ------> postule
          |-- [déclin]        -------> rejected
          |-- [timeout]       -------> expired

                                       postule
                                          |
                         [signature devis + OTP + Stripe]
                                          |
                              ┌───────────┴───────────┐
                              v                       v
                           assigned               rejected
                              |
                    ┌─────────┴─────────┐
                    v                   v
                completed           canceled
```

**Points clés :**
- Les états `accepted`, `confirmed` et `employer_signed` n'existent **pas** pour les missions payantes
- Pas de contrat de prestation — le **devis** (taux horaire, temps de préparation, CGV) est le seul document
- Une seule signature (entreprise) suffit pour finaliser l'assignation
- Le paiement Stripe est déclenché au moment de la signature du devis
- Tous les autres candidats passent automatiquement à `rejected` lors de la signature

---

### Missions bénévoles (`is_paid: false`)

**Machine d'états complète (inchangée) :**

```
postule
    |
    |-- [accepté]  --> accepted
    |-- [rejeté]   --> rejected
                        |
                     accepted
                        |
                        |-- [confirmation presta, 1er arrivé] --> confirmed
                        |-- [déclin presta]                   --> rejected
                        |-- [autre presta confirmé avant]     --> rejected
                                |
                             confirmed
                                |
                                |-- [signature entreprise] --> employer_signed
                                |-- [annulation entreprise]--> rejected
                                            |
                                      employer_signed
                                            |
                                            |-- [signature presta]        --> assigned
                                            |-- [refus presta]            --> rejected
                                            |-- [délai dépassé - système] --> expired
                                                                                |
                                                                          + avis négatif auto
                                                assigned
                                                    |
                                                completed
```

**Points clés :**
- Multi-accept possible : l'entreprise peut accepter plusieurs candidats, le premier à confirmer remporte la mission
- Convention de bénévolat signée par les deux parties (entreprise en premier)
- Délai de signature : si `employer_signed` expire sans signature prestataire → `expired` + avis négatif automatique

---

## État `demarche` (missions payantes uniquement)

Lorsqu'une entreprise sollicite directement un prestataire, un `profile_mission` est créé avec :
- `state: 'demarche'`
- `origin: 'sourced'`

Le prestataire reçoit une notification push. Il peut alors :
- **Soumettre son devis** via PostulerDrawer → état `postule`
- **Décliner** → état `rejected` (aucune sanction)
- **Ne pas répondre** → état `expired` (timeout système)

Les candidatures spontanées ont `origin: 'applied'` et démarrent directement à `postule`.

---

## Tables de transitions

### Missions payantes

| De | Vers | Acteur | Action |
|----|------|--------|--------|
| — | `demarche` | Entreprise | Sollicite directement un prestataire |
| — | `postule` | Prestataire | Candidature spontanée via PostulerDrawer |
| `demarche` | `postule` | Prestataire | Répond à la sollicitation via PostulerDrawer |
| `demarche` | `rejected` | Prestataire | Décline la sollicitation (pas de sanction) |
| `demarche` | `expired` | Système | Timeout sans réponse du prestataire |
| `postule` | `assigned` | Entreprise | Signe le devis (vérification OTP → charge Stripe) |
| `postule` | `rejected` | Entreprise | Rejette la candidature OU un autre devis a été signé |
| `assigned` | `completed` | Système | Rapport de mission validé |
| `assigned` | `canceled` | Système | Mission annulée |

### Missions bénévoles

| De | Vers | Acteur | Action |
|----|------|--------|--------|
| — | `postule` | Prestataire | Candidature via PostulerDrawer |
| `postule` | `accepted` | Entreprise | Accepte la candidature (multi-accept possible) |
| `postule` | `rejected` | Entreprise | Rejette la candidature |
| `accepted` | `confirmed` | Prestataire | Confirme sa disponibilité (premier arrivé gagne) |
| `accepted` | `rejected` | Prestataire | Décline |
| `accepted` | `rejected` | Système | Un autre candidat a confirmé en premier |
| `confirmed` | `employer_signed` | Entreprise | Signe la convention (première signature) |
| `confirmed` | `rejected` | Entreprise | Annule avant signature |
| `employer_signed` | `assigned` | Prestataire | Signe la convention (deuxième signature) |
| `employer_signed` | `rejected` | Prestataire | Refuse de signer |
| `employer_signed` | `expired` | Système | Délai de signature dépassé → avis négatif automatique |
| `assigned` | `completed` | Système | Mission terminée |

---

## Protection contre les race conditions (missions payantes)

Une seule assignation possible par mission payante, garantie à deux niveaux :

**Niveau base de données :**
```sql
-- Index unique : un seul prestataire assigné par mission payante
CREATE UNIQUE INDEX ON missions.profile_missions (mission)
  WHERE state = 'assigned';
```

**Niveau API :**
- Utilisation de `SELECT ... FOR UPDATE` dans la transaction `verify-otp`
- Garantit qu'une seule requête concurrente peut aboutir

En cas de race condition, seule la première requête réussit — les autres reçoivent une erreur et restent à `postule`.

---

## Champ `origin`

| Valeur | Signification |
|--------|---------------|
| `applied` | Candidature spontanée du prestataire |
| `sourced` | Sollicitation directe par l'entreprise |

Ce champ permet de distinguer les deux modes d'entrée dans le flow et d'adapter l'interface (notamment l'affichage du drawer et les notifications).

---

## Avis négatif automatique (missions bénévoles)

Un avis négatif est automatiquement créé sur le profil du prestataire lorsque son état passe à `expired` (délai de signature dépassé après `employer_signed`).

| Champ | Valeur |
|-------|--------|
| Note | 1/5 |
| Commentaire | "Le prestataire n'a pas signé le contrat dans les délais après avoir confirmé sa disponibilité." |
| Type | `no_show_signature` |
| Visible | Oui |

Cet avis n'est **pas** déclenché si le prestataire décline à l'étape `accepted` (droit normal) ni si l'entreprise annule avant de signer.

---

## Annulation (cancel_mission v2 — document-aware)

Migration : `cancel_mission.sql` + `009-cancel-mission-document-aware.sql`. RPC : `missions.cancel_mission(p_profile_mission_id, p_cancel_type, p_user_id)`.

**Regle 24h** : impossible d'annuler moins de 24h avant `start_time`.

| Acteur | Etat actuel | Effet |
|--------|-------------|-------|
| Prestataire | `assigned` | mission → `unassigned`, contrat → `canceled`, refund integral, candidatures rouvertes |
| Entreprise | `postule`/`accepted`/`confirmed`/`assigned` | mission → `canceled`, tous profile_missions → `canceled`, refund integral |

**Document-aware** : un enregistrement est cree dans `providers.cancellation_logs` avec :
- `document_metadata` (snapshot : `contract_id`, `contract_pdf_path`, `contract_hash`, `devis_id`, `has_signature`)
- `payment_snapshot` (snapshot : `payment_flow_id`, `initial_status`, `final_status`, `captured_amount_cents`, `refund_amount_cents`)

Si paiement deja capture → Stripe Refund vers la CB de l'entreprise.

---

## Signalements / Disputes

Migration : `add_mission_report_and_disputes.sql` + `add_dispute_signalement_columns.sql` + commit `0cda107`.

| Initiateur | Endpoint | Quand | Statut initial |
|-----------|----------|-------|----------------|
| Prestataire | `POST /api/missions/open-problem-report` | En cours OU fin de mission | `pending` |
| Entreprise | `POST /api/missions/open-problem-report` (via OpenDisputeDrawer) | A la validation du rapport prestataire | `pending` |

Motifs (`disputes.reason`) : `hours_disagreement`, `payment_issue`, `quality_issue`, `no_show`, `other`.

Table `missions.disputes` :
- `opened_by` ∈ {`provider`, `company`}, `opened_by_profile`
- `disputed_hours_worked`, `disputed_hours_supp` (si motif hours)
- `status` : `pending` → `in_review` → `resolved` (+ `resolution_outcome`) ou `closed`
- `auto_release_at = opened_at + 31 jours` : apres 31j sans resolution, liberation auto de l'escrow
- `stripe_dispute_pi_id` : reference au PaymentIntent retenu

Endpoint capture en cas de dispute (Gotcha tranche en faveur de l'entreprise) : `POST /api/stripe/capture-on-dispute`.

RPC : `missions.open_dispute(...)`, `missions.get_dispute_for_mission_v2(p_profile_mission_id)`.

---

## Rapport de mission (provider-first)

Flow actuel (depuis Mars 2026) :

1. **Prestataire** soumet son rapport via `POST /api/missions/provider-submit-report` :
   - `hours_worked`, `hours_supp` (heures reellement travaillees)
   - `final_adjustment_lines` (frais supplementaires post-mission)
   - `provider_invoice_number` (numero unique annuel)
2. Etats : `profile_missions.report_submitted_at`, `provider_validation_status = 'approved'`, `payment_status = 'awaiting_company_payment'`
3. **Entreprise** consulte le rapport + apercu facture (`/api/invoices/preview`) :
   - **Valide** → `POST /api/missions/validate-report` puis `POST /api/stripe/release-payment` (capture escrow + transfer)
   - **Conteste** → ouverture d'un dispute, paiement bloque

Cron de relance :
- `/api/cron/company-report-followup` : email entreprise si rapport pendant
- `/api/cron/auto-validate-reports` : auto-validation apres delai
- `/api/cron/auto-default-ratings` : note neutre auto si pas de rating
