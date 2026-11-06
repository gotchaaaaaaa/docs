Voici les étapes principales (fichiers appelés et leur utilité) pour envoyer une notification “helloworld” à tous les utilisateurs de votre PWA Gotcha! :

1. **Génération des clés VAPID**

   * **Outil** : dans un terminal
   * **Commande** :

     ```bash
     npx web-push generate-vapid-keys --json > vapid-keys.json
     ```
   * **Sortie** : fichier `vapid-keys.json` contenant vos clés publiques/privées VAPID.

2. **Ajout des clés VAPID à la config Nuxt**

   * **Fichier** : `nuxt.config.js`
   * **But** : exposer la clé publique au client et stocker la clé privée côté serveur.
   * **Exemple** :

     ```js
     export default defineNuxtConfig({
       publicRuntimeConfig: {
         vapidPublicKey: process.env.VAPID_PUBLIC_KEY
       },
       privateRuntimeConfig: {
         vapidPrivateKey: process.env.VAPID_PRIVATE_KEY
       },
       modules: ['@vite-pwa/nuxt'],
       pwa: {
         registerType: 'autoUpdate',
         workbox: {
           clientsClaim: true,
           skipWaiting: true
         }
       }
     })
     ```

3. **Enregistrement du Service Worker**

   * **Fichier** : `plugins/pwa-push.client.js`
   * **But** : s’abonner aux notifications dès que la PWA est chargée.
   * **Contenu** (JS pur) :

     ```js
     export default defineNuxtPlugin(async () => {
       if ('serviceWorker' in navigator && 'PushManager' in window) {
         const sw = await navigator.serviceWorker.ready
         const subscription = await sw.pushManager.subscribe({
           userVisibleOnly: true,
           applicationServerKey: atob(useRuntimeConfig().public.vapidPublicKey)
         })
         // envoyer l’objet subscription à votre API
         await $fetch('/api/push/subscribe', {
           method: 'POST',
           body: subscription.toJSON()
         })
       }
     })
     ```

4. **Route API pour enregistrer l’abonnement**

   * **Fichier** : `server/api/push/subscribe.js`
   * **But** : stocker en base l’objet JSON de la subscription pour chaque utilisateur.
   * **Contenu** :

     ```js
     export default defineEventHandler(async (event) => {
       const body = await useBody(event)
       // stocker body (endpoint, keys) en base, lié à l’utilisateur connecté
       await saveSubscriptionForUser(event.context.auth.user.id, body)
       return { success: true }
     })
     ```

5. **Implémentation du Service Worker**

   * **Fichier** : `public/sw.js`
   * **But** : gérer l’événement “push” et afficher la notification.
   * **Contenu** :

     ```js
     self.addEventListener('push', event => {
       const data = event.data.json()
       self.registration.showNotification(data.title, {
         body: data.body,
         icon: '/icon-192.png'
       })
     })
     ```

6. **Exposer le Service Worker dans Nuxt**

   * **Fichier** : clé `workbox.swURL` dans `nuxt.config.js`
   * **Exemple** :

     ```js
     pwa: {
       workbox: {
         swURL: '/sw.js'
       }
     }
     ```

7. **Route API pour envoyer la notification**

   * **Fichier** : `server/api/push/send.js`
   * **But** : parcourir toutes les subscriptions stockées et déclencher `web-push`.
   * **Contenu** :

     ```js
     import webpush from 'web-push'
     export default defineEventHandler(async (event) => {
       const { title, body } = await useBody(event)
       webpush.setVapidDetails(
         'mailto:hello@gotchaaaa.com',
         useRuntimeConfig().public.vapidPublicKey,
         useRuntimeConfig().vapidPrivateKey
       )
       const subs = await getAllSubscriptions()  // depuis votre base
       await Promise.all(subs.map(sub =>
         webpush.sendNotification(sub, JSON.stringify({ title, body }))
       ))
       return { sent: subs.length }
     })
     ```

8. **Planification d’envoi périodique “helloworld”**

   * **Méthode** : crontab externe, Cloud Function ou script Node lancé à l’intervalle voulu.
   * **Exemple simple avec `node-cron`** :

     ```js
     import cron from 'node-cron'
     import fetch from 'node-fetch'
     cron.schedule('* * * * *', async () => {
       await fetch('http://localhost:3000/api/push/send', {
         method: 'POST',
         headers: { 'Content-Type': 'application/json' },
         body: JSON.stringify({ title: 'Hello world', body: 'Ceci est un test' })
       })
     })
     ```

9. **Tests en local**

   * Lancer Nuxt en mode dev :

     ```bash
     VAPID_PUBLIC_KEY=… VAPID_PRIVATE_KEY=… npm run dev
     ```
   * Ouvrir la PWA, accepter les notifications, puis vérifier que votre script cron déclenche l’alerte toutes les minutes.

---

Avec ces fichiers et ces étapes en chaîne, votre PWA Gotcha! s’abonne aux push, stocke les abonnements, et envoie “helloworld” automatiquement chaque minute à tous les utilisateurs. N’hésitez pas si vous avez besoin de détails sur l’une des étapes !
