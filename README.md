# UniStay – Student Housing App (Switzerland)

UniStay is a Flutter-based application designed to help students in Switzerland find housing easily.  
It provides separate interfaces for students (to book properties) and landlords (to list properties).

---

## 🌟 Features

- **User Registration & Login**
  - Student accounts
  - Landlord accounts
  - (In progress) Face authentication

- **Search & Booking**
  - Search for available housing
  - Book properties
  - View property locations on map

- **Landlord Management**
  - Create, update, and delete property listings
  - Manage bookings

- **Additional Features**
  - Price prediction for properties
  - Multiplatform support (Android + Web)

> ⚠️ Note: Payment system is not included in this project.

---

## 🛠️ Technologies

- **Frontend:** Flutter (Dart)
- **Backend:** Firebase (Authentication, Firestore, Storage)
- **Database:** Firestore (NoSQL)
- **External APIs:** Price prediction, Map services

---

## 💻 Installation

### From Source (Flutter) – For Development Only

> ⚠️ Note: Firebase services (auth, database, storage) will not work with the cloned repository unless you configure your own Firebase project.  
> The following steps are meant for developers who want to run and modify the app locally.

1. Make sure you have Flutter installed.
2. Clone the repository:
   ```bash
   git clone https://github.com/Algath/SS2-UniStay.git
   cd SS2-UniStay
   ```
3. ```bash
   flutter pub get
   ```
4. ```bash
   flutter run
   ```
   Can be run on Android device/emulator or in a browser (Edge).

### Using the App (Internal Testing)
- Available via Google Play internal testing.
- Testers need to be registered via their Google account in the testing group
- This is the only way to access live data and fully functional features.

## 📂 Project Structure
Inside the `lib/` folder:
- `screens/` -> Main UI screens (Login, Register, Home, Property Details, Booking)
- `widgets/` -> Reusable UI components
- `models/` -> Data models (User, Property, Reservation)
- `services/` → Firebase interactions (AuthService, DatabaseService, StorageService)
- `providers/` → State management
- `utils/` → Helper functions

## 🔐 Authentication
- Managed via Firebase Authentication
- Supports student and landlord accounts
- Face authentication fully implemented and functional

## 🗄️ Database (Firestore)
Main collections:
- users → student & landlord profiles
- properties → property listings
- bookings → reservations linked to users & properties

## 🖼️ Media Storage
- Property images stored in Firebase Storage
- Image URLs referenced in Firestore

## 🌍 Platform Support
- Android (internal testing)
- Web (Edge browser)

## 📡 APIs & Services
- Firebase services (auth, Firestore, storage)
- External APIs for price prediction
- Map integration

## ⚙️ Architecture Overview
- Flutter App ↔ Firebase Authentication ↔ Firestore ↔ Firebase Storage
- External APIs for price prediction & map services

## 🎯 Target Users
- Students looking for housing in Switzerland
- Landlords seeking to rent properties to students

## 📄 Known Limitations
- No payment system
- Only internal testing on Google Play

## 🎥 Demonstration
- 1-minute overview video (UI + main flows)
- 5-minute detailed video (walkthrough of features)
- Screenshots included for reference

## 📝 Guides
- User Guide: (Coming soon – see USER_GUIDE.md)
- Technical Guide: (See TECHNICAL_GUIDE.md)