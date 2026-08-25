/* Dev Firebase Messaging service worker. This contains only public web-app
 * configuration; private keys and Admin SDK credentials never belong here. */
importScripts('https://www.gstatic.com/firebasejs/10.13.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyCXVooAey8oNhbKDg38qjOiJVfQBx4rmQY',
  appId: '1:480914480895:web:1ea186f293feafa66476ca',
  messagingSenderId: '480914480895',
  projectId: 'kinetictecharc-app-dev',
});

const messaging = firebase.messaging();
messaging.onBackgroundMessage((payload) => {
  const notification = payload.notification || {};
  return self.registration.showNotification(notification.title || 'AMORAA', {
    body: notification.body || 'You have a new notification.',
    data: payload.data || {},
  });
});
