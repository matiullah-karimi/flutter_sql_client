import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sql_client/features/query/domain/query_tab.dart';
import 'package:uuid/uuid.dart';

final queryTabsProvider =
    StateNotifierProvider.family<QueryTabsNotifier, List<QueryTab>, int>((
      ref,
      connectionId,
    ) {
      return QueryTabsNotifier();
    });

final activeTabIndexProvider = StateProvider.family<int, int>(
  (ref, connectionId) => 0,
);

class QueryTabsNotifier extends StateNotifier<List<QueryTab>> {
  QueryTabsNotifier()
    : super([
        QueryTab(
          id: const Uuid().v4(),
          title: 'Query 1',
          content: 'SELECT * FROM ',
        ),
      ]);

  void addTab() {
    final newTab = QueryTab(
      id: const Uuid().v4(),
      title: 'Query ${state.length + 1}',
      content: '',
    );
    state = [...state, newTab];
  }

  void removeTab(String id) {
    if (state.length > 1) {
      state = state.where((tab) => tab.id != id).toList();
    }
  }

  void updateTabContent(String id, String content) {
    state = [
      for (final tab in state)
        if (tab.id == id) tab.copyWith(content: content) else tab,
    ];
  }

  void renameTab(String id, String newTitle) {
    state = [
      for (final tab in state)
        if (tab.id == id) tab.copyWith(title: newTitle) else tab,
    ];
  }

  void setTabLoading(String id, bool isLoading) {
    state = [
      for (final tab in state)
        if (tab.id == id)
          tab.copyWith(isLoading: isLoading, clearError: true)
        else
          tab,
    ];
  }

  void setTabResults(String id, List<Map<String, dynamic>> results) {
    state = [
      for (final tab in state)
        if (tab.id == id)
          tab.copyWith(results: results, isLoading: false, clearError: true)
        else
          tab,
    ];
  }

  void setTabError(String id, String error) {
    state = [
      for (final tab in state)
        if (tab.id == id) tab.copyWith(error: error, isLoading: false) else tab,
    ];
  }
}
