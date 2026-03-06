# Politique de signalement de problèmes — Gotcha

**Date :** Février 2026
**Statut :** Interne — référence pour les CGV et CGU

---

## 1. Ce que Gotcha peut faire (Trust & Safety)

Gotcha agit en tant que **plateforme de mise en relation**. À ce titre, elle peut :

- **Collecter les signalements** → enregistrer les problèmes signalés pour protéger l'intégrité de la plateforme
- **Contacter les parties** → pour comprendre les faits (rôle de "trust & safety", pas de médiation)
- **Sanctionner les bad actors** → suspension ou bannissement de compte en cas de violation avérée des CGU
- **Sécuriser le paiement** → via Stripe Connect (PSP agréé), sans que les fonds ne transitent par Gotcha

Ces actions relèvent de **l'enforcement de ses propres Conditions Générales d'Utilisation**, pas de la médiation.

---

## 2. Ce que Gotcha ne peut PAS faire

| Action interdite | Raison légale |
|-----------------|---------------|
| Trancher qui a raison sur le fond du litige commercial | De l'arbitrage → nécessite un agrément |
| Forcer une résolution entre les parties | De la médiation → nécessite l'agrément CECMC |
| Se qualifier de "médiateur" | Interdit sans agrément CECMC (Ordonnance 2015-1033) |
| Retenir les fonds hors PSP | Encaissement pour compte de tiers → nécessite agrément ACPR |

---

## 3. Référence médiateur externe

Pour les litiges commerciaux entre prestataires et entreprises, les parties sont orientées vers :

**CNPM — Centre National de la Médiation et d'Arbitrage**
[cnpm-mediation-nationale.fr](https://www.cnpm-mediation-nationale.fr)

> À mentionner dans les CGV/CGU comme recours disponible pour les litiges commerciaux.

---

## 4. Mécanique de paiement lors d'un signalement

### Architecture légale

Les fonds ne transitent **jamais** par le compte bancaire de Gotcha.
→ Gotcha utilise **Stripe Connect** (PSP agréé, licencié en Europe) comme agent des fonds.
→ Gotcha se contente d'instruire Stripe sur le timing de libération.
→ Cela n'est **pas du séquestre** (les fonds sont chez Stripe, pas chez Gotcha).

### Flow à l'ouverture d'un signalement

```
Signalement ouvert (prestataire ou entreprise)
        ↓
Capture immédiate Stripe SANS transfer_data
(fonds chez Gotcha/Stripe, pas transférés au prestataire)
        ↓
Signalement visible des deux parties
Lien CNPM fourni pour médiation externe
        ↓
Résolution (max 31 jours)
        ↓
Transfer Stripe manuel vers prestataire (admin Gotcha)
```

### Délai maximum

- Paiement sécurisé maximum **31 jours** (limite technique Stripe `delay_days_override`)
- Passé ce délai : libération manuelle par l'admin via Transfer Stripe
- À terme : job cron automatique (hors scope initial)

### Base légale

- Fonds détenus par Stripe (PSP réglementé PSD2 / ACPR) → Gotcha exempt d'agrément établissement de paiement
  Source : [Pequi - Encaissement pour compte de tiers](https://www.pequi.eu/encaissement-pour-compte-de-tiers-aspects-legaux-pour-une-marketplace/)
- Payout delay jusqu'à 31 jours : fonctionnalité native Stripe Connect
  Source : [Stripe - Manage payout schedule](https://docs.stripe.com/connect/manage-payout-schedule)

---

## 5. Vocabulaire à utiliser

| À éviter | À utiliser |
|----------|-----------|
| "litige" | "signalement de problème" |
| "Notre équipe va examiner" | "Signalement enregistré" |
| "Traité par notre équipe support" | *(ne pas promettre d'examen)* |
| "résolution par Gotcha" | "résolution entre les parties" |
| "médiateur" | "plateforme de mise en relation" |

---

## 6. Mention CGV recommandée

> *En cas de problème survenu lors d'une mission, les parties peuvent soumettre un signalement via la plateforme Gotcha. Ce signalement a pour effet de sécuriser le paiement (fonds détenus par notre prestataire de paiement Stripe) pendant une durée maximale de 31 jours, afin de permettre aux parties de trouver un accord amiable.*
>
> *Gotcha n'intervient pas en qualité de médiateur dans le règlement du différend commercial entre l'entreprise et le prestataire. Les parties sont libres de recourir à un médiateur agréé, tel que le CNPM (Centre National de la Médiation et d'Arbitrage — [cnpm-mediation-nationale.fr](https://www.cnpm-mediation-nationale.fr)).*
>
> *Gotcha se réserve le droit de suspendre ou bannir tout compte en cas de violation avérée de ses Conditions Générales d'Utilisation (comportement abusif, fraude, faux profil).*

---

## 7. Note sur la consultation juridique

Ce document est une référence interne basée sur des recherches publiques.
**Une consultation auprès d'un avocat spécialisé en droit des plateformes / fintech est recommandée** avant finalisation des CGV/CGU, notamment pour :
- Vérifier l'applicabilité des règles B2B vs B2C à votre cas
- Valider la mention médiateur dans les CGV selon l'évolution réglementaire
- Confirmer le statut de Gotcha vis-à-vis de la DSP2/DSP3
