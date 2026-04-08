import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';

const _gold = Color(0xFFCA8A04);
const _goldLight = Color(0xFFEAB308);
const _darkBg = Color(0xFF1C1917);
const _surfaceDark = Color(0xFF292524);
const _textLight = Color(0xFFFAFAF9);
const _muted = Color(0xFF78716C);
const _mutedLight = Color(0xFFA8A29E);
const _border = Color(0xFF44403C);

class _ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  _ChatMessage({required this.role, required this.content, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();
}

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _loading = false;
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    ref.read(analyticsProvider).trackChatStarted();
    _loadHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await supabase
          .from('chat_messages')
          .select('role, content, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: true)
          .limit(50);

      if (mounted) {
        setState(() {
          _messages.addAll((data as List).map((m) => _ChatMessage(
            role: m['role'] as String,
            content: m['content'] as String,
            timestamp: DateTime.parse(m['created_at'] as String),
          )));
          _loadingHistory = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;

    ref.read(analyticsProvider).trackChatMessageSent(text.length);
    _controller.clear();
    setState(() {
      _messages.add(_ChatMessage(role: 'user', content: text));
      _loading = true;
    });
    _scrollToBottom();

    try {
      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;
      if (session == null) throw Exception('Not authenticated');

      // Send recent history for context
      final history = _messages
          .where((m) => m.role == 'user' || m.role == 'assistant')
          .toList()
          .reversed
          .take(10)
          .toList()
          .reversed
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();

      final response = await supabase.functions.invoke(
        'ai-chat',
        body: {'message': text, 'history': history},
      );

      if (response.status != 200) {
        throw Exception(response.data?['error'] ?? 'Failed to get response');
      }

      final reply = response.data['reply'] as String;
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(role: 'assistant', content: reply));
          _loading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(
            role: 'assistant',
            content: 'Sorry, I couldn\'t connect right now. Please try again or contact us directly.',
          ));
          _loading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      appBar: AppBar(
        backgroundColor: _darkBg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _mutedLight),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: _gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.smart_toy, color: _gold, size: 18),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PartyPour AI', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _textLight)),
                Text('Ask about products, offers & more', style: TextStyle(fontSize: 10, color: _muted)),
              ],
            ),
          ],
        ),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: _muted, size: 20),
              onPressed: () => _showClearDialog(),
            ),
          IconButton(
            icon: const Icon(Icons.close, color: _mutedLight, size: 20),
            tooltip: 'Close chat',
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _loadingHistory
                ? const Center(child: CircularProgressIndicator(color: _gold, strokeWidth: 2))
                : _messages.isEmpty
                    ? _buildWelcome()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        itemCount: _messages.length + (_loading ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i == _messages.length) return _buildTypingIndicator();
                          return _buildBubble(_messages[i]);
                        },
                      ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
            decoration: BoxDecoration(
              color: _surfaceDark,
              border: Border(top: BorderSide(color: _border.withValues(alpha: 0.5))),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: _textLight, fontSize: 14),
                      maxLines: 3,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Ask anything...',
                        hintStyle: const TextStyle(color: _muted, fontSize: 14),
                        filled: true,
                        fillColor: _darkBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: _border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: _border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: _gold, width: 1.5)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _loading ? null : _sendMessage,
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        gradient: _loading ? null : const LinearGradient(colors: [_gold, _goldLight]),
                        color: _loading ? _surfaceDark : null,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.send_rounded,
                        size: 20,
                        color: _loading ? _muted : _darkBg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: _gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.smart_toy, color: _gold, size: 32),
            ),
            const SizedBox(height: 16),
            const Text('PartyPour AI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textLight)),
            const SizedBox(height: 8),
            const Text(
              'Ask me about our products, prices,\ndelivery, offers, or anything else!',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            // Quick prompts
            Wrap(
              spacing: 8, runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _QuickPrompt(label: 'What whiskey brands do you have?', onTap: (t) { _controller.text = t; _sendMessage(); }),
                _QuickPrompt(label: 'Delivery policy?', onTap: (t) { _controller.text = t; _sendMessage(); }),
                _QuickPrompt(label: 'Any offers right now?', onTap: (t) { _controller.text = t; _sendMessage(); }),
                _QuickPrompt(label: 'Can I return unopened bottles?', onTap: (t) { _controller.text = t; _sendMessage(); }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(_ChatMessage msg) {
    final isUser = msg.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 28, height: 28,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: _gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.smart_toy, color: _gold, size: 15),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? _gold.withValues(alpha: 0.12) : _surfaceDark,
                border: Border.all(color: isUser ? _gold.withValues(alpha: 0.2) : _border),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Text(
                msg.content,
                style: TextStyle(fontSize: 14, color: isUser ? _textLight : _mutedLight, height: 1.4),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.smart_toy, color: _gold, size: 15),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _surfaceDark,
              border: Border.all(color: _border),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dot(delay: 0),
                const SizedBox(width: 4),
                _Dot(delay: 200),
                const SizedBox(width: 4),
                _Dot(delay: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Chat?', style: TextStyle(color: _textLight, fontSize: 16, fontWeight: FontWeight.w600)),
        content: const Text('This will clear the chat history from this screen.', style: TextStyle(color: _mutedLight, fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: _muted))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _messages.clear());
            },
            child: const Text('Clear', style: TextStyle(color: _gold, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _QuickPrompt extends StatelessWidget {
  final String label;
  final ValueChanged<String> onTap;
  const _QuickPrompt({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _surfaceDark,
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12, color: _mutedLight)),
      ),
    );
  }
}

/// Animated typing dot
class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(widget.delay / 1000, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Container(
        width: 7, height: 7,
        decoration: BoxDecoration(
          color: _gold.withValues(alpha: _animation.value),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
