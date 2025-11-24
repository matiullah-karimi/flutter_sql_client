import 'package:postgres/postgres.dart';
import 'package:flutter_sql_client/features/connections/domain/connection_config.dart';
import 'package:flutter_sql_client/features/query/domain/database_adapter.dart';

class PostgresAdapter implements DatabaseAdapter {
  final ConnectionConfig config;
  Connection? _connection;

  PostgresAdapter(this.config);

  @override
  Future<void> connect() async {
    _connection = await Connection.open(
      Endpoint(
        host: config.host,
        port: config.port,
        database: config.database,
        username: config.username,
        password: config.password,
      ),
      settings: const ConnectionSettings(sslMode: SslMode.disable),
    );
  }

  @override
  Future<void> disconnect() async {
    await _connection?.close();
    _connection = null;
  }

  @override
  Future<List<Map<String, dynamic>>> query(String sql) async {
    if (_connection == null || !_connection!.isOpen) await connect();
    final result = await _connection!.execute(sql);

    // Convert Result to List<Map>
    // Postgres returns a Result object which is iterable of ResultRow
    // ResultRow can be converted to Map but it's a bit tricky with column names
    // We need to map columns to values

    final headers = result.schema.columns
        .map((c) => c.columnName ?? '')
        .toList();

    return result.map((row) {
      final map = <String, dynamic>{};
      for (var i = 0; i < headers.length; i++) {
        map[headers[i]] = row[i];
      }
      return map;
    }).toList();
  }

  @override
  Future<List<String>> getTables() async {
    final result = await query(
      "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'",
    );
    return result.map((row) => row['table_name'] as String).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getTableStructure(String tableName) async {
    return await query(
      "SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_name = '$tableName'",
    );
  }

  @override
  Future<List<String>> getDatabases() async {
    final result = await query(
      "SELECT datname FROM pg_database WHERE datistemplate = false",
    );
    return result.map((row) => row['datname'] as String).toList();
  }

  @override
  Future<void> createDatabase(String name) async {
    // Note: CREATE DATABASE cannot run inside a transaction block.
    // The query method here uses simple execute which might be fine,
    // but if it wraps in transaction, this might fail.
    // Postgres package 'execute' usually runs directly.
    await query('CREATE DATABASE "$name"');
  }
}
