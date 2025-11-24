import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sql_client/features/connections/data/connection_repository.dart';
import 'package:flutter_sql_client/features/connections/domain/connection_config.dart';

final connectionsProvider =
    StateNotifierProvider<
      ConnectionsNotifier,
      AsyncValue<List<ConnectionConfig>>
    >((ref) {
      return ConnectionsNotifier(ref.watch(connectionRepositoryProvider));
    });

class ConnectionsNotifier
    extends StateNotifier<AsyncValue<List<ConnectionConfig>>> {
  final ConnectionRepository _repository;

  ConnectionsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadConnections();
  }

  Future<void> loadConnections() async {
    try {
      final connections = await _repository.loadConnections();
      state = AsyncValue.data(connections);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addConnection(ConnectionConfig config) async {
    await _repository.saveConnection(config);
    await loadConnections();
  }

  Future<void> deleteConnection(int id) async {
    await _repository.deleteConnection(id);
    await loadConnections();
  }
}
