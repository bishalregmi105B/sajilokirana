class ShopAnalytics {
  final double reliabilityScore;
  final int reliabilityPercent;
  final AnalyticsOrders orders;
  final AnalyticsRevenue revenue;

  const ShopAnalytics({required this.reliabilityScore, required this.reliabilityPercent,
    required this.orders, required this.revenue});

  factory ShopAnalytics.fromJson(Map<String, dynamic> j) => ShopAnalytics(
    reliabilityScore: (j['reliabilityScore'] as num?)?.toDouble() ?? 0,
    reliabilityPercent: j['reliabilityPercent'] as int? ?? 0,
    orders: AnalyticsOrders.fromJson(j['orders'] as Map<String, dynamic>),
    revenue: AnalyticsRevenue.fromJson(j['revenue'] as Map<String, dynamic>),
  );
}

class AnalyticsOrders {
  final int today, thisWeek, allTime, cancelled;
  const AnalyticsOrders({required this.today, required this.thisWeek, required this.allTime, required this.cancelled});
  factory AnalyticsOrders.fromJson(Map<String, dynamic> j) => AnalyticsOrders(
    today: j['today'] as int? ?? 0, thisWeek: j['thisWeek'] as int? ?? 0,
    allTime: j['allTime'] as int? ?? 0, cancelled: j['cancelled'] as int? ?? 0,
  );
}

class AnalyticsRevenue {
  final double today, thisWeek, allTime;
  const AnalyticsRevenue({required this.today, required this.thisWeek, required this.allTime});
  factory AnalyticsRevenue.fromJson(Map<String, dynamic> j) => AnalyticsRevenue(
    today: (j['today'] as num?)?.toDouble() ?? 0,
    thisWeek: (j['thisWeek'] as num?)?.toDouble() ?? 0,
    allTime: (j['allTime'] as num?)?.toDouble() ?? 0,
  );
}
