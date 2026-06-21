import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../config/theme/malate_colors.dart';
import '../config/theme/malate_typography.dart';
import '../widgets/malate_card.dart';
import '../services/ride_logger.dart';
import '../services/fatigue_monitor.dart';
import '../core/database/local_database.dart';

class SafetyScreen extends StatefulWidget {
  const SafetyScreen({super.key});

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen> {
  List<Map<String, String>> _contacts = [];
  Position? _currentPosition;
  bool _loadingGps = false;

  static const String _contactsKey = 'emergency_contacts_json';
  static const int _maxContacts = 3;

  static const List<Map<String, String>> _safetyTips = [
    {
      'icon': '🪖',
      'tip': 'Laging mag-helmet at safety gear',
    },
    {
      'icon': '🛑',
      'tip': 'Check your brakes before every ride',
    },
    {
      'icon': '🚛',
      'tip': 'Avoid blind spots ng mga truck',
    },
    {
      'icon': '📵',
      'tip': 'Wag gumamit ng phone habang nagmamaneho',
    },
    {
      'icon': '🔆',
      'tip': 'Stay visible — use reflectors at night',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _fetchGps();
  }

  Future<void> _loadContacts() async {
    final raw = await LocalDatabase.getRiderSetting(_contactsKey);
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw) as List<dynamic>;
      setState(() {
        _contacts = decoded
            .map((e) => Map<String, String>.from(e as Map))
            .toList();
      });
    }
  }

  Future<void> _saveContacts() async {
    final encoded = jsonEncode(_contacts);
    await LocalDatabase.setRiderSetting(_contactsKey, encoded);
  }

  Future<void> _fetchGps() async {
    setState(() => _loadingGps = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() => _loadingGps = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      setState(() {
        _currentPosition = pos;
        _loadingGps = false;
      });
    } catch (_) {
      setState(() => _loadingGps = false);
    }
  }

  String _buildSosMessage() {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    if (_currentPosition != null) {
      final lat = _currentPosition!.latitude.toStringAsFixed(6);
      final lng = _currentPosition!.longitude.toStringAsFixed(6);
      return 'EMERGENCY! Arangkada AI SOS. Rider needs help at: '
          'https://maps.google.com/?q=$lat,$lng Time: $dateStr';
    }
    return 'EMERGENCY! Arangkada AI SOS. Rider needs help. Time: $dateStr '
        '(GPS unavailable)';
  }

