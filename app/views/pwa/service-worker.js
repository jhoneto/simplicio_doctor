// app/views/pwa/service-worker.js
importScripts("https://cdn.onesignal.com/sdks/web/v16/OneSignalSDK.sw.js");
// The install event is fired when the service worker is first installed
self.addEventListener('install', function(event) {
  console.log('Service Worker installed');
});

// The activate event is fired after the install event when the service worker is actually controlling the page
self.addEventListener('activate', function(event) {
  console.log('Service Worker activated');
});