# Arangkada AI

**Your 24/7 Rider Road Assistant**

A Flutter-based navigation and AI assistant app built for Filipino motorcycle riders on platforms like Grab, FoodPanda, Angkas, JoyRide, MoveIt, and Lalamove. Designed **offline-first** — maps, search, and AI all work without internet.

**Current Version: v0.05** | 63 Dart files | ~14,500 lines of code | ₱0 budget

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

### Voice Commands (Hands-Free)
- **Speech-to-Text** — Tap mic and speak, works in English and Filipino
- **Navigation** — "Navigate to SM North EDSA" / "Papunta sa Makati"
- **Ride Logging** — "Log ride Grab 150" creates a ride log instantly
- **Hazard Reports** — "Report pothole" / "Baha" submits at current location
- **Earnings Query** — "Earnings today" speaks back your total
- **AI Passthrough** — Unmatched commands go to AI assistant

### Fare Estimator (Trip Worth Calculator)
- **Route-Based Calculation** — Uses OSRM routing for accurate distance and duration
- **Cost Analysis** — Fuel needed, fuel cost, cost per km based on your vehicle settings
- **Traffic Buffer** — 1.3x time multiplier for realistic Manila traffic estimates
- **SULIT / PUWEDE NA / LUGI Verdict** — Color-coded badge tells you if the trip is worth it
- **Real-Time** — Verdict updates as you type the fare amount
- **Navigate Button** — Jump directly to turn-by-turn navigation from the estimate

### Flood & Weather Alerts
- **Live Weather** — Current temperature, conditions, and rain amount from Open-Meteo API (free, no key)
- **Weather Widget** — Compact card on home screen with color-coded borders (cyan = rain, red = flood risk)
- **12-Hour Forecast** — Rain probability and heavy rain detection
- **3 Flood Severity Levels** — Ankle-deep (BAHA BABAW), knee-deep (BAHA TUHOD), impassable (BAHA LUBOG)
- **Flood Map Markers** — Color-coded markers on map (cyan → blue → dark blue by severity)
- **Route Flood Warnings** — "FLOOD ZONE AHEAD" banner during navigation with report count
- **6-Hour Expiry** — Flood reports auto-expire to keep data fresh
- **Offline Cache** — Weather data cached in SQLite for offline viewing

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
| Database | SQLite (sqflite) — schema v5 | Free |
| State | Provider (ChangeNotifier) | Free |
| Voice Output | flutter_tts (en-PH locale) | Free |
| Voice Input | speech_to_text v7 (offline capable) | Free |
| Weather | Open-Meteo API (no key, no limits) | Free |
| Charts | fl_chart | Free |
| Tile Cache | flutter_map_tile_caching | Free |

**Total cost: ₱0** — Everything runs on free tiers and open-source tools.

## Storage Requirements

| Component | Size | Required? |
|-----------|------|-----------|
| App + Knowledge Base | ~25 MB | Yes (built-in) |
| Offline Map Tiles (Metro Manila) | ~30-50 MB | Optional (WiFi download) |
| On-Device AI Model (Qwen 0.5B) | ~200 MB | Optional (WiFi download) |
| POI + Weather Cache | ~5-10 MB | Auto-cached |
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
    database/          # SQLite schema (v5), migrations, CRUD
    offline/           # Connectivity monitor, tile cache, POI cache, sync engine
  models/              # Data models (route, hazard, ride log, location, weather)
  screens/             # 14 screens
    home_screen        # Map with POI overlay + weather widget + flood markers
    navigation_screen  # Turn-by-turn guidance + flood zone warnings
    search_screen      # Origin/destination with offline fallback
    ai_assistant_screen # Chat UI with streaming + source badges + mic input
    fare_estimator     # Trip worth calculator with SULIT/LUGI verdict
    settings_screen    # Theme, AI model management, vehicle config
    offline_maps_screen # Download/manage map tiles
    earnings_screen    # Ride logging + weekly charts
    dashboard_screen   # Analytics overview
    safety_screen      # SOS + emergency contacts
    fuel_calculator    # Trip cost calculator
    hotspot_screen     # Booking density map
    hazard_report      # Community hazard + flood severity reporting
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
    voice_command_service # Speech-to-text + command parser
    weather_service    # Open-Meteo API wrapper with caching
    fare_calculator    # Trip cost vs fare analysis
    ride_logger        # Earnings per platform
    navigation_provider # Route + step management
    poi_service        # POI fetching with cache layer
    mapbox_service     # Geocoding + search
    location_service   # GPS with PH bounds check
    hazard_service     # Community hazard + flood reports
    theme_provider     # Light/dark/system toggle
  utils/               # Route optimizer
  widgets/             # Reusable components (9 widgets)
    voice_fab          # Animated mic button with pulse
    weather_widget     # Compact weather card
    flood_marker       # Severity-colored map marker
    ...                # route_info_card, nav_instruction_card, etc.
  main.dart            # Entry point with MultiProvider (12 providers)
