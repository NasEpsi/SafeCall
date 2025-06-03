/*
*
* models of a user
*
* -----------------------------------------
*
* A user is made with
*
*uid
* email
* - password ( in firebase auth )
* - number_user
* - provider (email, google)
*
* */

import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String numberUser;
  final String provider;
  final List<String> numbersBlocked; // Liste des IDs de numéros bloqués
  final List<String> prefixesBlocked; // Liste des IDs de préfixes bloqués

  UserProfile({
    required this.uid,
    required this.email,
    required this.numberUser,
    this.provider = 'email',
    this.numbersBlocked = const [],
    this.prefixesBlocked = const [],
  });

  // Convert doc Firestore into user model
  factory UserProfile.fromDocument(DocumentSnapshot doc) {
    return UserProfile(
      uid: doc['uid'],
      email: doc['email'],
      numberUser: doc['number_user'] ?? '',
      provider: doc['provider'] ?? 'email',
      numbersBlocked: List<String>.from(doc['numbers_blocked'] ?? []),
      prefixesBlocked: List<String>.from(doc['prefixes_blocked'] ?? []),
    );
  }

  // Convert user model in firestore doc
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'number_user': numberUser,
      'provider': provider,
      'numbers_blocked': numbersBlocked,
      'prefixes_blocked': prefixesBlocked,
    };
  }
}