import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_sql_client/features/connections/domain/connection_config.dart';
import 'package:flutter_sql_client/features/query/domain/database_adapter.dart';

class SqliteAdapter implements DatabaseAdapter {
  final ConnectionConfig config;
  Database? _db;

  SqliteAdapter(this.config);

  @override
  Future<void> connect() async {
    sqfliteFfiInit();
    var databaseFactory = databaseFactoryFfi;
    _db = await databaseFactory.openDatabase(config.filePath!);
  }

  @override
  Future<void> disconnect() async {
    await _db?.close();
    _db = null;
  }

  @override
  Future<List<Map<String, dynamic>>> query(String sql) async {
    if (_db == null) await connect();
    return await _db!.rawQuery(sql);
  }

  @override
  Future<List<String>> getTables() async {
    final result = await query(
      "SELECT name FROM sqlite_master WHERE type='table'",
    );
    return result.map((row) => row['name'] as String).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getTableStructure(String tableName) async {
    return await query("PRAGMA table_info($tableName)");
  }

  @override
  Future<List<String>> getDatabases() async {
    return ['main'];
  }

  @override
  Future<void> createDatabase(String name) async {
    throw UnimplementedError(
      'Cannot create database in SQLite via SQL connection',
    );
  }

  @override
  Future<void> dropDatabase(String name) async {
    throw UnimplementedError(
      'Cannot drop database in SQLite via SQL connection',
    );
  }

  @override
  Future<void> dropTable(String name) async {
    await query('DROP TABLE "$name"');
  }

  @override
  Future<void> exportDatabase(String filePath) async {
    final file = File(filePath);
    final sink = file.openWrite();

    try {
      final tables = await query(
        "SELECT name, sql FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
      );

      for (final tableRow in tables) {
        final tableName = tableRow['name'] as String;
        final createSql = tableRow['sql'] as String;

        sink.writeln('DROP TABLE IF EXISTS "$tableName";');
        sink.writeln('$createSql;');
        sink.writeln();

        final rows = await query('SELECT * FROM "$tableName"');
        if (rows.isNotEmpty) {
          sink.writeln('INSERT INTO "$tableName" VALUES');
          for (var i = 0; i < rows.length; i++) {
            final row = rows[i];
            final values = row.values.map((v) => _escapeValue(v)).join(', ');
            sink.write('($values)');
            if (i < rows.length - 1) {
              sink.writeln(',');
            } else {
              sink.writeln(';');
            }
          }
          sink.writeln();
        }
      }
    } finally {
      await sink.close();
    }
  }

  String _escapeValue(dynamic value) {
    if (value == null) return 'NULL';
    if (value is num) return value.toString();
    if (value is bool) return value ? '1' : '0';
    final str = value.toString().replaceAll("'", "''");
    return "'$str'";
  }
}
