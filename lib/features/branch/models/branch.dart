class Branch {
  const Branch({
    required this.id,
    required this.name,
    required this.address,
    required this.distanceKm,
    this.services = const [
      'Gadai HP',
      'Gadai Elektronik',
      'Pembayaran',
      'Pengambilan Barang',
    ],
    this.phone,
    this.todayLabel = '08:00 - 17:00 WIB',
    this.openingHours = const [
      ('Senin - Jumat', '08:00 - 17:00'),
      ('Sabtu', '09:00 - 17:00'),
      ('Minggu', 'Tutup'),
    ],
  });

  /// One outlet from GET /branches (MyRG backend). Hours and services are set by MyRG admin;
  /// distanceKm is only there when the app sent its location.
  factory Branch.fromApi(Map<String, dynamic> json) {
    String range(Object? hours) =>
        hours is Map ? '${hours['open']} - ${hours['close']}' : 'Tutup';
    final week = json['openingHours'];
    final services = json['services'];
    return Branch(
      id: '${json['code'] ?? ''}',
      name: '${json['name'] ?? ''}',
      address: '${json['address'] ?? ''}',
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      phone: (json['phone'] as String?)?.trim().isEmpty ?? true
          ? null
          : (json['phone'] as String).trim(),
      todayLabel: '${json['todayLabel'] ?? '-'}',
      services: services is List ? [for (final s in services) '$s'] : const [],
      openingHours: week is List
          ? [
              for (final day in week)
                if (day is Map) ('${day['days']}', range(day['hours'])),
            ]
          : const [],
    );
  }

  final String id, name, address;
  final double? distanceKm;
  final List<String> services;
  final String? phone;
  final String todayLabel;
  final List<(String, String)> openingHours;
  String get hours => todayLabel;
}
