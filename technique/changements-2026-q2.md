# Changements Q2 2026 — synthese technique

> Derniere mise a jour : Mai 2026

Synthese des fonctionnalites livrees entre avril et mai 2026, avec pointeurs vers code et migrations. A lire avant toute modification touchant a la facturation, au paiement, aux missions ou au PostulerDrawer.

---

## 1. Modele de commission (13% HT) — INVERSION du payeur

**Migrations** : `provider_commission_model_13_percent.sql`, `update_commission_invoice_transaction_fee_ht_tva.sql`, `add_split_commission_invoices.sql`, `update_invoice_insert_v2_for_split_commission.sql`
**Commits** : `acca872`, `fd850b6`, `6865da7`, **`42f78b7` "feat(commission): from company to providers"**

### Avant (jusqu'a mars 2026)
- Commission **12.5% TTC** ajoutee a ce que paye l'entreprise (l'entreprise voyait `provider_ttc + commission_ttc`)
- Facture de commission emise vers l'entreprise
- Frais Stripe absorbes par Gotcha
- Une seule facture de commission par mission

### Apres (depuis avril-mai 2026)
- Commission **13% HT** + TVA 20% en sus (`GOTCHA_COMMISSION_RATE_HT = 0.13`)
- **Modele *absorbed*** (`buildAbsorbedFeeChargeAmounts`) : la commission est **deduite du montant prestataire**, pas ajoutee au prix paye par l'entreprise
- L'entreprise paie strictement le TTC prestataire ; Stripe retient la commission via `application_fee_amount` lors du transfer Connect
- Facture de commission emise par Gotcha **vers le prestataire** (`recipient_type = 'provider'`, `recipient_provider_id`)
- Frais Stripe egalement absorbes par le prestataire (inclus dans `application_fee_amount`) ; ligne distincte sur la facture de commission (`stripe_fee_amount`)
- **Split commission** : 2 factures de commission possibles
  - `COMMISSION_INITIAL` : a la signature du devis, basee sur `devis_total_ht`
  - `COMMISSION_FINAL` : a la validation du rapport si `final_adjustments_ht != 0`

### Resultat economique
```
Entreprise paie total     = provider_total_ttc           (idem qu'avant si on enleve l'ancienne ligne commission)
Prestataire recoit net    = provider_total_ttc - commission_ttc - stripe_fee_ttc
Gotcha encaisse net       = commission_ht + commission_tva - frais bancaires reels Stripe
```

### Fichiers
- `utils/payment-amounts.js` (`buildAbsorbedFeeChargeAmounts`, `buildGotchaCommissionAmounts`, `computeStripeFee`, constantes)
- `utils/commission-invoice-amounts.js`
- `server/utils/payment-flow.js` (`computeInitialPayment`, `computeFinalPayment`)
- `server/api/invoices/generate.post.js` (`recipient_type: "provider"`)
- `server/api/stripe/release-payment.js` (`application_fee_amount = platformCommissionCents + stripeFeeCents`)
- RPC : `missions.invoice_insert_v2(p_invoice_data jsonb)` avec `recipient_type`

---

## 2. Flow de paiement en 2 phases (acompte 30% conserve)

**Migrations** : `add_escrow_payment_columns.sql`, `add_non_escrow_payment_flows.sql`

### Le modele actuel (corrige Mai 2026)

L'acompte 30% / seuil 800 EUR HT est **toujours actif** (constantes dans `server/utils/payment-flow.js`) :
```js
DEPOSIT_RATE: 0.3,
DEPOSIT_THRESHOLD_HT: 800,
```

**Phase 1 — Signature du devis** (`server/api/devis/company/verify-otp.post.js`) :
- Si `base_ht >= 800 EUR` : `deposit_ttc = base_ttc * 30%`, sinon `deposit_ttc = 0`
- `PaymentIntent` avec `capture_method: 'automatic'` (charge directe, **pas** d'escrow)
- L'acompte est preleve immediatement et transfere au prestataire (pas d'application fee)

