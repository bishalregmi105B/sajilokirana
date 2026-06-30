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
  runApp(const ShopkeeperApp());
}

class ShopkeeperApp extends StatelessWidget {
  const ShopkeeperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SajiloKirana — Shopkeeper',
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
        '/': (_) => const ShopLoginScreen(),
        '/home': (_) => const ShopHomeScreen(),
        '/onboarding': (_) => const ShopOnboardingScreen(),
        '/orders': (_) => const ShopOrdersScreen(),
        '/inventory': (_) => const ShopInventoryScreen(),
        '/reliability': (_) => const ShopReliabilityScreen(),
        '/payouts': (_) => const ShopPayoutsScreen(),
      },
    );
  }
}

// ── Stub screens (fully implemented below in their own files) ────────────────

// ignore: prefer_const_constructors_in_immutables
class ShopLoginScreen extends StatelessWidget {
  const ShopLoginScreen({super.key});
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
              const Text(
                'SajiloKirana',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFA8442C),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Shopkeeper Portal',
                style: TextStyle(fontSize: 16, color: Color(0xFF6B6F7A)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                  prefixText: '+977 ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed('/home'),
                child: const Text('Send OTP'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShopHomeScreen extends StatelessWidget {
  const ShopHomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Stock',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        selectedIndex: 0,
        onDestinationSelected: (i) {
          if (i == 1) Navigator.of(context).pushNamed('/orders');
          if (i == 2) Navigator.of(context).pushNamed('/inventory');
        },
      ),
      body: const _DashboardContent(),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Today's summary
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _StatTile(
                  label: "Today's orders",
                  value: '7',
                  icon: Icons.receipt_long,
                ),
                _StatTile(
                  label: "Today's earnings",
                  value: 'रु 3,240',
                  icon: Icons.payments_outlined,
                ),
                _StatTile(
                  label: 'Reliability',
                  value: '82%',
                  icon: Icons.star_half_rounded,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Incoming orders', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _IncomingOrderCard(),
        _IncomingOrderCard(),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(
      {required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFA8442C)),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B6F7A)),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _IncomingOrderCard extends StatefulWidget {
  @override
  State<_IncomingOrderCard> createState() => _IncomingOrderCardState();
}

class _IncomingOrderCardState extends State<_IncomingOrderCard> {
  int _secondsLeft = 40;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Order #A1B2',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8A33D).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    '${_secondsLeft}s',
                    style: const TextStyle(
                        color: Color(0xFFE8A33D), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Wai Wai × 2, Mustard Oil × 1'),
            const Text('Total: रु 280',
                style: TextStyle(color: Color(0xFF6B6F7A))),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {},
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ShopOnboardingScreen extends StatefulWidget {
  const ShopOnboardingScreen({super.key});

  @override
  State<ShopOnboardingScreen> createState() => _ShopOnboardingScreenState();
}

class _ShopOnboardingScreenState extends State<ShopOnboardingScreen> {
  int _step = 0;
  int _tier = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Setup — Step ${_step + 1} of 4'),
      ),
      body: IndexedStack(
        index: _step,
        children: [
          _StepShopDetails(),
          _StepTierPicker(
              selectedTier: _tier,
              onTierChanged: (t) => setState(() => _tier = t)),
          _StepCategoryPicker(),
          _StepSeedStock(),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: FilledButton(
          onPressed: () {
            if (_step < 3) {
              setState(() => _step++);
            } else {
              Navigator.of(context).pushReplacementNamed('/home');
            }
          },
          child: Text(_step == 3 ? 'Finish Setup' : 'Next'),
        ),
      ),
    );
  }
}

class _StepShopDetails extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Shop details',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
        const SizedBox(height: 24),
        const TextField(
            decoration: InputDecoration(
                labelText: 'Shop name', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        const TextField(
            decoration: InputDecoration(
                labelText: "Owner's name", border: OutlineInputBorder())),
        const SizedBox(height: 12),
        const TextField(
            decoration: InputDecoration(
                labelText: 'Phone',
                prefixText: '+977 ',
                border: OutlineInputBorder())),
      ],
    );
  }
}

