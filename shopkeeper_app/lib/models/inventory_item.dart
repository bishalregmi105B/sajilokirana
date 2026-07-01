class InventoryItem {
  final String shopId;
  final String productId;
  final double price;
  final bool inStock;
  final String productName;
  final String productUnit;
  final String productCategory;

  const InventoryItem({required this.shopId, required this.productId,
    required this.price, required this.inStock, required this.productName,
    required this.productUnit, required this.productCategory});

  factory InventoryItem.fromJson(Map<String, dynamic> j) => InventoryItem(
    shopId: j['shopId'] as String? ?? '',
    productId: j['productId'] as String? ?? '',
    price: (j['price'] as num?)?.toDouble() ?? 0,
    inStock: j['inStock'] as bool? ?? false,
    productName: (j['product'] as Map?)?['name'] as String? ?? 'Product',
    productUnit: (j['product'] as Map?)?['unit'] as String? ?? '',
    productCategory: (j['product'] as Map?)?['category'] as String? ?? '',
  );
}
