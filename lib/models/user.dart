/*
*
* models of a user
*
* -----------------------------------------
*
* A user is made with
*
*uid
* name
* email
*
* */

import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String numero;



  UserProfile({
    required this.uid,
    required this.email,
    required this.numero
  });

  // Converting a firestore file into a model user
  factory UserProfile.fromDocument(DocumentSnapshot doc) {
    return UserProfile(
      uid: doc['uid'],
      email: doc['email'],
      numero: doc['numero'],
    );
  }

  // Converting a model user into a firestore file
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'numero': numero,
    };
  }
}