**Phase 2 — Validation du rapport** (`server/api/stripe/release-payment.js`) :
- `PaymentIntent` avec `capture_method: 'manual'` (pre-auth) pour `provider_due_ttc = provider_total_ttc - deposit_ttc`
- `application_fee_amount = commission_ttc + stripe_fee_ttc` → Gotcha encaisse sa commission sur le HT total ici
- Capture immediate
- Si `final_adjustments_ht != 0` : le flow de pre-auth/capture supplementaire est **integre** dans `/api/missions/submit-report.post.js` (l'endpoint `/api/stripe/create-supp-hours-preauth` est marque comme **obsolete** et renvoie une erreur, cf. son contenu actuel)

**Colonnes payment_flows / profile_missions** : `escrow_captured_at`, `escrow_amount`, `transfer_id`, `refund_amount`, `refund_id`, `supp_hours_payment_intent_id`, `supp_hours_escrow_captured_at`, `supp_hours_transfer_id`, `final_amount_cents`, `final_provider_amount_cents`, `final_platform_amount_cents`, `stripe_fee_final_cents`.

---

## 3. TJM + regle demi-journee

**Migrations** : `migrate_to_tjm.sql`, `update_billing_to_half_day_rule.sql`, `2f63c39`

### Concepts
- Facturation au **TJM HT** (1 jour = 8h, `HOURS_PER_DAY` dans `utils/rate-calculation.js`)
- `profile_missions.daily_rate` et `daily_rate_supp` (defaut `daily_rate * 1.25`)
- Regle demi-journee : `billing_days = ceil(hours / 4) * 0.5`
  - 1h-4h → 0.5j, 4.5h-8h → 1j, 8.5h-12h → 1.5j, etc.
- Multi-jour : `billing_days = nombre de jours de mission`

### Implementation
- `utils/rate-calculation.js` (`billingDaysFromHours`, `canUpgradeBillingDays`, `tjmToHourly`, `hourlyToTjm`)
- Dans le PostulerDrawer (etape TJM), le prestataire peut **overrider** le palier (commit `d2fec2c`) — typiquement choisir 1j au lieu du 0.5j calcule
- Le TJM est **clampe** par defaut au minimum du prestataire (commit `7973f2e`)

---

## 4. Multi-day missions

**Migration** : `add_multi_day_missions.sql`, `update_create_mission_v2_preparation.sql`
**Commit** : `67777a1`

### Modele
- `missions.missions.is_multi_day` (boolean), `start_date`, `end_date`
- Table `missions.mission_schedules` :
  - `mission_id`, `schedule_date`, `start_time`, `end_time`
  - UNIQUE(mission_id, schedule_date)

### RPC
```sql
missions.create_mission_v2(
  ...,
  p_schedules JSONB DEFAULT '[]'::JSONB,
  p_has_preparation_time BOOLEAN DEFAULT FALSE,
  p_preparation_hours DECIMAL DEFAULT NULL
)
```

Format `p_schedules` :
```json
[
  { "date": "2026-05-20", "start_hour": 8, "start_minute": 0, "end_hour": 17, "end_minute": 0 }
]
```

### Front
- `pages/entreprise/create-mission.vue` : `StepDate` + `StepTime` adaptes
- `composables/useMissionDraft.js` : draft persiste localStorage
- `shared/mission-schedule-utils.js` : helpers de normalisation
- `composables/useProviderSignedMissionSlots.js` : affichage multi-jour cote prestataire

---

## 5. Additional fees et Final adjustments

**Migration** : `add_additional_fee_lines.sql`, `add_final_invoice_adjustments.sql`
**Commits** : `9e80692`, `6865da7`

### `additional_fee_lines` (sur le devis)
- Ajoutes par le prestataire dans le PostulerDrawer (etape 5)
- JSONB `[{ description: string, amount_ht: number }]`
- Limites : max 20 lignes, description 160 chars, amount > 0, max 2 decimales
- Total : `profile_missions.additional_fees_ht`
- Validation : `utils/additional-fees.js` (`validateAdditionalFeeLines`)

### `final_adjustment_lines` (sur le rapport)
- Ajoutes par le prestataire a la soumission de son rapport
- Memes regles (max 20 lignes, etc.), mais le montant peut etre **negatif** (avoir/penalite)
- Total : `profile_missions.final_adjustments_ht`
- Generent la facture de commission FINALE

---

## 6. Provider clustering on map

**Commit** : `6f684e0`

- Implementation **custom pixel-based** (PAS le clustering natif Mapbox GeoJSON) dans `pages/map/search-provider.vue`
- Seuil : `CLUSTER_PX_THRESHOLD = 50` pixels (`pages/map/search-provider.vue:505`)
- Algo : pour chaque provider non encore assigne, on projette sa position en pixels (`map.project()`) et on regroupe ceux dont la distance ecran < 50px
- Barycentre = moyenne lat/lng du groupe
- Markers DOM custom (photo provider stackee + badge count), pas des layers Mapbox `cluster`/`unclustered`
- Click cluster → calcul du zoom auquel il se desagrege effectivement (`findClusterBurstZoom`) puis `map.flyTo`
- Diff-based : reutilise les markers entre 2 reclusters via `clusterKey(group)` pour eviter le fade-out des photos
- Cache des photos signees (`getFile`) entre reclusters
- RPC backend : `public.get_providers_for_map_v3` (renvoie `is_available_now`, etc.)

---

## 7. Available now indicator

**Migration** : `add_provider_available_now_indicator.sql`
**Commit** : `c83af91`

- RPC `providers.is_provider_available_now(p_provider_id, p_now)` :
  - `profiles.available = true` ET `profiles.visible_on_map = true`
  - Au moins un creneau `availabilities` couvre `p_now`
- Affichage badge vert "Disponible maintenant" sur `ProviderCard` de la carte entreprise
- `utils/providerAvailabilityNow.js` : helper client

---

## 8. Disputes / Signalements

**Migrations** : `add_mission_report_and_disputes.sql`, `add_dispute_signalement_columns.sql`
**Commit** : `0cda107`

### Table `missions.disputes`
- `profile_mission`, `opened_by` (`provider`/`company`), `opened_by_profile`
- `reason` (`hours_disagreement`, `payment_issue`, `quality_issue`, `no_show`, `other`)
- `description`, `disputed_hours_worked`, `disputed_hours_supp`
- `status` (`pending`, `in_review`, `resolved`, `closed`)
- `resolution_outcome` (`company_favor`, `provider_favor`, `compromise`, `canceled`)
- `auto_release_at = opened_at + 31 jours` → liberation auto si pas de resolution
- `stripe_dispute_pi_id` : ref PaymentIntent retenu

### Endpoints
- `POST /api/missions/open-problem-report`
- `GET /api/missions/dispute/[pmId]` (RPC `get_dispute_for_mission_v2`, decryption des noms)
- `POST /api/stripe/capture-on-dispute` (internal auth, capture en cas de tranche en faveur entreprise)

### Provider-initiated (nouveau)
Le prestataire peut ouvrir un signalement en cours ou en fin de mission (avant c'etait reserve a l'entreprise).

---

## 9. Document-aware cancellation

**Migration** : `009-cancel-mission-document-aware.sql`, `cancellation_system_v2.sql`

RPC : `missions.cancel_mission(p_profile_mission_id, p_cancel_type, p_user_id)` retourne :
```json
{
  "success": true,
  "profile_mission_id": "...",
  "mission_id": "...",
  "payment_intent_id": "pi_...",
  "payment_status": "released" | "refunded" | "voided"
}
```

Table `providers.cancellation_logs` :
- `document_metadata` (snapshot : `contract_id`, `contract_pdf_path`, `contract_hash`, `devis_id`, `has_signature`)
- `payment_snapshot` (snapshot : `payment_flow_id`, `initial_status`, `final_status`, `captured_amount_cents`, `refund_amount_cents`)

Regle 24h : annulation impossible moins de 24h avant `start_time`.

---

## 10. Security : field whitelisting (anti mass-assignment)

**Commit** : `f2ca900` (12/05/2026)

- **Pas de helper centralise** (`server/utils/security-whitelist.js` n'existe pas) — le whitelist est applique **inline** dans chaque endpoint d'onboarding
- Pattern typique (`server/api/provider/save-onboarding.post.js:42`) :
  ```js
  // SECURITY: Strict whitelist of fields writable via this endpoint.
  const ALLOWED_FIELDS = [...];
  // ...
  // Filter body to whitelist only
  const safeBody = Object.fromEntries(Object.entries(body).filter(([k]) => ALLOWED_FIELDS.includes(k)));
  ```
- Endpoints concernes :
  - `POST /api/auth/signup` : champs auth
  - `PATCH /api/me/profile` : champs profil (first_name, last_name, email, phone, birth_date, photo, etc.)
  - `POST /api/provider/save-onboarding` : champs prestataire
  - `POST /api/company/save-onboarding` : champs entreprise
- Tout champ non liste est silencieusement ignore

---

## 11. Photo de profil

**Commit** : `15a643b`

- Endpoint : `POST /api/upload` (formidable, validation MIME + taille)
- Compression client : maxWidth 1200px, quality 0.8 (canvas resize)
- **Support HEIC/HEIF iPhone** : `computedAcceptTypes` dans `SelectFile.vue` ajoute `.heic,.heif`
- Stockage : Supabase Storage `profiles/{profileId}/photo.{ext}`
- Update profil : `PATCH /api/me/profile` avec `photo: file_id`

---

## 12. Tutorial onboarding

**Migration** : `add_tutorial_completed.sql`

- Flag `profiles.tutorial_completed` (boolean)
- Composable `composables/useTutorial.js` + composants `Tutorial*.vue`
- Declenche apres `done_onboarding = true` si `tutorial_completed = false`
- Spotlight + tooltip steps par role (provider / company)
- Marquer comme fait : `PATCH /api/me/profile { tutorial_completed: true }`

---

## 13. IP de signature chiffree

**Commit** : `ac6ebba`

- L'IP de l'utilisateur lors de la signature est **chiffree** en base (AES-256-GCM)
- Wording explicite affiche a l'utilisateur lors de la signature ("Votre adresse IP sera chiffree en base pour proteger votre vie privee")
- Champs concernes : `contrats.provider_signature_ip`, `company_signature_ip`, idem sur `devis` et `cgv_signatures`

---

## 14. PostulerDrawer refondu (7 etapes)

**Commits** : `d2fec2c`, `7973f2e`, `fbbcde8`, `9e80692`, `6865da7`

Refonte complete pour missions payantes :
1. Disponibilite + transport
2. Materiel a apporter (checklist)
3. Temps de preparation (toggle si mission sans prep)
4. **TJM** (clamp min/max + choix `billing_days` si demi-palier)
5. **Frais additionnels** (`additional_fee_lines`)
6. CGV
7. Recap avec **preview PDF du devis** + display commission 13% HT + TVA + net cash TTC + saisie `devis_number`

Submission → `POST /api/missions/apply` :
```json
{
  "mission_id", "daily_rate", "daily_rate_supp", "billing_days",
  "preparation_hours", "additional_fee_lines", "devis_number", "cgv_file_path"
}
```

Validation `devis_number` (`utils/devis-number.js`) : regex `/^[A-Za-z0-9][A-Za-z0-9 ._/-]{0,39}$/`, 40 chars max.

---

## 15. Endpoints API : whitelisting et BFF

Tous les endpoints API serveur appliquent maintenant :
- `verifyUserAuth(event)` ou `verifyInternalAuth(event)` (HMAC pour cron/internal)
- Whitelist strict des champs d'entree
- Dechiffrement BFF des donnees sensibles (jamais expose au front)
- Re-chiffrement avant ecriture en DB

Liste complete des endpoints : voir `documentation/technique/parcours-mission-complet.md` section 3.3 + l'inventaire dans `documentation/README.md`.

---

## A faire / dette technique

- [ ] Regenerer `documentation/technique/bdd/database-architecture.json` apres chaque batch de migrations (`get-bdd-archi.sql`)
- [ ] Audit RLS sur les nouvelles tables (`disputes`, `mission_schedules`, `cancellation_logs`)
- [ ] Cleanup des champs legacy `payment_flows` lies a l'ancien modele de commission ajoutee (avant `42f78b7`)
- [ ] Plateforme Agreee facturation electronique (Sept. 2026 → 2027) — voir `documentation/critique/facturation/analyse-conformitee-facturation.md`