```

---

## Development Log

Full build history from initial commit to current version. Every commit, every fix, every decision.

### Day 1 — June 12, 2026: Foundation (v0.01)

**`6b629c1` — feat: Arangkada AI v0.01 — rider navigation app for PH riders**
- Built the entire initial app from scratch in Flutter
- Created: navigation with Mapbox, ride logging per platform, hazard reporting, settings
- Models: LocationModel, RouteModel, HazardReport, RideLog
- Services: NavigationProvider, RideLogger, HazardService, LocationService
- Screens: HomeScreen (map), NavigationScreen, SearchScreen, EarningsScreen, SettingsScreen
- Theme: Malate Street Style — dark cyberpunk theme inspired by Manila nightlife
- Database: SQLite v1 with hazard_reports, recent_searches, saved_locations, offline_regions, landmark_rag tables

### Day 2 — June 13, 2026: Theme System (v0.02)

**`24ae75e` — feat: add light/dark theme system with ThemeExtension pattern**
- Added MalateColors ThemeExtension with full color palette for both light and dark mode
- Created ThemeProvider with system/light/dark toggle persisted to SharedPreferences
- All screens updated to use `MalateColors.of(context)` instead of hardcoded colors

**`84c06d9` — chore: bump version to v0.02, fix build_context_synchronously lint**
- Fixed async context usage warnings across the app

**`4bcd281` — docs: update README with project info, features, and setup guide**
- First README with feature list and setup instructions

### Day 2 (cont.) — June 14, 2026: Mapbox → OpenStreetMap Migration

**`a7f8c88` — fix: ride toggle END button infinite width, set iOS deployment to 14.0**
- Fixed layout overflow on the ride toggle widget
- Set iOS minimum deployment target to 14.0

**`e809322` — feat: migrate from Mapbox to OpenStreetMap (free, no API key)**
- **DELETED:** All Mapbox dependencies and API key requirements
- **REPLACED WITH:** OpenStreetMap tiles via flutter_map (CartoDB Voyager style)
- **REPLACED WITH:** OSRM for routing (was Mapbox Directions API)
- **REPLACED WITH:** Nominatim for geocoding (was Mapbox Geocoding)
- **WHY:** ₱0 budget — Mapbox requires paid API keys, OSM ecosystem is fully free

**`b6f163a` — fix: platform logos, overlapping UI, settings scroll, map tiles**
- Fixed platform logo display in ride logger
- Fixed UI elements overlapping on smaller screens
- Made settings screen scrollable
- Fixed tile URL configuration

**`8318a22` — fix: remove retina placeholder from dark tile URL**
- Dark mode tiles had `{r}` placeholder causing 404 errors — removed it

**`fc42409` — feat: add Luzon preset cities + fix iOS map tile loading**
- Added preset cities across Luzon for quick navigation
- Fixed iOS-specific tile loading issues

**`66459f9` — feat: Google Maps-style search with origin/destination fields**
- Redesigned search screen with origin + destination fields (like Google Maps)
- Added "EXPLORE NEARBY" category grid and "POPULAR DESTINATIONS" list

**`9c77ab5` — fix: search now shows live address results for both fields**
- Search results now update in real-time as user types for both origin and destination

**`cf26ead` — fix: GPS falls back to Manila when outside PH, fix map zoom**
- **PROBLEM:** Simulator GPS reports Cupertino, CA — map showed wrong location
- **FIX:** Added PH bounds check (lat 4.5-21.5, lng 116-127), falls back to Manila if outside
- Fixed default zoom level

**`4596511` — fix: nav engine uses PH bounds check to prevent OFF ROUTE on simulator**
- Navigation engine was showing "OFF ROUTE" because GPS coordinates were in California
- Added same PH bounds check to nav engine

**`4e9167a` — feat: Google Maps-style search with exact addresses + cleanup unused platforms**
- Search now shows full addresses with barangay/city
- **DELETED:** Unused platform-specific code that was cluttering the codebase

**`9b84f0c` — feat: add fuel calculator, booking hotspots, and rider safety screens**
- New screens: FuelCalculatorScreen, HotspotScreen, SafetyScreen
- Fuel calculator uses vehicle settings (km/L, fuel price) to estimate trip cost
- Safety screen with SOS button and emergency contacts
- Hotspot screen showing booking density information

### Day 3 — June 15, 2026: Dashboard & Navigation

**`219072e` — feat: upgrade map tiles for Google Maps-like street detail**
- Switched to CartoDB Voyager tiles — cleaner labels, better road hierarchy, Google Maps feel

**`88b9c27` — feat: add bottom navigation bar with dashboard analytics screen**
- Added MainShell with bottom nav: Map, Dashboard, Earnings, Settings
- New DashboardScreen with Today's Performance card, Quick Access grid, weekly chart
- **REPLACED:** Previous tab-less navigation with proper bottom tab bar

### Day 4 — June 16, 2026: POI System

**`e1c2eaf` — feat: add POI overlay with Google Maps-style category browsing**
- Added PoiService fetching from Overpass API (OpenStreetMap POI data)
- 9 categories: Cafe, Restaurant, Fast Food, Gas Station, Bank, Pharmacy, Store, Hospital, Parking
- POI markers on map with category-colored icons
- Tappable markers with bottom sheet detail + "NAVIGATE HERE" button
- Horizontal chip bar for category filtering

### Day 5 — June 18, 2026: Offline Infrastructure & AI

**`b992f32` — feat: add offline map tiles with FMTC v10 for Metro Manila**
- Integrated flutter_map_tile_caching v10 with ObjectBox backend
- OfflineMapsScreen to download Metro Manila tiles (zoom 13-15)
- Downloads all 16 Metro Manila cities with progress tracking
- Tiles served from cache when offline — seamless map experience

**`c5b01a1` — feat: add offline POI caching with SQLite fallback for search and nearby**
- Added `cached_pois` table to SQLite (schema bumped to v4)
- POI results cached on first fetch — subsequent queries served from SQLite when offline
- Added spatial index on latitude/longitude for fast nearby queries

**`b3f8f45` — feat: add Smart Knowledge Base with 100+ PH rider topics**
- Created KnowledgeBase service with 100+ curated entries
- Topics: PH traffic laws, platform policies (Grab/FoodPanda/Angkas/etc.), vehicle maintenance, earnings tips, Manila landmarks, emergency procedures, weather safety, fuel optimization, legal rights
- Keyword-based matching with priority scoring — instant responses, no API needed

**`6de3826` — feat: add on-device LLM infrastructure with Gemma 2B download management**
- Created LlmService for running GGUF models on-device
- Created ModelDownloadManager with WiFi-only download, pause/resume, progress tracking
- **INITIAL MODEL:** Gemma 2B (~1.5 GB) — later replaced with smaller model
- Created AiAssistant with chat state management and streaming display
- Created AiRouter with fallback chain: KB → Gemini → LLM → rule-based
- Added AiAssistantScreen with chat UI, source badges, streaming indicator

### Day 6 — June 19, 2026: Online AI, Storage Optimization & New Features (v0.04 → v0.05)

**`3a06141` — feat: add Gemini Flash online AI + optimize storage (~2.1 GB → ~250 MB)**
- Added GeminiService — Gemini 2.0 Flash via REST API (free tier: 15 RPM, 1,500 RPD)
- **DELETED:** Gemma 2B model reference (~1.5 GB)
- **REPLACED WITH:** Qwen2.5-0.5B Q2_K GGUF (~200 MB) — 7.5x smaller, still useful offline
- **CHANGED:** Map tiles from @2x to @1x — ~50% size reduction
- **CHANGED:** Tile zoom range from 10-17 to 13-15 — ~90% fewer tiles
- **RESULT:** Total storage went from ~2.1 GB to ~280 MB

**`2336fc4` — docs: update README with v0.04 features, AI architecture, and storage info**
- Complete README rewrite with AI architecture diagram, tech stack table, storage requirements

**`892d3a1` — feat: add voice commands for hands-free rider control**
- Added `speech_to_text: ^7.0.0` dependency
- Created VoiceCommandService — speech recognition with offline command parser
- Command parser priority chain: navigation → ride log → hazard → earnings → AI passthrough
- Supports English and Filipino commands ("navigate to X" / "papunta sa X")
- Created VoiceFab — animated floating mic button with pulse effect
- Added mic to HomeScreen, NavigationScreen, and AiAssistantScreen
- Added `RECORD_AUDIO` permission to AndroidManifest
- **FIX:** speech_to_text v7 deprecated API — wrapped params in SpeechListenOptions
- **FIX:** Removed duplicate import that caused analyzer warning

**`e6e9377` — feat: add Trip Worth Calculator with SULIT/PUWEDE NA/LUGI verdict**
- Created FareCalculator — static calculation with traffic buffer
- Created FareEstimatorScreen — two location fields, auto-route fetch, cost breakdown
- Verdict system: SULIT (green, ≥₱100/hr) / PUWEDE NA (amber, ≥₱70/hr) / LUGI (red, below)
- Real-time recalculation as fare amount changes
- NAVIGATE button to jump to turn-by-turn from estimate
- Added fare estimator FAB to home screen
- **FIX:** RouteModel units — distance was in meters, duration in seconds, needed km and minutes
- **FIX:** BuildContext across async gap — added `if (!mounted) return` check

**`30a77c9` — feat: add Flood & Weather Alerts with Open-Meteo API and flood severity system**
- Created WeatherData model with WMO weather code mappings (Filipino descriptions)
- Created WeatherService — Open-Meteo API wrapper with 30-min auto-refresh + SQLite cache
- Created WeatherWidget — compact card showing temp, conditions, rain, FLOOD RISK badge, CACHED badge
- Created FloodMarker — severity-colored map markers (cyan/blue/dark blue)
- Extended HazardType enum with 3 flood levels: floodAnkle, floodKnee, floodImpassable
- Added flood-specific database queries with 6-hour expiry
- Added flood markers to home screen map
- Added "FLOOD ZONE AHEAD" warning banner during navigation
- Updated hazard report screen: replaced single "Flooding" with 3 severity options
- Database bumped to v5 with `weather_cache` table
- Registered WeatherService in MultiProvider

---

## What Was Removed / Replaced

| Removed | Replaced With | Why |
|---------|---------------|-----|
| Mapbox SDK + API key | flutter_map + OpenStreetMap | ₱0 budget — Mapbox costs money |
| Mapbox Directions API | OSRM (open-source routing) | Free, no API key |
| Mapbox Geocoding | Nominatim | Free, no API key |
| Gemma 2B model (~1.5 GB) | Qwen2.5-0.5B Q2_K (~200 MB) | 7.5x smaller, fits ₱0 storage budget |
| @2x retina tiles | @1x standard tiles | ~50% storage saved |
| Zoom levels 10-17 | Zoom levels 13-15 | ~90% fewer tiles to download |
| Single "Flooding" hazard | 3 flood severity levels | More useful for riders |
| Touch-only navigation | Voice commands + touch | Hands-free safety while riding |

## Key Technical Decisions

1. **Offline-first architecture** — SQLite caching at every layer (POIs, routes, weather, tiles) so the app works in Manila's dead zones
2. **3-tier AI fallback** — Knowledge Base (instant, offline) → Gemini Flash (best quality, online) → Local LLM (good enough, offline) → rule-based (always works)
3. **₱0 constraint** — Every API, service, and tool is free tier or open-source. No paid dependencies.
4. **Provider pattern** — ChangeNotifier + MultiProvider for state management, avoiding over-engineering
5. **Filipino-first UX** — Taglish voice guidance, Filipino weather descriptions, Tagalog hazard labels, peso currency throughout

## Version History

| Version | Date | Highlights |
|---------|------|-----------|
| **v0.05** | Jun 19, 2026 | Voice commands, Fare Estimator (SULIT/LUGI), Flood & Weather Alerts |
| v0.04 | Jun 19, 2026 | 3-tier AI (Gemini + LLM + KB), storage optimized to ~280 MB |
| v0.03 | Jun 16-18, 2026 | Migrated to OpenStreetMap, POI overlay, offline tiles, bottom nav, dashboard |
| v0.02 | Jun 13-14, 2026 | Light/dark theme, fuel calculator, safety features, search redesign |
| v0.01 | Jun 12, 2026 | Initial release — navigation, ride logging, hazard reporting |

## Stats

- **63 Dart files** | ~14,500 lines of code
- **0 analysis errors** (9 warnings/info, all pre-existing)
- **27 commits** over 7 days of development
- **v0.05** — Voice + Fare Estimator + Flood Alerts, ₱0 budget

## Developer

**James Earl Medrano**
- GitHub: [@youngNwis31](https://github.com/youngNwis31)
- Email: jamesearlmedrano02@gmail.com

## License

This project is for educational and personal use.
