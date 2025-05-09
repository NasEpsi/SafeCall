/*
*
* Service who will handle all the data from and to firestore
*
* ----------------------------------------------------------
*
* - user
* - Blocked numbers
* - Blocked prefixes
* - Report of numbers
* */

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/user.dart';

class DatabaseService {
  // get an instance of Firestore
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  /*
  * User
  * When creating an account, we will save the data in the database to display it on the profile
  * */

  // Saving User data
  Future<void> saveUserInfoInFirebase({required String email, provider, numberUser}) async {
    // gets uid
    String? uid = _auth.currentUser?.uid;

    if (uid == null) {
      throw Exception("Utilisateur non connecté");
    }

    // Create userProfile
    UserProfile user = UserProfile(
      uid: uid,
      email: email,
      numberUser: numberUser,
      provider: provider,
    );

    // converting the user in a map in order to save it in the firestore
    final userMap = user.toMap();

    // saving in the database
    await _db.collection('Users').doc(uid).set(userMap);
  }

  // update users number
  Future<void> updateUserPhoneInFirebase(String numberUser) async {
    // gets uid
    String? uid = _auth.currentUser?.uid;


    // update in firebase
    try {
      await _db
          .collection("Users")
          .doc(uid)
          .update({"number_user": numberUser});
    } catch (e) {
      throw Exception("Erreur lors de la mise à jour du numéro");
    }
  }

  // Get user Data
  Future<UserProfile?> getUserFromFirebase(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await _db.collection("Users").doc(uid).get();
      return UserProfile.fromDocument(userDoc);
    } catch (e) {
      print(e);
      return null;
    }
  }

}
