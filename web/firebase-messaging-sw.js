// Firebase Cloud Messaging for the web build: shows FCM notifications while the tab is
// closed or in the background (Android does this natively). Same values as
// DefaultFirebaseOptions.web in lib/firebase_options.dart; these are public identifiers.
importScripts('https://www.gstatic.com/firebasejs/11.0.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/11.0.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyAs5xKjGB5p-4I3Poy2ZI8Er65TVOfTLlk',
  authDomain: 'prm393-34056.firebaseapp.com',
  projectId: 'prm393-34056',
  storageBucket: 'prm393-34056.firebasestorage.app',
  messagingSenderId: '21478927288',
  appId: '1:21478927288:web:3a6610131a3a29879dbd4d',
  measurementId: 'G-RFWHW9GJT0',
});

// Messages with a "notification" payload are displayed by the SDK itself
firebase.messaging();
