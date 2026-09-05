import 'dart:async';
import 'package:sqflite/sqflite.dart';

/// SQLite serializes separate Flutter engines; Dart file locks only exclude
/// other processes. No app preferences or notification records live in this DB.
abstract class ScheduleLock {
  Future<T> run<T>(Future<T> Function() action);
}

class DatabaseScheduleLock implements ScheduleLock {
  const DatabaseScheduleLock({this.name = 'prayer_schedule'});
  final String name;

  @override
  Future<T> run<T>(Future<T> Function() action) async {
    final path = '${await getDatabasesPath()}/$name.lock.db';
    final db = await openDatabase(
      path,
      singleInstance: false,
      onConfigure: (db) async {
        await db.rawQuery('PRAGMA busy_timeout = 0');
      },
    );
    final deadline = DateTime.now().add(const Duration(seconds: 25));
    try {
      while (true) {
        var entered = false;
        try {
          return await db.transaction((_) {
            entered = true;
            return action();
          }, exclusive: true);
        } on DatabaseException catch (error) {
          final code = error.getResultCode();
          final busy =
              code != null && ((code & 0xff) == 5 || (code & 0xff) == 6);
          if (entered || !busy || DateTime.now().isAfter(deadline)) rethrow;
          // Never block the plugin's native worker thread while another Dart
          // isolate needs that same thread to commit and release its lock.
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      }
    } finally {
      await db.close();
    }
  }
}
