// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "@popperjs/core";
import "bootstrap";
import "chartkick"
import "Chart.bundle"
import "controllers";

// import "libs/onesignal"

if ('serviceWorker' in navigator) {
  // Register the service worker
  window.addEventListener('load', function() {
    navigator.serviceWorker.register('/service-worker.js')
      .then(function(registration) {
        console.log('Service Worker registered with scope:', registration.scope);
      })
      .catch(function(error) {
        console.log('Service Worker registration failed:', error);
      });
    
    navigator.serviceWorker.getRegistrations().then(function(registrations) {
        for(let registration of registrations) {
          if (registration.active.scriptURL.includes("sw.js")) {
            registration.unregister();
          }
        } 
    });
  });
}