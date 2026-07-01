class Shop {
  final String id;
  final String ownerName;
  final String shopName;
  final String phone;
  final double lat;
  final double lng;
  final List<String> categories;
  final int onboardingTier;
  final String status;
  final double reliabilityScore;
  final String? payoutAccount;

  const Shop({required this.id, required this.ownerName, required this.shopName,
    required this.phone, required this.lat, required this.lng,
    required this.categories, required this.onboardingTier,
    required this.status, required this.reliabilityScore, this.payoutAccount});

  int get reliabilityPercent => (reliabilityScore * 100).round();

  factory Shop.fromJson(Map<String, dynamic> j) => Shop(
    id: j['id'] as String, ownerName: j['ownerName'] as String? ?? '',
    shopName: j['shopName'] as String? ?? '', phone: j['phone'] as String? ?? '',
    lat: (j['lat'] as num?)?.toDouble() ?? 0, lng: (j['lng'] as num?)?.toDouble() ?? 0,
    categories: (j['categories'] as List?)?.cast<String>() ?? [],
    onboardingTier: j['onboardingTier'] as int? ?? 2,
    status: j['status'] as String? ?? 'active',
    reliabilityScore: (j['reliabilityScore'] as num?)?.toDouble() ?? 0.5,
    payoutAccount: j['payoutAccount'] as String?,
  );
}
