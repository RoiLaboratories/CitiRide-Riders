import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  final List<_NotificationItem> _notifications = const [
    _NotificationItem(
      title: 'Your ride just arrived',
      subtitle: 'Lagos Street, Benin City',
      timeAgo: '3 minutes ago',
    ),
    _NotificationItem(
      title: 'You cancelled your order',
      subtitle: 'Dawson Road, Benin City',
      timeAgo: '2 days ago',
    ),
    _NotificationItem(
      title: 'Ride successfully completed',
      subtitle: 'Oba Market Road, Benin City 300102',
      timeAgo: '5 days ago',
    ),
    _NotificationItem(
      title: 'Your ride just arrived',
      subtitle: '5 junction, Benin City',
      timeAgo: '10 days ago',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).extension<CitiRideThemeColors>()?.surface ?? const Color(0xFFF2F2F4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 72,
        leadingWidth: 56,
        leading: IconButton(
          padding: const EdgeInsets.only(left: 12),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 28,
            color: Color(0xFF2D2F3A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Color(0xFF2D2F3A),
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
        itemCount: _notifications.length,
        separatorBuilder: (_, _) => const SizedBox(height: 18),
        itemBuilder: (context, index) {
          final item = _notifications[index];
          return Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(15),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2F323D),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8A8E95),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    item.timeAgo,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94989F),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NotificationItem {
  const _NotificationItem({
    required this.title,
    required this.subtitle,
    required this.timeAgo,
  });

  final String title;
  final String subtitle;
  final String timeAgo;
}
