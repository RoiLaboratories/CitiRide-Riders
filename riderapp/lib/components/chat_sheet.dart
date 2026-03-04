import 'package:flutter/material.dart';

import '../constants/ride_sheet_constants.dart';

class ChatSheet extends StatefulWidget {
  const ChatSheet({
    super.key,
    required this.scrollController,
    this.onClose,
  });

  final ScrollController scrollController;
  final VoidCallback? onClose;

  @override
  State<ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends State<ChatSheet> {
  final TextEditingController _messageController = TextEditingController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text: 'Hi, I am almost at the pickup point.',
      isUser: false,
    ),
  ];

  static const List<String> _quickReplies = [
    "Hi, I'm on my way",
    "I'm here",
    'Hello',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage(String rawMessage) {
    final message = rawMessage.trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: message, isUser: true));
    });
    _messageController.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.scrollController.hasClients) return;
      widget.scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 20, 8, 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 360;

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(34),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                SizedBox(height: compact ? 8 : 12),
                Center(
                  child: Container(
                    width: 56,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD0D0D2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: compact ? 8 : 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: widget.onClose,
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 22,
                          color: Color(0xFF333741),
                        ),
                      ),
                      const CircleAvatar(
                        radius: 18,
                        backgroundImage: AssetImage('images/driver.png'),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Andrew Johnson',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF333741),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Toyota Corolla Sedan - BEN931AP',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF8A8E95),
                              ),
                            ),
                          ],
                        ),
                      ),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFFC8F0C4),
                        child: Icon(Icons.phone, color: Colors.green.shade700),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: widget.scrollController,
                    reverse: true,
                    padding: EdgeInsets.fromLTRB(14, compact ? 8 : 12, 14, 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[_messages.length - 1 - index];
                      return _chatBubble(message);
                    },
                  ),
                ),
                if (!compact)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _quickReplies
                            .map(
                              (reply) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _QuickReplyChip(
                                  label: reply,
                                  onTap: () => _sendMessage(reply),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                SizedBox(height: compact ? 8 : 14),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 10, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: compact ? 50 : 56,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE1E1E3),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.chat_bubble_outline,
                                color: Color(0xFF888A8F),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _messageController,
                                  textInputAction: TextInputAction.send,
                                  onSubmitted: _sendMessage,
                                  decoration: const InputDecoration(
                                    hintText: 'Type your message',
                                    hintStyle: TextStyle(
                                      color: Color(0xFF80838A),
                                      fontSize: 17,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                  style: const TextStyle(
                                    color: Color(0xFF2E313B),
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: () => _sendMessage(_messageController.text),
                        customBorder: const CircleBorder(),
                        child: CircleAvatar(
                          radius: compact ? 24 : 28,
                          backgroundColor: kPrimaryBlue,
                          child: Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: compact ? 24 : 30,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _chatBubble(_ChatMessage message) {
    final isUser = message.isUser;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = isUser ? const Color(0xFF1690F0) : const Color(0xFFB03AE6);

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 260),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          message.text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _QuickReplyChip extends StatelessWidget {
  const _QuickReplyChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFCBE7FF),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF178BEA),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.isUser,
  });

  final String text;
  final bool isUser;
}
