# Parcours Mission Complet

> De la creation de mission au paiement et notation - tous les cas possibles.

## Vue d'ensemble

```mermaid
flowchart LR
    A["Entreprise\ncree une mission"] --> B["Prestataires\npostulent"]
    B --> C["Entreprise\nchoisit un profil"]
    C --> D{Type de mission}
    D -- Payee --> E["Devis signe\n+ paiement"]
    D -- Benevole --> F["Convention\nsignee"]
    E --> G["Mission\nen cours"]
    F --> G
    G --> H["Rapport\nd'heures"]
    H --> I{Validation}
    I -- OK --> J["Paiement\nfinal"]
    I -- OK --> K["Notation"]
    I -- Litige --> L["Resolution"]
    J --> K
    L --> K
    K --> M(("Termine"))

    style A fill:#e3f2fd,stroke:#1565c0,color:#000
    style B fill:#f3e5f5,stroke:#7b1fa2,color:#000
    style C fill:#e8f5e9,stroke:#2e7d32,color:#000
    style E fill:#fff9c4,stroke:#f9a825,color:#000
    style F fill:#fce4ec,stroke:#c62828,color:#000
    style G fill:#e0f7fa,stroke:#00838f,color:#000
    style H fill:#f1f8e9,stroke:#558b2f,color:#000
    style J fill:#fff9c4,stroke:#f9a825,color:#000
    style K fill:#ede7f6,stroke:#4527a0,color:#000
    style L fill:#fbe9e7,stroke:#d84315,color:#000
    style M fill:#e8f5e9,stroke:#2e7d32,color:#000
```

---

## 1. Schema Fonctionnel

