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
import '../../helper/numbers_format.dart';
import '../../models/user.dart';
import '../../models/report.dart';
import 'local_database.dart';

class DatabaseService {
  // get an instance of Firestore
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _localDb = LocalDatabase();

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

    // saving in sqlite database
    await _localDb.insertUser(user);
  }

  // update users number
  Future<void> updateUserPhoneInFirebase(String numberUser) async {
    // gets uid
    String? uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception("Utilisateur non connecté");
    }

    // update in firebase
    try {
      await _db
          .collection("Users")
          .doc(uid)
          .update({"number_user": numberUser});

      // Update in local database
      await _localDb.updateUserPhone(uid, numberUser);

      // Mark as synced
      await _localDb.markUserSynced(uid);

    } catch (e) {
      throw Exception("Erreur lors de la mise à jour du numéro");
    }
  }

  // Get user Data
  Future<UserProfile?> getUserFromFirebase(String uid) async {
    try {
      // First check local database for fast response
      UserProfile? localUser = await _localDb.getUser(uid);
      if (localUser != null) {
        return localUser;
      }

      DocumentSnapshot userDoc = await _db.collection("Users").doc(uid).get();
      return UserProfile.fromDocument(userDoc);
    } catch (e) {
      print(e);
      return null;
    }
  }

  /*
  * Blocked NUMBERS
  */

  // Add number into the blocked number list with a reason
  Future<bool> addBlockedNumberInFirebase(String number, String reason) async {
    try {
      String? uid = _auth.currentUser?.uid;
      if (uid == null) return false;

      //
      String normalized = normalizePhoneNumber(number);
      if (!isValidFrenchMobile(normalized)) {
        throw Exception("Numéro de téléphone non valide");
      }

      // verify if the number is in the Numbers collection
      QuerySnapshot numberQuery = await _db
          .collection("Numbers")
          .where('number', isEqualTo: normalized)
          .limit(1)
          .get();

      String numberId;

      if (numberQuery.docs.isEmpty) {
        // Create a new number if Numbers empty
        DocumentReference newNumberRef = await _db.collection("Numbers").add({
          'number': normalized,
          'prefix': normalized.substring(0,3),
          'is_spam': false
        });
        numberId = newNumberRef.id;
      } else {
        numberId = numberQuery.docs.first.id;
      }

      // Add id number to list of blocked numbers of user
      await _db.collection("Users").doc(uid).update({
        'numbers_blocked': FieldValue.arrayUnion([numberId])
      });

      // Create report in Firebase
      String reportId = 'fb_report_${DateTime.now().millisecondsSinceEpoch}';
      Report report = Report(
        id: reportId,
        numberId: numberId,
        userId: uid,
        reason: reason,
        reportDate: DateTime.now(),
      );

      // Save report to Firestore
      await _db.collection("Reports").doc(reportId).set(report.toMap());

      // Update local database
      await _localDb.insertBlockedNumber(
          numberId,
          normalized,
          normalized.substring(0,3),
          false
      );
      await _localDb.associateNumberWithUser(uid, numberId);
      await _localDb.insertReport(
          reportId,
          numberId,
          uid,
          reason,
          DateTime.now()
      );

      // Mark local entries as synced
      await _localDb.markNumberSynced(numberId);
      await _localDb.markNumberRelationSynced(uid, numberId);
      await _localDb.markReportSynced(reportId);

      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  // remove a number from the blocked number list
  Future<bool> removeBlockedNumberInFirebase(String numberId) async {
    try {
      String? uid = _auth.currentUser?.uid;
      if (uid == null) return false;

      await _db.collection("Users").doc(uid).update({
        'numbers_blocked': FieldValue.arrayRemove([numberId])
      });

      // Remove from local database
      await _localDb.removeBlockedNumber(uid, numberId);

      // Also attempt to find and delete any reports
      QuerySnapshot reportQuery = await _db
          .collection("Reports")
          .where('number_id', isEqualTo: numberId)
          .where('user_id', isEqualTo: uid)
          .get();

      for (var doc in reportQuery.docs) {
        await _db.collection("Reports").doc(doc.id).delete();
      }

      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  // get all blocked numbers of User with their reasons
  Future<List<Map<String, dynamic>>> getBlockedNumbersInFirebase() async {
    try {
      String? uid = _auth.currentUser?.uid;
      if (uid == null) return [];

      // First try to get from local database for fast response
      List<Map<String, dynamic>> localNumbers = await _localDb.getBlockedNumbers(uid);
      if (localNumbers.isNotEmpty) {
        return localNumbers;
      }

      UserProfile? user = await getUserFromFirebase(uid);
      if (user == null) return [];

      List<Map<String, dynamic>> blockedNumbers = [];

      for (String numberId in user.numbersBlocked) {
        DocumentSnapshot numberDoc = await _db.collection("Numbers").doc(numberId).get();

        if (numberDoc.exists) {
          final rawNumber = numberDoc['number'];
          final normalizedNumber = normalizePhoneNumber(rawNumber);

          // Get report for this number if exists
          QuerySnapshot reportQuery = await _db
              .collection("Reports")
              .where('number_id', isEqualTo: numberId)
              .where('user_id', isEqualTo: uid)
              .limit(1)
              .get();

          String reason = "";
          DateTime? reportDate;
          String? reportId;

          if (reportQuery.docs.isNotEmpty) {
            reason = reportQuery.docs.first['reason'];
            reportDate = (reportQuery.docs.first['report_date'] as Timestamp).toDate();
            reportId = reportQuery.docs.first.id;
          }

          Map<String, dynamic> numberData = {
            'id': numberDoc.id,
            'number': normalizedNumber,
            'is_spam': numberDoc['is_spam'] ?? false,
            'reason': reason,
            'report_date': reportDate,
          };
          blockedNumbers.add(numberData);

          // Save to local database
          await _localDb.insertBlockedNumber(
              numberDoc.id,
              normalizedNumber,
              normalizedNumber.substring(0,3),
              numberDoc['is_spam'] ?? false
          );
          await _localDb.associateNumberWithUser(uid, numberDoc.id);

          // Save report if exists
          if (reportId != null) {
            await _localDb.insertReport(
              reportId,
              numberId,
              uid,
              reason,
              reportDate!,
            );
          }
        }
      }

      return blockedNumbers;
    } catch (e) {
      print(e);
      return [];
    }
  }

  // Update reason for blocked number
  Future<bool> updateBlockedNumberReason(String numberId, String newReason) async {
    try {
      String? uid = _auth.currentUser?.uid;
      if (uid == null) return false;



      // Check if a report exists for this number
      QuerySnapshot reportQuery = await _db
          .collection("Reports")
          .where('number_id', isEqualTo: numberId)
          .where('user_id', isEqualTo: uid)
          .limit(1)
          .get();

      if (reportQuery.docs.isNotEmpty) {
        // Update existing report
        String reportId = reportQuery.docs.first.id;
        await _db.collection("Reports").doc(reportId).update({
          'reason': newReason,
          'report_date': FieldValue.serverTimestamp()
        });

        // Update local database
        Report report = Report(
          id: reportId,
          numberId: numberId,
          userId: uid,
          reason: newReason,
          reportDate: DateTime.now(),
        );

      } else {
        // Create new report
        String reportId = 'fb_report_${DateTime.now().millisecondsSinceEpoch}';
        Report report = Report(
          id: reportId,
          numberId: numberId,
          userId: uid,
          reason: newReason,
          reportDate: DateTime.now(),
        );
        await _db.collection("Reports").doc(reportId).set(report.toMap());
      }

      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  /*
  * Blocked Prefixes
  */

  // add prefixe to the list of blocked prefixes
  Future<bool> addBlockedPrefixInFirebase(String prefixe) async {
    try {
      String? uid = _auth.currentUser?.uid;
      if (uid == null) return false;

      // Verify if prefixe already is in the database collection
      QuerySnapshot prefixeQuery = await _db
          .collection("Prefix")
          .where('prefix', isEqualTo: prefixe)
          .limit(1)
          .get();

      String prefixeId;

      if (prefixeQuery.docs.isEmpty) {
        // New prefixe
        DocumentReference newPrefixeRef = await _db
            .collection("Prefix")
            .add({'prefix': prefixe});
        prefixeId = newPrefixeRef.id;
      } else {
        prefixeId = prefixeQuery.docs.first.id;
      }

      //Adding prefixes id to the blocked list
      await _db.collection("Users").doc(uid).update({
        'prefixes_blocked': FieldValue.arrayUnion([prefixeId])
      });

      // Also update local database
      await _localDb.insertBlockedPrefix(prefixeId, prefixe);
      await _localDb.associatePrefixWithUser(uid, prefixeId);

      // Mark as synced
      await _localDb.markPrefixSynced(prefixeId);
      await _localDb.markPrefixRelationSynced(uid, prefixeId);

      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  // Removing prefixes from list
  Future<bool> removeBlockedPrefixInFirebase(String prefixeId) async {
    try {
      String? uid = _auth.currentUser?.uid;
      if (uid == null) return false;

      await _db.collection("Users").doc(uid).update({
        'prefixes_blocked': FieldValue.arrayRemove([prefixeId])
      });

      // Remove from local database
      await _localDb.removeBlockedPrefix(uid, prefixeId);

      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  // Get all blocked prefixes
  Future<List<Map<String, dynamic>>> getBlockedPrefixesInFirebase() async {
    try {
      String? uid = _auth.currentUser?.uid;
      if (uid == null) return [];

      // First try to get from local database for fast response
      List<Map<String, dynamic>> localPrefixes = await _localDb.getBlockedPrefixes(uid);
      if (localPrefixes.isNotEmpty) {
        return localPrefixes;
      }

      UserProfile? user = await getUserFromFirebase(uid);
      if (user == null) return [];

      List<Map<String, dynamic>> blockedPrefixes = [];

      for (String prefixeId in user.prefixesBlocked) {
        DocumentSnapshot prefixeDoc = await _db.collection("Prefix").doc(prefixeId).get();
        if (prefixeDoc.exists) {
          Map<String, dynamic> prefixData = {
            'id': prefixeDoc.id,
            'prefix': prefixeDoc['prefix'],
          };

          blockedPrefixes.add(prefixData);

          // Save to local database
          await _localDb.insertBlockedPrefix(prefixeDoc.id, prefixeDoc['prefix']);
          await _localDb.associatePrefixWithUser(uid, prefixeId);
        }
      }

      return blockedPrefixes;
    } catch (e) {
      print(e);
      return [];
    }
  }

  Future<List<Object>> getReports() async {
    try {
      String? uid = _auth.currentUser?.uid;
      if (uid == null) return [];

      final reports = await _localDb.getUserReports(uid);
      return reports;
    } catch (e) {
      print(e);
      return [];
    }
  }


  Future<bool> addReportToFirebase(String number, String reason) async {
    try {
      String? uid = _auth.currentUser?.uid;
      if (uid == null) return false;

      String normalized = normalizePhoneNumber(number);
      if (!isValidFrenchMobile(normalized)) {
        throw Exception("Numéro de téléphone non valide");
      }

      QuerySnapshot numberQuery = await _db
          .collection("Numbers")
          .where('number', isEqualTo: normalized)
          .limit(1)
          .get();

      String numberId;
      if (numberQuery.docs.isEmpty) {
        DocumentReference newNumberRef = await _db.collection("Numbers").add({
          'number': normalized,
          'prefix': normalized.substring(0,3),
          'is_spam': false
        });
        numberId = newNumberRef.id;
      } else {
        numberId = numberQuery.docs.first.id;
      }

      // Firestore ID
      final newReportRef = _db.collection("Reports").doc();

      final report = Report(
        id: newReportRef.id,
        numberId: numberId,
        userId: uid,
        reason: reason,
        reportDate: DateTime.now(),
      );

      // Save local
      await _localDb.insertReport(
        report.id!,
        report.numberId,
        report.userId,
        report.reason,
        report.reportDate,
      );

      // Sync to Firebase
      await newReportRef.set(report.toMap());

      // Mark as sync
      await _localDb.markReportSynced(report.id!);

      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  // remove report

  // Initial data synchronization between Firebase and local SQLite
  Future<void> syncInitialData() async {
    try {
      String? uid = _auth.currentUser?.uid;
      if (uid == null) return;

      // Sync user profile
      UserProfile? user = await getUserFromFirebase(uid);
      if (user != null) {
        await _localDb.insertUser(user);
      }

      // Sync blocked numbers and their reports
      await getBlockedNumbersInFirebase();

      // Sync blocked prefixes
      await getBlockedPrefixesInFirebase();
    } catch (e) {
      print(e);
    }
  }
}