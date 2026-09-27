// Service worker minimal : rend l'application installable (PWA).
// Aucune mise en cache : les données viennent toujours de l'API en ligne,
// et chaque déploiement Vercel est visible immédiatement.
self.addEventListener('install', () => self.skipWaiting())
self.addEventListener('activate', (event) => event.waitUntil(self.clients.claim()))
self.addEventListener('fetch', () => {})
