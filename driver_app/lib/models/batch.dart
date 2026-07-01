class Batch {
  final String id;
  final String driverId;
  final List<String> orderIds;
  final String status;
  final String createdAt;
  final List<BatchOrder> orders;

  const Batch({
    required this.id,
    required this.driverId,
    required this.orderIds,
    required this.status,
    required this.createdAt,
    required this.orders,
  });

  factory Batch.fromJson(Map<String, dynamic> j) => Batch(
    id: j['id'] as String,
    driverId: j['driverId'] as String? ?? '',
    orderIds: (j['orderIds'] as List?)?.cast<String>() ?? [],
    status: j['status'] as String? ?? 'assigned',
    createdAt: j['createdAt'] as String? ?? '',
    orders: (j['orders'] as List?)?.map((o) => BatchOrder.fromJson(o as Map<String, dynamic>)).toList() ?? [],
  );
}

class BatchOrder {
  final String id;
  final String status;
  final double totalAmount;
  final String createdAt;
  final Map<String, dynamic>? deliveryAddress;
  final List<OrderItem> items;
  final ShopInfo? shop;

  const BatchOrder({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    this.deliveryAddress,
    required this.items,
    this.shop,
  });

  factory BatchOrder.fromJson(Map<String, dynamic> j) => BatchOrder(
    id: j['id'] as String,
    status: j['status'] as String? ?? 'pending',
    totalAmount: (j['totalAmount'] as num?)?.toDouble() ?? 0,
    createdAt: j['createdAt'] as String? ?? '',
    deliveryAddress: j['deliveryAddress'] as Map<String, dynamic>?,
    items: (j['items'] as List?)?.map((i) => OrderItem.fromJson(i as Map<String, dynamic>)).toList() ?? [],
    shop: j['assignedShop'] != null ? ShopInfo.fromJson(j['assignedShop'] as Map<String, dynamic>) : null,
  );

  String get itemSummary {
    if (items.isEmpty) return 'Order';
    final first = items.first.productName;
    return items.length > 1 ? '$first + ${items.length - 1} more' : first;
  }
}

class OrderItem {
  final String id;
  final String productId;
  final int qty;
  final double unitPrice;
  final String productName;

  const OrderItem({
    required this.id,
    required this.productId,
    required this.qty,
    required this.unitPrice,
    required this.productName,
  });

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
    id: j['id'] as String? ?? '',
    productId: j['productId'] as String? ?? '',
    qty: j['qty'] as int? ?? 0,
    unitPrice: (j['unitPrice'] as num?)?.toDouble() ?? 0,
    productName: (j['product'] as Map?)?['name'] as String? ?? 'Item',
  );
}

class ShopInfo {
  final String shopName;
  final double? lat;
  final double? lng;
  final String? phone;

  const ShopInfo({required this.shopName, this.lat, this.lng, this.phone});

  factory ShopInfo.fromJson(Map<String, dynamic> j) => ShopInfo(
    shopName: j['shopName'] as String? ?? '',
    lat: (j['lat'] as num?)?.toDouble(),
    lng: (j['lng'] as num?)?.toDouble(),
    phone: j['phone'] as String?,
  );
}
