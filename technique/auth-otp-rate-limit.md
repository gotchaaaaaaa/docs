# Auth OTP rate limits

## Limites actives

- Mot de passe oublie : 5 demandes de code par email et par IP sur 15 minutes.
- Connexion OTP : 5 demandes de code par email et par IP sur 15 minutes.
- Renvoi de code : cooldown de 60 secondes par email.
- Verification de code : limite IP separee, OTP expire au bout de 5 minutes, 3 essais de code maximum par OTP.

## Deblocage support

1. Verifier que la personne controle bien l'adresse email du compte.
2. Lui demander d'attendre le cooldown restant indique dans l'interface.
3. Si le blocage est urgent et confirme comme un rate limit memoire, faire un reload applicatif controle pour vider les limites en memoire.

Ne pas contourner le reset password en modifiant directement le mot de passe utilisateur. Ajouter un endpoint admin seulement si ces incidents deviennent frequents et avec une authentification admin stricte.
