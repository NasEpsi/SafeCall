/*

Verify if the number is in the good format

*/

String normalizePhoneNumber(String input) {
  String raw = input.replaceAll(RegExp(r'[^+0-9]'), ''); // supprime espaces, tirets, etc.

  if (raw.startsWith('0033')) {
    raw = raw.replaceFirst('0033', '+33');
  } else if (raw.startsWith('0')) {
    raw = raw.replaceFirst('0', '+33');
  }
  return raw;
}

bool isValidFrenchMobile(String number) {
  final cleaned = normalizePhoneNumber(number);
  return RegExp(r'^\+33[67][0-9]{8}$').hasMatch(cleaned);
}

// Méthode pour normaliser et formater le numéro avant sauvegarde
String normalizeToInternationalFormat(String number) {
  try {
    String cleaned = number.replaceAll(RegExp(r'[^+0-9]'), '');

    // if format number has no +33
    if (cleaned.length == 10 && RegExp(r'^0[6-9][0-9]{8}$').hasMatch(cleaned)) {
      final withoutFirst = cleaned.substring(1); // Enlever le premier 0
      return '+33 ${withoutFirst.substring(0, 1)} ${withoutFirst.substring(1, 3)} ${withoutFirst.substring(3, 5)} ${withoutFirst.substring(5, 7)} ${withoutFirst.substring(7, 9)}';
    }

    if (cleaned.startsWith('0033') && cleaned.length == 13) {
      final mobile = cleaned.substring(4); // Enlever 0033
      return '+33 ${mobile.substring(0, 1)} ${mobile.substring(1, 3)} ${mobile.substring(3, 5)} ${mobile.substring(5, 7)} ${mobile.substring(7, 9)}';
    }

    // if format is 33 with no +
    if (cleaned.startsWith('33') && cleaned.length == 11 && !cleaned.startsWith('+33')) {
      final mobile = cleaned.substring(2); // Enlever le 33
      return '+33 ${mobile.substring(0, 1)} ${mobile.substring(1, 3)} ${mobile.substring(3, 5)} ${mobile.substring(5, 7)} ${mobile.substring(7, 9)}';
    }

    // if + 33 format is already here
    if (cleaned.startsWith('+33')) {
      final mobile = cleaned.substring(3);
      if (mobile.length == 9) {
        return '+33 ${mobile.substring(0, 1)} ${mobile.substring(1, 3)} ${mobile.substring(3, 5)} ${mobile.substring(5, 7)} ${mobile.substring(7, 9)}';
      }
    }

    // if format is not recognized
    if (cleaned.length == 9 && RegExp(r'^[6-9][0-9]{8}$').hasMatch(cleaned)) {
      return '+33 ${cleaned.substring(0, 1)} ${cleaned.substring(1, 3)} ${cleaned.substring(3, 5)} ${cleaned.substring(5, 7)} ${cleaned.substring(7, 9)}';
    }

    // En dernier recours, retourner le numéro original
    return number;
  } catch (e) {
    // En cas d'erreur, retourner le numéro original
    return number;
  }
}