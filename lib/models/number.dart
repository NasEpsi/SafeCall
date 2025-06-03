/*
*
* models of a number
*
* -----------------------------------------
*
* A number is made with
*
* - number
* - prefix
* - Spam
*
* */



class Number {
  final String id;
  final String number;
  final String prefix;
  final bool isSpam;

  Number({
    required this.id,
    required this.number,
    required this.prefix,
    this.isSpam = false,
  });

  factory Number.fromMap(Map<String, dynamic> map, String id) {
    return Number(
      id: id,
      number: map['number'],
      prefix: map['prefix'],
      isSpam: map['is_spam'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'number': number,
      'prefix': prefix,
      'is_spam': isSpam,
    };
  }
}