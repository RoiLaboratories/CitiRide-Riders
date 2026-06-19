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
    final colors = context.citiRideColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          if (isDark) ...[
            Positioned.fill(
              child: Image.asset(
                'images/map.png',
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                isAntiAlias: true,
              ),
            ),
            Positioned.fill(
              child: Container(color: Colors.black.withAlpha(210)),
            ),
          ],
          SafeArea(
            child: Column(
              children: [
                SizedBox(
                  height: 58,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 58,
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 22,
                            color: colors.text,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Notifications',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.text,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 58),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 18,
                      color: isDark ? const Color(0xFF2A2A2A) : colors.border,
                    ),
                    itemBuilder: (context, index) {
                      final item = _notifications[index];
                      return _NotificationTile(item: item, dark: isDark);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.dark});

  final _NotificationItem item;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final colors = context.citiRideColors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: colors.mutedText),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            item.timeAgo,
            style: TextStyle(
              fontSize: 11,
              color: dark ? const Color(0xFFB8B8B8) : colors.mutedText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
