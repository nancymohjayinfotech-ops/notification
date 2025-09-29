// Import Firebase compat libraries for service worker
importScripts("https://www.gstatic.com/firebasejs/9.6.10/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.6.10/firebase-messaging-compat.js");

// Initialize Firebase (same config as in main.dart)
firebase.initializeApp({
  apiKey: "AIzaSyCMM9sLCT8IxhA8cuucp2P0Ou2KrCSAgag",
  authDomain: "testnotification-1ef05.firebaseapp.com",
  projectId: "testnotification-1ef05",
  storageBucket: "testnotification-1ef05.appspot.com",
  messagingSenderId: "746508962866",
  appId: "1:746508962866:web:f900d17aa110435ea7802b",
  measurementId: "G-NB635SFCHC"
});

// Retrieve an instance of Firebase Messaging
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log(
    "[firebase-messaging-sw.js] Received background message ",
    payload
  );

  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: "/icons/Icon-192.png", // optional
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});