```mermaid
flowchart TD
    subgraph CREATION["CREATION MISSION - Entreprise"]
        A1[Entreprise remplit le formulaire multi-etapes]
        A2{CGV signees ?}
        A3[Modal signature CGV]
        A4[Mission creee - status: open]
        A5[Notifications push aux prestataires matches]

        A1 --> A2
        A2 -- Non --> A3 --> A4
        A2 -- Oui --> A4
        A4 --> A5
    end

    subgraph CANDIDATURE["CANDIDATURE - Prestataire"]
        B1[Prestataire voit la mission]
        B2{Mission benevole ?}

        B3[PostulerDrawer - Payee]
        B3a[1. Dispo + mobilite]
        B3b[2. Objets a apporter]
        B3c[3. Tarif horaire]
        B3d[4. Temps de preparation]
        B3e[5. CGV prestataire]
        B3f[6. Recap devis]

        B4[PostulerDrawer - Benevole]
        B4a[1. Dispo + mobilite]
        B4b[2. Recap]

        B1 --> B2
        B2 -- Payee --> B3 --> B3a --> B3b --> B3c --> B3d --> B3e --> B3f
        B2 -- Benevole --> B4 --> B4a --> B4b
    end

    subgraph DEMARCHAGE["DEMARCHAGE - Entreprise"]
        D1[Entreprise recherche prestataire]
        D2[Envoi proposition directe]
        D3["profile_mission creee - state: demarche"]
        D1 --> D2 --> D3
    end

    subgraph REVIEW["REVUE CANDIDATURES - Entreprise"]
        C1[Voir les profils candidats]
        C2{Decision}
        C3["Rejeter - state: rejected"]
        C4{Mission payee ?}

        C1 --> C2
        C2 -- Refuser --> C3
        C2 -- Accepter --> C4
    end

    subgraph DEVIS["PARCOURS DEVIS - Mission Payee"]
        E1[Entreprise consulte le devis]
        E2["Recap : TJM + jours factures (half-day) + temps prep + frais additionnels"]
        E3[Verification moyen de paiement Stripe]
        E4[Signature OTP entreprise + acceptation CGV prestataire]
        E5{"base_ht >= 800 EUR ?"}
        E6["Charge directe Stripe : acompte 30% TTC (capture_method=automatic)"]
        E7["Aucun prelevement (deposit=0)"]
        E8["state: assigned / Autres candidats: rejected"]
        E9["Facture commission INITIALE → prestataire (recipient_type=provider)"]

        E1 --> E2 --> E3 --> E4 --> E5
        E5 -- Oui --> E6 --> E8
        E5 -- Non --> E7 --> E8
        E8 --> E9
    end

    subgraph CONTRAT_BENEVOLE["PARCOURS CONVENTION - Benevole"]
        F1[Prestataire consulte la convention]
        F2[Signature OTP prestataire]
        F3["state: employer_signed"]
        F4{Multi-participants ?}
        F5[Entreprise selectionne le participant]
        F6[Entreprise consulte la convention]
        F7[Signature OTP entreprise]
        F8["state: assigned"]

        F1 --> F2 --> F3 --> F4
        F4 -- Oui --> F5 --> F6
        F4 -- Non --> F6
        F6 --> F7 --> F8
    end

    subgraph EXECUTION["EXECUTION MISSION"]
        G1["Mission en cours - contract_signed_ongoing"]
        G2[Fin de la mission]
    end

    subgraph RAPPORT["RAPPORT POST-MISSION"]
        H1[Popup rapport prestataire]
        H2[Saisie heures travaillees + heures sup]
        H3[Rapport soumis]
        H4{Entreprise valide ?}
        H5[Rapport approuve]
        H6["Litige ouvert - dispute"]
    end

    subgraph PAIEMENT_FINAL["PAIEMENT FINAL - Payee uniquement"]
        I1[Prestataire soumet son rapport - heures + final_adjustment_lines]
        I2["Apercu de la facture (preview) cote entreprise"]
        I3[Entreprise valide le rapport]
        I4["Capture du PaymentIntent initial (escrow)"]
        I5{"final_adjustments_ht != 0 ?"}
        I6["Pre-auth + capture supp_hours PaymentIntent"]
        I7["Transfer Stripe vers compte Connect prestataire"]
        I8[Facture prestataire + facture commission finale generes]

        I1 --> I2 --> I3 --> I4 --> I5
        I5 -- Oui --> I6 --> I7
        I5 -- Non --> I7
        I7 --> I8
    end

    subgraph NOTE["NOTATION"]
        J1{Mission payee ?}
        J2[Entreprise note le prestataire]
        J3["4 criteres : ponctualite, brief, competences, communication"]
        J4[Commentaire optionnel]
        J5[Prestataire note entreprise]
        J6[Note 1-5 etoiles + commentaire]
        J7["Mission terminee"]

        J1 -- Payee --> J2 --> J3 --> J4 --> J7
        J1 -- Benevole --> J5 --> J6 --> J7
    end

    subgraph ANNULATION["CAS D ANNULATION"]
        K1{Qui annule ?}
        K2{Contrat signe ?}
        K3[Mission annulee sans frais]
        K4[Prestataire paye malgre annulation]
        K5[Retrait prestataire]
        K6[Avertissement suspension]

        K1 -- Entreprise --> K2
        K2 -- Non --> K3
        K2 -- Oui --> K4
        K1 -- Prestataire --> K5 --> K6
    end

    subgraph LITIGE["GESTION LITIGES"]
        L1[Signalement probleme]
        L2[Paiement bloque en escrow]
        L3{Resolution sous 30j ?}
        L4[Resolution manuelle]
        L5[Liberation auto du paiement]

        L1 --> L2 --> L3
        L3 -- Oui --> L4
        L3 -- Non --> L5
    end

    A5 --> B1
    A5 --> D1
    B3f --> C1
    B4b --> C1
    D3 --> C1
    C4 -- Payee --> E1
    C4 -- Benevole --> F1
    E9 --> G1
    F8 --> G1
    G1 --> G2
    G2 --> H1
    H1 --> H2 --> H3 --> H4
    H4 -- Approuve --> H5
    H4 -- Conteste --> H6
    H6 --> L1
    H5 --> I1
    I4 --> J1
    I5 --> J1
    H5 -. Benevole .-> J1

    style CREATION fill:#e3f2fd
    style CANDIDATURE fill:#f3e5f5
    style DEMARCHAGE fill:#fff3e0
    style REVIEW fill:#e8f5e9
    style DEVIS fill:#fff9c4
    style CONTRAT_BENEVOLE fill:#fce4ec
    style EXECUTION fill:#e0f7fa
    style RAPPORT fill:#f1f8e9
    style PAIEMENT_FINAL fill:#fff9c4
    style NOTE fill:#ede7f6
    style ANNULATION fill:#ffebee
    style LITIGE fill:#fbe9e7

```

---

## 2. Schema Technique

### Creation + Candidature

```mermaid
flowchart TD
    A["create-mission.vue"] --> B["CompanyCgvSignatureFlow"]
    B --> C["RPC create_mission_v2"]
    C --> D[("missions.missions\nstatus: open")]
    C --> E["api/notifications/trigger-mission-created"]

    F["prestataire/mission/id.vue"] --> G["PostulerDrawer"]
    G --> H[("missions.profile_missions\nstate: postule")]

    style A fill:#e3f2fd
    style F fill:#f3e5f5
    style D fill:#fff3e0
    style H fill:#fff3e0
```

### Devis + Paiement initial (mission payee)

