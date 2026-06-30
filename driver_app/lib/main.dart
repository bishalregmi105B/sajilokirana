import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFFFFFFFF),
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const DriverApp());
}

class DriverApp extends StatelessWidget {
  const DriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SajiloKirana — Driver',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFA8442C),
          primary: const Color(0xFFA8442C),
        ),
        scaffoldBackgroundColor: const Color(0xFFFCFAF8),
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const DriverLoginScreen(),
        '/home': (_) => const DriverHomeScreen(),
        '/delivery': (_) => const ActiveDeliveryScreen(),
        '/earnings': (_) => const EarningsScreen(),
        '/history': (_) => const BatchHistoryScreen(),
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// LOGIN
// ══════════════════════════════════════════════════════════════════

class DriverLoginScreen extends StatelessWidget {
  const DriverLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.electric_bike_rounded,
                size: 72,
                color: Color(0xFFA8442C),
              ),
              const SizedBox(height: 16),
              const Text(
                'SajiloKirana',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFA8442C),
                ),
                textAlign: TextAlign.center,
              ),
              const Text(
                'Driver Portal',
                style: TextStyle(fontSize: 16, color: Color(0xFF6B6F7A)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Phone number',
                  prefixText: '+977 ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/home');
                },
                child: const Text('Send OTP'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// HOME — online/offline toggle + current batch summary
// ══════════════════════════════════════════════════════════════════

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool _online = false;
  int _todayDeliveries = 3;
  double _todayEarnings = 480;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Switch(
              value: _online,
              onChanged: (v) => setState(() => _online = v),
              activeColor: const Color(0xFF2E7D52),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'Delivery',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments),
            label: 'Earnings',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
        ],
        onDestinationSelected: (i) {
          if (i == 1) Navigator.of(context).pushNamed('/delivery');
          if (i == 2) Navigator.of(context).pushNamed('/earnings');
          if (i == 3) Navigator.of(context).pushNamed('/history');
        },
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _online
                  ? const Color(0xFF2E7D52).withValues(alpha: 0.1)
                  : const Color(0xFFFBEEE8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _online
                    ? const Color(0xFF2E7D52)
                    : const Color(0xFFE7E5E2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _online ? Icons.electric_bike_rounded : Icons.hotel_rounded,
                  color: _online
                      ? const Color(0xFF2E7D52)
                      : const Color(0xFF6B6F7A),
                  size: 36,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _online ? 'You are ONLINE' : 'You are OFFLINE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _online
                            ? const Color(0xFF2E7D52)
                            : const Color(0xFF6B6F7A),
                      ),
                    ),
                    Text(
                      _online
                          ? 'Waiting for batch assignment…'
                          : 'Go online to receive deliveries',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B6F7A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Today's stats
          Row(
            children: [
              _DriverStatCard(
                label: "Today's deliveries",
                value: '$_todayDeliveries',
                icon: Icons.check_circle_outline_rounded,
              ),
              const SizedBox(width: 12),
              _DriverStatCard(
                label: "Today's earnings",
                value: 'रु ${_todayEarnings.toStringAsFixed(0)}',
                icon: Icons.payments_outlined,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Current batch (if any)
          if (_online) ...[
            const Text(
              'Current batch',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const _BatchCard(),
          ],
        ],
      ),
    );
  }
}

class _DriverStatCard extends StatelessWidget {
  const _DriverStatCard({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFFA8442C)),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B6F7A)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BatchCard extends StatelessWidget {
  const _BatchCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text(
                  'Batch #B001',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Spacer(),
                Text('2 stops', style: TextStyle(color: Color(0xFF6B6F7A))),
              ],
            ),
            const SizedBox(height: 12),
            _StopRow(
              icon: Icons.storefront_outlined,
              color: const Color(0xFFA8442C),
              label: 'PICKUP — Shrestha General Store',
              address: 'Lazimpat, Ward 3',
            ),
            const SizedBox(height: 8),
            _StopRow(
              icon: Icons.home_outlined,
              color: const Color(0xFF2E7D52),
              label: 'DROP — Anjali Karki',
              address: 'Lazimpat, Ward 3',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.navigation_rounded),
                label: const Text('Start Delivery'),
                onPressed: () => Navigator.of(context).pushNamed('/delivery'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StopRow extends StatelessWidget {
  const _StopRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.address,
  });
  final IconData icon;
  final Color color;
  final String label;
  final String address;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            Text(
              address,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B6F7A)),
            ),
          ],
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// ACTIVE DELIVERY — map + stop list + confirm actions
// ══════════════════════════════════════════════════════════════════

