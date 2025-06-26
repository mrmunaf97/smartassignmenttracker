importScripts('https://www.gstatic.com/firebasejs/9.6.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.6.1/firebase-messaging-compat.js');

firebase.initializeApp({
    apiKey: "AIzaSyDotDeqHUMo7ojwDdIB0yN8gOZmz3qMJoY",
    authDomain: "assignment-tracker-16c81.firebaseapp.com",
    projectId: "assignment-tracker-16c81",
    storageBucket: "assignment-tracker-16c81.firebasestorage.app",
    messagingSenderId: "539805701076",
    appId: "1:539805701076:web:11f624946a46244e0a7c41",
    measurementId: "G-QZG64SE2FQ"
});

const messaging = firebase.messaging(); 