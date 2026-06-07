const CACHE = 'margem-v2';
const ASSETS = ['./', './index.html', './icon.svg', './manifest.json'];

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
    fetch(e.request).then(res => {
      if (res.ok) {
        const cl = res.clone();
        caches.open(CACHE).then(c => c.put(e.request, cl));
      }
      return res;
    }).catch(() => caches.match(e.request))
  );
});
