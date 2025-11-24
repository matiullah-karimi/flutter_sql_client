import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sql_client/core/data/objectbox.dart';
import 'package:flutter_sql_client/features/connections/domain/connection_config.dart';
import 'package:flutter_sql_client/objectbox.g.dart';

final objectBoxProvider = Provider<ObjectBox>((ref) {
  throw UnimplementedError('ObjectBox must be initialized in main.dart');
});

final connectionRepositoryProvider = Provider((ref) {
  final objectBox = ref.watch(objectBoxProvider);
  return ConnectionRepository(objectBox.store);
});

class ConnectionRepository {
  final Store _store;
  late final Box<ConnectionConfig> _box;

  ConnectionRepository(this._store) {
    _box = _store.box<ConnectionConfig>();
  }

  Future<List<ConnectionConfig>> loadConnections() async {
    return _box.getAll();
  }

  Future<void> saveConnection(ConnectionConfig config) async {
    _box.put(config);
  }

  Future<void> deleteConnection(int id) async {
    _box.remove(id);
  }
}
