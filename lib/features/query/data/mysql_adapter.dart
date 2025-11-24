import 'dart:io';
import 'package:mysql_client/mysql_client.dart';
import 'package:flutter_sql_client/features/connections/domain/connection_config.dart';
import 'package:flutter_sql_client/features/query/domain/database_adapter.dart';

class MysqlAdapter implements DatabaseAdapter {
  final ConnectionConfig config;
  MySQLConnection? _connection;

  MysqlAdapter(this.config);

  @override
  Future<void> connect() async {
    _connection = await MySQLConnection.createConnection(
      host: config.host,
      port: config.port,
      userName: config.username,
      password: config.password ?? '',
      databaseName: config.database,
      secure: true,
    );
    await _connection!.connect();
  }

  @override
  Future<void> disconnect() async {
    await _connection?.close();
    _connection = null;
  }

  @override
  Future<List<Map<String, dynamic>>> query(String sql) async {
    if (_connection == null || !_connection!.connected) await connect();

    final results = await _connection!.execute(sql);

    // Convert IResultSet to List<Map>
    final List<Map<String, dynamic>> rows = [];
    for (final row in results.rows) {
      rows.add(row.assoc());
    }
    return rows;
  }

  @override
  Future<List<String>> getTables() async {
    final results = await query("SHOW TABLES");
    return results.map((row) => row.values.first.toString()).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getTableStructure(String tableName) async {
    return await query("DESCRIBE $tableName");
  }

  @override
  Future<List<String>> getDatabases() async {
    final result = await query("SHOW DATABASES");
    return result.map((row) => row.values.first.toString()).toList();
  }

  @override
  Future<void> createDatabase(String name) async {
    await query('CREATE DATABASE `$name`');
  }

  @override
  Future<void> dropDatabase(String name) async {
    await query('DROP DATABASE `$name`');
  }

  @override
  Future<void> dropTable(String name) async {
    await query('DROP TABLE `$name`');
  }

  @override
  Future<void> exportDatabase(String filePath) async {
    final file = File(filePath);
    final sink = file.openWrite();

    try {
      final tables = await getTables();

      for (final table in tables) {
        // Structure
        final createResult = await query('SHOW CREATE TABLE `$table`');
        if (createResult.isNotEmpty) {
          final createSql = createResult.first['Create Table'] as String;
          sink.writeln('DROP TABLE IF EXISTS `$table`;');
          sink.writeln('$createSql;');
          sink.writeln();
        }

        // Data
        final rows = await query('SELECT * FROM `$table`');
        if (rows.isNotEmpty) {
          sink.writeln('INSERT INTO `$table` VALUES');
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
    final str = value.toString().replaceAll("'", "''").replaceAll(r'\', r'\\');
    return "'$str'";
  }
}
