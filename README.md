# Arangkada AI

**Your 24/7 Rider Road Assistant**

A Flutter-based navigation and AI assistant app built for Filipino motorcycle riders on platforms like Grab, FoodPanda, Angkas, JoyRide, MoveIt, and Lalamove. Designed **offline-first** — maps, search, and AI all work without internet.

## Features

### Navigation & Maps
- **Offline Map Tiles** — Download Metro Manila (~30-50 MB) for use in dead zones, auto-caches areas you browse
- **AI Route Scoring** — Multi-route analysis weighing distance, duration, and congestion
- **Turn-by-Turn Navigation** — Voice guidance in Taglish (Tagalog-English) that works offline
- **POI Search** — Google Maps-style category browsing (food, gas, ATM, etc.) with offline fallback
- **Hazard Reporting** — Community-driven road alerts with offline sync

### AI Assistant (3-Tier Fallback)
- **Gemini Flash (Online)** — Best quality answers when connected, free tier (15 RPM, 1,500/day)
- **On-Device LLM (Offline)** — Qwen2.5-0.5B runs locally (~200 MB download), no internet needed
- **Knowledge Base** — 100+ instant-answer topics: PH traffic rules, platform policies, maintenance, earnings tips, Manila landmarks, emergencies, weather/safety, fuel, legal
- **Context-Aware** — AI uses your ride data (earnings, platforms, ride count) to personalize answers
- **Streaming Responses** — Token-by-token display for LLM responses

### Rider Tools
- **Earnings Tracker** — Log rides per platform with weekly chart analytics
- **Fuel Calculator** — Calculate fuel cost per trip based on your vehicle
- **Booking Hotspots** — See where you get the most bookings
- **Rider Safety** — SOS, emergency contacts, rest reminders
- **Battery Saver** — Adaptive GPS intervals based on motion detection
- **Light/Dark Theme** — Toggle between Malate Street Style dark mode and clean light mode

## AI Architecture

```
User Query
    |
    v
[1] Knowledge Base (100+ topics) ──match──> Instant response
    |  no match
    v
[2] Gemini Flash (online?) ──yes──> Cloud AI response
    |  offline / rate limited
    v
[3] Local LLM (downloaded?) ──yes──> On-device streaming response
    |  not downloaded
    v
[4] Rule-based fallback ──> Basic helpful response
```

Each response shows a source badge: book (KB), cloud (Gemini), brain (LLM), gear (rule-based).

## Tech Stack

| Layer | Technology | Cost |
|-------|-----------|------|
| Framework | Flutter (Dart) | Free |
| Maps | OpenStreetMap via flutter_map | Free |
| Offline Tiles | FMTC v10 (ObjectBox backend) | Free |
| Routing | OSRM (Open Source Routing Machine) | Free |
| Geocoding | Nominatim | Free |
| POI Data | Overpass API | Free |
| Online AI | Gemini 2.0 Flash (REST API) | Free tier |
| Offline AI | Qwen2.5-0.5B GGUF (on-device) | Free |
| Knowledge Base | 100+ entries, keyword matching | Free |
| Database | SQLite (sqflite) + FTS4 | Free |
| State | Provider (ChangeNotifier) | Free |
| Voice | flutter_tts (en-PH locale) | Free |
| Charts | fl_chart | Free |
| Tile Cache | flutter_map_tile_caching | Free |

**Total cost: ₱0** — Everything runs on free tiers and open-source tools.

## Storage Requirements

| Component | Size | Required? |
|-----------|------|-----------|
| App + Knowledge Base | ~25 MB | Yes (built-in) |
| Offline Map Tiles (Metro Manila) | ~30-50 MB | Optional (WiFi download) |
| On-Device AI Model (Qwen 0.5B) | ~200 MB | Optional (WiFi download) |
| POI Cache | ~5-10 MB | Auto-cached |
| **Total (all features)** | **~280 MB** | |

## Setup

1. Install [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.8.1+)
2. Clone and run — no API keys needed for core features:
   ```bash
   git clone https://github.com/youngNwis31/arangkada-ai.git
   cd arangkada-ai
   flutter pub get
   flutter run
   ```
3. **Optional:** Add a free Gemini API key in Settings > AI Model for online AI (get one at [Google AI Studio](https://aistudio.google.com/apikey))

## Project Structure

```
lib/
  config/              # App config, theme system (Malate Street Style)
    theme/             # MalateColors, MalateTypography, ThemeExtension
  core/                # Infrastructure
    battery/           # Battery saver with motion detection
    database/          # SQLite schema (v4), migrations, CRUD
    offline/           # Connectivity monitor, tile cache, POI cache, sync engine
  models/              # Data models (route, hazard, ride log, location)
  screens/             # 13 screens
    home_screen        # Map with POI overlay
    navigation_screen  # Turn-by-turn guidance
    search_screen      # Origin/destination with offline fallback
    ai_assistant_screen # Chat UI with streaming + source badges
    settings_screen    # Theme, AI model management, vehicle config
    offline_maps_screen # Download/manage map tiles
    earnings_screen    # Ride logging + weekly charts
    dashboard_screen   # Analytics overview
    safety_screen      # SOS + emergency contacts
    fuel_calculator    # Trip cost calculator
    hotspot_screen     # Booking density map
    splash_screen      # App launch
    main_shell         # Bottom nav + tab management
  services/            # Business logic
    ai/                # AI system (7 files)
      ai_router        # Fallback chain orchestrator
      ai_assistant     # Chat state + message management
      ai_context       # Live data aggregator (earnings, time, connectivity)
      knowledge_base   # 100+ PH rider topics
      llm_service      # On-device model wrapper
      model_download_manager # WiFi-only download with resume
      gemini_service   # Gemini Flash REST API wrapper
    ride_logger        # Earnings per platform
    navigation_provider # Route + step management
    poi_service        # POI fetching with cache layer
    mapbox_service     # Geocoding + search
    location_service   # GPS with PH bounds check
    hazard_service     # Community hazard reports
    theme_provider     # Light/dark/system toggle
  utils/               # Route optimizer
  widgets/             # Reusable components (7 widgets)
  main.dart            # Entry point with MultiProvider
```

## Version History

| Version | Highlights |
|---------|-----------|
| **v0.04** | 3-tier AI (Gemini + LLM + KB), offline maps, offline POI, storage optimized to ~280 MB |
| v0.03 | Migrated to OpenStreetMap (100% free), POI overlay, bottom nav, dashboard |
| v0.02 | Light/dark theme system, fuel calculator, safety features |
| v0.01 | Initial release — navigation, ride logging, hazard reporting |

## Stats

- **55 Dart files** | ~12,600 lines of code
- **0 analysis errors**
- **v0.04** — Offline AI + Offline Maps, ₱0 budget

## Developer

**James Earl Medrano**
- GitHub: [@youngNwis31](https://github.com/youngNwis31)
- Email: jamesearlmedrano02@gmail.com

## License

This project is for educational and personal use.
