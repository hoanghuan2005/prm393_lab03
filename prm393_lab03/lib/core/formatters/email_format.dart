/// "x…@gmail.com": first character of the local part only, so the full email is never shown
String maskEmail(String email) {
  final at = email.indexOf('@');
  if (at <= 0) return '…';
  return '${email[0]}…${email.substring(at)}';
}
