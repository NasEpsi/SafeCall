/*
*
* Database provider
*
*
* Used to separate the management of firestore data in the way it is displayed on the UI
*
* - the database service takes care of managing the data of the bdd
* - the database provider organizes and displays the data
*
* ca makes the code adaptable, readable , easy to test, clean and on.
*
* we choose to evolve the backend, the front end interacting with this provider and not with the live service
* only service interactions will have to be evaluated ___ provider simplifying transition and maintenance
*
* */

import 'package:flutter/foundation.dart';

import '../../models/user.dart';
import '../auth/auth_service.dart';
import 'database_service.dart';

class DatabaseProvider extends ChangeNotifier {

  // get database and auth
  final _auth = AuthService();
  final _db = DatabaseService();



  // locale variables
  UserProfile? _currentUser;
  List<Map<String, dynamic>> _blockedNumbers = [];
  List<Map<String, dynamic>> _blockedPrefixes = [];
  List<Map<String, dynamic>> _userReports = [];
  bool _isLoading = false;

  // Getters
  UserProfile? get currentUser => _currentUser;
  List<Map<String, dynamic>> get blockedNumbers => _blockedNumbers;
  List<Map<String, dynamic>> get blockedPrefixes => _blockedPrefixes;
  List<Map<String, dynamic>> get userReports => _userReports;
  bool get isLoading => _isLoading;

  // Initialisation usersData
  Future<void> initUserData() async {
    setLoading(true);

    try {
      String? uid = _auth.getCurrentUid();
        await loadUserProfile(uid);
        // await loadBlockedNumbers();
        // await loadBlockedPrefixes();
        // await loadUserReports();
    } catch (e) {
      print(e);
    } finally {
      setLoading(false);
    }
  }

  // Définir l'état de chargement
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Charger le profil de l'utilisateur
  Future<void> loadUserProfile(String uid) async {
    try {
      _currentUser = await _db.getUserFromFirebase(uid);
      notifyListeners();
    } catch (e) {
      print(e);
    }
  }

  // Mettre à jour le numéro de téléphone de l'utilisateur
  Future<void> updateUserPhoneNumber(String phone) async {
    try {
      setLoading(true);
      await _db.updateUserPhoneInFirebase(phone);

      // Recharger le profil utilisateur
      String? uid = _auth.getCurrentUid();
        await loadUserProfile(uid);
    } catch (e) {
      print(e);
    } finally {
      setLoading(false);
    }
  }

  }