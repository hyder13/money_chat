import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../services/gemini_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiService _geminiService = GeminiService();
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeGemini();
  }

  Future<void> _initializeGemini() async {
    await _geminiService.initialize();
    setState(() {
      _isInitialized = _geminiService.isInitialized;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    _controller.clear();
    setState(() => _isLoading = true);

    // Add user message
    await ref.read(chatMessagesProvider.notifier).addMessage(message, 'user');
    _scrollToBottom();

    if (!_isInitialized) {
      await ref
          .read(chatMessagesProvider.notifier)
          .addMessage('請先到設定頁面輸入你的 Gemini API Key 🔑', 'assistant');
      setState(() => _isLoading = false);
      _scrollToBottom();
      return;
    }

    // Send to Gemini
    final result = await _geminiService.sendMessage(message);

    if (result == null) {
      await ref
          .read(chatMessagesProvider.notifier)
          .addMessage('發生錯誤，請稍後再試', 'assistant');
    } else if (result['type'] == 'expense') {
      final data = result['data'] as Map<String, dynamic>;
      final action = data['action'] as String;

      if (action == 'add' || action == 'update') {
        final amount = (data['amount'] as num).toDouble();
        final category = data['category'] as String;
        final description = data['description'] as String;

        if (action == 'add') {
          await ref
              .read(transactionsProvider.notifier)
              .addTransaction(
                amount: amount,
                category: category,
                description: description,
              );

          // Update category preference
          await _geminiService.updateCategoryPreference(description, category);

          await ref
              .read(chatMessagesProvider.notifier)
              .addMessage(
                '✓ 已記錄\n$category \$${amount.toStringAsFixed(0)}\n$description',
                'assistant',
              );
        } else {
          await ref
              .read(transactionsProvider.notifier)
              .updateLatest(
                amount: amount,
                category: category,
                description: description,
              );

          await ref
              .read(chatMessagesProvider.notifier)
              .addMessage('✓ 已修改為 \$${amount.toStringAsFixed(0)}', 'assistant');
        }
      } else if (action == 'query') {
        final target = data['target'] as String;
        final category = data['category'] as String?;

        DateTime start;
        String periodName;
        final now = DateTime.now();

        if (target == 'today') {
          start = DateTime(now.year, now.month, now.day);
          periodName = '今天';
        } else if (target == 'week') {
          start = now.subtract(Duration(days: now.weekday - 1));
          start = DateTime(start.year, start.month, start.day);
          periodName = '本週';
        } else {
          start = DateTime(now.year, now.month, 1);
          periodName = '本月';
        }

        final filtered = ref
            .read(transactionsProvider.notifier)
            .getFilteredTransactions(start: start, category: category);

        final total = filtered.fold<double>(0, (sum, t) => sum + t.amount);

        String response =
            '$periodName${category != null ? '的 $category' : ''}總計：\$${total.toStringAsFixed(0)}';
        if (filtered.isNotEmpty) {
          final items = filtered
              .map(
                (t) =>
                    '• ${t.category}: \$${t.amount.toStringAsFixed(0)} (${t.description})',
              )
              .join('\n');
          response += '\n$items';
        } else {
          response += '\n尚無記錄。';
        }

        await ref
            .read(chatMessagesProvider.notifier)
            .addMessage(response, 'assistant');
      } else if (action == 'delete') {
        if (data['target'] == 'latest') {
          await ref.read(transactionsProvider.notifier).deleteLatest();
          await ref
              .read(chatMessagesProvider.notifier)
              .addMessage('✓ 已刪除最後一筆記錄', 'assistant');
        }
      }
    } else if (result['type'] == 'error') {
      await ref
          .read(chatMessagesProvider.notifier)
          .addMessage(result['data'] as String, 'assistant');
    } else {
      await ref
          .read(chatMessagesProvider.notifier)
          .addMessage(result['data'] as String, 'assistant');
    }

    setState(() => _isLoading = false);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('💰 記帳小幫手')),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyState(theme)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isLoading && index == messages.length) {
                        return const _TypingIndicator();
                      }
                      return _ChatBubble(message: messages[index]);
                    },
                  ),
          ),
          _buildInputArea(theme),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/crab_mascot.png', width: 150, height: 150),
          const SizedBox(height: 24),
          Text(
            '我是小螃，讓我幫你夾住每一分錢！',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '試試輸入「午餐 120」或問我「今天花了多少？」',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
  // ... (omitting transition for brevity if possible, but replace_file_content needs contiguous block)
  // I'll stick to a single contiguous block for the whole build and avatar part.
  // Wait, I can't skip part of a contiguous block. I'll target the empty state first, then the bubble.

  Widget _buildInputArea(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: '輸入支出，例如「午餐 120」',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.3,
                        ),
                      ),
                      fillColor: theme.colorScheme.surface.withValues(
                        alpha: 0.5,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                _AnimatedSendButton(
                  onPressed: _isLoading ? null : _sendMessage,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedSendButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const _AnimatedSendButton({this.onPressed, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: onPressed == null
            ? theme.colorScheme.primary.withValues(alpha: 0.3)
            : theme.colorScheme.primary,
        shape: BoxShape.circle,
        boxShadow: onPressed == null
            ? []
            : [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.send_rounded, color: Colors.white),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                image: const DecorationImage(
                  image: AssetImage('assets/crab_mascot.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser
                    ? LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isUser ? null : theme.colorScheme.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(24),
                  topRight: const Radius.circular(24),
                  bottomLeft: Radius.circular(isUser ? 24 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.content,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isUser ? Colors.white : theme.colorScheme.onSurface,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: const Text('🤖', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _AnimatedDot(delay: i * 200),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedDot extends StatefulWidget {
  final int delay;

  const _AnimatedDot({required this.delay});

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final alpha = (0.3 + _controller.value * 0.4).clamp(0.0, 1.0);
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: alpha),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
