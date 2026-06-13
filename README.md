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
| Maps | OpenStreetMap (flutter_map) — free, no API key |
| Routing | OSRM (Open Source Routing Machine) — free |
| Geocoding | Nominatim — free |
| Database | SQLite (sqflite) — offline-first |
| State | Provider (ChangeNotifier) |
| Theme | ThemeExtension pattern |
| Voice | flutter_tts (en-PH locale) |
| Charts | fl_chart |

## Setup

1. Install [Flutter SDK](https://docs.flutter.dev/get-started/install)
2. Run the app — no API keys needed:
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
  services/        # Business logic, providers, AI, map services
  widgets/         # Reusable UI components
  main.dart        # App entry point with MultiProvider
```

## Stats

- **41 Dart files** | ~18,500 lines of code
- **0 analysis errors**
- **v0.03** — Migrated to OpenStreetMap (100% free, no credit card)

## Developer

**James Earl Medrano**
- GitHub: [@youngNwis31](https://github.com/youngNwis31)
- Email: workwitheaaarl@gmail.com

## License

This project is for educational and personal use.
