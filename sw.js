const CACHE = 'margem-v5';
const ASSETS = ['./', './index.html', './icon.svg', './manifest.json', './apple-touch-icon.png'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(ASSETS)));
  self.skipWaiting();
});

self.addEventListener('activate', e => {
  e.waitUntil(caches.keys().then(ks =>
    Promise.all(ks.filter(k => k !== CACHE).map(k => caches.delete(k)))
  ));
  self.clients.claim();
});

self.addEventListener('fetch', e => {
  if (e.request.method !== 'GET') return;
  if (!e.request.url.startsWith(self.location.origin)) return; // deixa Supabase e CDNs passarem
  e.respondWith(
    // no-cache: revalida com o servidor (ETag) em vez de confiar no cache HTTP de 10min do Pages
    fetch(e.request, { cache: 'no-cache' }).then(res => {
      if (res.ok) {
        const cl = res.clone();
        caches.open(CACHE).then(c => c.put(e.request, cl));
      }
      return res;
    }).catch(() => caches.match(e.request))
  );
});
