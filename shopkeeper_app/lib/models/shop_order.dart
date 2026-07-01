class ShopOrder {
  final String id;
  final String status;
  final double totalAmount;
  final String createdAt;
  final List<ShopOrderItem> items;
  final String? driverName;
  final String? driverPhone;

  const ShopOrder({required this.id, required this.status, required this.totalAmount,
    required this.createdAt, required this.items, this.driverName, this.driverPhone});

  factory ShopOrder.fromJson(Map<String, dynamic> j) => ShopOrder(
    id: j['id'] as String,
    status: j['status'] as String? ?? 'pending',
    totalAmount: (j['totalAmount'] as num?)?.toDouble() ?? 0,
    createdAt: j['createdAt'] as String? ?? '',
    items: (j['items'] as List?)?.map((i) => ShopOrderItem.fromJson(i as Map<String, dynamic>)).toList() ?? [],
    driverName: (j['assignedDriver'] as Map?)?['name'] as String?,
    driverPhone: (j['assignedDriver'] as Map?)?['phone'] as String?,
  );

  String get itemSummary {
    if (items.isEmpty) return 'Order';
    return items.map((i) => '${i.productName} \u00d7 ${i.qty}').join(', ');
  }
}

class ShopOrderItem {
  final String productName;
  final int qty;
  final double unitPrice;
  const ShopOrderItem({required this.productName, required this.qty, required this.unitPrice});
  factory ShopOrderItem.fromJson(Map<String, dynamic> j) => ShopOrderItem(
    productName: (j['product'] as Map?)?['name'] as String? ?? 'Item',
    qty: j['qty'] as int? ?? 0,
    unitPrice: (j['unitPrice'] as num?)?.toDouble() ?? 0,
  );
}
