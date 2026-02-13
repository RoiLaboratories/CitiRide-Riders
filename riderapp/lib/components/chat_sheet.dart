import 'package:flutter/material.dart';
import '../constants/ride_sheet_constants.dart';

class ChatSheet extends StatelessWidget {
  final ScrollController scrollController;

  const ChatSheet({
    super.key,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Container(
        decoration: floatingSheetDecoration(),
        child: Column(
          children: [
            const SizedBox(height: 12),
            dragHandle(),
            const SizedBox(height: 12),

            ListTile(
              leading: const CircleAvatar(
                backgroundImage: AssetImage('images/driver.png'),
              ),
              title: const Text('Andrew Johnson'),
              subtitle: const Text('Toyota Corolla Sedan · BEN931AP'),
              trailing: CircleAvatar(
                backgroundColor: Colors.green.shade100,
                child: const Icon(Icons.phone, color: Colors.green),
              ),
            ),
            SizedBox(height: 12),

            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: const [
                  _DriverBubble(text: 'I’m on my way'),
                  _UserBubble(text: 'Okay 👍'),
                ],
              ),
            ),

            _ChatInput(),
          ],
        ),
      ),
    );
  }
}

/// USER MESSAGE
class _UserBubble extends StatelessWidget {
  final String text;

  const _UserBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: kPrimaryBlue,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

/// DRIVER MESSAGE
class _DriverBubble extends StatelessWidget {
  final String text;

  const _DriverBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: kDriverPurple.withOpacity(0.15),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(text),
      ),
    );
  }
}

/// CHAT INPUT
class _ChatInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: kLightGrey,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Type your message',
                  style: TextStyle(color: kTextGrey),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 24,
            backgroundColor: kPrimaryBlue,
            child: const Icon(Icons.send, color: Colors.white),
          ),
        ],
      ),
    );
  }
}