/*
*
* models of a prefix
*
* -----------------------------------------
*
* A prefix is made with
*
* - id
* - prefix
*
* */


class Prefix {
  final int? id;
  final String prefix;


  Prefix({
    this.id,
    required this.prefix,
  });

  factory Prefix.fromMap(Map<String, dynamic> map) {
    return Prefix(
      id: map['id'],
      prefix: map['prefix'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'prefix': prefix,
    };
  }
}
