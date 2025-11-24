import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sql_client/features/connections/domain/connection_config.dart';
import 'package:flutter_sql_client/features/connections/presentation/connections_provider.dart';
import 'package:flutter_sql_client/features/query/data/mysql_adapter.dart';
import 'package:flutter_sql_client/features/query/data/postgres_adapter.dart';
import 'package:flutter_sql_client/features/query/data/sqlite_adapter.dart';
import 'package:flutter_sql_client/features/query/domain/database_adapter.dart';

final databaseAdapterProvider = FutureProvider.autoDispose
    .family<DatabaseAdapter, int>((ref, connectionId) async {
      final connectionsAsync = ref.watch(connectionsProvider);
      final connections = connectionsAsync.value;

      if (connections == null) {
        throw Exception('Connections not loaded');
      }

      final config = connections.firstWhere(
        (c) => c.id == connectionId,
        orElse: () => throw Exception('Connection not found'),
      );

      DatabaseAdapter adapter;
      switch (config.type) {
        case DatabaseType.postgres:
          adapter = PostgresAdapter(config);
          break;
        case DatabaseType.mysql:
          adapter = MysqlAdapter(config);
          break;
        case DatabaseType.sqlite:
          adapter = SqliteAdapter(config);
          break;
      }

      await adapter.connect();
      ref.onDispose(() => adapter.disconnect());
      return adapter;
    });

final tablesProvider = FutureProvider.family<List<String>, int>((
  ref,
  connectionId,
) async {
  final adapter = await ref.watch(databaseAdapterProvider(connectionId).future);
  return adapter.getTables();
});

final queryResultsProvider =
    StateNotifierProvider.family<
      QueryNotifier,
      AsyncValue<List<Map<String, dynamic>>>,
      int
    >((ref, connectionId) {
      return QueryNotifier(ref, connectionId);
    });

class QueryNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final Ref ref;
  final int connectionId;

  QueryNotifier(this.ref, this.connectionId) : super(const AsyncValue.data([]));

  Future<void> runQuery(String sql) async {
    state = const AsyncValue.loading();
    try {
      final adapter = await ref.read(
        databaseAdapterProvider(connectionId).future,
      );
      final results = await adapter.query(sql);
      state = AsyncValue.data(results);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
