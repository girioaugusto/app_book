import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'app_database.dart';

class UserRecord {
  final int id;
  final String username;
  final String passwordHash;
  final String salt;
  final int createdAt;

  UserRecord({
    required this.id,
    required this.username,
    required this.passwordHash,
    required this.salt,
    required this.createdAt,
  });

  static UserRecord fromMap(Map<String, Object?> m) => UserRecord(
        id: m['id'] as int,
        username: m['username'] as String,
        passwordHash: m['password_hash'] as String,
        salt: m['salt'] as String,
        createdAt: m['created_at'] as int,
      );
}

class UserDao {
  Future<UserRecord?> findByUsername(String username) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UserRecord.fromMap(rows.first);
  }

  Future<UserRecord> insertUser({
    required String username,
    required String passwordHash,
    required String salt,
  }) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = await db.insert(
      'users',
      {
        'username': username,
        'password_hash': passwordHash,
        'salt': salt,
        'created_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return UserRecord(
      id: id,
      username: username,
      passwordHash: passwordHash,
      salt: salt,
      createdAt: now,
    );
  }

  Future<void> updatePassword({
    required int userId,
    required String newPasswordHash,
    required String newSalt,
  }) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'users',
      {
        'password_hash': newPasswordHash,
        'salt': newSalt,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
}
