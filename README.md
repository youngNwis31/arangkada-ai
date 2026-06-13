# Arangkada AI

**Your 24/7 Rider Road Assistant**

A Flutter-based navigation app built for Filipino riders on platforms like Grab, FoodPanda, Angkas, JoyRide, and MoveIt. Designed to work offline-first with AI-powered route optimization.

## Features

- **AI Route Scoring** — Multi-route analysis weighing distance, duration, and congestion
- **Offline Navigation** — Turn-by-turn voice guidance (Taglish) that works without internet
- **Ride Logging** — Track earnings per platform with weekly chart analytics
- **Hazard Reporting** — Community-driven road hazard alerts with offline sync
- **AI Assistant** — Rider-focused Q&A for traffic, routes, and tips
- **Battery Saver** — Adaptive GPS intervals based on motion detection
- **Light/Dark Theme** — Toggle between Malate Street Style dark mode and clean light mode

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart) |
| Maps | Mapbox Maps Flutter SDK |
| Database | SQLite (sqflite) — offline-first |
| State | Provider (ChangeNotifier) |
| Theme | ThemeExtension pattern |
| Voice | flutter_tts (en-PH locale) |
| Charts | fl_chart |

## Setup

1. Install [Flutter SDK](https://docs.flutter.dev/get-started/install)
2. Get a free [Mapbox Access Token](https://account.mapbox.com/)
3. Add your token in `lib/config/app_config.dart`:
   ```dart
   static const String mapboxAccessToken = 'YOUR_TOKEN_HERE';
   ```
4. Run the app:
   ```bash
   flutter pub get
   flutter run
   ```

## Project Structure

```
lib/
  config/          # App config, theme system
  core/            # Database, connectivity, battery saver
  models/          # Data models (route, hazard, ride log, location)
  screens/         # 8 screens (home, nav, search, earnings, etc.)
  services/        # Business logic, providers, AI, Mapbox API
  widgets/         # Reusable UI components
  main.dart        # App entry point with MultiProvider
```

## Stats

- **41 Dart files** | ~18,500 lines of code
- **0 analysis errors**
- **v0.02** — Light/Dark theme system

## Developer

**James Earl Medrano**
- GitHub: [@youngNwis31](https://github.com/youngNwis31)
- Email: workwitheaaarl@gmail.com

## License

This project is for educational and personal use.
