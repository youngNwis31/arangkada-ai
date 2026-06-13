import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme/malate_colors.dart';
import '../config/theme/malate_typography.dart';
import '../services/ai/ai_assistant.dart';
import '../widgets/neon_badge.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    context.read<AiAssistant>().sendMessage(text);

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = MalateColors.of(context);
    return Scaffold(
      backgroundColor: c.midnight,
      appBar: AppBar(
        backgroundColor: c.midnight,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Icon(Icons.smart_toy, color: MalateColors.cyberCyan, size: 20),
            const SizedBox(width: 8),
            Text('AI ASSISTANT',
                style: MalateTypography.neonAccent(MalateColors.cyberCyan)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: NeonBadge(
              label: 'OFFLINE',
              color: MalateColors.neonMint,
              icon: Icons.flash_on,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: c.asphalt,
            child: Text(
              'Offline AI — Taglish & English supported',
              style: MalateTypography.labelSmall
                  .copyWith(color: c.textMuted),
            ),
          ),
          Expanded(
            child: Consumer<AiAssistant>(
              builder: (_, ai, __) {
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: ai.messages.length + (ai.isProcessing ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i >= ai.messages.length) return _typingIndicator();
                    return _bubble(ai.messages[i]);
                  },
                );
              },
            ),
          ),
          _inputBar(),
        ],
      ),
    );
  }

  Widget _bubble(ChatMessage msg) {
    final c = MalateColors.of(context);
    final isUser = msg.role == MessageRole.user;

    return Padding(
      padding: EdgeInsets.only(
        bottom: 12,
        left: isUser ? 48 : 0,
        right: isUser ? 0 : 48,
      ),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isUser ? MalateColors.neonMint.withValues(alpha: 0.12) : c.gutter,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
              bottomRight: isUser ? Radius.zero : const Radius.circular(16),
            ),
            border: Border.all(
              color: isUser
                  ? MalateColors.neonMint.withValues(alpha: 0.2)
                  : c.sidewalk,
            ),
          ),
          child: Text(
            msg.text,
            style: MalateTypography.bodyMedium.copyWith(
              color: c.textPrimary,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _typingIndicator() {
    final c = MalateColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 48),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.gutter,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.sidewalk),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: MalateColors.cyberCyan.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputBar() {
    final c = MalateColors.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: c.asphalt,
        border: Border(top: BorderSide(color: c.sidewalk)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: MalateTypography.bodyLarge
                  .copyWith(color: c.textPrimary),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Ask me anything, rider...',
                hintStyle: MalateTypography.bodyLarge
                    .copyWith(color: c.textMuted),
                filled: true,
                fillColor: c.gutter,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: MalateColors.cyberCyan,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.send,
                  color: c.midnight, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