```mermaid
flowchart TD
    A["entreprise/devis/pmId.vue"] --> B["ContractRecap + DevisSignature"]
    B --> C["POST api/devis/company/verify-otp"]
    C --> D{"OTP valide ?"}
    D -- Oui --> E["Calcul deposit_ttc (30% si base_ht>=800, sinon 0)"]
    E --> F["Stripe PaymentIntent.create capture_method=automatic"]
    F --> G["amount = deposit_ttc - PAS d'application_fee a ce stade"]
    F --> H["transfer_data.destination = compte Connect prestataire"]
    F --> H2["L'acompte est integralement transfere au prestataire"]
    C --> I[("missions.devis\ncompany_signed_at + certificate eIDAS")]
    C --> J[("profile_missions\nstate: assigned")]
    C --> K[("payment_flows\ninitial_status: initial_captured")]

    style A fill:#fff9c4
    style F fill:#e8f5e9
    style I fill:#fff3e0
    style J fill:#fff3e0
    style K fill:#fff3e0
```

### Convention (mission benevole)

```mermaid
flowchart TD
    A["prestataire/contrat/id.vue"] --> B["POST api/contract/provider/verify-otp"]
    B --> C[("contrats\nprovider_signed_at")]
    B --> E[("profile_missions\nstate: employer_signed")]

    F["entreprise/contrat/id.vue"] --> G["POST api/contract/company/verify-otp"]
    G --> H[("contrats\ncompany_signed_at")]
    G --> I[("profile_missions\nstate: assigned")]

    style A fill:#fce4ec
    style F fill:#fce4ec
    style C fill:#fff3e0
    style E fill:#fff3e0
    style H fill:#fff3e0
    style I fill:#fff3e0
```

### Rapport + Paiement final + Notation

```mermaid
flowchart TD
    A["MissionFinishedPopup"] --> B["POST api/missions/provider-submit-report"]
    B --> C[("profile_missions\nreport_submitted_at + final_adjustment_lines")]

    E["Entreprise valide"] --> F["POST api/missions/validate-report"]
    F --> G{Approuve ?}
    G -- Oui --> H["POST api/stripe/release-payment"]
    H --> H2["Capture initial PaymentIntent (escrow)"]
    H2 --> H3{"final_adjustments != 0 ?"}
    H3 -- Oui --> H4["submit-report integre: pre-auth + capture supp"]
    H3 -- Non --> I
    H4 --> I["Transfer vers compte Connect prestataire"]
    I --> J[("payment_flows\nfinal_status: final_captured")]
    I --> J2[("invoices\nPROVIDER + COMMISSION_INITIAL + COMMISSION_FINAL")]
    G -- Conteste --> K[("missions.disputes\nopened_by: company")]
    G -- Conteste --> K2["POST api/stripe/capture-on-dispute"]

    L["RatingProviderDrawer"] --> M["RPC submit_provider_rating"]
    M --> N[("public.ratings")]
    O["RatingCompanyDrawer"] --> P["RPC submit_company_rating"]
    P --> N

    style A fill:#f1f8e9
    style H fill:#fff9c4
    style I fill:#e8f5e9
    style C fill:#fff3e0
    style J fill:#fff3e0
    style K fill:#ffebee
    style N fill:#ede7f6
```

---

## 3. State Machine - profile_missions

```mermaid
stateDiagram-v2
    [*] --> postule: Prestataire candidature spontanee (origin=applied)
    [*] --> demarche: Entreprise demarche un prestataire (payante uniquement)

    demarche --> postule: Prestataire soumet son devis
    demarche --> rejected: Prestataire decline
    demarche --> expired: Timeout sans reponse

    postule --> assigned: Entreprise signe devis + preauth Stripe (payee)
    postule --> accepted: Entreprise retient (benevole, multi-accept)
    postule --> rejected: Entreprise refuse OU autre devis signe

    accepted --> confirmed: Prestataire confirme dispo (benevole, premier arrive)
    accepted --> rejected: Decline / autre presta confirme

    confirmed --> employer_signed: Entreprise signe convention (benevole)
    confirmed --> rejected: Entreprise annule

    employer_signed --> assigned: Prestataire signe convention (benevole)
    employer_signed --> rejected: Prestataire refuse
    employer_signed --> expired: Timeout signature → avis negatif auto

    assigned --> completed: Rapport valide + paiement capture
    assigned --> canceled: Annulation (regle 24h minimum)

    completed --> [*]
    rejected --> [*]
    canceled --> [*]
    expired --> [*]

    note right of assigned
        Payee: PaymentIntent initial en escrow (requires_capture)
        Benevole: 2 signatures OTP (entreprise puis prestataire)
    end note

    note right of canceled
        cancel_mission v2 document-aware :
        - snapshot contrat/devis + payment_flow
        - refund si paiement capture
        - mission peut repasser a 'unassigned' (cf. missions.status)
    end note
```

## 4. State Machine - contrats

