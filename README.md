# Nûr AI

Flutter-based mobile application combining AI assistance with prayer times, qibla direction, Quran browsing, notifications and premium subscription flows.

## Highlights

- Gemini API powered conversational assistant
- Location-based prayer times
- Qibla direction using device sensors
- Quran browsing with Turkish and English support
- Local notifications
- RevenueCat subscription flow
- AdMob integration
- Riverpod state management

## Tech Stack

- Flutter / Dart
- Riverpod
- Gemini API
- RevenueCat
- Firebase / local services where applicable
- Geolocator & Geocoding
- Flutter Local Notifications

## Architecture

```text
lib/
├── domain/        # Models, business rules and interfaces
├── data/          # Repositories, storage and API clients
├── presentation/  # Screens, widgets and Riverpod providers
└── main.dart      # Application entry point
```

## Getting Started

```bash
git clone https://github.com/omrfarukkahraman/nur-ai.git
cd nur-ai
flutter pub get
flutter run
```

Create the required local environment/configuration files before running the app. Do not commit private API keys.

## What I Practiced

- Structuring a medium-sized Flutter application
- Integrating external APIs into a mobile product
- Managing asynchronous state with Riverpod
- Subscription and premium-access flows
- Location and sensor-based mobile features

## Status

Completed as a portfolio/product project. Not currently published to an app store.

## Author

**Ömer Faruk Kahraman**  
[GitHub](https://github.com/omrfarukkahraman) · [LinkedIn](https://www.linkedin.com/in/%C3%B6mer-faruk-kahraman-aa4808273/)
