/*
* Service Auth Firbase
*
* Gere l'autorisation des utilisateurs dans Firebase Auth
*
*
*
* -----------------------------------------------------
*
* login
* logout
* Create an account
* Delete an account
*
*
*/

import 'package:firebase_auth/firebase_auth.dart';

class AuthService {

  // get the auth  instance
  final _auth = FirebaseAuth.instance;

  // get the current user and his id
  User? getCurrentUser() => _auth.currentUser;

  String getCurrentUid() => _auth.currentUser!.uid;

  // login by email and password
  Future<UserCredential> loginEmailPassword(String email, password) async {
    // try to connect
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }
//logout
  Future<void> logout() async {
    await _auth.signOut();
  }
// creation
  Future<UserCredential> registerEmailPassword(String email, password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return userCredential;
    } on FirebaseAuthException catch(e){
      throw Exception(e.code);
    }
  }

}