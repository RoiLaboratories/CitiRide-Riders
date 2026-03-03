import 'package:flutter/material.dart';
import '../ride_flow/ride_history_store.dart';

class RideScreen extends StatefulWidget {
  const RideScreen({super.key});

  @override
  State<RideScreen> createState() => _RideScreenState();
}

class _RideItem {
  const _RideItem({
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

class _RideScreenState extends State<RideScreen> {
  final RideHistoryStore _rideStore = RideHistoryStore.instance;
  bool _showUpcoming = true;

  List<_RideItem> get _upcomingRides => _rideStore.upcomingRides.value
      .map(
        (entry) => _RideItem(
          date: entry.date,
          route: entry.route,
          price: entry.price,
          status: entry.status,
        ),
      )
      .toList();

  List<_RideItem> get _pastRides => _rideStore.pastRides
      .map(
        (entry) => _RideItem(
          date: entry.date,
          route: entry.route,
          price: entry.price,
          status: entry.status,
        ),
      )
      .toList();

  @override
  void initState() {
    super.initState();
    _rideStore.upcomingRides.addListener(_onUpcomingRidesChanged);
  }

  @override
  void dispose() {
    _rideStore.upcomingRides.removeListener(_onUpcomingRidesChanged);
    super.dispose();
  }

  void _onUpcomingRidesChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _openRideDetails(_RideItem ride) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _RideCompletedDetailsScreen(ride: ride),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rides = _showUpcoming ? _upcomingRides : _pastRides;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F4),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 36, 16, 118),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rides',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D2F3A),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _tabChip(
                    label: 'Upcoming Rides',
                    selected: _showUpcoming,
                    onTap: () => setState(() => _showUpcoming = true),
                  ),
                  const SizedBox(width: 14),
                  _tabChip(
                    label: 'Past',
                    selected: !_showUpcoming,
                    onTap: () => setState(() => _showUpcoming = false),
                    compact: true,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: rides.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return _rideRow(
                      ride: rides[index],
                      upcoming: _showUpcoming,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool compact = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 18 : 16,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1690F0) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? const Color(0xFF1690F0) : const Color(0xFFB3B5B9),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(selected ? 0 : 12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF3A3D47),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _rideRow({required _RideItem ride, required bool upcoming}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _openRideDetails(ride),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFF6DCE8),
                child: ClipOval(
                  child: Image.asset(
                    'images/profile.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          ride.date,
                          style: const TextStyle(
                            color: Color(0xFF7F838A),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (ride.status != RideLogStatus.upcoming) ...[
                          const Text(
                            '  \u00B7  ',
                            style: TextStyle(
                              color: Color(0xFF7F838A),
                              fontSize: 13,
                            ),
                          ),
                          _statusChip(ride.status),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ride.route,
                      style: const TextStyle(
                        color: Color(0xFF2E313B),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ride.price,
                      style: const TextStyle(
                        color: Color(0xFF1690F0),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFE3E4E6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  upcoming ? Icons.close_rounded : Icons.refresh_rounded,
                  size: 30,
                  color: const Color(0xFF15181F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(RideLogStatus status) {
    final bool completed = status == RideLogStatus.completed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
      decoration: BoxDecoration(
        color: completed ? const Color(0xFFBDE7B8) : const Color(0xFFF4C3DA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        completed ? 'Completed' : 'Cancelled',
        style: TextStyle(
          color: completed ? const Color(0xFF0A8A14) : const Color(0xFFE2197D),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _RideCompletedDetailsScreen extends StatelessWidget {
  const _RideCompletedDetailsScreen({required this.ride});

  final _RideItem ride;

  void _rebook(BuildContext context) {
    Navigator.pushNamed(
      context,
      '/route',
      arguments: {'prefilledDestination': ride.route},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F4),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Color(0xFF2D2F3A),
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFFF6DCE8),
                          child: ClipOval(
                            child: Image.asset(
                              'images/profile.png',
                              width: 42,
                              height: 42,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ride Completed',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2F323D),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ride.date.replaceFirst('Sun, ', ''),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF9A9CA1),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: SizedBox(
                        height: 220,
                        width: double.infinity,
                        child: Image.asset('images/map.png', fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _routePoint(
                      label: 'Lagos Street, Benin City',
                      color: const Color(0xFF1690F0),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Container(
                        height: 28,
                        width: 2,
                        color: const Color(0xFFB8BBC1),
                      ),
                    ),
                    _routePoint(
                      label: 'Ring Road Bus Terminal, Benin City',
                      color: const Color(0xFFD21DDB),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F4F5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Payment',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2F323D),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _paymentRow(
                            left: 'Cash Payment',
                            right: '\u20A61,500.00',
                            highlight: false,
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          _paymentRow(
                            left: 'Total',
                            right: '\u20A61,500.00',
                            highlight: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _rebook(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1690F0),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Rebook',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _routePoint({required String label, required Color color}) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          child: const Icon(Icons.circle, color: Colors.white, size: 7),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: color == const Color(0xFF1690F0)
                  ? const Color(0xFF2F323D)
                  : const Color(0xFF8E9197),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _paymentRow({
    required String left,
    required String right,
    required bool highlight,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            left,
            style: TextStyle(
              fontSize: 16,
              color: highlight
                  ? const Color(0xFF1690F0)
                  : const Color(0xFF8E9197),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          right,
          style: TextStyle(
            fontSize: 16,
            color: highlight
                ? const Color(0xFF1690F0)
                : const Color(0xFF8E9197),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
