import 'package:flutter/foundation.dart';

enum RideLogStatus { upcoming, completed, cancelled }

class RideLogEntry {
  const RideLogEntry({
    required this.date,
    required this.route,
    required this.price,
    required this.status,
  });

  final String date;
  final String route;
  final String price;
  final RideLogStatus status;
}

class RideHistoryStore {
  RideHistoryStore._();
  static final RideHistoryStore instance = RideHistoryStore._();

  final ValueNotifier<List<RideLogEntry>> upcomingRides =
      ValueNotifier<List<RideLogEntry>>(
        const [
          RideLogEntry(
            date: 'Sun, 31 Aug 2025',
            route: 'Lagos Street, Benin City',
            price: '\u20A61,500.00',
            status: RideLogStatus.upcoming,
          ),
        ],
      );

  final List<RideLogEntry> pastRides = const [
    RideLogEntry(
      date: 'Sun, 31 Aug 2025',
      route: 'Lagos Street, Benin City',
      price: '\u20A61,500.00',
      status: RideLogStatus.completed,
    ),
    RideLogEntry(
      date: 'Sun, 31 Aug 2025',
      route: 'Lagos Street, Benin City',
      price: '\u20A61,500.00',
      status: RideLogStatus.cancelled,
    ),
    RideLogEntry(
      date: 'Sun, 31 Aug 2025',
      route: 'Lagos Street, Benin City',
      price: '\u20A61,500.00',
      status: RideLogStatus.completed,
    ),
  ];

  void addUpcomingRide({
    required String pickup,
    required String destination,
    String price = '\u20A63,500.00',
  }) {
    final route = '${pickup.trim()} \u2192 ${destination.trim()}';
    final entry = RideLogEntry(
      date: _formatDate(DateTime.now()),
      route: route,
      price: price,
      status: RideLogStatus.upcoming,
    );

    upcomingRides.value = [entry, ...upcomingRides.value];
  }

  String _formatDate(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final dayLabel = days[date.weekday - 1];
    final monthLabel = months[date.month - 1];
    final day = date.day.toString().padLeft(2, '0');
    return '$dayLabel, $day $monthLabel ${date.year}';
  }
}
