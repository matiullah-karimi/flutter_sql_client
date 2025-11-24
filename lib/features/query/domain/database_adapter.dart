abstract class DatabaseAdapter {
  Future<void> connect();
  Future<void> disconnect();
  Future<List<Map<String, dynamic>>> query(String sql);
  Future<List<String>> getTables();
  Future<List<Map<String, dynamic>>> getTableStructure(String tableName);
  Future<List<String>> getDatabases();
  Future<void> createDatabase(String name);
  Future<void> dropDatabase(String name);
  Future<void> dropTable(String name);
  Future<void> exportDatabase(String filePath);
}
