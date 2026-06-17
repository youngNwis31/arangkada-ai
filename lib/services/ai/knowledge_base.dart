import '../../models/ride_log_model.dart';

class KnowledgeEntry {
  final List<String> keywords;
  final List<String> keywordsTagalog;
  final String response;
  final String category;
  final bool requiresContext;

  const KnowledgeEntry({
    required this.keywords,
    this.keywordsTagalog = const [],
    required this.response,
    required this.category,
    this.requiresContext = false,
  });
}

class KnowledgeBase {
  static const _entries = <KnowledgeEntry>[
    // ── PH TRAFFIC RULES ──
    KnowledgeEntry(
      keywords: ['edsa', 'motorcycle ban', 'motor ban', 'edsa ban'],
      keywordsTagalog: ['bawal motor edsa', 'edsa bawal', 'motor edsa'],
      response: 'Motorcycles are BANNED on EDSA main road (MMDA regulation). '
          'You can only use EDSA service roads. Violation: ₱500 fine + impounding. '
          'Alternative routes: C5, Shaw Blvd, Ortigas Ave service roads.',
      category: 'traffic_rules',
    ),
    KnowledgeEntry(
      keywords: ['number coding', 'coding scheme', 'plate number', 'coding today'],
      keywordsTagalog: ['coding', 'numero coding', 'bawal plate'],
      response: 'MMDA Number Coding (UVVRP):\n'
          '• Monday: plates ending 1, 2\n'
          '• Tuesday: 3, 4\n'
          '• Wednesday: 5, 6\n'
          '• Thursday: 7, 8\n'
          '• Friday: 9, 0\n'
          'Window: 7AM-8PM on major roads. Motorcycles are EXEMPT from number coding.',
      category: 'traffic_rules',
    ),
    KnowledgeEntry(
      keywords: ['helmet', 'helmet law', 'no helmet', 'helmet fine'],
      keywordsTagalog: ['helmet', 'walang helmet', 'helmet requirement'],
      response: 'RA 10054 (Motorcycle Helmet Act): Rider AND backrider must wear '
          'standard helmets with ICC sticker. Fine: ₱1,500 first offense, '
          '₱3,000 second, ₱5,000 + license suspension for third. '
          'Must be DOT/ECE certified, not construction hardhat.',
      category: 'traffic_rules',
    ),
    KnowledgeEntry(
      keywords: ['registration', 'or cr', 'lto registration', 'expired registration'],
      keywordsTagalog: ['rehistro', 'pag renew', 'expired rehistro'],
      response: 'LTO Registration renewal: Bring OR/CR, valid insurance (CTPL), '
          'and emission test result. Can renew online via LTMS portal or at '
          'LTO offices. Late renewal: ₱50/month penalty. Always carry original '
          'OR/CR — photocopy not accepted by enforcers.',
      category: 'traffic_rules',
    ),
    KnowledgeEntry(
      keywords: ['expressway', 'nlex', 'slex', 'skyway', 'tplex', 'calax'],
      keywordsTagalog: ['expressway', 'skyway motor', 'toll'],
      response: 'Motorcycle expressway rules:\n'
          '• NLEX: Allowed (Class 1, reduced toll)\n'
          '• SLEX: Allowed\n'
          '• Skyway: Allowed on Skyway Stage 1 & 3, some restrictions on Stage 2\n'
          '• TPLEX: Allowed\n'
          '• CALAX: Allowed\n'
          'All require Autosweep/Easytrip RFID. Minimum 400cc for some sections.',
      category: 'traffic_rules',
    ),
    KnowledgeEntry(
      keywords: ['speed limit', 'over speed', 'speeding'],
      keywordsTagalog: ['bilis', 'over speed', 'mabilis'],
      response: 'PH Speed Limits (RA 4136):\n'
          '• National highways: 80 kph\n'
          '• City/municipal roads: 30-60 kph\n'
          '• School zones: 20 kph\n'
          '• Expressways: 60-100 kph (varies)\n'
          'Fine: ₱150-₱1,000 depending on excess speed.',
      category: 'traffic_rules',
    ),
    KnowledgeEntry(
      keywords: ['drunk driving', 'anti drunk', 'alak', 'alcohol driving'],
      keywordsTagalog: ['lasing', 'bawal lasing', 'inom', 'alak motor'],
      response: 'RA 10586 (Anti-Drunk Driving Act): BAC limit 0.05%. '
          'Penalties: ₱20,000-₱500,000 fine + 3 months to 20 years imprisonment '
          'depending on severity. License suspension/revocation. '
          'Random breathalyzer checkpoints are common, especially on weekends.',
      category: 'traffic_rules',
    ),
    KnowledgeEntry(
      keywords: ['counterflow', 'swerving', 'reckless', 'reckless driving'],
      keywordsTagalog: ['counterflow', 'swerve', 'pabaya'],
      response: 'Counterflowing/Reckless Driving penalties:\n'
          '• Counterflow: ₱2,000 fine\n'
          '• Reckless driving: ₱2,000 first offense, ₱3,000 second\n'
          '• Can lead to license suspension. Always stay in your lane — '
          'it\'s the #1 cause of motorcycle fatalities in the Philippines.',
      category: 'traffic_rules',
    ),
    KnowledgeEntry(
      keywords: ['no contact', 'apprehension', 'lto contact', 'caught'],
      keywordsTagalog: ['no contact', 'huli', 'nahuli', 'tiket', 'ticket'],
      response: 'No Contact Apprehension Policy (NCAP):\n'
          '• CCTV-based ticketing in Metro Manila\n'
          '• Violations sent by mail to registered address\n'
          '• Check MMDA portal or LTO LTMS for tickets\n'
          '• You can contest within 10 days of notice\n'
          'Common violations caught: counterflow, beating red light, illegal parking.',
      category: 'traffic_rules',
    ),
    KnowledgeEntry(
      keywords: ['backrider', 'backride', 'passenger', 'angkas passenger'],
      keywordsTagalog: ['angkas', 'backrider', 'sakay'],
      response: 'Backrider rules: Maximum 1 passenger. Passenger must wear helmet. '
          'Children under 18 NOT allowed as motorcycle taxi passengers (DOTr rule). '
          'For Angkas/JoyRide: passenger must book through the app — no flag-down.',
      category: 'traffic_rules',
    ),
    KnowledgeEntry(
      keywords: ['license', 'drivers license', 'non pro', 'student permit'],
      keywordsTagalog: ['lisensya', 'license', 'student permit', 'non pro'],
      response: 'LTO Motorcycle License:\n'
          '• Student Permit: valid 1 year, must have supervisor\n'
          '• Non-Pro: 5-year validity\n'
          '• Pro: required for motorcycle taxi (Angkas, JoyRide)\n'
          'Requirements: TDC (Theoretical Driving Course) + PDC (Practical). '
          'Renewal at LTO or satellite offices. Apply via LTMS portal.',
      category: 'traffic_rules',
    ),
    KnowledgeEntry(
      keywords: ['checkpoint', 'police checkpoint', 'mmda checkpoint'],
      keywordsTagalog: ['checkpoint', 'hinto pulis', 'tsekpoint'],
      response: 'Checkpoint tips:\n'
          '• Always stop when flagged. Stay calm.\n'
          '• Have OR/CR, license, and insurance ready\n'
          '• You can record the interaction (legal in PH)\n'
          '• Officers must show ID if asked\n'
          '• They can check documents but NOT search without warrant\n'
          '• Report abusive enforcers to MMDA 136 or PNP hotline.',
      category: 'traffic_rules',
    ),

    // ── PLATFORM POLICIES ──
    KnowledgeEntry(
      keywords: ['grab fare', 'grab rate', 'grab base fare', 'grab commission'],
      keywordsTagalog: ['grab presyo', 'grab bayad', 'grab rate'],
      response: 'Grab Motorcycle (GrabBike):\n'
          '• Base fare: ~₱40\n'
          '• Per km: ~₱8-12 (varies by area)\n'
          '• Commission: ~20% of fare\n'
          '• Surge pricing during peak hours\n'
          '• Incentives vary weekly — check driver app for current promos.',
      category: 'platform_policies',
    ),
    KnowledgeEntry(
      keywords: ['foodpanda rate', 'foodpanda pay', 'panda commission', 'foodpanda fare'],
      keywordsTagalog: ['foodpanda bayad', 'panda rate', 'panda sweldo'],
      response: 'FoodPanda Rider Pay:\n'
          '• Per delivery: ₱35-65 base (distance-based)\n'
          '• Batch orders: higher per-batch rate\n'
          '• Peak hour bonus: +₱10-20 per delivery\n'
          '• Weekly incentive tiers based on delivery count\n'
          '• No commission deduction — you keep the delivery fee.',
      category: 'platform_policies',
    ),
    KnowledgeEntry(
      keywords: ['angkas rate', 'angkas fare', 'angkas pay', 'angkas commission'],
      keywordsTagalog: ['angkas presyo', 'angkas bayad', 'angkas sahod'],
      response: 'Angkas:\n'
          '• Base fare: ~₱40\n'
          '• Per km: ~₱7-10\n'
          '• Commission: ~18-20%\n'
          '• Peak pricing during rush hours\n'
          '• Rider rating must stay above 4.5\n'
          '• Fuel subsidy programs available periodically.',
      category: 'platform_policies',
    ),
    KnowledgeEntry(
      keywords: ['joyride rate', 'joyride fare', 'joyride commission'],
      keywordsTagalog: ['joyride presyo', 'joyride bayad'],
      response: 'JoyRide:\n'
          '• Base fare: ~₱35\n'
          '• Per km: ~₱7-9\n'
          '• Commission: ~15-18% (lower than Grab)\n'
          '• "JoyRide Express" higher rates for premium service\n'
          '• Regular promos and incentive programs for active riders.',
      category: 'platform_policies',
    ),
    KnowledgeEntry(
      keywords: ['lalamove rate', 'lalamove fare', 'lalamove motorcycle'],
      keywordsTagalog: ['lalamove presyo', 'lalamove motor'],
      response: 'Lalamove Motorcycle:\n'
          '• Base fare: ~₱63 (first 4 km)\n'
          '• Additional: ~₱15/km after\n'
          '• Extra charges for: multi-stop, fragile, COD\n'
          '• Commission: ~15-20%\n'
          '• Good for delivery riders — consistent demand.',
      category: 'platform_policies',
    ),
    KnowledgeEntry(
      keywords: ['moveit rate', 'moveit fare', 'move it commission'],
      keywordsTagalog: ['moveit presyo', 'move it bayad'],
      response: 'MoveIt:\n'
          '• Base fare: varies by vehicle type\n'
          '• Motorcycle: starting ~₱100 for small package\n'
          '• Commission: ~18-20%\n'
          '• Multi-stop delivery available\n'
          '• Good for heavy/bulky item deliveries.',
      category: 'platform_policies',
    ),
    KnowledgeEntry(
      keywords: ['cancel', 'cancellation', 'cancel fee', 'passenger cancel'],
      keywordsTagalog: ['cancel', 'kinansela', 'cancel fee'],
      response: 'Cancellation policies (most platforms):\n'
          '• Passenger cancel after 5 min: ₱30-50 cancellation fee to rider\n'
          '• Rider cancel: affects acceptance rate, too many = penalty\n'
          '• No-show passenger: wait 5 min, then cancel with fee\n'
          '• Grab: 3+ cancels/day may trigger temporary ban\n'
          'Tip: Screenshot the timer as proof of waiting.',
      category: 'platform_policies',
    ),
    KnowledgeEntry(
      keywords: ['incentive', 'bonus', 'quest', 'promo driver'],
      keywordsTagalog: ['incentive', 'bonus', 'promo rider'],
      response: 'Maximizing incentives:\n'
          '• Check your driver app daily for quest targets\n'
          '• Peak hour bonuses: typically 7-9 AM and 5-8 PM\n'
          '• Complete ride streaks without cancellation\n'
          '• Maintain 4.8+ rating for priority dispatch\n'
          '• Multi-apping: run 2 apps to reduce idle time (but don\'t double-book).',
      category: 'platform_policies',
    ),
    KnowledgeEntry(
      keywords: ['rating', 'rider rating', 'low rating', 'star'],
      keywordsTagalog: ['rating', 'mababang rating', 'bituin'],
      response: 'Protecting your rating:\n'
          '• Greet passengers warmly\n'
          '• Keep extra helmet clean and ready\n'
          '• Follow the app route (passengers get suspicious with shortcuts)\n'
          '• Offer phone holder for passenger to see route\n'
          '• Rating below 4.5 = fewer bookings. Below 4.0 = risk of deactivation.',
      category: 'platform_policies',
    ),
    KnowledgeEntry(
      keywords: ['multi app', 'multi-app', 'double app', '2 apps'],
      keywordsTagalog: ['dalawang app', 'multi app', 'sabay app'],
      response: 'Multi-apping tips:\n'
          '• Run Grab + Angkas or Grab + JoyRide simultaneously\n'
          '• Accept on ONE platform at a time — never double-book\n'
          '• Turn off one app when you accept a ride on another\n'
          '• Use Arangkada AI to track earnings across all platforms\n'
          '• Best during slow periods to reduce idle time.',
      category: 'platform_policies',
    ),

    // ── MOTORCYCLE MAINTENANCE ──
    KnowledgeEntry(
      keywords: ['oil change', 'change oil', 'engine oil', 'oil interval'],
      keywordsTagalog: ['palit oyl', 'change oil', 'oyl motor'],
      response: 'Oil change schedule for daily riders:\n'
          '• Every 1,500-2,000 km (or monthly if riding daily)\n'
          '• Use recommended grade (most PH bikes: 10W-40 or 15W-40)\n'
          '• Popular brands: Motul, Shell Advance, Repsol, Castrol\n'
          '• Budget: ~₱200-400 per change at shop\n'
          '• DIY saves money if you know how.',
      category: 'maintenance',
    ),
    KnowledgeEntry(
      keywords: ['tire', 'tire pressure', 'tire change', 'flat tire', 'gulong'],
      keywordsTagalog: ['gulong', 'hangin gulong', 'flat tire', 'psos gulong'],
      response: 'Tire care for riders:\n'
          '• Check pressure weekly: Front 28-32 PSI, Rear 32-36 PSI\n'
          '• Replace tires every 10,000-15,000 km\n'
          '• Look for cracks, bulges, or worn tread\n'
          '• Always carry a tire repair kit for emergencies\n'
          '• Tubeless tires recommended for daily riders — easier to repair.',
      category: 'maintenance',
    ),
    KnowledgeEntry(
      keywords: ['chain', 'chain lube', 'chain slack', 'sprocket'],
      keywordsTagalog: ['kadena', 'chain motor', 'sprocket'],
      response: 'Chain maintenance:\n'
          '• Clean and lube every 500 km (more often in rain)\n'
          '• Check slack: should be 20-30mm of play\n'
          '• Replace chain + sprocket set every 20,000-30,000 km\n'
          '• Signs of wear: stiff links, stretched chain, worn sprocket teeth\n'
          '• Budget: ~₱800-2,000 for chain+sprocket set.',
      category: 'maintenance',
    ),
    KnowledgeEntry(
      keywords: ['brake', 'brake pad', 'brakes', 'brake fluid'],
      keywordsTagalog: ['preno', 'brake pad', 'preno motor'],
      response: 'Brake maintenance:\n'
          '• Check pads every 3,000-5,000 km\n'
          '• Replace when pad thickness < 2mm\n'
          '• Brake fluid: change every 2 years or when it looks dark\n'
          '• Front brake does 70% of stopping — keep it in top shape\n'
          '• Squealing = time to replace. Grinding = OVERDUE.\n'
          '• Budget: ₱200-500 per pad set.',
      category: 'maintenance',
    ),
    KnowledgeEntry(
      keywords: ['battery', 'motor battery', 'dead battery', 'battery replacement'],
      keywordsTagalog: ['baterya', 'patay baterya', 'battery motor'],
      response: 'Motorcycle battery tips:\n'
          '• Lifespan: 1-2 years for daily riders\n'
          '• Signs of dying: slow crank, dim headlights, frequent stalling\n'
          '• MF (Maintenance-Free) batteries recommended\n'
          '• Brands: Motolite, GS, Yuasa (₱500-1,500)\n'
          '• Keep terminals clean. Check if charging system is working.',
      category: 'maintenance',
    ),
    KnowledgeEntry(
      keywords: ['spark plug', 'sparkplug', 'misfire', 'bujia'],
      keywordsTagalog: ['bujia', 'spark plug', 'bujia motor'],
      response: 'Spark plug care:\n'
          '• Replace every 6,000-8,000 km\n'
          '• Signs of wear: hard starting, poor fuel economy, misfires\n'
          '• Iridium plugs last longer but cost more\n'
          '• Always use the correct heat range for your bike\n'
          '• Budget: ₱80-300 per plug.',
      category: 'maintenance',
    ),
    KnowledgeEntry(
      keywords: ['tune up', 'tuneup', 'maintenance schedule', 'pms'],
      keywordsTagalog: ['tune up', 'pms motor', 'ayos motor'],
      response: 'Recommended PMS schedule:\n'
          '• Every 2,000 km: Oil change, chain lube\n'
          '• Every 5,000 km: Air filter, brake check\n'
          '• Every 10,000 km: Spark plug, valve clearance\n'
          '• Every 20,000 km: Chain+sprocket, brake fluid\n'
          '• Annual: Full tune-up, battery check\n'
          'Keeping a log in Arangkada AI helps track your intervals!',
      category: 'maintenance',
    ),

    // ── EARNINGS OPTIMIZATION ──
    KnowledgeEntry(
      keywords: ['earnings', 'how much', 'income', 'sahod', 'magkano kinikita'],
      keywordsTagalog: ['kita', 'sahod', 'magkano', 'income', 'kinikita'],
      response: '{earnings_summary}',
      category: 'earnings',
      requiresContext: true,
    ),
    KnowledgeEntry(
      keywords: ['average', 'per ride', 'average earnings', 'per trip'],
      keywordsTagalog: ['average kita', 'bawat trip', 'per ride'],
      response: '{per_ride_average}',
      category: 'earnings',
      requiresContext: true,
    ),
    KnowledgeEntry(
      keywords: ['best platform', 'which app', 'best app', 'pinaka malaki'],
      keywordsTagalog: ['pinaka malaki', 'anong app', 'best app'],
      response: '{platform_comparison}',
      category: 'earnings',
      requiresContext: true,
    ),
    KnowledgeEntry(
      keywords: ['peak hours', 'best time', 'busy hours', 'rush hour'],
      keywordsTagalog: ['peak', 'anong oras', 'busy oras', 'matao'],
      response: 'Peak earning hours in Metro Manila:\n'
          '• Morning rush: 6:30-9:00 AM (commuters)\n'
          '• Lunch: 11:00 AM-1:00 PM (food delivery)\n'
          '• Afternoon rush: 4:30-8:00 PM (commuters + dinner)\n'
          '• Late night: 9-11 PM (food delivery + going home)\n'
          '• Weekends: Lunch and dinner peaks are strongest.\n'
          'Tip: Position yourself near malls and business districts before peak.',
      category: 'earnings',
    ),
    KnowledgeEntry(
      keywords: ['hotspot', 'best area', 'busy area', 'where to ride'],
      keywordsTagalog: ['saan punuan', 'matao saan', 'hotspot'],
      response: 'Metro Manila hotspots for riders:\n'
          '• BGC / Taguig — corporate commuters + food delivery\n'
          '• Makati CBD — high-value rides\n'
          '• Ortigas Center — steady demand\n'
          '• SM Megamall / SM North area — passenger hub\n'
          '• Quezon City universities (UP, Ateneo area)\n'
          '• MOA / Pasay — airport trips + events\n'
          'Match platform to area: Grab for commuters, FoodPanda near food strips.',
      category: 'earnings',
    ),
    KnowledgeEntry(
      keywords: ['fuel cost', 'gas cost', 'fuel expense', 'gas budget'],
      keywordsTagalog: ['gastos gas', 'fuel budget', 'gas magkano'],
      response: '{fuel_analysis}',
      category: 'earnings',
      requiresContext: true,
    ),
    KnowledgeEntry(
      keywords: ['daily target', 'target', 'goal', 'how many rides'],
      keywordsTagalog: ['target', 'ilang ride', 'goal'],
      response: 'Daily earning targets (Metro Manila, motorcycle):\n'
          '• Moderate: ₱800-1,200/day (8-12 rides)\n'
          '• Good: ₱1,200-1,800/day (12-18 rides)\n'
          '• Hustle mode: ₱1,800-2,500/day (18+ rides, peak hours)\n'
          'After fuel: expect 30-40% of gross as net.\n'
          'Track your progress in the Ride Logger tab!',
      category: 'earnings',
    ),

    // ── MANILA LANDMARKS ──
    KnowledgeEntry(
      keywords: ['sm megamall', 'megamall', 'mega mall'],
      keywordsTagalog: ['megamall', 'sm mega'],
      response: 'SM Megamall — EDSA corner Julia Vargas, Mandaluyong.\n'
          'Parking: Motorcycle parking at Building A or B basement.\n'
          'Rider pickup: Use the designated TNVS pickup area (Building A, Ground Floor).\n'
          'Nearby: Ortigas Center, Shaw Station (MRT).',
      category: 'landmarks',
    ),
    KnowledgeEntry(
      keywords: ['sm north', 'trinoma', 'north edsa'],
      keywordsTagalog: ['sm north', 'trinoma'],
      response: 'SM North EDSA / TriNoma area — North EDSA, QC.\n'
          'Heavy traffic area. Use Mindanao Ave or Congressional Ave as alternatives.\n'
          'Rider pickup: SM North main entrance or TriNoma Bus Terminal side.\n'
          'Nearby: MRT North Avenue Station, Muñoz.',
      category: 'landmarks',
    ),
    KnowledgeEntry(
      keywords: ['bgc', 'bonifacio global', 'taguig'],
      keywordsTagalog: ['bgc', 'fort', 'bonifacio'],
      response: 'BGC (Bonifacio Global City) — Taguig.\n'
          'Grid layout — easy to navigate. Speed limit 40 kph enforced.\n'
          'Enter via Kalayaan Flyover, McKinley Road, or Market Market side.\n'
          'Parking: Motorcycle parking available at most buildings.\n'
          'High-value area for ride-hailing — corporate workers during rush hour.',
      category: 'landmarks',
    ),
    KnowledgeEntry(
      keywords: ['naia', 'airport', 'terminal', 'pasay airport'],
      keywordsTagalog: ['airport', 'naia', 'paliparan'],
      response: 'NAIA Terminals:\n'
          '• T1: International (Pasay side)\n'
          '• T2: PAL/Cebu Pacific (Pasay side)\n'
          '• T3: Cebu Pacific/AirAsia (Pasay-Parañaque)\n'
          '• T4: Domestic budget airlines\n'
          'Motorcycle taxi pickup: designated areas only. '
          'Heavy traffic on NAIA Road — use Skyway for faster access.',
      category: 'landmarks',
    ),
    KnowledgeEntry(
      keywords: ['makati', 'ayala', 'makati cbd'],
      keywordsTagalog: ['makati', 'ayala'],
      response: 'Makati CBD — Ayala Avenue, Gil Puyat (Buendia) area.\n'
          'One-way streets: memorize Ayala, Paseo, Rufino directions.\n'
          'Rider pickup: Ayala Triangle, Greenbelt area.\n'
          'Peak demand: 6-9 AM and 5-8 PM. Lots of short rides = high volume.',
      category: 'landmarks',
    ),
    KnowledgeEntry(
      keywords: ['hospital', 'nearest hospital', 'emergency hospital', 'ospital'],
      keywordsTagalog: ['ospital', 'hospital', 'emergency room'],
      response: 'Major hospitals in Metro Manila:\n'
          '• PGH — Taft Ave, Manila (public, free ER)\n'
          '• East Avenue Medical Center — QC (public)\n'
          '• St. Luke\'s BGC — Taguig (private)\n'
          '• Makati Medical Center — Makati (private)\n'
          '• The Medical City — Ortigas (private)\n'
          '• Ospital ng Maynila — Malate (public)\n'
          'For emergencies: call 911 or go to nearest ER.',
      category: 'landmarks',
    ),
    KnowledgeEntry(
      keywords: ['lto office', 'lto branch', 'nearest lto'],
      keywordsTagalog: ['lto', 'lto malapit', 'lto saan'],
      response: 'LTO Offices in Metro Manila:\n'
          '• LTO Central — East Ave, QC\n'
          '• LTO Makati — Pasong Tamo\n'
          '• LTO Manila (Ermita) — UN Ave\n'
          '• LTO Las Piñas — Alabang-Zapote Rd\n'
          '• SM branches: License renewal at select SM malls\n'
          'Online: LTMS portal for appointment booking.',
      category: 'landmarks',
    ),

    // ── EMERGENCY ──
    KnowledgeEntry(
      keywords: ['emergency', 'accident', 'aksidente', 'help', 'tulong'],
      keywordsTagalog: ['emergency', 'aksidente', 'tulong', 'saklolo'],
      response: 'EMERGENCY NUMBERS:\n'
          '🚨 911 — National Emergency Hotline\n'
          '🚔 PNP: 117 or (02) 8722-0650\n'
          '🚦 MMDA: 136 or (02) 8882-4151\n'
          '🚑 Red Cross: 143\n'
          '🔥 BFP: (02) 8426-0219\n'
          '🏥 DOH Health Hotline: 1555\n\n'
          'If in an accident: 1) Move to safety 2) Call 911 3) Don\'t remove helmet '
          '4) Take photos of the scene 5) Exchange info with other party.',
      category: 'emergency',
    ),
    KnowledgeEntry(
      keywords: ['road crash', 'accident what to do', 'nagka aksidente'],
      keywordsTagalog: ['nagka aksidente', 'nabangga', 'nasagasaan'],
      response: 'What to do after a road crash:\n'
          '1. Check yourself for injuries. Don\'t move if spine/neck pain.\n'
          '2. Move to roadside if you can walk.\n'
          '3. Call 911 immediately.\n'
          '4. DO NOT remove your helmet until medics arrive.\n'
          '5. Take photos: damage, license plates, road conditions.\n'
          '6. Get police report — needed for insurance claims.\n'
          '7. Don\'t admit fault or sign anything at the scene.',
      category: 'emergency',
    ),
    KnowledgeEntry(
      keywords: ['stolen', 'carnap', 'motorcycle stolen', 'theft'],
      keywordsTagalog: ['nakaw', 'kinarnap', 'ninakaw motor'],
      response: 'If your motorcycle is stolen:\n'
          '1. Report to nearest police station IMMEDIATELY\n'
          '2. Bring OR/CR copy and photo of motorcycle\n'
          '3. File a police report (blotter)\n'
          '4. Report to LTO Anti-Carnapping Unit: (02) 8920-8068\n'
          '5. Post on social media (PH rider groups help a lot)\n'
          '6. Check CCTV if available in the area\n'
          '7. File insurance claim if comprehensive coverage.',
      category: 'emergency',
    ),

    // ── APP FEATURES ──
    KnowledgeEntry(
      keywords: ['offline map', 'download map', 'offline mode', 'no signal map'],
      keywordsTagalog: ['offline mapa', 'download mapa', 'walang signal mapa'],
      response: 'Arangkada AI Offline Maps:\n'
          '1. Go to Settings → Offline Maps\n'
          '2. Tap "DOWNLOAD" to save Metro Manila map tiles\n'
          '3. Wait for download to complete (~500-700 MB)\n'
          '4. Done! Map works even with zero signal.\n\n'
          'The map auto-caches tiles as you browse, so areas you visit '
          'frequently are already saved.',
      category: 'app_features',
    ),
    KnowledgeEntry(
      keywords: ['hazard', 'report hazard', 'pothole report', 'baha report'],
      keywordsTagalog: ['report lubak', 'report baha', 'hazard'],
      response: 'Reporting hazards in Arangkada AI:\n'
          '1. Tap the warning icon (⚠️) on the map\n'
          '2. Select hazard type: Pothole, Flood, Checkpoint, Construction, Accident\n'
          '3. Add description (optional)\n'
          '4. Submit — it logs your GPS automatically\n\n'
          'Reports are saved offline and sync when you\'re back online. '
          'Other riders will see your reports on their map!',
      category: 'app_features',
    ),
    KnowledgeEntry(
      keywords: ['ride logger', 'log ride', 'track earnings', 'track ride'],
      keywordsTagalog: ['log ride', 'track kita', 'ride record'],
      response: 'Using the Ride Logger:\n'
          '1. Go to the Rides tab\n'
          '2. Select your platform (Grab, FoodPanda, etc.)\n'
          '3. Tap "START RIDE" when you get a booking\n'
          '4. GPS tracks your distance automatically\n'
          '5. Tap "END RIDE" and enter your earnings\n\n'
          'View daily/weekly stats, earnings by platform, and fuel costs. '
          'Helps you find your most profitable platform!',
      category: 'app_features',
    ),
    KnowledgeEntry(
      keywords: ['navigation', 'navigate', 'directions', 'route'],
      keywordsTagalog: ['navigate', 'direksyon', 'ruta', 'daan'],
      response: 'Arangkada AI Navigation:\n'
          '1. Search for destination in the search bar\n'
          '2. Select from search results\n'
          '3. View route options: Fastest, Shortest, AI Recommended\n'
          '4. Tap "Start Navigation" for turn-by-turn guidance\n\n'
          'AI Recommended route considers traffic, road conditions, and '
          'hazard reports from other riders.',
      category: 'app_features',
    ),
    KnowledgeEntry(
      keywords: ['voice', 'voice command', 'voice assistant', 'boses'],
      keywordsTagalog: ['boses', 'voice', 'salita', 'voice command'],
      response: 'Voice features in Arangkada AI:\n'
          '• Voice search: tap the mic icon in search bar\n'
          '• Voice navigation: turn-by-turn audio directions\n'
          '• Works in English and Filipino\n'
          '• Voice commands work offline too!\n'
          'Tip: Connect Bluetooth earpiece for hands-free navigation.',
      category: 'app_features',
    ),
    KnowledgeEntry(
      keywords: ['search', 'search place', 'find place', 'hanap lugar'],
      keywordsTagalog: ['hanapin', 'search lugar', 'saan'],
      response: 'Searching in Arangkada AI:\n'
          '• Type any place, address, or landmark in the search bar\n'
          '• Browse by category: Food, Gas, ATM, Hospital, etc.\n'
          '• Results show distance and direction from you\n'
          '• Tap a result to see it on the map or navigate\n\n'
          'Search works offline too! Previously viewed places are cached.',
      category: 'app_features',
    ),

    // ── WEATHER & SAFETY ──
    KnowledgeEntry(
      keywords: ['rain', 'rainy', 'ulan', 'wet road', 'storm'],
      keywordsTagalog: ['ulan', 'maulan', 'basa daan', 'bagyo'],
      response: 'Riding in the rain safely:\n'
          '• Slow down — braking distance doubles on wet roads\n'
          '• Avoid painted lines and manhole covers (very slippery)\n'
          '• Use both brakes gently — never grab front brake hard\n'
          '• Wear bright/reflective gear for visibility\n'
          '• If heavy rain: pull over and wait it out — not worth the risk\n'
          '• Watch for flash floods, especially in Manila low-lying areas.',
      category: 'weather_safety',
    ),
    KnowledgeEntry(
      keywords: ['flood route', 'baha area', 'flood prone', 'flood avoid'],
      keywordsTagalog: ['baha area', 'binabaha', 'baha saan'],
      response: 'Known flood-prone areas in Metro Manila:\n'
          '• España Blvd (Manila)\n'
          '• A. Bonifacio Ave (QC)\n'
          '• Taft Avenue (near PGH)\n'
          '• Lacson Ave underpass\n'
          '• Katipunan near Ateneo\n'
          '• Sucat Road (Parañaque)\n'
          '• Libertad, Pasay\n\n'
          'Check Arangkada AI hazard reports for real-time flood info from riders!',
      category: 'weather_safety',
    ),
    KnowledgeEntry(
      keywords: ['night riding', 'gabi', 'night', 'dark road'],
      keywordsTagalog: ['gabi', 'dilim', 'night ride', 'madilim'],
      response: 'Night riding safety tips:\n'
          '• Check all lights before riding (headlight, tail, signal)\n'
          '• Wear reflective vest or tape\n'
          '• Stay on well-lit main roads when possible\n'
          '• Extra caution at intersections — many runners at night\n'
          '• Keep visor up or use clear visor (tinted = dangerous at night)\n'
          '• Avoid isolated areas. Trust your gut — if it feels unsafe, leave.',
      category: 'weather_safety',
    ),
    KnowledgeEntry(
      keywords: ['heat', 'init', 'hot', 'summer', 'dehydrated'],
      keywordsTagalog: ['init', 'mainit', 'summer', 'pawis'],
      response: 'Riding in extreme heat:\n'
          '• Hydrate every 30 min — carry a water bottle\n'
          '• Wear light-colored riding gear\n'
          '• Take breaks every 2 hours in shade\n'
          '• Signs of heat stroke: dizziness, nausea, no sweating — STOP riding\n'
          '• Avoid 11 AM - 2 PM rides if possible\n'
          '• Keep your bike cool — overheating engine = breakdown risk.',
      category: 'weather_safety',
    ),
    KnowledgeEntry(
      keywords: ['earthquake', 'lindol', 'quake'],
      keywordsTagalog: ['lindol', 'earthquake', 'lumilindol'],
      response: 'Earthquake while riding:\n'
          '1. Pull over to the side immediately\n'
          '2. Stay away from buildings, overpasses, power lines\n'
          '3. Keep helmet on for protection from falling debris\n'
          '4. After shaking stops: check road for cracks/damage\n'
          '5. Avoid bridges and flyovers until cleared\n'
          '6. Check 911 or PHIVOLCS for updates before continuing.',
      category: 'weather_safety',
    ),

    // ── FUEL TIPS ──
    KnowledgeEntry(
      keywords: ['cheap gas', 'gas station', 'murang gas', 'fuel price'],
      keywordsTagalog: ['murang gas', 'mura gas', 'presyo gas'],
      response: 'Finding cheaper fuel:\n'
          '• Independent stations are usually ₱2-5/L cheaper than branded\n'
          '• Shell, Petron, Caltex — use loyalty cards for rebates\n'
          '• Unioil, Seaoil, Phoenix — consistently lower prices\n'
          '• Fill up early Tuesday (after price adjustment day)\n'
          '• DOE Oil Monitor: check for weekly price rollbacks\n'
          'Tip: Save your frequent gas station in Arangkada AI for quick navigation.',
      category: 'fuel',
    ),
    KnowledgeEntry(
      keywords: ['fuel efficiency', 'tipid gas', 'save fuel', 'fuel saving'],
      keywordsTagalog: ['tipid gas', 'tipid fuel', 'makatipid gas'],
      response: 'Fuel-saving tips:\n'
          '• Maintain steady speed — avoid hard acceleration\n'
          '• Keep tire pressure correct (saves up to 3% fuel)\n'
          '• Regular tune-ups improve efficiency 10-15%\n'
          '• Don\'t idle too long — turn off at long traffic lights\n'
          '• Use routes with fewer stops (less braking = less fuel)\n'
          '• Avoid overloading — extra weight = more fuel.',
      category: 'fuel',
    ),

    // ── LEGAL ──
    KnowledgeEntry(
      keywords: ['insurance', 'ctpl', 'comprehensive', 'motor insurance'],
      keywordsTagalog: ['insurance', 'seguro', 'ctpl'],
      response: 'Motorcycle insurance in PH:\n'
          '• CTPL (Compulsory Third Party Liability): REQUIRED for registration\n'
          '  - Covers injury to third parties only\n'
          '  - Cost: ~₱350-700/year\n'
          '• Comprehensive: Optional but recommended for riders\n'
          '  - Covers theft, accident, fire\n'
          '  - Cost: ~₱3,000-8,000/year depending on bike value\n'
          '• Providers: Standard Insurance, Malayan, Pioneer, FPG.',
      category: 'legal',
    ),
    KnowledgeEntry(
      keywords: ['franchise', 'tnvs', 'cpc', 'ltfrb'],
      keywordsTagalog: ['franchise', 'tnvs permit', 'ltfrb'],
      response: 'Motorcycle Taxi Franchise (LTFRB):\n'
          '• Required for Angkas, JoyRide legal operation\n'
          '• CPC (Certificate of Public Convenience) per unit\n'
          '• Requirements: Pro license, registration, insurance, NBI clearance\n'
          '• Apply through your platform (Angkas/JoyRide handles filing)\n'
          '• Operating without franchise: ₱200K fine + impounding.',
      category: 'legal',
    ),
    KnowledgeEntry(
      keywords: ['tax', 'taxes', 'bir', 'income tax rider'],
      keywordsTagalog: ['tax', 'buwis', 'bir', 'income tax'],
      response: 'Tax for riders:\n'
          '• If earning < ₱250,000/year: EXEMPT from income tax\n'
          '• Still need to register with BIR as self-employed\n'
          '• 8% flat rate option for those earning ₱250K-₃M\n'
          '• Keep records of expenses (fuel, maintenance) for deductions\n'
          '• Arangkada AI Ride Logger data helps track income for BIR filing.\n'
          '• Deadline: April 15 annually.',
      category: 'legal',
    ),

    // ── GENERAL GREETINGS ──
    KnowledgeEntry(
      keywords: ['hello', 'hi', 'hey', 'yo', 'sup'],
      keywordsTagalog: ['musta', 'kamusta', 'oy', 'hoy', 'pre'],
      response: '{greeting}',
      category: 'greeting',
      requiresContext: true,
    ),
    KnowledgeEntry(
      keywords: ['thank', 'thanks', 'salamat', 'nice'],
      keywordsTagalog: ['salamat', 'thank you', 'sige', 'ayos'],
      response: 'You\'re welcome, rider! Happy to help. '
          'Kung may iba ka pang tanong — from traffic rules to earnings tips — '
          'just ask. Ride safe! 🏍️',
      category: 'greeting',
    ),
    KnowledgeEntry(
      keywords: ['who are you', 'ano ka', 'what are you', 'about'],
      keywordsTagalog: ['sino ka', 'ano ka', 'tungkol sa'],
      response: 'Ako si Arangkada AI — your 24/7 Filipino rider assistant! 🏍️\n\n'
          'I can help with:\n'
          '• Traffic rules & regulations\n'
          '• Earnings optimization & platform tips\n'
          '• Motorcycle maintenance\n'
          '• Navigation & offline maps\n'
          '• Emergency info\n'
          '• Manila landmarks & directions\n\n'
          'I work offline too — no signal needed! Taglish or English, G!',
      category: 'greeting',
    ),
  ];

  static ({String response, String category, bool found}) match(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return (response: '', category: '', found: false);

    int bestScore = 0;
    KnowledgeEntry? bestEntry;

    for (final entry in _entries) {
      int score = 0;
      for (final kw in entry.keywords) {
        if (q == kw) {
          score += 10;
        } else if (q.contains(kw)) {
          score += 5 + kw.length;
        } else if (kw.split(' ').any((w) => q.contains(w) && w.length > 2)) {
          score += 2;
        }
      }
      for (final kw in entry.keywordsTagalog) {
        if (q == kw) {
          score += 10;
        } else if (q.contains(kw)) {
          score += 5 + kw.length;
        } else if (kw.split(' ').any((w) => q.contains(w) && w.length > 2)) {
          score += 2;
        }
      }
      if (score > bestScore) {
        bestScore = score;
        bestEntry = entry;
      }
    }

    if (bestEntry != null && bestScore >= 2) {
      return (
        response: bestEntry.response,
        category: bestEntry.category,
        found: true,
      );
    }

    return (response: '', category: '', found: false);
  }

  static int get entryCount => _entries.length;
}
