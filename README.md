# Gotcha - Documentation

Bienvenue sur la documentation de **Gotcha**, la plateforme de mise en relation entre prestataires et entreprises pour des missions urgentes.

> Derniere mise a jour : **Mai 2026**

---

## Changements recents majeurs (avril-mai 2026)

| Date | Changement | Migration / Commit |
|------|-----------|-------------------|
| 12/05 | Field whitelisting strict sur endpoints onboarding (anti mass-assignment) — inline dans chaque endpoint, pas de helper central | `f2ca900` (ex. `server/api/provider/save-onboarding.post.js:42`) |
| 03/05 | **Inversion du payeur de la commission** : la commission est desormais absorbee par le prestataire (modele `buildAbsorbedFeeChargeAmounts`), plus ajoutee a ce que paye l'entreprise. La facture de commission est emise vers le prestataire (`recipient_type = 'provider'`) | `42f78b7` + `add_split_commission_invoices.sql` |
| 01/05 | Clustering des prestataires sur la carte Mapbox | `6f684e0` |
| 30/04 | Le prestataire peut ouvrir un signalement | `0cda107` + `add_mission_report_and_disputes.sql` |
| 29/04 | Multi-jour : table `mission_schedules` + RPC `create_mission_v2` etendue | `67777a1` + `add_multi_day_missions.sql` |
| 27/04 | TJM clamp par defaut au minimum dans le PostulerDrawer | `7973f2e` |
| 26/04 | PostulerDrawer : choix du palier `billing_days` (half-day) | `d2fec2c` |
| 24/04 | IP de signature chiffree en base + wording utilisateur | `ac6ebba` |
| 23/04 | Additional fees en fin de mission (facture commission finale) | `6865da7` |
| 22/04 | Commission migree de 12.5% TTC a **13% HT** + frais Stripe HT/TVA | `acca872` + `provider_commission_model_13_percent.sql` |
| 21/04 | Additional fees sur devis & invoices | `9e80692` |
| 20/04 | Badge "Disponible maintenant" sur la carte entreprise | `c83af91` + `add_provider_available_now_indicator.sql` |
| 19/04 | Regle demi-journee (half-day billing) en SQL et JS | `2f63c39` + `update_billing_to_half_day_rule.sql` |
| 18/04 | Photo de profil : upload avec validation + compression HEIC | `15a643b` |
| 06/04 | Heures supp pre-auth + capture separee | `fix(invoicing): additionnal fees at the end of the mission` |

---

## Sujets critiques

| Sujet | Fonctionnel | Technique |
|-------|:-----------:|:---------:|
| **Contrats** | [Fonctionnement](critique/contrats/fonctionnement.md) | [Technique](critique/contrats/technique.md) |
| **Paiement** | [Fonctionnement](critique/paiement/fonctionnement.md) ⚡ MAJ | [Technique](critique/paiement/technique.md) ⚡ MAJ |
| **Facturation** | [Fonctionnement](critique/facturation/fonctionnement.md) ⚡ MAJ | [Technique](critique/facturation/technique.md) ⚡ MAJ |

[Etat d'implementation](critique/etat-implementation.md) - Ce qui est en place vs ce qui reste a faire.

---

## Fonctionnel

- [Presentation du projet (CGU/CGV)](fonctionnel/presentation-cgu-cgv.md)
- [Parcours prestataire](fonctionnel/parcours-prestataire.md)
- [Assignation des missions](fonctionnel/assignation-mission.md)
- [Glossaire](fonctionnel/glossaire.md) ⚡ MAJ (commission 13%, escrow, half-day, multi-day, additional fees, disputes, available now)

---

## Technique

- [**Changements Q2 2026** (synthese technique)](technique/changements-2026-q2.md) ⭐ NOUVEAU
- [Parcours mission complet (mermaid)](technique/parcours-mission-complet.md) ⚡ MAJ
- [State machine missions (mermaid)](technique/mission-state-machine.mmd) ⚡ MAJ
- [Diagramme fonctionnel mission](technique/mission-fonctionnel.mmd) ⚡ MAJ
- [Diagramme technique mission](technique/mission-technique.mmd)
- [Architecture BDD (JSON)](technique/bdd/database-architecture.json) — source de verite
- [Composants partages](technique/shared-components.md) ⚡ MAJ (clustering, PostulerDrawer 7 etapes, photo upload, tutorial)
- [APIs externes](technique/apis-externes.md)
- [User object](technique/user-object.json)
- [Notifications push & PWA](technique/notifications-push-pwa.md)
- [Securite & chiffrement](technique/securite/encryption-roadmap.md) | [Files](technique/securite/file-encryption.md)
- [Infrastructure & deploiement](technique/infra/deploiement.md) | [Crontab](technique/infra/crontab.md) | [SECURITY-ROTATION](technique/infra/SECURITY-ROTATION.md)
- [Plan implementation CGV entreprise SES](technique/plan-implementation-cgv-entreprise-ses.md)

---

## Conventions de wording

- **Prestataire** = "provider" (jamais "candidat" en interne, jamais "candidature" en UI)
- **Entreprise** = "company"
- **Mission** = "Mission" (jamais "offre d'emploi")
- **Devis** = document commercial signe par l'entreprise pour missions payantes
- **Convention de benevolat** = document signe par les 2 parties pour missions benevoles
- **NE JAMAIS** utiliser un wording d'agence d'interim (cf. risques juridiques) : pas de "embaucher", "contrat de travail", "candidat", "offre", "postuler" en UI publique
