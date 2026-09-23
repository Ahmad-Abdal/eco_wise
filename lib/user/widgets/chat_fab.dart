import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chatbot_providers.dart';

class ChatFab extends ConsumerStatefulWidget {
  const ChatFab({Key? key}) : super(key: key);

  @override
  ConsumerState<ChatFab> createState() => ChatFabState();
}

class ChatFabState extends ConsumerState<ChatFab> with SingleTickerProviderStateMixin {
  static const Color pureWhite = Colors.white;
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGray = Color(0xFF6B6B6B);
  static const Color primaryGreen = Color(0xFF1B7A43);
  static const Color lightGreenBg = Color(0xFFE7F4EC);
  static const Color borderGray = Color(0xFFE0E0E0);
  static const Color sectionFill = Color(0xFFF7F8F6);

  bool isOpen = false;
  final messageController = TextEditingController();
  final scrollController = ScrollController();

  late final AnimationController pulseController;
  late final Animation<double> pulseAnimation;

  @override
  void initState() {
    super.initState();
    pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
    pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    pulseController.dispose();
    super.dispose();
  }

  void toggle() {
    setState(() => isOpen = !isOpen);
    if (isOpen) {
      pulseController.stop();
    } else {
      pulseController.repeat(reverse: true);
    }
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> send() async {
    final text = messageController.text;
    if (text.trim().isEmpty) return;
    messageController.clear();
    await ref.read(chatNotifierProvider.notifier).sendMessage(text);
    scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatNotifierProvider);

    return Positioned(
      right: 20,
      bottom: 40, // sits just above the rounded floating nav bar
      child: AnimatedSize(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        alignment: Alignment.bottomRight,
        child: isOpen ? buildPanel(chatState) : buildFabButton(),
      ),
    );
  }

  Widget buildFabButton() {
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) => Transform.scale(scale: pulseAnimation.value, child: child),
      child: GestureDetector(
        onTap: toggle,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [pureWhite, Colors.white]),
            boxShadow: [BoxShadow(color: primaryGreen.withOpacity(0.4), blurRadius: 18, offset: const Offset(0, 6))],
          ),
          child: ClipOval(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Image.asset(
                'assets/icon/chatbot.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 26),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildPanel(ChatState chatState) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: screenWidth * 0.82,
      height: screenHeight * 0.55,
      constraints: const BoxConstraints(maxWidth: 340, maxHeight: 460),
      decoration: BoxDecoration(
        color: pureWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [primaryGreen, Color(0xFF2FA362)]),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.2)),
                  child: const Icon(Icons.eco_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('EcoWise Assistant', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                GestureDetector(
                  onTap: toggle,
                  child: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 24),
                ),
              ],
            ),
          ),
          Expanded(
            child: chatState.messages.isEmpty
                ? buildEmptyState()
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(14),
                    itemCount: chatState.messages.length,
                    itemBuilder: (context, index) {
                      final message = chatState.messages[index];
                      final isUser = message.role == 'user';
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: const BoxConstraints(maxWidth: 230),
                          decoration: BoxDecoration(
                            color: isUser ? primaryGreen : sectionFill,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            message.content,
                            style: TextStyle(color: isUser ? Colors.white : textDark, fontSize: 13, height: 1.35),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (chatState.isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: primaryGreen)),
            ),
          if (chatState.errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Text(chatState.errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
            ),
          // ── Input ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(color: sectionFill, borderRadius: BorderRadius.circular(20)),
                    child: TextField(
                      controller: messageController,
                      onSubmitted: (_) => send(),
                      style: const TextStyle(color: textDark, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Ask about products or stores...',
                        hintStyle: TextStyle(color: textGray, fontSize: 12.5),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: send,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: primaryGreen),
                    child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(shape: BoxShape.circle, color: lightGreenBg),
            child: const Icon(Icons.chat_bubble_outline_rounded, color: primaryGreen, size: 26),
          ),
          const SizedBox(height: 14),
          const Text('Ask me anything about products or stores', textAlign: TextAlign.center,
              style: TextStyle(color: textDark, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          Text('"Which kitchen product is more eco-friendly?"', textAlign: TextAlign.center,
              style: TextStyle(color: textGray.withOpacity(0.8), fontSize: 11.5, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}