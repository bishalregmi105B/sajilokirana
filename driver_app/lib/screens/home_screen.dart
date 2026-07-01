import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/driver_provider.dart';
import '../theme/colors.dart';
import '../constants.dart';
import '../widgets/stat_card.dart';
import '../widgets/batch_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dp = context.read<DriverProvider>();
      dp.loadProfile();
      dp.loadCurrentBatch();
      dp.loadEarnings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        actions: [
          Consumer<DriverProvider>(builder: (_, dp, __) {
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Switch(
                value: dp.isOnline,
                onChanged: (v) => dp.toggleOnline(v),
                activeColor: AppColors.success,
              ),
            );
          }),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (!mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
            },
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) {
          if (i == 1) Navigator.of(context).pushNamed('/delivery');
          else if (i == 2) Navigator.of(context).pushNamed('/earnings');
          else if (i == 3) Navigator.of(context).pushNamed('/history');
          else setState(() => _navIndex = i);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.route_outlined), selectedIcon: Icon(Icons.route), label: 'Delivery'),
          NavigationDestination(icon: Icon(Icons.payments_outlined), selectedIcon: Icon(Icons.payments), label: 'Earnings'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
        ],
      ),
      body: Consumer<DriverProvider>(builder: (_, dp, __) {
        return RefreshIndicator(
          onRefresh: () async {
            await dp.loadProfile();
            await dp.loadCurrentBatch();
            await dp.loadEarnings();
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Status card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: dp.isOnline ? AppColors.success.withValues(alpha: 0.1) : AppColors.surfaceTint,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: dp.isOnline ? AppColors.success : AppColors.border),
                ),
                child: Row(children: [
                  Icon(dp.isOnline ? Icons.electric_bike_rounded : Icons.hotel_rounded, color: dp.isOnline ? AppColors.success : AppColors.textMuted, size: 36),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(dp.isOnline ? 'You are ONLINE' : 'You are OFFLINE', style: TextStyle(fontWeight: FontWeight.bold, color: dp.isOnline ? AppColors.success : AppColors.textMuted)),
                    Text(dp.isOnline ? (dp.hasBatch ? 'Active delivery in progress' : 'Waiting for batch assignment…') : 'Go online to receive deliveries', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ]),
                ]),
              ),
              const SizedBox(height: 16),
              // Stats
              Row(children: [
                StatCard(label: "Today's deliveries", value: '${dp.earnings?.today.deliveries ?? 0}', icon: Icons.check_circle_outline_rounded),
                const SizedBox(width: 12),
                StatCard(label: "Today's earnings", value: '$appCurrencySymbol ${dp.earnings?.today.earnings ?? 0}', icon: Icons.payments_outlined),
              ]),
              const SizedBox(height: 16),
              // Current batch
              if (dp.currentBatch != null) ...[
                const Text('Current batch', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                BatchCard(batch: dp.currentBatch!, onStartDelivery: () => Navigator.of(context).pushNamed('/delivery')),
              ],
            ],
          ),
        );
      }),
    );
  }
}
