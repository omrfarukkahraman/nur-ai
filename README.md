# 🌙 Nûr AI — Your Digital Heart's Guide (Kalbinin Dijital Rehberi)

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Gemini_API-8E75C2?style=for-the-badge&logo=google-gemini&logoColor=white" alt="Gemini API" />
  <img src="https://img.shields.io/badge/RevenueCat-FF4B4B?style=for-the-badge&logo=revenuecat&logoColor=white" alt="RevenueCat" />
  <img src="https://img.shields.io/badge/AdMob-34A853?style=for-the-badge&logo=google-admob&logoColor=white" alt="AdMob" />
</p>

---

## 🌟 Overview

**Nûr AI** is a state-of-the-art, feature-rich Islamic assistant and spiritual guidance mobile application built using Flutter, Dart, and Riverpod. Powered by Google's **Gemini API** for intelligent theological dialogues, it serves as a modern companion for Muslims worldwide. The app features GPS-based prayer calculation, a full Quran explorer, Qibla compass, local notifications, Google AdMob monetization, and an enterprise-grade subscription billing system integrated via **RevenueCat**.

---

## ✨ Key Features

### 🤖 Gemini AI Spiritual Chat
* **Intelligent Theological Assistant:** Answers questions about Islamic history, jurisprudence, and general knowledge using Gemini Generative AI.
* **Contextual Conversations:** Smart prompt engineering to ensure reliable, polite, and spiritually enriching chat experiences.

### 📖 Quran Companion
* **Complete Quran Text:** Read and browse the Holy Quran with clean, beautiful typography.
* **Surah & Verse Metadata:** Detailed information per surah (revelation place, verse count).
* **Translations:** Support for Turkish and English translations.

### 📍 GPS-Based Prayer Times & Qibla Compass
* **Adhan Calculators:** High-precision geographical calculations using GPS coordinates via `adhan`.
* **Dynamic Timezones:** Automatic adjusting of prayer schedules based on the user's location.
* **Qibla Finder:** Interactive compass tool using the mobile device's magnetometer to locate the Qibla.

### 💎 RevenueCat Premium Monetization
* **Premium Subscriptions:** Robust premium unlock mechanism with paywalls, monthly/annual packages, and subscription state tracking.

### 📢 Google AdMob Integration
* **Banner & Interstitial Ads:** Non-intrusive ad placement configuration optimized for free tier users.

### 🌍 Easy Localization (TR/EN)
* **Multi-Language Support:** Fully translated application UI, menus, and AI chat templates.

### 🔔 Local Notification System
* **Prayer Reminders:** Daily notifications scheduled precisely at prayer times.
* **Verse of the Day:** Automated spiritual reminders.

---

## 🛠️ Architecture & Tech Stack

Nûr AI follows clean, modular development patterns:

```text
lib/
├── domain/             # Core models, business rules, and interfaces
├── data/               # Repositories, local storage, API clients
├── presentation/       # UI layer (Screens, Widgets, ViewModels, Riverpod Providers)
├── main.dart           # App entry point and service initializations
└── store_assets/       # Store screenshots, graphics, and branding assets
```

* **Framework:** Flutter & Dart
* **AI Engine:** Google Generative AI (`google_generative_ai`)
* **State Management:** Riverpod
* **Billing System:** RevenueCat (`purchases_flutter`)
* **Monetization:** Google Mobile Ads (`google_mobile_ads`)
* **Location & Geocoding:** Geolocator & Geocoding
* **Internationalization:** Easy Localization
* **Notifications:** Flutter Local Notifications

---

## 🚀 Getting Started

### Prerequisites
Make sure you have Flutter SDK installed on your system.

```bash
# Verify your Flutter installation
flutter doctor
```

### Setup

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/omrfarukkahraman/nur-ai.git
   cd nur-ai
   ```

2. **Install Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Environment Variables:**
   Create a `.env` file in the project root:
   ```env
   GEMINI_API_KEY=your_gemini_api_key_here
   REVENUECAT_API_KEY_ANDROID=your_android_key
   REVENUECAT_API_KEY_IOS=your_ios_key
   ```

4. **Launch the App:**
   ```bash
   flutter run
   ```

---

## 🧑‍💻 Author

* **Ömer Faruk Kahraman**
* GitHub: [@omrfarukkahraman](https://github.com/omrfarukkahraman)
* LinkedIn: [Ömer Faruk Kahraman](https://www.linkedin.com/in/%C3%B6mer-faruk-kahraman-aa4808273/)

---

## 📄 License

This project is licensed under the MIT License.
