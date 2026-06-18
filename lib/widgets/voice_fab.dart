import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme/malate_colors.dart';
import '../config/theme/malate_typography.dart';
import '../services/voice_command_service.dart';

class VoiceFab extends StatefulWidget {
  const VoiceFab({super.key});

  @override
  State<VoiceFab> createState() => _VoiceFabState();
}

class _VoiceFabState extends State<VoiceFab> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = MalateColors.of(context);
    final voice = context.watch<VoiceCommandService>();

    if (voice.isListening && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!voice.isListening && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (voice.transcript.isNotEmpty &&
            (voice.state == VoiceCommandState.listening ||
                voice.state == VoiceCommandState.processing))
          _transcriptBubble(c, voice),

        if (voice.resultMessage.isNotEmpty &&
            voice.state == VoiceCommandState.idle)
          _resultBubble(c, voice),

        const SizedBox(height: 8),

        ScaleTransition(
          scale: _pulseAnimation,
          child: GestureDetector(
            onTap: () {
              if (voice.isListening) {
                voice.stopListening();
              } else {
                voice.startListening();
              }
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: c.asphalt,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _borderColor(voice.state),
                  width: voice.isListening ? 2 : 1,
                ),
                boxShadow: voice.isListening
                    ? [
                        BoxShadow(
                          color: MalateColors.neonMint.withValues(alpha: 0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: _icon(voice.state, c),
            ),
          ),
        ),
      ],
    );
  }

  Widget _transcriptBubble(dynamic c, VoiceCommandService voice) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.asphalt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MalateColors.neonMint.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (voice.state == VoiceCommandState.processing)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: MalateColors.neonMint,
                ),
              ),
            ),
          Flexible(
            child: Text(
              voice.transcript,
              style: MalateTypography.bodySmall.copyWith(
                color: MalateColors.neonMint,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultBubble(dynamic c, VoiceCommandService voice) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      builder: (_, opacity, child) => Opacity(opacity: opacity, child: child),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: c.asphalt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.sidewalk),
        ),
        child: Text(
          voice.resultMessage,
          style: MalateTypography.bodySmall,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Color _borderColor(VoiceCommandState state) {
    return switch (state) {
      VoiceCommandState.listening => MalateColors.neonMint,
      VoiceCommandState.processing => MalateColors.electricAmber,
      VoiceCommandState.error => MalateColors.hazardRed,
      VoiceCommandState.idle => MalateColors.cyberCyan.withValues(alpha: 0.4),
    };
  }

  Widget _icon(VoiceCommandState state, dynamic c) {
    return switch (state) {
      VoiceCommandState.listening => const Icon(
          Icons.mic, color: MalateColors.neonMint, size: 24),
      VoiceCommandState.processing => const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: MalateColors.electricAmber,
          ),
        ),
      VoiceCommandState.error => const Icon(
          Icons.mic_off, color: MalateColors.hazardRed, size: 24),
      VoiceCommandState.idle => const Icon(
          Icons.mic, color: MalateColors.cyberCyan, size: 24),
    };
  }
}
