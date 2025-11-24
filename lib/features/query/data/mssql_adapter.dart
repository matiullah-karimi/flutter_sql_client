import 'dart:convert';
import 'dart:io';
import 'package:mssql_connection/mssql_connection.dart';
import 'package:flutter_sql_client/features/connections/domain/connection_config.dart';
import 'package:flutter_sql_client/features/query/domain/database_adapter.dart';

class MssqlAdapter implements DatabaseAdapter {
  final ConnectionConfig config;
  MssqlConnection? _connection;

  MssqlAdapter(this.config);

  @override
  Future<void> connect() async {
    _connection = MssqlConnection.getInstance();
    await _connection!.connect(
      ip: config.host,
      port: config.port.toString(),
      databaseName: config.database,
      username: config.username,
      password: config.password ?? '',
    );
  }

  @override
  Future<void> disconnect() async {
    await _connection?.disconnect();
    _connection = null;
  }

  @override
  Future<List<Map<String, dynamic>>> query(String sql) async {
    if (_connection == null) await connect();

    final result = await _connection!.getData(sql);

    // getData() returns a String in JSON format
    // Parse it to get the actual data
    if (result.isEmpty || result == '[]' || result == 'null') {
      return [];
    }

    try {
      final dynamic parsed = jsonDecode(result);
      if (parsed is List) {
        return parsed
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
      return [];
    } catch (e) {
      // If parsing fails, return empty list (likely a non-SELECT query)
      return [];
    }
  }

  @override
  Future<List<String>> getTables() async {
    final result = await query(
      "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_CATALOG = '${config.database}'",
    );
    return result.map((row) => row['TABLE_NAME'] as String).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getTableStructure(String tableName) async {
    return await query(
      "SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, COLUMN_DEFAULT FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '$tableName'",
    );
  }

  @override
  Future<List<String>> getDatabases() async {
    final result = await query(
      "SELECT name FROM sys.databases WHERE name NOT IN ('master', 'tempdb', 'model', 'msdb')",
    );
    return result.map((row) => row['name'] as String).toList();
  }

  @override
  Future<void> createDatabase(String name) async {
    await query('CREATE DATABASE [$name]');
  }

  @override
  Future<void> dropDatabase(String name) async {
    await query('DROP DATABASE [$name]');
  }

  @override
  Future<void> dropTable(String name) async {
    await query('DROP TABLE [$name]');
  }

  @override
  Future<void> exportDatabase(String filePath) async {
    final file = File(filePath);
    final sink = file.openWrite();

    try {
      final tables = await getTables();

      for (final table in tables) {
        // Structure
        final columns = await query(
          "SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, COLUMN_DEFAULT FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '$table' ORDER BY ORDINAL_POSITION",
        );

        sink.writeln('DROP TABLE IF EXISTS [$table];');
        sink.writeln('GO');
        sink.write('CREATE TABLE [$table] (');

        final colDefs = columns
            .map((col) {
              final name = col['COLUMN_NAME'];
              final type = col['DATA_TYPE'];
              final nullable = col['IS_NULLABLE'] == 'YES'
                  ? 'NULL'
                  : 'NOT NULL';
              final def = col['COLUMN_DEFAULT'] != null
                  ? 'DEFAULT ${col['COLUMN_DEFAULT']}'
                  : '';
              return '[$name] $type $nullable $def'.trim();
            })
            .join(',\n  ');

        sink.writeln('\n  $colDefs\n);');
        sink.writeln('GO');
        sink.writeln();

        // Data
        final rows = await query('SELECT * FROM [$table]');
        if (rows.isNotEmpty) {
          sink.writeln('INSERT INTO [$table] VALUES');
          for (var i = 0; i < rows.length; i++) {
            final row = rows[i];
            final values = columns
                .map((col) {
                  final val = row[col['COLUMN_NAME']];
                  return _escapeValue(val);
                })
                .join(', ');

            sink.write('($values)');
            if (i < rows.length - 1) {
              sink.writeln(',');
            } else {
              sink.writeln(';');
            }
          }
          sink.writeln('GO');
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
