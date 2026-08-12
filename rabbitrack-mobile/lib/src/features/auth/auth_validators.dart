String? requiredTextValidator(String? value, String message) {
  return value == null || value.trim().isEmpty ? message : null;
}

String? emailValidator(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) {
    return 'Enter your email';
  }
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
    return 'Enter a valid email';
  }

  return null;
}

String? passwordValidator(String? value) {
  if ((value ?? '').length < 8) {
    return 'Use at least 8 characters';
  }

  return null;
}

String? confirmPasswordValidator(String? value, String password) {
  if (value != password) {
    return 'Passwords do not match';
  }

  return null;
}

String? resetCodeValidator(String? value) {
  if ((value ?? '').length != 6) {
    return 'Enter the 6-digit code';
  }

  return null;
}
