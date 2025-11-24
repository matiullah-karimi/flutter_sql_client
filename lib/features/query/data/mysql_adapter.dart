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
}
