# Moderation des recommandations externes (GT-303)

L'interface de moderation vit dans le repo `admin-dashboard`. Ce document decrit le
contrat des deux endpoints exposes par l'app Gotcha, a appeler avec la signature
HMAC interne (voir `server/utils/internal-auth.js`).

Aucune recommandation n'est publiee automatiquement : tout passe par ces endpoints.

## En-tetes

```
x-internal-timestamp: <epoch secondes>
x-internal-signature: HMAC-SHA256("<timestamp>.", INTERNAL_API_SECRET) en hexa
```

## GET /api/internal/recommendations/pending

Query :

| Parametre | Valeurs | Defaut |
|-----------|---------|--------|
| `status`  | `pending` (file de moderation), `reported` (publiees signalees), `all` | `pending` |
| `limit`   | 1 a 200 | 50 |

Reponse :

```json
{
  "count": 2,
  "recommendations": [
    {
      "id": "uuid",
      "provider_id": "uuid",
      "provider": { "profile_id": "uuid", "first_name": "Marie" },
      "first_name": "Paul",
      "last_name": "Martin",
      "company_name": "Beta Productions",
      "company_name_norm": "beta productions",
      "job_title": "Directeur",
      "recommender_email": "paul@beta-productions.fr",
      "email_domain": "beta-productions.fr",
      "testimonial": "...",
      "context": "Regie festival, juin 2026",
      "status": "pending",
      "reports_count": 0,
      "linked_company_id": null,
      "created_at": "2026-09-18T10:00:00Z"
    }
  ]
}
```

L'email est renvoye en clair : l'admin doit pouvoir verifier la coherence identite /
entreprise, c'est le coeur de la validation. Il n'est jamais affiche publiquement.

## POST /api/internal/recommendations/moderate

| Champ | Type | Notes |
|-------|------|-------|
| `id` | uuid | obligatoire |
| `decision` | `approve` \| `reject` \| `delete` | obligatoire |
| `adminEmail` | string | trace dans `public.admin_audit_log` |
| `reason` | string | obligatoire si `reject` |
| `final` | boolean | `reject` seulement. `true` = fraude : cette entreprise et cet email ne pourront plus soumettre sans nouvelle decision admin, et aucun email de correction n'est envoye |
| `linkedCompanyId` | uuid | `approve` seulement. Rattache la recommandation a une entreprise Gotchaaaa connue : si cette entreprise a aussi laisse un avis, la recommandation cesse de compter pour les badges (la meme relation client ne compte qu'une fois) |

Effets de bord geres par l'app, rien a faire cote admin-dashboard :

- `approve` : publication, email au recommandant (lien vers la recommandation en
  ligne + presentation de Gotchaaaa + inscription entreprise pre-remplie), recalcul
  des badges par trigger ;
- `reject` non definitif : email au recommandant avec le motif et un lien de
  correction (son invitation nominative est rouverte, a defaut le lien generique du
  prestataire) ;
- `delete` : suppression complete, sans historique applicatif (cf. ticket, section 8) ;
- toute decision est tracee dans `public.admin_audit_log`
  (`recommendation_approve` / `recommendation_reject` / `recommendation_delete`).

L'admin ne peut jamais modifier le texte d'une recommandation : l'endpoint n'accepte
que le statut, le motif et le rattachement entreprise.

## Ce que l'admin verifie

1. coherence de l'identite ;
2. coherence de l'entreprise (le domaine email aide, `email_domain`) ;
3. coherence du temoignage ;
4. absence de doublon ou de suspicion d'auto-recommandation.

Les regles d'unicite (1 email = 1 reco, 1 entreprise = 1 reco par prestataire) sont
deja appliquees en base a la soumission : l'admin n'a pas a les reverifier.