```mermaid
stateDiagram-v2
    [*] --> pending_company: Devis/Contrat genere
    pending_company --> pending_provider: Entreprise signe (benevole)
    pending_company --> signed: Entreprise signe + paiement (payante - skip provider)
    pending_provider --> signed: Prestataire signe (benevole)
    pending_company --> expired: Timeout signature
    pending_provider --> expired: Timeout signature
    pending_company --> canceled: Annulation
    pending_provider --> canceled: Annulation
    signed --> [*]
    expired --> [*]
    canceled --> [*]
```

## 5. State Machine - disputes

```mermaid
stateDiagram-v2
    [*] --> pending: Signalement ouvert (provider OU company)
    pending --> in_review: Mediation Gotcha
    in_review --> resolved: Decision (resolution_outcome)
    pending --> resolved: Accord direct entre parties
    pending --> closed: auto_release_at depasse (31j sans resolution)
    resolved --> [*]
    closed --> [*]

    note right of pending
        auto_release_at = opened_at + 31 jours
        Apres : liberation auto du paiement escrow
    end note
```

---

## 4. Modeles de calcul

### Commission Gotcha (13% HT) — modele *absorbed*

Commit `42f78b7` : la commission est **absorbee par le prestataire** (deduite de son montant), pas ajoutee a ce que paye l'entreprise.

```
provider_amount_ht = daily_rate * billing_days
                   + preparation_hours * (daily_rate / 8)
                   + sum(additional_fee_lines.amount_ht)

commission_ht  = provider_amount_ht * 0.13
commission_tva = commission_ht * 0.20
commission_ttc = commission_ht + commission_tva
```

Constantes : `GOTCHA_COMMISSION_RATE_HT = 0.13`, `GOTCHA_TVA_RATE = 0.20` (cf. `utils/payment-amounts.js`).

### Frais de transaction Stripe — egalement absorbes par le prestataire

```
amount_ttc      = provider_amount_ht * (1 + provider_tva_rate)
stripe_fee_ht   = (amount_ttc * 0.015 + 0.25)
stripe_fee_tva  = stripe_fee_ht * 0.20
stripe_fee_ttc  = stripe_fee_ht + stripe_fee_tva
```

Inclus dans `application_fee_amount` Stripe au moment de la capture finale → deduits du transfer au prestataire (modele *absorbed*). Ligne distincte sur la facture de commission (`update_commission_invoice_transaction_fee_ht_tva.sql`).

### Flow Stripe (deux phases)

```
Phase 1 (signature devis) :
  base_ht >= 800 ?
    Oui → PaymentIntent { amount: deposit_ttc, capture_method: 'automatic', application_fee_amount: 0 }
    Non → pas de PaymentIntent
  → l'acompte est integralement transfere au prestataire

Phase 2 (validation rapport) :
  provider_due_ttc = provider_total_ttc - deposit_ttc
  PaymentIntent {
    amount: provider_due_ttc,
    capture_method: 'manual',
    application_fee_amount: commission_ttc + stripe_fee_ttc,
    transfer_data.destination: compte Connect prestataire,
  }
  → capture immediate
  → le prestataire recoit (provider_due_ttc - application_fee_amount)
  → Gotcha encaisse application_fee_amount
```

### Regle demi-journee (billing_days)

```
mono-jour :
  billing_days = ceil(hours / 4) * 0.5
  → 1h-4h = 0.5j, 4.5h-8h = 1j, 8.5h-12h = 1.5j ...

multi-jour :
  billing_days = nombre_jours_de_mission
  (le prestataire peut overrider dans PostulerDrawer)
```

Implementation : `utils/rate-calculation.js` (`billingDaysFromHours`, `canUpgradeBillingDays`).

### Factures generees par mission

Migration : `add_split_commission_invoices.sql` + `update_invoice_insert_v2_for_split_commission.sql`.

| Invoice type | Emetteur | Destinataire | Contenu |
|---|---|---|---|
| `PROVIDER` | Prestataire | Entreprise | TJM × billing_days + prep + additional_fee_lines + final_adjustment_lines (HT/TVA si regime_tva) |
| `COMMISSION_INITIAL` | Gotcha | **Prestataire** (`recipient_type=provider`) | 13% HT sur le devis signe + TVA 20% |
| `COMMISSION_FINAL` | Gotcha | **Prestataire** (`recipient_type=provider`) | 13% HT sur les ajustements finaux (si non nuls) + frais Stripe + TVA |
| `LEGACY_COMMISSION` | Gotcha | Entreprise | Backward compat (avant inversion `42f78b7`) |

RPC : `missions.invoice_insert_v2(p_invoice_data jsonb)` avec `recipient_type` ∈ {`company`, `provider`}.

Depuis commit `42f78b7` ("feat(commission): from company to providers"), les factures de commission Gotcha (initial + final) sont emises vers le prestataire (`recipient_type = "provider"`, `recipient_provider_id` renseigne). C'est lui qui absorbe la commission.

