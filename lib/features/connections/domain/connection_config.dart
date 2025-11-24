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

  ConnectionConfig copyWith({
    int? id,
    String? uuid,
    String? name,
    DatabaseType? type,
    String? host,
    int? port,
    String? database,
    String? username,
    String? password,
    String? filePath,
  }) {
    return ConnectionConfig(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      type: type ?? this.type,
      host: host ?? this.host,
      port: port ?? this.port,
      database: database ?? this.database,
      username: username ?? this.username,
      password: password ?? this.password,
      filePath: filePath ?? this.filePath,
    );
  }
}
