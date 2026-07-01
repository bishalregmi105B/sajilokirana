class IncomingBroadcast {
  final String id;
  final String orderId;
  final int confirmWindowSeconds;
  final String broadcastAt;
  final BroadcastOrder order;

  const IncomingBroadcast({required this.id, required this.orderId,
    required this.confirmWindowSeconds, required this.broadcastAt, required this.order});

  factory IncomingBroadcast.fromJson(Map<String, dynamic> j) => IncomingBroadcast(
    id: j['id'] as String, orderId: j['orderId'] as String,
    confirmWindowSeconds: j['confirmWindowSeconds'] as int? ?? 40,
    broadcastAt: j['broadcastAt'] as String? ?? '',
    order: BroadcastOrder.fromJson(j['order'] as Map<String, dynamic>),
  );
}

class BroadcastOrder {
  final String id;
  final double totalAmount;
  final List<BroadcastItem> items;

  const BroadcastOrder({required this.id, required this.totalAmount, required this.items});
  factory BroadcastOrder.fromJson(Map<String, dynamic> j) => BroadcastOrder(
    id: j['id'] as String,
    totalAmount: (j['totalAmount'] as num?)?.toDouble() ?? 0,
    items: (j['items'] as List?)?.map((i) => BroadcastItem.fromJson(i as Map<String, dynamic>)).toList() ?? [],
  );
  String get itemSummary => items.map((i) => '${i.productName} \u00d7 ${i.qty}').join(', ');
}

class BroadcastItem {
  final String productName;
  final int qty;
  const BroadcastItem({required this.productName, required this.qty});
  factory BroadcastItem.fromJson(Map<String, dynamic> j) => BroadcastItem(
    productName: (j['product'] as Map?)?['name'] as String? ?? 'Item',
    qty: j['qty'] as int? ?? 0,
  );
}
