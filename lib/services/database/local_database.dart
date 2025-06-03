/*
*
*  Updated SQLite local database
*
* Added report handling for blocked numbers
*
*/

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/user.dart';


class LocalDatabase {
  static final LocalDatabase _instance = LocalDatabase._internal();
  static Database? _database;

  factory LocalDatabase() => _instance;

  LocalDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // TODO Allowing the user to delete the data from the app

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'block_app.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (Database db, int version) async {
        // Create users table
        await db.execute('''
          CREATE TABLE users (
            uid TEXT PRIMARY KEY,
            email TEXT NOT NULL,
            number_user TEXT,
            provider TEXT,
            sync_status INTEGER DEFAULT 0
          )
        ''');

        // Create blocked numbers table
        await db.execute('''
          CREATE TABLE blocked_numbers (
            id TEXT PRIMARY KEY,
            number TEXT NOT NULL,
            prefix TEXT NOT NULL,
            is_spam INTEGER DEFAULT 0,
            sync_status INTEGER DEFAULT 0
          )
        ''');

        // Create blocked prefixes table
        await db.execute('''
          CREATE TABLE blocked_prefixes (
            id TEXT PRIMARY KEY,
            prefix TEXT NOT NULL,
            sync_status INTEGER DEFAULT 0
          )
        ''');

        // Create user_blocked_numbers relation table
        await db.execute('''
          CREATE TABLE user_blocked_numbers (
            user_id TEXT,
            number_id TEXT,
            sync_status INTEGER DEFAULT 0,
            PRIMARY KEY (user_id, number_id),
            FOREIGN KEY (user_id) REFERENCES users (uid),
            FOREIGN KEY (number_id) REFERENCES blocked_numbers (id)
          )
        ''');

        // Create user_blocked_prefixes relation table
        await db.execute('''
          CREATE TABLE user_blocked_prefixes (
            user_id TEXT,
            prefix_id TEXT,
            sync_status INTEGER DEFAULT 0,
            PRIMARY KEY (user_id, prefix_id),
            FOREIGN KEY (user_id) REFERENCES users (uid),
            FOREIGN KEY (prefix_id) REFERENCES blocked_prefixes (id)
          )
        ''');

