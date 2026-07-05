importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyAgT4rvWSyvaDbHujMmZTDDUZn2xMnts5M",
  authDomain: "edu-bridge-246fd.firebaseapp.com",
  projectId: "edu-bridge-246fd",
  storageBucket: "edu-bridge-246fd.firebasestorage.app",
  messagingSenderId: "1087208747554",
  appId: "1:1087208747554:web:ab689779c18d1872f9107b",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[EduBridge SW] Background message:', payload);

  const title = payload.notification?.title || payload.data?.title || 'EduBridge';
  const body  = payload.notification?.body  || payload.data?.body  || '';

  self.registration.showNotification(title, {
    body: body,
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    dir: 'rtl',
    lang: 'ar',
  });
});
