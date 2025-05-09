/*
* Service Auth Firbase
*
* Gere l'autorisation des utilisateurs dans Firebase Auth
*
*
*
* -----------------------------------------------------
*
* login (email and password / Google)
* logout
* Create an account
* Delete an account
*
*
*/

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../database/database_service.dart';

class AuthService {
  // get the auth  instance
  final _auth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn();
  final _dbService = DatabaseService();

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

  // Google sign in
  Future<UserCredential?> signInWithGoogleService() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // creating a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // when  connected return to user Credential
      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      // if its a new user, saving data in firebase
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _dbService.saveUserInfoInFirebase(
          email: userCredential.user?.email ?? '',
          provider: 'google',
          numberUser: '',
        );
      }

      return userCredential;
    } catch (e) {
      print(e);
      throw Exception('Échec de la connexion avec Google');
    }
  }

//logout
  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

// creation
  Future<UserCredential> registerEmailPassword(
      String email, password, numberUser) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // saving data in firestore
      await _dbService.saveUserInfoInFirebase(
        email: email,
        provider: 'email',
        numberUser: numberUser,
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }
}
