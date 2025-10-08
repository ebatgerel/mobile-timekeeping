# Firebase Setup (Flutter)

Prereqs:
- Node.js & npm
- Firebase CLI: npm i -g firebase-tools
- Flutter SDK

Steps:
1) Login and init
   - firebase login
   - firebase projects:create (or use existing)
   - firebase use <PROJECT_ID>
   - firebase init firestore functions storage

2) iOS/Android app
   - In Firebase Console > Project settings > Your apps, add iOS & Android apps.
   - Download GoogleService-Info.plist (iOS) and google-services.json (Android) to Flutter project platforms.

3) Flutter packages
   - Add to pubspec.yaml: firebase_core, firebase_auth, cloud_firestore, firebase_storage, geoflutterfire2, firebase_messaging (optional), url_launcher (optional)
   - flutterfire configure (optional, generates firebase_options.dart)

4) Deploy rules & functions
   - firebase deploy --only firestore:rules,storage:rules,functions

5) Local emulators (optional)
   - firebase emulators:start