class ActiveDeliveryScreen extends StatefulWidget {
  const ActiveDeliveryScreen({super.key});

  @override
  State<ActiveDeliveryScreen> createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends State<ActiveDeliveryScreen> {
  final List<_Stop> _stops = [
    const _Stop(
      type: StopType.pickup,
      name: 'Shrestha General Store',
      address: 'Lazimpat, Ward 3',
      orderId: 'A1B2',
      done: false,
    ),
    const _Stop(
      type: StopType.dropoff,
      name: 'Anjali Karki',
      address: 'Lazimpat, Ward 3',
      orderId: 'A1B2',
      done: false,
    ),
  ];

  void _confirmStop(int i) {
    setState(() {
      _stops[i] = _Stop(
        type: _stops[i].type,
        name: _stops[i].name,
        address: _stops[i].address,
        orderId: _stops[i].orderId,
        done: true,
      );
    });
    // TODO: call POST /driver/orders/:id/pickup or /deliver
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active Delivery')),
      body: Column(
        children: [
          // Map placeholder
          Container(
            height: 240,
            color: const Color(0xFFFBEEE8),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 60, color: Color(0xFF6B6F7A)),
                  SizedBox(height: 8),
                  Text(
                    'Live map — wire flutter_map\nwith driver location stream',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF6B6F7A)),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _stops.length,
              itemBuilder: (ctx, i) {
                final stop = _stops[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: stop.type == StopType.pickup
                                  ? const Color(
                                      0xFFA8442C,
                                    ).withValues(alpha: 0.12)
                                  : const Color(
                                      0xFF2E7D52,
                                    ).withValues(alpha: 0.12),
                              child: Icon(
                                stop.type == StopType.pickup
                                    ? Icons.storefront_outlined
                                    : Icons.home_outlined,
                                color: stop.type == StopType.pickup
                                    ? const Color(0xFFA8442C)
                                    : const Color(0xFF2E7D52),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    stop.type == StopType.pickup
                                        ? 'PICKUP'
                                        : 'DROP OFF',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: stop.type == StopType.pickup
                                          ? const Color(0xFFA8442C)
                                          : const Color(0xFF2E7D52),
                                    ),
                                  ),
                                  Text(
                                    stop.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    stop.address,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B6F7A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (stop.done)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF2E7D52),
                              ),
                          ],
                        ),
                        if (!stop.done) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () => _confirmStop(i),
                              child: Text(
                                stop.type == StopType.pickup
                                    ? 'Confirm Pickup'
                                    : 'Confirm Delivery',
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

enum StopType { pickup, dropoff }

class _Stop {
  const _Stop({
    required this.type,
    required this.name,
    required this.address,
    required this.orderId,
    required this.done,
  });
  final StopType type;
  final String name;
  final String address;
  final String orderId;
  final bool done;
}

// ══════════════════════════════════════════════════════════════════
// EARNINGS
// ══════════════════════════════════════════════════════════════════

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary cards
          Row(
            children: [
              _EarnCard(label: 'Today', amount: 480),
              const SizedBox(width: 12),
              _EarnCard(label: 'This week', amount: 3240),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Daily breakdown',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...List.generate(7, (i) {
            final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
            final amounts = [540, 480, 720, 480, 600, 960, 480];
            return ListTile(
              title: Text(days[i]),
              subtitle: Text('${3 + i % 3} deliveries'),
              trailing: Text(
                'रु ${amounts[i]}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _EarnCard extends StatelessWidget {
  const _EarnCard({required this.label, required this.amount});
  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B6F7A)),
              ),
              Text(
                'रु ${amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// BATCH HISTORY
// ══════════════════════════════════════════════════════════════════

class BatchHistoryScreen extends StatelessWidget {
  const BatchHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Batch History')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 10,
        itemBuilder: (ctx, i) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF2E7D52).withValues(alpha: 0.12),
              child: const Icon(Icons.check_rounded, color: Color(0xFF2E7D52)),
            ),
            title: Text('Batch #B${100 + i}'),
            subtitle: Text('${1 + i % 3} orders · Jun ${30 - i}'),
            trailing: Text('रु ${(300 + i * 80).toString()}'),
          ),
        ),
      ),
    );
  }
}