  Future<void> _onSosTap() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final c = MalateColors.of(ctx);
        return AlertDialog(
          backgroundColor: c.asphalt,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: MalateColors.hazardRed, width: 1.5),
          ),
          title: Text(
            'Send SOS?',
            style: MalateTypography.headlineMedium
                .copyWith(color: MalateColors.hazardRed),
          ),
          content: Text(
            'Send SOS to emergency contacts?',
            style: MalateTypography.bodyMedium.copyWith(color: c.textPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'CANCEL',
                style: MalateTypography.labelLarge
                    .copyWith(color: c.textMuted),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                'SEND SOS',
                style: MalateTypography.labelLarge
                    .copyWith(color: MalateColors.hazardRed),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final msg = _buildSosMessage();
    await Clipboard.setData(ClipboardData(text: msg));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: MalateColors.hazardRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Text(
          'SOS message copied! Paste it to send to your contacts.',
          style: MalateTypography.bodySmall
              .copyWith(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showAddContactDialog() {
    if (_contacts.length >= _maxContacts) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Maximum $_maxContacts contacts reached.',
            style: MalateTypography.bodySmall,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final c = MalateColors.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.asphalt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: c.sidewalk),
        ),
        title: Text(
          'Add Emergency Contact',
          style: MalateTypography.headlineSmall.copyWith(color: c.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: MalateTypography.bodyMedium.copyWith(color: c.textPrimary),
              decoration: InputDecoration(
                labelText: 'Name',
                labelStyle:
                    MalateTypography.bodySmall.copyWith(color: c.textMuted),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: c.sidewalk),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: MalateColors.neonMint),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              style: MalateTypography.bodyMedium.copyWith(color: c.textPrimary),
              decoration: InputDecoration(
                labelText: 'Phone Number',
                labelStyle:
                    MalateTypography.bodySmall.copyWith(color: c.textMuted),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: c.sidewalk),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: MalateColors.neonMint),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'CANCEL',
              style: MalateTypography.labelLarge.copyWith(color: c.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final phone = phoneCtrl.text.trim();
              if (name.isEmpty || phone.isEmpty) return;
              setState(() {
                _contacts.add({'name': name, 'phone': phone});
              });
              _saveContacts();
              Navigator.of(ctx).pop();
            },
            child: Text(
              'ADD',
              style: MalateTypography.labelLarge
                  .copyWith(color: MalateColors.neonMint),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteContact(int index) {
    setState(() => _contacts.removeAt(index));
    _saveContacts();
  }

  Duration _todayRideDuration(RideLogger logger) {
    final total = logger.todayLogs.fold<Duration>(
      Duration.zero,
      (acc, ride) => acc + ride.duration,
    );
    return total;
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  Color _timerColor(Duration d) {
    if (d.inHours >= 4) return MalateColors.hazardRed;
    if (d.inHours >= 2) return MalateColors.electricAmber;
    return MalateColors.neonMint;
  }

  @override
  Widget build(BuildContext context) {
    final c = MalateColors.of(context);
    final logger = context.watch<RideLogger>();
    final rideTime = _todayRideDuration(logger);
    final timerColor = _timerColor(rideTime);

    return Scaffold(
      backgroundColor: c.midnight,
      appBar: AppBar(
        backgroundColor: c.midnight,
        elevation: 0,
        title: Text(
          'RIDER SAFETY',
          style: MalateTypography.neonAccent(MalateColors.hazardRed),
        ),
        iconTheme: IconThemeData(color: c.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _buildSosSection(c),
          const SizedBox(height: 20),
          _buildContactsSection(c),
          const SizedBox(height: 20),
          _buildRideTimerSection(c, rideTime, timerColor),
          const SizedBox(height: 20),
          _buildSafetyTipsSection(c),
        ],
      ),
    );
  }

  Widget _buildSosSection(dynamic c) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.asphalt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: MalateColors.hazardRed.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: MalateColors.neonGlow(MalateColors.hazardRed, intensity: 0.2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'SOS EMERGENCY',
                style: MalateTypography.neonAccent(MalateColors.hazardRed),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: MalateColors.hazardRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: MalateColors.hazardRed.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'EMERGENCY',
                  style: MalateTypography.labelSmall
                      .copyWith(color: MalateColors.hazardRed),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _onSosTap,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MalateColors.hazardRed,
                boxShadow:
                    MalateColors.neonGlow(MalateColors.hazardRed, intensity: 0.5),
              ),
              child: const Center(
                child: Text(
                  'SOS',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tap to copy SOS message',
            style: MalateTypography.bodySmall.copyWith(color: c.textMuted),
          ),
          const SizedBox(height: 12),
          _buildGpsCoords(c),
        ],
      ),
    );
  }

  Widget _buildGpsCoords(dynamic c) {
    if (_loadingGps) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: MalateColors.cyberCyan,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Getting GPS...',
            style: MalateTypography.bodySmall
                .copyWith(color: MalateColors.cyberCyan),
          ),
        ],
      );
    }

    if (_currentPosition == null) {
      return GestureDetector(
        onTap: _fetchGps,
        child: Text(
          'GPS unavailable — tap to retry',
          style: MalateTypography.bodySmall
              .copyWith(color: c.textMuted),
        ),
      );
    }

    final lat = _currentPosition!.latitude.toStringAsFixed(5);
    final lng = _currentPosition!.longitude.toStringAsFixed(5);
    return Column(
      children: [
        Text(
          'Current Location',
          style: MalateTypography.labelSmall.copyWith(color: c.textMuted),
        ),
        const SizedBox(height: 4),
        Text(
          '$lat, $lng',
          style: MalateTypography.bodySmall
              .copyWith(color: MalateColors.cyberCyan, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _fetchGps,
          child: Text(
            'Refresh location',
            style: MalateTypography.labelSmall
                .copyWith(color: c.textMuted, decoration: TextDecoration.underline),
          ),
        ),
      ],
    );
  }

  Widget _buildContactsSection(dynamic c) {
    return MalateCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'EMERGENCY CONTACTS',
                style: MalateTypography.neonAccent(MalateColors.electricAmber),
              ),
              const Spacer(),
              Text(
                '${_contacts.length}/$_maxContacts',
                style: MalateTypography.bodySmall.copyWith(color: c.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Long-press a contact to delete',
            style: MalateTypography.labelSmall.copyWith(color: c.textMuted),
          ),
          const SizedBox(height: 14),
          if (_contacts.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No emergency contacts saved yet.',
                  style: MalateTypography.bodySmall.copyWith(color: c.textMuted),
                ),
              ),
            )
          else
            ...List.generate(_contacts.length, (i) {
              final contact = _contacts[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onLongPress: () => _confirmDeleteContact(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: c.gutter,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.sidewalk),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: MalateColors.electricAmber.withValues(alpha: 0.15),
                            border: Border.all(
                              color: MalateColors.electricAmber.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              (contact['name'] ?? '?')[0].toUpperCase(),
                              style: MalateTypography.headlineSmall
                                  .copyWith(color: MalateColors.electricAmber),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                contact['name'] ?? '',
                                style: MalateTypography.bodyMedium
                                    .copyWith(color: c.textPrimary, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                contact['phone'] ?? '',
                                style: MalateTypography.bodySmall
                                    .copyWith(color: c.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right,
                            color: c.textMuted, size: 18),
                      ],
                    ),
                  ),
                ),
              );
            }),
          const SizedBox(height: 4),
          if (_contacts.length < _maxContacts)
            GestureDetector(
              onTap: _showAddContactDialog,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: MalateColors.electricAmber.withValues(alpha: 0.4),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: MalateColors.electricAmber.withValues(alpha: 0.06),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add,
                        color: MalateColors.electricAmber, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'ADD CONTACT',
                      style: MalateTypography.labelLarge
                          .copyWith(color: MalateColors.electricAmber),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _confirmDeleteContact(int index) {
    final c = MalateColors.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.asphalt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: c.sidewalk),
        ),
        title: Text(
          'Remove Contact?',
          style: MalateTypography.headlineSmall.copyWith(color: c.textPrimary),
        ),
        content: Text(
          'Remove "${_contacts[index]['name']}" from emergency contacts?',
          style: MalateTypography.bodyMedium.copyWith(color: c.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('CANCEL',
                style: MalateTypography.labelLarge.copyWith(color: c.textMuted)),
          ),
          TextButton(
            onPressed: () {
              _deleteContact(index);
              Navigator.of(ctx).pop();
            },
            child: Text('REMOVE',
                style: MalateTypography.labelLarge
                    .copyWith(color: MalateColors.hazardRed)),
          ),
        ],
      ),
    );
  }

  Widget _buildRideTimerSection(dynamic c, Duration rideTime, Color timerColor) {
    final isOverFourHours = rideTime.inHours >= 4;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.asphalt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: timerColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: MalateColors.subtleGlow(timerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RIDE TIMER & REST REMINDER',
            style: MalateTypography.neonAccent(MalateColors.cyberCyan),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: timerColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: timerColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  _formatDuration(rideTime),
                  style: MalateTypography.headlineLarge
                      .copyWith(color: timerColor),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Riding today',
                      style: MalateTypography.bodySmall
                          .copyWith(color: c.textMuted),
                    ),
                    const SizedBox(height: 4),
                    _buildTimerLabel(rideTime, timerColor),
                  ],
                ),
              ),
            ],
          ),
          if (isOverFourHours) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MalateColors.hazardRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: MalateColors.hazardRed.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Magpahinga ka na, rider! You\'ve been riding for over 4 hours.',
                      style: MalateTypography.bodySmall.copyWith(
                          color: MalateColors.hazardRed,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.info_outline, color: c.textMuted, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Take a 15-minute break every 2 hours for safety.',
                  style: MalateTypography.bodySmall.copyWith(color: c.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Consumer<FatigueMonitor>(
            builder: (_, fatigue, __) {
              final fatigueColor = fatigue.mustRest
                  ? MalateColors.hazardRed
                  : fatigue.shouldRest
                      ? MalateColors.electricAmber
                      : MalateColors.neonMint;
              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: fatigueColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: fatigueColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.timer, color: fatigueColor, size: 18),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Continuous ride',
                              style: MalateTypography.labelSmall
                                  .copyWith(color: c.textMuted),
                            ),
                            Text(
                              fatigue.rideTimeText,
                              style: MalateTypography.headlineSmall
                                  .copyWith(color: fatigueColor),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (fatigue.shouldRest)
                          GestureDetector(
                            onTap: fatigue.markRest,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: fatigueColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'TAKE A BREAK',
                                style: MalateTypography.labelSmall.copyWith(
                                  color: c.midnight,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimerLabel(Duration rideTime, Color timerColor) {
    String label;
    if (rideTime.inHours >= 4) {
      label = 'Overdue for rest';
    } else if (rideTime.inHours >= 2) {
      label = 'Rest recommended';
    } else {
      label = 'Looking good';
    }
    return Text(
      label,
      style: MalateTypography.bodySmall
          .copyWith(color: timerColor, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildSafetyTipsSection(dynamic c) {
    return MalateCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SAFETY TIPS',
            style: MalateTypography.neonAccent(MalateColors.neonMint),
          ),
          const SizedBox(height: 14),
          ...List.generate(_safetyTips.length, (i) {
            final tip = _safetyTips[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: MalateColors.neonMint.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color:
                              MalateColors.neonMint.withValues(alpha: 0.2)),
                    ),
                    child: Center(
                      child: Text(
                        tip['icon']!,
                        style: const TextStyle(fontSize: 17),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        tip['tip']!,
                        style: MalateTypography.bodyMedium
                            .copyWith(color: c.textPrimary),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
