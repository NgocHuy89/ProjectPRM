class AppValidators {
  AppValidators._();

  static final RegExp _emailPattern = RegExp(
    r"^[A-Z0-9.!#$%&'*+/=?^_`{|}~-]+@(?:[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?\.)+[A-Z]{2,63}$",
    caseSensitive: false,
  );

  static bool isValidEmail(String value) {
    final email = value.trim();
    if (email.isEmpty || email.length > 254) return false;

    final parts = email.split('@');
    if (parts.length != 2) return false;
    if (parts.first.isEmpty || parts.first.length > 64) return false;

    return _emailPattern.hasMatch(email);
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập email';
    }
    if (!isValidEmail(value)) {
      return 'Email không hợp lệ';
    }
    return null;
  }
}
