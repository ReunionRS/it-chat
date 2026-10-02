importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: '__FIREBASE_API_KEY__',
  authDomain: 'itchat-eaa60.firebaseapp.com',
  projectId: 'itchat-eaa60',
  storageBucket: 'itchat-eaa60.firebasestorage.app',
  messagingSenderId: '959980227800',
  appId: '1:959980227800:web:9afb8b99c66bbd4f76dbad',
});

firebase.messaging();
