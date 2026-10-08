import '../../../core/network/rg_integration.dart';

enum RegistrationOutcome { newCustomer, syncMember, memberConflict }

class RegistrationRequest {
  const RegistrationRequest({
    required this.name,
    required this.phone,
    required this.email,
    required this.birthDate,
    this.memberNumber,
    this.referral,
  });
  final String name;
  final String phone;
  final String email;
  final DateTime birthDate;
  final String? memberNumber;
  final String? referral;
  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'email': email,
    'birthDate': birthDate.toIso8601String().split('T').first,
    if (memberNumber?.isNotEmpty == true) 'memberNumber': memberNumber,
    if (referral?.isNotEmpty == true) 'referral': referral,
  };
}

abstract class RegistrationRepository {
  Future<RegistrationOutcome> validateAndRegister(RegistrationRequest request);
  static RegistrationRepository create() => RgIntegration.preview
      ? const PreviewRegistrationRepository()
      : RgRegistrationRepository();
}

class PreviewRegistrationRepository implements RegistrationRepository {
  const PreviewRegistrationRepository({
    this.outcome = RegistrationOutcome.newCustomer,
  });
  final RegistrationOutcome outcome;
  @override
  Future<RegistrationOutcome> validateAndRegister(
    RegistrationRequest request,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    return outcome;
  }
}

class RgRegistrationRepository implements RegistrationRepository {
  @override
  Future<RegistrationOutcome> validateAndRegister(
    RegistrationRequest request,
  ) async {
    final url = RgIntegration.requireHttps(RgIntegration.registrationUrl);
    final response = await RgIntegration.dio.postUri(
      url,
      data: request.toJson(),
    );
    // Normalized MyRG contract; mapping to RG's actual payload needs API agreement.
    final status = (response.data as Map<String, dynamic>)['outcome'];
    return switch (status) {
      'newCustomer' => RegistrationOutcome.newCustomer,
      'syncMember' => RegistrationOutcome.syncMember,
      'memberConflict' => RegistrationOutcome.memberConflict,
      _ => throw const FormatException('Unknown registration outcome'),
    };
  }
}