class _StepTierPicker extends StatelessWidget {
  const _StepTierPicker(
      {required this.selectedTier, required this.onTierChanged});
  final int selectedTier;
  final ValueChanged<int> onTierChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('How do you want to manage stock?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text(
          'Choose the tier that matches how you work. You can change this later.',
          style: TextStyle(color: Color(0xFF6B6F7A)),
        ),
        const SizedBox(height: 24),
        _TierCard(
          tier: 1,
          selected: selectedTier == 1,
          title: 'SMS only (simplest)',
          body:
              'Reply "OUT 14" or "IN 14" to update stock via SMS. No app needed.',
          onTap: () => onTierChanged(1),
        ),
        _TierCard(
          tier: 2,
          selected: selectedTier == 2,
          title: 'App — toggle stock',
          body: 'Tap to mark items in/out of stock in this app.',
          onTap: () => onTierChanged(2),
        ),
        _TierCard(
          tier: 3,
          selected: selectedTier == 3,
          title: 'Full catalog',
          body: 'Manage prices, quantities, and your full product list.',
          onTap: () => onTierChanged(3),
        ),
      ],
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.tier,
    required this.selected,
    required this.title,
    required this.body,
    required this.onTap,
  });
  final int tier;
  final bool selected;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFBEEE8) : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFFA8442C) : const Color(0xFFE7E5E2),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: selected
                              ? const Color(0xFFA8442C)
                              : const Color(0xFF2B2D3D))),
                  const SizedBox(height: 4),
                  Text(body,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF6B6F7A))),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: Color(0xFFA8442C)),
          ],
        ),
      ),
    );
  }
}

class _StepCategoryPicker extends StatefulWidget {
  @override
  State<_StepCategoryPicker> createState() => _StepCategoryPickerState();
}

class _StepCategoryPickerState extends State<_StepCategoryPicker> {
  final Set<String> _selected = {'Staples', 'Dairy'};
  static const _cats = [
    'Staples',
    'Oils & Fats',
    'Spices',
    'Dairy',
    'Snacks',
    'Beverages',
    'Cleaning',
    'Hygiene',
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('What do you sell?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _cats.map((c) {
            final sel = _selected.contains(c);
            return FilterChip(
              label: Text(c),
              selected: sel,
              onSelected: (v) =>
                  setState(() => v ? _selected.add(c) : _selected.remove(c)),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _StepSeedStock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Seed your top 20 products',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text(
          'Mark which items you currently carry. You can update this any time.',
          style: TextStyle(color: Color(0xFF6B6F7A)),
        ),
        const SizedBox(height: 16),
        ...List.generate(
            8,
            (i) => SwitchListTile(
                  title: Text('Product ${i + 1}'),
                  subtitle: const Text('500g'),
                  value: i < 5,
                  onChanged: (_) {},
                )),
      ],
    );
  }
}

class ShopOrdersScreen extends StatelessWidget {
  const ShopOrdersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Queue')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _OrderQueueSection(title: 'Accepted', status: 'shop_confirmed'),
          _OrderQueueSection(title: 'Preparing', status: 'preparing'),
          _OrderQueueSection(title: 'Ready for pickup', status: 'ready'),
        ],
      ),
    );
  }
}

class _OrderQueueSection extends StatelessWidget {
  const _OrderQueueSection({required this.title, required this.status});
  final String title;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Card(
          child: ListTile(
            title: Text('Order #A1B2'),
            subtitle: Text('Wai Wai × 2, Mustard Oil × 1'),
            trailing: Text('रु 280'),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class ShopInventoryScreen extends StatelessWidget {
  const ShopInventoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 10,
        itemBuilder: (ctx, i) => SwitchListTile(
          title: Text('Product ${i + 1}'),
          subtitle: const Text('500g · रु 120'),
          value: i % 3 != 2,
          onChanged: (_) {},
          activeColor: const Color(0xFFA8442C),
        ),
      ),
    );
  }
}

class ShopReliabilityScreen extends StatelessWidget {
  const ShopReliabilityScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reliability Score')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('Your Score', style: TextStyle(fontSize: 16)),
                  const Text(
                    '82%',
                    style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFA8442C)),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8A33D).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Text('Silver Tier',
                        style: TextStyle(color: Color(0xFFE8A33D))),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Score breakdown',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const ListTile(
            leading: Icon(Icons.check_circle, color: Color(0xFF2E7D52)),
            title: Text('Orders fulfilled on time'),
            trailing: Text('41'),
          ),
          const ListTile(
            leading: Icon(Icons.cancel, color: Color(0xFFC0392B)),
            title: Text('Orders cancelled after accept'),
            trailing: Text('3'),
          ),
        ],
      ),
    );
  }
}

class ShopPayoutsScreen extends StatelessWidget {
  const ShopPayoutsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payout History')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('This week', style: TextStyle(color: Color(0xFF6B6F7A))),
                  Text(
                    'रु 14,250',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  Text('7 orders', style: TextStyle(color: Color(0xFF6B6F7A))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Past payouts',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...List.generate(
            4,
            (i) => ListTile(
              title: Text('Week of Jun ${(30 - i * 7).clamp(1, 30)}'),
              subtitle: Text('${6 + i} orders'),
              trailing: Text('रु ${(12000 + i * 1200).toString()}'),
            ),
          ),
        ],
      ),
    );
  }
}
