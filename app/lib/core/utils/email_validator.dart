bool isValidEmailAddress(String value) {
  final email = value.trim();
  final emailRegex = RegExp(
    r'^[A-Za-z0-9._%+-]+@(?:[A-Za-z0-9-]+\.)+[A-Za-z]{2,}$',
  );
  return emailRegex.hasMatch(email);
}
