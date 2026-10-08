import '../models/branch.dart';

/// Figma fixtures only, not live addresses, GPS distances or schedules.
class BranchRepository {
  const BranchRepository();
  static const fixtures = [
    Branch(
      id: 'tebet',
      name: 'Raja Gadai Tebet',
      address: 'Jl. Kemang Raya No. 15, Jakarta Selatan',
      distanceKm: 1.2,
    ),
    Branch(
      id: 'kemang',
      name: 'Raja Gadai Kemang',
      address: 'Jl. Melawai Raya No. 10, Jakarta Selatan',
      distanceKm: 2.5,
    ),
    Branch(
      id: 'menteng',
      name: 'Raja Gadai Menteng',
      address: 'Jl. HOS Cokroaminoto No. 22, Jakarta Pusat',
      distanceKm: 3.1,
    ),
  ];
  Future<List<Branch>> load() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return fixtures;
  }
}