        // Create reports table
        await db.execute('''
          CREATE TABLE reports (
            id TEXT PRIMARY KEY,
            number_id TEXT NOT NULL,
            user_id TEXT NOT NULL,
            reason TEXT NOT NULL,
            report_date INTEGER NOT NULL,
            sync_status INTEGER DEFAULT 0,
            FOREIGN KEY (number_id) REFERENCES blocked_numbers (id),
            FOREIGN KEY (user_id) REFERENCES users (uid)
          )
        ''');
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          // Add reports table if upgrading from version 1
          await db.execute('''
            CREATE TABLE reports (
              id TEXT PRIMARY KEY,
              number_id TEXT NOT NULL,
              user_id TEXT NOT NULL,
              reason TEXT NOT NULL,
              report_date INTEGER NOT NULL,
              sync_status INTEGER DEFAULT 0,
              FOREIGN KEY (number_id) REFERENCES blocked_numbers (id),
              FOREIGN KEY (user_id) REFERENCES users (uid)
            )
          ''');
        }
      },
    );
  }

  // User operations
  Future<void> insertUser(UserProfile user) async {
    final db = await database;
    await db.insert(
      'users',
      {
        'uid': user.uid,
        'email': user.email,
        'number_user': user.numberUser,
        'provider': user.provider,
        'sync_status': 1, // 1 means synced with Firestore
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateUserPhone(String uid, String phone) async {
    final db = await database;
    await db.update(
      'users',
      {'number_user': phone, 'sync_status': 0},
      where: 'uid = ?',
      whereArgs: [uid],
    );
  }

  Future<UserProfile?> getUser(String uid) async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'uid = ?',
      whereArgs: [uid],
    );

    if (maps.isEmpty) {
      return null;
    }

    List<String> blockedNumbers = await getUserBlockedNumberIds(uid);
    List<String> blockedPrefixes = await getUserBlockedPrefixIds(uid);

    return UserProfile(
      uid: maps[0]['uid'],
      email: maps[0]['email'],
      numberUser: maps[0]['number_user'] ?? '',
      provider: maps[0]['provider'] ?? 'email',
      numbersBlocked: blockedNumbers,
      prefixesBlocked: blockedPrefixes,
    );
  }

  // Blocked numbers operations
  Future<void> insertBlockedNumber(String numberId, String number, String prefix, bool isSpam) async {
    final db = await database;
    await db.insert(
      'blocked_numbers',
      {
        'id': numberId,
        'number': number,
        'prefix': prefix,
        'is_spam': isSpam ? 1 : 0,
        'sync_status': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String> addNewBlockedNumber(String userId, String number, String reason) async {
    final db = await database;

    // Generate a unique ID for the number
    String numberId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    String prefix = number.length > 4 ? number.substring(0, 4) : number;

    // Insert the new number
    await db.insert(
      'blocked_numbers',
      {
        'id': numberId,
        'number': number,
        'prefix': prefix,
        'is_spam': reason.toLowerCase() == 'spam' ? 1 : 0,
        'sync_status': 0, // 0 means not yet synced with Firestore
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Associate the number with the user
    await db.insert(
      'user_blocked_numbers',
      {
        'user_id': userId,
        'number_id': numberId,
        'sync_status': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Create a report for this blocked number
    await insertReport(
        'local_report_${DateTime.now().millisecondsSinceEpoch}',
        numberId,
        userId,
        reason,
        DateTime.now()
    );

    return numberId;
  }

  Future<void> associateNumberWithUser(String userId, String numberId) async {
    final db = await database;
    await db.insert(
      'user_blocked_numbers',
      {
        'user_id': userId,
        'number_id': numberId,
        'sync_status': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeBlockedNumber(String userId, String numberId) async {
    final db = await database;
    await db.delete(
      'user_blocked_numbers',
      where: 'user_id = ? AND number_id = ?',
      whereArgs: [userId, numberId],
    );

    // Mark the relation as needing sync
    await db.insert(
      'user_blocked_numbers',
      {
        'user_id': userId,
        'number_id': numberId,
        'sync_status': -1, // -1 means needs to be removed from Firebase
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Also mark any reports for this number-user combination as deleted
    await db.update(
      'reports',
      {'sync_status': -1},
      where: 'user_id = ? AND number_id = ?',
      whereArgs: [userId, numberId],
    );
  }

  Future<List<Map<String, dynamic>>> getBlockedNumbers(String userId) async {
    final db = await database;

    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT bn.id, bn.number, bn.is_spam, r.reason
      FROM blocked_numbers bn
      INNER JOIN user_blocked_numbers ubn ON bn.id = ubn.number_id
      LEFT JOIN reports r ON bn.id = r.number_id AND r.user_id = ?
      WHERE ubn.user_id = ? AND ubn.sync_status >= 0
    ''', [userId, userId]);

    return results;
  }

  Future<List<String>> getUserBlockedNumberIds(String userId) async {
    final db = await database;

    final List<Map<String, dynamic>> results = await db.query(
      'user_blocked_numbers',
      columns: ['number_id'],
      where: 'user_id = ? AND sync_status >= 0',
      whereArgs: [userId],
    );

    return results.map((row) => row['number_id'] as String).toList();
  }

  // Blocked prefixes operations
  Future<void> insertBlockedPrefix(String prefixId, String prefix) async {
    final db = await database;
    await db.insert(
      'blocked_prefixes',
      {
        'id': prefixId,
        'prefix': prefix,
        'sync_status': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String> addNewBlockedPrefix(String userId, String prefix) async {
    final db = await database;

    // Generate a unique ID for the prefix (you'll replace this with Firebase ID later)
    String prefixId = 'local_${DateTime.now().millisecondsSinceEpoch}';

    // Insert the new prefix
    await db.insert(
      'blocked_prefixes',
      {
        'id': prefixId,
        'prefix': prefix,
        'sync_status': 0, // 0 means not yet synced with Firestore
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Associate the prefix with the user
    await db.insert(
      'user_blocked_prefixes',
      {
        'user_id': userId,
        'prefix_id': prefixId,
        'sync_status': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Create a virtual number for reporting purposes
    String numberId = 'prefix_${prefix}_${DateTime.now().millisecondsSinceEpoch}';
    await db.insert(
      'blocked_numbers',
      {
        'id': numberId,
        'number': 'PREFIX:${prefix}',
        'prefix': prefix,
        'sync_status': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return prefixId;
  }

  Future<void> associatePrefixWithUser(String userId, String prefixId) async {
    final db = await database;
    await db.insert(
      'user_blocked_prefixes',
      {
        'user_id': userId,
        'prefix_id': prefixId,
        'sync_status': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeBlockedPrefix(String userId, String prefixId) async {
    final db = await database;
    await db.delete(
      'user_blocked_prefixes',
      where: 'user_id = ? AND prefix_id = ?',
      whereArgs: [userId, prefixId],
    );

    // Mark the relation as needing sync (deleted)
    await db.insert(
      'user_blocked_prefixes',
      {
        'user_id': userId,
        'prefix_id': prefixId,
        'sync_status': -1, // -1 means needs to be removed from Firebase
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getBlockedPrefixes(String userId) async {
    final db = await database;

    return await db.rawQuery('''      SELECT bp.id, bp.prefix
      FROM blocked_prefixes bp
      INNER JOIN user_blocked_prefixes ubp ON bp.id = ubp.prefix_id
      WHERE ubp.user_id = ? AND ubp.sync_status >= 0
    ''', [userId]);
  }

  Future<List<String>> getUserBlockedPrefixIds(String userId) async {
    final db = await database;

    final List<Map<String, dynamic>> results = await db.query(
      'user_blocked_prefixes',
      columns: ['prefix_id'],
      where: 'user_id = ? AND sync_status >= 0',
      whereArgs: [userId],
    );

    return results.map((row) => row['prefix_id'] as String).toList();
  }

  // Report operations
  Future<void> insertReport(String reportId, String numberId, String userId, String reason, DateTime reportDate) async {
    final db = await database;
    await db.insert(
      'reports',
      {
        'id': reportId,
        'number_id': numberId,
        'user_id': userId,
        'reason': reason,
        'report_date': reportDate.millisecondsSinceEpoch,
        'sync_status': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getUserReports(String userId) async {
    final db = await database;

    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT r.id, r.number_id, r.reason, r.report_date, bn.number
      FROM reports r
      INNER JOIN blocked_numbers bn ON r.number_id = bn.id
      WHERE r.user_id = ? AND r.sync_status >= 0
      ORDER BY r.report_date DESC
    ''', [userId]);

    return results.map((row) {
      return {
        'id': row['id'],
        'number_id': row['number_id'],
        'reason': row['reason'],
        'number': row['number'],
        'report_date': DateTime.fromMillisecondsSinceEpoch(row['report_date'] as int),
      };
    }).toList();
  }

  Future<void> markReportSynced(String reportId) async {
    final db = await database;
    await db.update(
      'reports',
      {'sync_status': 1},
      where: 'id = ?',
      whereArgs: [reportId],
    );
  }

  Future<List<Map<String, dynamic>>> getPendingReportUpdates() async {
    final db = await database;

    final List<Map<String, dynamic>> results = await db.query(
      'reports',
      where: 'sync_status = ?',
      whereArgs: [0],
    );

    return results.map((row) {
      return {
        'id': row['id'],
        'number_id': row['number_id'],
        'user_id': row['user_id'],
        'reason': row['reason'],
        'report_date': DateTime.fromMillisecondsSinceEpoch(row['report_date'] as int),
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getPendingReportDeletions() async {
    final db = await database;

    final List<Map<String, dynamic>> results = await db.query(
      'reports',
      where: 'sync_status = ?',
      whereArgs: [-1],
    );

    return results.map((row) {
      return {
        'id': row['id'],
        'number_id': row['number_id'],
        'user_id': row['user_id'],
      };
    }).toList();
  }

  // Sync status operations
  Future<List<Map<String, dynamic>>> getPendingUserUpdates() async {
    final db = await database;
    return await db.query(
      'users',
      where: 'sync_status = ?',
      whereArgs: [0],
    );
  }

  Future<List<Map<String, dynamic>>> getPendingNumberUpdates() async {
    final db = await database;
    return await db.query(
      'blocked_numbers',
      where: 'sync_status = ?',
      whereArgs: [0],
    );
  }

  Future<List<Map<String, dynamic>>> getPendingPrefixUpdates() async {
    final db = await database;
    return await db.query(
      'blocked_prefixes',
      where: 'sync_status = ?',
      whereArgs: [0],
    );
  }

  Future<List<Map<String, dynamic>>> getPendingNumberRelationUpdates() async {
    final db = await database;
    return await db.query(
      'user_blocked_numbers',
      where: 'sync_status = ?',
      whereArgs: [0],
    );
  }

  Future<List<Map<String, dynamic>>> getPendingPrefixRelationUpdates() async {
    final db = await database;
    return await db.query(
      'user_blocked_prefixes',
      where: 'sync_status = ?',
      whereArgs: [0],
    );
  }

  Future<List<Map<String, dynamic>>> getPendingNumberDeletions() async {
    final db = await database;
    return await db.query(
      'user_blocked_numbers',
      where: 'sync_status = ?',
      whereArgs: [-1],
    );
  }

  Future<List<Map<String, dynamic>>> getPendingPrefixDeletions() async {
    final db = await database;
    return await db.query(
      'user_blocked_prefixes',
      where: 'sync_status = ?',
      whereArgs: [-1],
    );
  }

  Future<void> markUserSynced(String userId) async {
    final db = await database;
    await db.update(
      'users',
      {'sync_status': 1},
      where: 'uid = ?',
      whereArgs: [userId],
    );
  }

  Future<void> markNumberSynced(String numberId) async {
    final db = await database;
    await db.update(
      'blocked_numbers',
      {'sync_status': 1},
      where: 'id = ?',
      whereArgs: [numberId],
    );
  }

  Future<void> markPrefixSynced(String prefixId) async {
    final db = await database;
    await db.update(
      'blocked_prefixes',
      {'sync_status': 1},
      where: 'id = ?',
      whereArgs: [prefixId],
    );
  }

  Future<void> markNumberRelationSynced(String userId, String numberId) async {
    final db = await database;
    await db.update(
      'user_blocked_numbers',
      {'sync_status': 1},
      where: 'user_id = ? AND number_id = ?',
      whereArgs: [userId, numberId],
    );
  }

  Future<void> markPrefixRelationSynced(String userId, String prefixId) async {
    final db = await database;
    await db.update(
      'user_blocked_prefixes',
      {'sync_status': 1},
      where: 'user_id = ? AND prefix_id = ?',
      whereArgs: [userId, prefixId],
    );
  }

  Future<void> cleanupDeletedRelations() async {
    final db = await database;
    await db.delete('user_blocked_numbers', where: 'sync_status = ?', whereArgs: [-1]);
    await db.delete('user_blocked_prefixes', where: 'sync_status = ?', whereArgs: [-1]);
    await db.delete('reports', where: 'sync_status = ?', whereArgs: [-1]);
  }
}