import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shop_provider.dart';
import '../theme/colors.dart';
import '../constants.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ShopProvider>().loadInventory());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: Consumer<ShopProvider>(builder: (_, sp, __) {
        if (sp.isLoading && sp.inventory.isEmpty) return const Center(child: CircularProgressIndicator());
        if (sp.inventory.isEmpty) return const Center(child: Text('No inventory items'));
        return ListView.builder(
          padding: const EdgeInsets.all(16), itemCount: sp.inventory.length,
          itemBuilder: (_, i) {
            final item = sp.inventory[i];
            return Card(margin: const EdgeInsets.only(bottom: 8), child: SwitchListTile(
              title: Text(item.productName),
              subtitle: Text('${item.productUnit} \u00b7 $appCurrencySymbol ${item.price.toStringAsFixed(0)}'),
              value: item.inStock, onChanged: (v) => sp.toggleStock(item.productId, v),
              activeColor: AppColors.primary,
            ));
          },
        );
      }),
    );
  }
}
