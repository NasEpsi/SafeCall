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

import 'dart:async';
import 'native_bridge.dart';
import 'package:flutter/foundation.dart';

import '../../models/report.dart';
import '../../models/user.dart';
import '../auth/auth_service.dart';
import 'database_service.dart';
import 'local_database.dart';

class DatabaseProvider extends ChangeNotifier {

  // get database and auth
  final _auth = AuthService();
  final _db = DatabaseService();
  final _localDb = LocalDatabase();




  // locale variables
  UserProfile? _currentUser;
  List<Map<String, dynamic>> _blockedNumbers = [];
  List<Map<String, dynamic>> _blockedPrefixes = [];
  List<Map<String, dynamic>> _userReports = [];
  bool _isLoading = false;
  Timer? _syncTimer;


  // Getters
  UserProfile? get currentUser => _currentUser;
  List<Map<String, dynamic>> get blockedNumbers => _blockedNumbers;
  List<Map<String, dynamic>> get blockedPrefixes => _blockedPrefixes;
  List<Map<String, dynamic>> get userReports => _userReports;
  bool get isLoading => _isLoading;

  // Constructor with initialization
  DatabaseProvider() {
    // Setup periodic sync with Firebase (every 30 seconds)
    _syncTimer = Timer.periodic(Duration(seconds: 30), (_) => syncWithFirebase());
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  // Initialize user data  first from local DB, then update from Firebase
  Future<void> initUserData() async {
    setLoading(true);

    try {
      String? uid = _auth.getCurrentUid();

        // First load from local database for immediate UI update
        await _loadUserFromLocal(uid);

        // Load reports
        await loadUserReports();

        // Then update from Firebase in background
        _loadUserFromFirebase(uid);

    } catch (e) {
      print(e);
    } finally {
      setLoading(false);
    }
  }

  // Load user from local database
  Future<void> _loadUserFromLocal(String uid) async {
    try {
      // Get user profile from local DB
      UserProfile? user = await _localDb.getUser(uid);

      if (user != null) {
        _currentUser = user;

        // Load blocked numbers and prefixes from local DB
        _blockedNumbers = await _localDb.getBlockedNumbers(uid);
        _blockedPrefixes = await _localDb.getBlockedPrefixes(uid);

        notifyListeners();
      }
    } catch (e) {
      print(e);
    }
  }

  // Load user from Firebase and update local DB
  Future<void> _loadUserFromFirebase(String uid) async {
    try {
      // Get user profile from Firebase
      UserProfile? user = await _db.getUserFromFirebase(uid);

      if (user != null) {
        // Update local database with Firebase data
        await _localDb.insertUser(user);

        // Get blocked numbers and prefixes from Firebase
        List<Map<String, dynamic>> firebaseBlockedNumbers = await _db.getBlockedNumbersInFirebase();
        List<Map<String, dynamic>> firebasePrefixes = await _db.getBlockedPrefixesInFirebase();

        // Update local database with Firebase data
        for (var number in firebaseBlockedNumbers) {
          await _localDb.insertBlockedNumber(
            number['id'],
            number['number'],
            number['number'].length > 4 ? number['number'].substring(0, 4) : number['number'],
            number['is_spam'] ?? false,
          );
          await _localDb.associateNumberWithUser(uid, number['id']);

          if (number['reason'] != null && number['reason'].isNotEmpty) {
            String reportId = 'firebase_report_${number['id']}_${DateTime.now().millisecondsSinceEpoch}';
            await _localDb.insertReport(
              reportId,
              number['id'],
              uid,
              number['reason'],
              number['report_date'] ?? DateTime.now(),
            );
          }
        }

        for (var prefix in firebasePrefixes) {
          await _localDb.insertBlockedPrefix(prefix['id'], prefix['prefix']);
          await _localDb.associatePrefixWithUser(uid, prefix['id']);
        }

        // Reload from local DB to update UI with newest data
        await _loadUserFromLocal(uid);
        await loadBlockedNumbers();
        await loadBlockedPrefixes();
        await loadUserReports();

      }
    } catch (e) {
      print(e);
    }
  }

  // Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Update user phone number
  Future<void> updateUserPhoneNumber(String phone) async {
    try {
      setLoading(true);
      String? uid = _auth.getCurrentUid();

      // Update local database immediately
      await _localDb.updateUserPhone(uid, phone);

      // Reload user from local DB
      await _loadUserFromLocal(uid);

      // Schedule sync with Firebase
      _syncUserDataWithFirebase();

    } catch (e) {
      print(e);
    } finally {
      setLoading(false);
    }
  }

  /*
   * Blocked numbers management
   */

  // Load blocked numbers from local database
  Future<void> loadBlockedNumbers() async {
    try {
      String? uid = _auth.getCurrentUid();
        _blockedNumbers = await _localDb.getBlockedNumbers(uid);
        notifyListeners();
      await _syncWithNative();
    } catch (e) {
      print(e);
    }
  }

  // Add blocked number
  Future<bool> addBlockedNumber(String number, String selectedReason) async {
    try {
      setLoading(true);
      String? uid = _auth.getCurrentUid();

        // Add to local database immediately
        await _localDb.addNewBlockedNumber(uid, number, selectedReason);

        // Reload numbers from local DB
        await loadBlockedNumbers();

        // Also reload reports
        await loadUserReports();

        // Schedule sync with Firebase
        _syncNumbersWithFirebase();
        _syncReportsWithFirebase();

      await _syncWithNative();


      return true;
    } catch (e) {
      print(e);
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Remove blocked number
  Future<bool> removeBlockedNumber(String numberId) async {
    try {
      setLoading(true);
      String? uid = _auth.getCurrentUid();

        // Remove from local database immediately
        await _localDb.removeBlockedNumber(uid, numberId);

        // Reload numbers from local DB
        await loadBlockedNumbers();

        await loadUserReports();

        // Schedule sync with Firebase
        _syncNumbersWithFirebase();
        _syncReportsWithFirebase();
      await _syncWithNative();


      return true;
    } catch (e) {
      print(e);
      return false;
    } finally {
      setLoading(false);
    }
  }

  /*
   * Blocked prefixes management
   */

  // Load blocked prefixes from local database
  Future<void> loadBlockedPrefixes() async {
    try {
      String? uid = _auth.getCurrentUid();
        _blockedPrefixes = await _localDb.getBlockedPrefixes(uid);
        notifyListeners();
      await _syncWithNative();

    } catch (e) {
      print(e);
    }
  }

  // Add blocked prefix
  Future<bool> addBlockedPrefix(String prefix) async {
    try {
      setLoading(true);
      String? uid = _auth.getCurrentUid();

        // Add to local database immediately
        await _localDb.addNewBlockedPrefix(uid, prefix);

        // Reload prefixes from local DB
        await loadBlockedPrefixes();

        // Schedule sync with Firebase
        _syncPrefixesWithFirebase();

      await _syncWithNative();



      return true;
    } catch (e) {
      print(e);
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Remove blocked prefix
  Future<bool> removeBlockedPrefix(String prefixId) async {
    try {
      setLoading(true);
      String? uid = _auth.getCurrentUid();

      // Remove from local database immediately
      await _localDb.removeBlockedPrefix(uid, prefixId);

      // Reload prefixes from local DB
      await loadBlockedPrefixes();

      // Schedule sync with Firebase
      _syncPrefixesWithFirebase();

      return true;
    } catch (e) {
      print(e);
      return false;
    } finally {
      setLoading(false);
    }
  }

  /*
  * Reports
  * */

  /*
   * Reports management
   */

  // Load user reports from local database
  Future<void> loadUserReports() async {
    try {
      String? uid = _auth.getCurrentUid();
      _userReports = await _localDb.getUserReports(uid);
      notifyListeners();
    } catch (e) {
      print(e);
    }
  }

  // Get block reason for a specific number
  String getBlockReasonForNumber(String numberId) {
    try {
      // Find report for this number
      final report = _userReports.firstWhere(
              (report) => report['number_id'] == numberId,
          orElse: () => {'reason': 'Unknown'}
      );
      return report['reason'];
    } catch (e) {
      return 'Unknown';
    }
  }


  // Add a report for an existing blocked number
  Future<bool> addReport(String numberId, String reason) async {
    try {
      setLoading(true);
      String? uid = _auth.getCurrentUid();

      // Create report ID
      String reportId = 'local_report_${DateTime.now().millisecondsSinceEpoch}';

      // Create report
      await _localDb.insertReport(
          reportId,
          numberId,
          uid,
          reason,
          DateTime.now()
      );

      // Reload reports for UI
      await loadUserReports();

      // Schedule sync with Firebase
      _syncReportsWithFirebase();

      return true;
    } catch (e) {
      print(e);
      return false;
    } finally {
      setLoading(false);
    }
  }

  // Get all blocked items with their reasons for the blocked page
  List<Map<String, dynamic>> getBlockedItemsWithReasons() {
    List<Map<String, dynamic>> result = [];

    // Add blocked numbers with reasons
    for (var number in _blockedNumbers) {
      result.add({
        'id': number['id'],
        'value': number['number'],
        'type': 'number',
        'reason': number['reason'] ?? getBlockReasonForNumber(number['id']),
        'is_spam': number['is_spam'] ?? false
      });
    }
    return result;
  }

  /*
   * Firebase synchronization
   */

  // Sync user data with Firebase
  Future<void> _syncUserDataWithFirebase() async {
    try {
      // Get pending user updates
      List<Map<String, dynamic>> pendingUpdates = await _localDb.getPendingUserUpdates();

      for (var update in pendingUpdates) {
        await _db.updateUserPhoneInFirebase(update['number_user']);
        await _localDb.markUserSynced(update['uid']);
      }
    } catch (e) {
      print(e);
    }
  }

  // Sync numbers with Firebase
  Future<void> _syncNumbersWithFirebase() async {
    try {
      String? uid = _auth.getCurrentUid();

      // Process pending number additions
      List<Map<String, dynamic>> pendingNumberUpdates = await _localDb.getPendingNumberUpdates();
      List<Map<String, dynamic>> pendingNumberRelations = await _localDb.getPendingNumberRelationUpdates();

      // Add new numbers to Firebase
      for (var number in pendingNumberUpdates) {
        // For new local numbers, find their associated report reason
        String reason = 'Unknown';
        final reports = await _localDb.getUserReports(uid);
        final relatedReports = reports.where((report) => report['number_id'] == number['id']).toList();
        if (relatedReports.isNotEmpty) {
          reason = relatedReports[0]['reason'];
        }

        // If it's a local ID, add it to Firebase
        if (number['id'].toString().startsWith('local_')) {
          bool success = await _db.addBlockedNumberInFirebase(number['number'], reason);
          if (success) {
            // Mark as synced for now - in a production app we'd need to handle ID mapping
            await _localDb.markNumberSynced(number['id']);
          }
        }
      }

      // Process existing number relations
      for (var relation in pendingNumberRelations) {
        await _localDb.markNumberRelationSynced(relation['user_id'], relation['number_id']);
      }

      // Process deleted numbers
      List<Map<String, dynamic>> pendingDeletions = await _localDb.getPendingNumberDeletions();
      for (var deletion in pendingDeletions) {
        await _db.removeBlockedNumberInFirebase(deletion['number_id']);
      }

      // Clean up after successful sync
      await _localDb.cleanupDeletedRelations();
    } catch (e) {
      print(e);
    }
  }

  // Sync prefixes with Firebase
  Future<void> _syncPrefixesWithFirebase() async {
    try {
      String? uid = _auth.getCurrentUid();
      if (uid == null) return;

      // Process pending prefix additions
      List<Map<String, dynamic>> pendingPrefixUpdates = await _localDb.getPendingPrefixUpdates();
      List<Map<String, dynamic>> pendingPrefixRelations = await _localDb.getPendingPrefixRelationUpdates();

      // Add new prefixes to Firebase
      for (var prefix in pendingPrefixUpdates) {
        // If it's a local ID, we need to add it to Firebase and update the ID
        if (prefix['id'].toString().startsWith('local_')) {
          bool success = await _db.addBlockedPrefixInFirebase(prefix['prefix']);
          if (success) {
            // Get the new ID from Firebase
            List<Map<String, dynamic>> firebasePrefixes = await _db.getBlockedPrefixesInFirebase();
            for (var fbPrefix in firebasePrefixes) {
              if (fbPrefix['prefix'] == prefix['prefix']) {
                // Update local ID with Firebase ID
                // TODO
                await _localDb.markPrefixSynced(prefix['id']);
                break;
              }
            }
          }
        }
      }

      // Process existing prefix relations
      for (var relation in pendingPrefixRelations) {
        await _localDb.markPrefixRelationSynced(relation['user_id'], relation['prefix_id']);
      }

      // Process deleted prefixes
      List<Map<String, dynamic>> pendingDeletions = await _localDb.getPendingPrefixDeletions();
      for (var deletion in pendingDeletions) {
        await _db.removeBlockedPrefixInFirebase(deletion['prefix_id']);
      }

      // Clean up after successful sync
      await _localDb.cleanupDeletedRelations();
    } catch (e) {
      print(e);
    }
  }

  // Sync reports with Firebase
  Future<void> _syncReportsWithFirebase() async {
    try {
      // Get pending report updates
      List<Map<String, dynamic>> pendingReports = await _localDb.getPendingReportUpdates();

      // Add new reports to Firebase
      for (var report in pendingReports) {
        // récupérer le numéro de téléphone depuis la base de données locale
        String? phoneNumber = await _getPhoneNumberFromReport(report['number_id']);

        if (phoneNumber != null) {
          // Add to Firebase avec les bons paramètres
          bool success = await _db.addReportToFirebase(phoneNumber, report['reason']);
          if (success) {
            await _localDb.markReportSynced(report['id']);
          }
        }
      }

      // Process deleted reports (if needed)
      List<Map<String, dynamic>> pendingDeletions = await _localDb.getPendingReportDeletions();
      for (var deletion in pendingDeletions) {
        // await _db.removeReportFromFirebase(deletion['id']);
      }

      // Clean up after successful sync
      await _localDb.cleanupDeletedRelations();
    } catch (e) {
      print(e);
    }
  }

// Méthode helper pour récupérer le numéro de téléphone à partir du number_id
  Future<String?> _getPhoneNumberFromReport(String numberId) async {
    try {
      String? uid = _auth.getCurrentUid();
      if (uid == null) return null;

      // Récupérer tous les numéros bloqués pour trouver celui correspondant
      List<Map<String, dynamic>> blockedNumbers = await _localDb.getBlockedNumbers(uid);

      for (var number in blockedNumbers) {
        if (number['id'] == numberId) {
          return number['number'];
        }
      }

      return null;
    } catch (e) {
      print(e);
      return null;
    }
  }

  // Sync everything with Firebase (called periodically)
  Future<void> syncWithFirebase() async {
    try {
      await _syncUserDataWithFirebase();
      await _syncNumbersWithFirebase();
      await _syncPrefixesWithFirebase();
      await _syncReportsWithFirebase();
    } catch (e) {
      print(e);
    }
  }

  Future<void> _syncWithNative() async {
    try {
      // Extraire les numéros de téléphone des données bloquées
      List<String> numbers = _blockedNumbers
          .map((item) => item['number']?.toString() ?? '')
          .where((number) => number.isNotEmpty)
          .toList();

      // Extraire les préfixes
      List<String> prefixes = _blockedPrefixes
          .map((item) => item['prefix']?.toString() ?? '')
          .where((prefix) => prefix.isNotEmpty)
          .toList();

      // Synchroniser avec le côté natif
      await NativeBridge.updateBlockedNumbers(numbers);
      await NativeBridge.updateBlockedPrefixes(prefixes);

      print(
          'Synchronisation native réussie: ${numbers.length} numéros, ${prefixes
              .length} préfixes');
    } catch (e) {
      print('Erreur lors de la synchronisation native: $e');
    }
  }
}