import 'package:flutter/foundation.dart';

enum RideLogStatus { upcoming, ongoing, completed, cancelled }

class RideLogEntry {
  const RideLogEntry({
    required this.id,
    required this.date,
    required this.pickup,
    required this.destination,
    required this.route,
    required this.price,
    required this.status,
  });

  final String id;
  final String date;
  final String pickup;
  final String destination;
  final String route;
  final String price;
  final RideLogStatus status;
}

class RideHistoryStore {
  RideHistoryStore._();
  static final RideHistoryStore instance = RideHistoryStore._();

  int _nextId = 1;

  final ValueNotifier<List<RideLogEntry>> upcomingRides =
      ValueNotifier<List<RideLogEntry>>(const [
        RideLogEntry(
          id: 'seed_upcoming_1',
          date: 'Sun, 31 Aug 2025',
          pickup: 'Lagos Street, Benin City',
          destination: 'Ring Road Bus Terminal, Benin City',
          route: 'Lagos Street, Benin City',
          price: '\u20A61,500.00',
          status: RideLogStatus.upcoming,
        ),
      ]);

  final List<RideLogEntry> pastRides = const [
    RideLogEntry(
      id: 'seed_completed_1',
      date: 'Sun, 31 Aug 2025',
      pickup: 'Lagos Street, Benin City',
      destination: 'Ring Road Bus Terminal, Benin City',
      route: 'Lagos Street, Benin City',
      price: '\u20A61,500.00',
      status: RideLogStatus.completed,
    ),
    RideLogEntry(
      id: 'seed_cancelled_1',
      date: 'Sun, 31 Aug 2025',
      pickup: 'Lagos Street, Benin City',
      destination: 'Ring Road Bus Terminal, Benin City',
      route: 'Lagos Street, Benin City',
      price: '\u20A61,500.00',
      status: RideLogStatus.cancelled,
    ),
    RideLogEntry(
      id: 'seed_completed_2',
      date: 'Sun, 31 Aug 2025',
      pickup: 'Lagos Street, Benin City',
      destination: 'Ring Road Bus Terminal, Benin City',
      route: 'Lagos Street, Benin City',
      price: '\u20A61,500.00',
      status: RideLogStatus.completed,
    ),
  ];

  RideLogEntry addUpcomingRide({
    required String pickup,
    required String destination,
    String price = '\u20A63,500.00',
    RideLogStatus status = RideLogStatus.upcoming,
  }) {
    final cleanedPickup = pickup.trim().isEmpty ? 'Pickup' : pickup.trim();
    final cleanedDestination = destination.trim().isEmpty
        ? 'Destination'
        : destination.trim();
    final route = '$cleanedPickup \u2192 $cleanedDestination';
    final entry = RideLogEntry(
      id: 'ride_${DateTime.now().microsecondsSinceEpoch}_${_nextId++}',
      date: _formatDate(DateTime.now()),
      pickup: cleanedPickup,
      destination: cleanedDestination,
      route: route,
      price: price,
      status: status,
    );

    upcomingRides.value = [entry, ...upcomingRides.value];
    return entry;
  }

  RideLogEntry addOngoingRide({
    required String pickup,
    required String destination,
    String price = '\u20A63,500.00',
  }) {
    return addUpcomingRide(
      pickup: pickup,
      destination: destination,
      price: price,
      status: RideLogStatus.ongoing,
    );
  }

  void removeRide(RideLogEntry ride) {
    upcomingRides.value = [
      for (final entry in upcomingRides.value)
        if (entry.id != ride.id) entry,
    ];
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
