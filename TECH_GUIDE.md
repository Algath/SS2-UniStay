# 🛠️ UniStay Technical Guide

---

## Introduction

This document describes the technical architecture, setup, and development workflow of the UniStay mobile application. It is aimed at developers who want to understand the internals, extend features, fix bugs, or deploy the app.

UniStay is a *school project* developed as part of an academic course.
⚠️ No long-term maintenance is planned after the project evaluation.

---

## ⚙️ Development Environment

### Prerequisites

Before diving in, ensure you have the following installed:

- Flutter SDK (>= 3.0)  
- Dart SDK (bundled with Flutter)  
- Android Studio or VS Code with Flutter extensions  
- A Google account with access to Firebase Console

+ Python (>=3.12) with DeepFace, uvicorn and FastAPI
+ ngrok and Docker (optional, for local API tunneling)  
+ Git (>= 2.20)  

### Firebase Setup

1. Create a Firebase project in the [Firebase Console].  
2. Enable **Authentication**, **Firestore Database**, and **Storage**.  
3. Download and store your Firebase keys locally (⚠️ keys are not published on GitHub).
4. Add Firestore security rules to restrict read/write by authenticated users.

### Face recognition API

UniStay relies on external API for face recognition. To configure the base URL:

1. Into your Firebase create a Collection `config` → Document `app_settings`
2. Set a field `api_base_url` to your REST endpoint. For example and ngrok url `https://your-ngrok-is.ngrok-free.app`.

3. The app will fetch this URL on startup and route all API calls through it.

As example you can make run the API following these instruction:

1. Open a terminal under `assets\face-api_server`.
2. The API need some Firebase credentials to fetch authentification token, add credentials (`firebase-service-account.json`) here.
3. Build your docker: `docker build -t face-api .`
4. Run the docker with a open port to enable http communication: `docker run -p 8080:8080 face-api`
5. Now that you docker is launched into another terminal you will create your ngrok server: `ngrok http 8080`
6. You can now update the URL into your Firebase.
```bash
cd assets/face-api_server
# Add Firebase service account credentials here
docker build -t face-api .
docker run -p 8080:8080 face-api
```
and in a new terminal:
```bash
ngrok http 8080
```
### Flutter development setup

Into the root of the flutter project simply run the following command;

``` bash
flutter clean
flutter pub get
flutter run
```

This should allow you to run a debug version of the app.

---


## 📁 Project Architecture

```
SS2-UniStay/
├── assets/face-api_server/ # The code for the Face recognition API
├── lib/
    ├── models/ # Data models (User, Property, Booking)
    ├── services/ # Firebase services (Auth, DB, Storage)
    ├── views/ # UI screens (Login, Home, Booking, etc.)
    ├── widgets/ # Reusable UI components
    ├── providers/ # State management (e.g., Provider)
    ├── utils/ # Helper functions
```
---

## 🔐 Authentication Flow

- Firebase Authentication handles login and registration.
- Two account types:
  - **Student**
  - **Homeowner**
- Face authentication:
  - Profile picture stored locally
  - Face recognition API compares live image with stored image

---

## 🗄️ Firestore Schema

| Collection         | Description                          |
|--------------------|--------------------------------------|
| `users`            | Student & homeowner profiles          |
| `rooms`            | Property listings                    |
| `booking_requests` | Reservation requests                 |
| `property_ratings` | Ratings for properties               |
| `reviews`          | Reviews on properties                |
| `student_reviews`  | Reviews on students                  |

---

## 🖼️ Media Storage

- Property images uploaded to Firebase Storage
- Image URLs stored in Firestore documents

---

## 🌐 External APIs

- **Face Recognition API**: Validates user identity
- **Nominatim**: Converts address to coordinates
- **Open-Meteo**: Displays weather at property location
- **OSRM**: Public transport routing
- **Map Services**: Displays property locations

---

## 🚀 Deployment

-Build with Google Cloud Build:
```bash
flutter pub run flutter_launcher_icons:main #only on the first time
flutter build appbundle
```
-Deployment tested via Google Play Console (internal testing).
-Works on emulator or physical Android device.

---

## 🔄 CI/CD

Google Cloud Build is used for compilation.
Current pipeline limited to building appbundle.
No automated tests or deployment pipeline configured.

---

## 🔐 Security

API and Firebase keys are local only (not stored in repository).
Firestore rules restrict access to authenticated users.
No obfuscation/minification (ProGuard/R8) configured.

---

## 🧑‍💻 Monitoring & Debugging

No crash reporting or performance monitoring configured.
Logs are accessible via flutter run or Android Studio Logcat.
Tools such as Firebase Crashlytics could be integrated in the future.

---

## 🎨 Design & UX

Built with Flutter default widgets + Material Design principles.
No dark mode.
No internationalization (single language supported).

---
## ⚠️ Known Limitations

- ❌ No payment system
- ❌ No automated tests
- ❌ No monitoring (Crashlytics, Sentry, etc.)
- ❌ No dark mode / no multi-language support
- ❌ Limited to Android mobile app (no web support)
- ❌ Internal testing only (not a public release)
- ❌ No post-project maintenance planned

Future improvements could include:

- Adding a secure secret management system (Firebase Config, GitHub Secrets).
- Integrating automated tests and a CI/CD pipeline.
- Adding Crashlytics for better monitoring.
- Implementing payment integration.
- Supporting multi-language and theming.
- Partially working on Windows

---

## 📄 Additional Resources

- [User Guide](USER_GUIDE.md)
- [README](README.md)
- [Generator of proprieties](README_populate_firebase.md)
