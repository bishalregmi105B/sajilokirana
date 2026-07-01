class Driver {
  final String id;
  final String name;
  final String phone;
  final String vehicleType;
  final double? currentLat;
  final double? currentLng;
  final String status;
  final String? currentBatchId;

  const Driver({
    required this.id,
    required this.name,
    required this.phone,
    required this.vehicleType,
    this.currentLat,
    this.currentLng,
    required this.status,
    this.currentBatchId,
  });

  bool get isOnline => status == 'available' || status == 'busy';
  bool get isAvailable => status == 'available';
  bool get isBusy => status == 'busy';

  factory Driver.fromJson(Map<String, dynamic> j) => Driver(
    id: j['id'] as String,
    name: j['name'] as String? ?? '',
    phone: j['phone'] as String? ?? '',
    vehicleType: j['vehicleType'] as String? ?? 'bike',
    currentLat: (j['currentLat'] as num?)?.toDouble(),
    currentLng: (j['currentLng'] as num?)?.toDouble(),
    status: j['status'] as String? ?? 'offline',
    currentBatchId: j['currentBatchId'] as String?,
  );
}
