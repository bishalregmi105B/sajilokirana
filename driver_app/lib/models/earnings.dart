class Earnings {
  final EarningsPeriod today;
  final EarningsPeriod thisWeek;
  final EarningsAllTime allTime;

  const Earnings({required this.today, required this.thisWeek, required this.allTime});

  factory Earnings.fromJson(Map<String, dynamic> j) => Earnings(
    today: EarningsPeriod.fromJson(j['today'] as Map<String, dynamic>),
    thisWeek: EarningsPeriod.fromJson(j['thisWeek'] as Map<String, dynamic>),
    allTime: EarningsAllTime.fromJson(j['allTime'] as Map<String, dynamic>),
  );
}

class EarningsPeriod {
  final int earnings;
  final int deliveries;
  const EarningsPeriod({required this.earnings, required this.deliveries});
  factory EarningsPeriod.fromJson(Map<String, dynamic> j) => EarningsPeriod(
    earnings: j['earnings'] as int? ?? 0,
    deliveries: j['deliveries'] as int? ?? 0,
  );
}

class EarningsAllTime {
  final int earnings;
  final int deliveries;
  final int batches;
  const EarningsAllTime({required this.earnings, required this.deliveries, required this.batches});
  factory EarningsAllTime.fromJson(Map<String, dynamic> j) => EarningsAllTime(
    earnings: j['earnings'] as int? ?? 0,
    deliveries: j['deliveries'] as int? ?? 0,
    batches: j['batches'] as int? ?? 0,
  );
}
