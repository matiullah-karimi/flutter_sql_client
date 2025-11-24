import 'package:objectbox/objectbox.dart';
import 'package:uuid/uuid.dart';

enum DatabaseType { postgres, mysql, sqlite }

@Entity()
class ConnectionConfig {
  @Id()
  int id = 0; // ObjectBox ID

  @Index()
  final String uuid; // External UUID

  final String name;

  @Transient()
  DatabaseType type = DatabaseType.postgres; // Default

  int get dbTypeIndex => type.index;
  set dbTypeIndex(int index) {
    type = DatabaseType.values[index];
  }

  final String host;
  final int port;
  final String database;
  final String username;
  final String? password;
  final String? filePath;

  ConnectionConfig({
    this.id = 0,
    String? uuid,
    required this.name,
    int? dbTypeIndex,
    DatabaseType? type,
    this.host = 'localhost',
    this.port = 5432,
    this.database = '',
    this.username = '',
    this.password,
    this.filePath,
  }) : uuid = uuid ?? const Uuid().v4(),
       type =
           type ??
           (dbTypeIndex != null
               ? DatabaseType.values[dbTypeIndex]
               : DatabaseType.postgres);
}
