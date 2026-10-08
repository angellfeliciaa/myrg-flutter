abstract final class Validators {
  static String? required(String? value, {String fieldName = 'Data'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName wajib diisi';
    }
    return null;
  }

  static String? email(String? value) {
    final requiredError = required(value, fieldName: 'Email');
    if (requiredError != null) return requiredError;

    final pattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return pattern.hasMatch(value!.trim()) ? null : 'Format email tidak valid';
  }

  static String? optionalEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return email(value);
  }

  static String? fullName(String? value) {
    final requiredError = required(value, fieldName: 'Nama lengkap');
    if (requiredError != null) return requiredError;
    if (value!.trim().length < 3) return 'Nama lengkap minimal 3 karakter';
    return null;
  }

  static String? indonesianPhone(String? value) {
    final requiredError = required(value, fieldName: 'Nomor telepon');
    if (requiredError != null) return requiredError;

    final phone = value!.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^08\d{8,11}$').hasMatch(phone)) {
      return 'Gunakan nomor Indonesia yang valid';
    }
    return null;
  }

  static String? emailOrPhone(String? value) {
    final requiredError = required(
      value,
      fieldName: 'Email atau nomor telepon',
    );
    if (requiredError != null) return requiredError;

    final input = value!.trim();
    if (input.contains('@')) return email(input);

    final phone = input.replaceAll(RegExp(r'[^0-9+]'), '');
    final digits = phone.replaceFirst(RegExp(r'^\+'), '');
    if (digits.length < 9 || digits.length > 15) {
      return 'Nomor telepon tidak valid';
    }
    return null;
  }

  static String? password(String? value) {
    final requiredError = required(value, fieldName: 'Password');
    if (requiredError != null) return requiredError;
    if (value!.length < 8) return 'Password minimal 8 karakter';
    return null;
  }
}
