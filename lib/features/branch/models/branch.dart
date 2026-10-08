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
  });
  final String id, name, address;
  final double distanceKm;
  final List<String> services;
  String get hours => '08:00 - 17:00 WIB';
}
