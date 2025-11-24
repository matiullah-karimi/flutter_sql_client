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
}
