import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sql_client/features/query/presentation/database_provider.dart';
import 'package:flutter_sql_client/features/query/presentation/query_tabs_provider.dart';
import 'package:highlight/languages/sql.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pluto_grid/pluto_grid.dart';

class WorkspaceScreen extends ConsumerStatefulWidget {
  final int connectionId;
  const WorkspaceScreen({super.key, required this.connectionId});

  @override
  ConsumerState<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends ConsumerState<WorkspaceScreen> {
  final Map<String, CodeController> _codeControllers = {};
  final Map<String, PlutoGridStateManager> _gridStateManagers = {};
  String _tableSearchQuery = '';

  @override
  void dispose() {
    for (final controller in _codeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  CodeController _getOrCreateController(String tabId, String initialContent) {
    if (!_codeControllers.containsKey(tabId)) {
      _codeControllers[tabId] = CodeController(
        text: initialContent,
        language: sql,
      );
    }
    return _codeControllers[tabId]!;
  }

  @override
  Widget build(BuildContext context) {
    final tablesAsync = ref.watch(tablesProvider(widget.connectionId));
    final tabs = ref.watch(queryTabsProvider(widget.connectionId));
    final activeTabIndex = ref.watch(
      activeTabIndexProvider(widget.connectionId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workspace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            tooltip: 'Run Query',
            onPressed: () => _runQuery(tabs, activeTabIndex),
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save Changes',
            onPressed:
                (tabs.isNotEmpty &&
                    activeTabIndex < tabs.length &&
                    tabs[activeTabIndex].hasChanges)
                ? () => _saveChanges(tabs, activeTabIndex)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export Results',
            onPressed: () => _exportResults(context, tabs, activeTabIndex),
          ),
        ],
      ),
      body: Row(
        children: [
          // Schema Explorer
          SizedBox(
            width: 250,
            child: Card(
              margin: EdgeInsets.zero,
              shape: const RoundedRectangleBorder(),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Tables',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 20),
                          onPressed: () {
                            ref.invalidate(tablesProvider(widget.connectionId));
                          },
                        ),
                      ],
                    ),
                  ),
                  // Search field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search tables...',
                        prefixIcon: Icon(Icons.search, size: 20),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _tableSearchQuery = value.toLowerCase();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: tablesAsync.when(
                      data: (tables) {
                        // Filter tables based on search query
                        final filteredTables = _tableSearchQuery.isEmpty
                            ? tables
                            : tables
                                  .where(
                                    (table) => table.toLowerCase().contains(
                                      _tableSearchQuery,
                                    ),
                                  )
                                  .toList();

                        if (filteredTables.isEmpty) {
                          return const Center(child: Text('No tables found'));
                        }

                        return ListView.separated(
                          itemCount: filteredTables.length,
                          separatorBuilder: (context, index) => const Divider(
                            height: 1,
                            thickness: 1,
                            indent: 16,
                            endIndent: 16,
                          ),
                          itemBuilder: (context, index) {
                            final tableName = filteredTables[index];
                            return ListTile(
                              title: Text(tableName),
                              dense: true,
                              leading: const Icon(Icons.table_chart, size: 16),
                              trailing: IconButton(
                                icon: const Icon(Icons.info_outline, size: 16),
                                tooltip: 'View Structure',
                                onPressed: () => _showTableStructure(tableName),
                              ),
                              onTap: () {
                                if (tabs.isNotEmpty &&
                                    activeTabIndex < tabs.length) {
                                  final activeTab = tabs[activeTabIndex];
                                  final controller = _getOrCreateController(
                                    activeTab.id,
                                    activeTab.content,
                                  );
                                  controller.text =
                                      'SELECT * FROM $tableName LIMIT 100;';
                                }
                              },
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(child: Text('Error: $err')),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Main Content
          Expanded(
            child: Column(
              children: [
                // Tab Bar
                Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (int i = 0; i < tabs.length; i++)
                                _buildTab(context, tabs[i], i, activeTabIndex),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 20),
                        tooltip: 'New Query Tab',
                        onPressed: () {
                          ref
                              .read(
                                queryTabsProvider(widget.connectionId).notifier,
                              )
                              .addTab();
                          ref
                                  .read(
                                    activeTabIndexProvider(
                                      widget.connectionId,
                                    ).notifier,
                                  )
                                  .state =
                              tabs.length;
                        },
                      ),
                    ],
                  ),
                ),
                // Query Editor
                if (tabs.isNotEmpty && activeTabIndex < tabs.length)
                  Expanded(
                    flex: 1,
                    child: CodeTheme(
                      data: CodeThemeData(styles: const {}),
                      child: SingleChildScrollView(
                        child: CodeField(
                          controller: _getOrCreateController(
                            tabs[activeTabIndex].id,
                            tabs[activeTabIndex].content,
                          ),
                          textStyle: const TextStyle(fontFamily: 'monospace'),
                          minLines: 10,
                          onChanged: (value) {
                            ref
                                .read(
                                  queryTabsProvider(
                                    widget.connectionId,
                                  ).notifier,
                                )
                                .updateTabContent(
                                  tabs[activeTabIndex].id,
                                  value,
                                );
                          },
                        ),
                      ),
                    ),
                  ),
                const Divider(height: 1),
                // Results
                if (tabs.isNotEmpty && activeTabIndex < tabs.length)
                  Expanded(
                    flex: 2,
                    child: KeyedSubtree(
                      key: ValueKey(tabs[activeTabIndex].id),
                      child: _buildResults(tabs[activeTabIndex]),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runQuery(List tabs, int activeTabIndex) async {
    if (tabs.isEmpty || activeTabIndex >= tabs.length) return;

    final activeTab = tabs[activeTabIndex];
    final controller = _codeControllers[activeTab.id];

    if (controller == null || controller.text.isEmpty) return;

    // Set loading state
    ref
        .read(queryTabsProvider(widget.connectionId).notifier)
        .setTabLoading(activeTab.id, true);

    try {
      final adapter = await ref.read(
        databaseAdapterProvider(widget.connectionId).future,
      );
      final results = await adapter.query(controller.text);

      // Extract table name from SQL query (simple regex for SELECT FROM)
      final String? sourceTable = _extractTableName(controller.text);

      ref
          .read(queryTabsProvider(widget.connectionId).notifier)
          .setTabResults(activeTab.id, results, sourceTable: sourceTable);
    } catch (e) {
      ref
          .read(queryTabsProvider(widget.connectionId).notifier)
          .setTabError(activeTab.id, e.toString());
    }
  }

  String? _extractTableName(String sql) {
    // Simple regex to extract table name from SELECT ... FROM table_name
    final regex = RegExp(r'FROM\s+([`"]?)(\w+)\1', caseSensitive: false);
    final match = regex.firstMatch(sql);
    return match?.group(2);
  }

  Future<void> _saveChanges(List tabs, int activeTabIndex) async {
    if (tabs.isEmpty || activeTabIndex >= tabs.length) return;

    final activeTab = tabs[activeTabIndex];
    final stateManager = _gridStateManagers[activeTab.id];

    if (stateManager == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Grid not initialized')));
      }
      return;
    }

    await _saveGridChanges(stateManager, activeTab);

    // Clear the hasChanges flag after successful save
    ref
        .read(queryTabsProvider(widget.connectionId).notifier)
        .setTabHasChanges(activeTab.id, false);
  }

  Widget _buildResults(tab) {
    if (tab.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tab.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Error: ${tab.error}',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    final results = tab.results;
    if (results == null || results.isEmpty) {
      return const Center(child: Text('No results or no query run yet.'));
    }

    PlutoGridStateManager? stateManager;

    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.keyS &&
            (event.physicalKey == PhysicalKeyboardKey.metaLeft ||
                event.physicalKey == PhysicalKeyboardKey.metaRight ||
                HardwareKeyboard.instance.isMetaPressed)) {
          final manager = stateManager;
          if (manager != null) {
            _saveGridChanges(manager, tab);
          }
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: PlutoGrid(
        columns: results.first.keys.map<PlutoColumn>((key) {
          return PlutoColumn(
            title: key,
            field: key,
            type: PlutoColumnType.text(),
            enableEditingMode: true,
          );
        }).toList(),
        rows: results.map<PlutoRow>((row) {
          return PlutoRow(
            cells: Map<String, PlutoCell>.fromEntries(
              row.entries.map<MapEntry<String, PlutoCell>>((
                MapEntry<String, dynamic> entry,
              ) {
                return MapEntry(
                  entry.key,
                  PlutoCell(value: entry.value.toString()),
                );
              }),
            ),
          );
        }).toList(),
        onLoaded: (PlutoGridOnLoadedEvent event) {
          _gridStateManagers[tab.id] = event.stateManager;
          stateManager = event.stateManager;
          event.stateManager.setKeepFocus(true);
        },
        onChanged: (PlutoGridOnChangedEvent event) {
          // Mark tab as having changes (delayed to avoid modifying provider during build)
          Future(() {
            ref
                .read(queryTabsProvider(widget.connectionId).notifier)
                .setTabHasChanges(tab.id, true);
          });
        },
        configuration: const PlutoGridConfiguration(
          style: PlutoGridStyleConfig(enableGridBorderShadow: false),
          enterKeyAction: PlutoGridEnterKeyAction.editingAndMoveDown,
        ),
      ),
    );
  }

  Future<void> _saveGridChanges(PlutoGridStateManager stateManager, tab) async {
    final sourceTable = tab.sourceTable;

    if (sourceTable == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot save: Unable to determine source table'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    try {
      final adapter = await ref.read(
        databaseAdapterProvider(widget.connectionId).future,
      );

      // Get all rows from the grid
      final rows = stateManager.rows;
      final columns = stateManager.columns;

      // Assume first column is the primary key (simple approach)
      if (columns.isEmpty || rows.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No data to save')));
        }
        return;
      }

      final primaryKeyColumn = columns.first.field;
      int updatedCount = 0;

      // Generate and execute UPDATE statements for each modified row
      for (final row in rows) {
        final primaryKeyValue = row.cells[primaryKeyColumn]?.value;

        if (primaryKeyValue == null) continue;

        // Build UPDATE statement
        final setClauses = <String>[];
        for (final column in columns) {
          if (column.field == primaryKeyColumn) continue; // Skip primary key

          final cell = row.cells[column.field];
          if (cell != null) {
            final cellValue = cell.value;

            // Handle NULL values properly
            if (cellValue == null ||
                cellValue.toString().toLowerCase() == 'null') {
              setClauses.add("${column.field} = NULL");
            } else {
              final value = cellValue.toString().replaceAll(
                "'",
                "''",
              ); // Escape quotes
              setClauses.add("${column.field} = '$value'");
            }
          }
        }

        if (setClauses.isEmpty) continue;

        final updateSql =
            '''
          UPDATE $sourceTable 
          SET ${setClauses.join(', ')} 
          WHERE $primaryKeyColumn = '$primaryKeyValue'
        ''';

        await adapter.query(updateSql);
        updatedCount++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully updated $updatedCount row(s)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildTab(BuildContext context, tab, int index, int activeIndex) {
    final isActive = index == activeIndex;
    return InkWell(
      onTap: () {
        ref.read(activeTabIndexProvider(widget.connectionId).notifier).state =
            index;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.surface
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tab.title,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 8),
            if (ref.watch(queryTabsProvider(widget.connectionId)).length > 1)
              InkWell(
                onTap: () {
                  ref
                      .read(queryTabsProvider(widget.connectionId).notifier)
                      .removeTab(tab.id);
                  if (activeIndex >=
                      ref.read(queryTabsProvider(widget.connectionId)).length) {
                    ref
                            .read(
                              activeTabIndexProvider(
                                widget.connectionId,
                              ).notifier,
                            )
                            .state =
                        ref
                            .read(queryTabsProvider(widget.connectionId))
                            .length -
                        1;
                  }
                },
                child: const Icon(Icons.close, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportResults(
    BuildContext context,
    List tabs,
    int activeTabIndex,
  ) async {
    if (tabs.isEmpty || activeTabIndex >= tabs.length) return;

    final activeTab = tabs[activeTabIndex];
    final results = activeTab.results;

    if (results == null || results.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No results to export')));
      return;
    }

    final csvData = <List<dynamic>>[
      results.first.keys.toList(),
      ...results.map((row) => row.values.toList()),
    ];

    final String csvString = const ListToCsvConverter().convert(csvData);

    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
        '${directory.path}/export_${DateTime.now().millisecondsSinceEpoch}.csv',
      );
      await file.writeAsString(csvString);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Exported to ${file.path}')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _showTableStructure(String tableName) async {
    try {
      final adapter = await ref.read(
        databaseAdapterProvider(widget.connectionId).future,
      );

      // Query to get column information (works for most SQL databases)
      final query =
          '''
        SELECT 
          column_name,
          data_type,
          is_nullable,
          column_default
        FROM information_schema.columns
        WHERE table_name = '$tableName'
        ORDER BY ordinal_position
      ''';

      final columns = await adapter.query(query);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.table_chart),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Table Structure'),
                    Text(
                      tableName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 700,
            height: 500,
            child: Column(
              children: [
                // Action buttons
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showAddColumnDialog(tableName);
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Column'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showTableIndexes(tableName);
                      },
                      icon: const Icon(Icons.key, size: 16),
                      label: const Text('View Indexes'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                // Columns list
                Expanded(
                  child: columns.isEmpty
                      ? const Center(child: Text('No columns found'))
                      : ListView.builder(
                          itemCount: columns.length,
                          itemBuilder: (context, index) {
                            final column = columns[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  radius: 16,
                                  child: Text('${index + 1}'),
                                ),
                                title: const Text(
                                  'Column',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.label, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Name: ${column['column_name']}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.text_fields, size: 14),
                                        const SizedBox(width: 4),
                                        Text('Type: ${column['data_type']}'),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          column['is_nullable'] == 'YES'
                                              ? Icons.check_circle_outline
                                              : Icons.cancel_outlined,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Nullable: ${column['is_nullable']}',
                                        ),
                                      ],
                                    ),
                                    if (column['column_default'] != null)
                                      Row(
                                        children: [
                                          const Icon(Icons.settings, size: 14),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Default: ${column['column_default']}',
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.edit, size: 16),
                                  tooltip: 'Edit column',
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _showEditColumnDialog(
                                      tableName,
                                      column['column_name']?.toString() ?? '',
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading structure: $e')));
      }
    }
  }

  Future<void> _showAddColumnDialog(String tableName) async {
    final nameController = TextEditingController();
    final typeController = TextEditingController(text: 'VARCHAR(255)');
    bool isNullable = true;
    String? defaultValue;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add Column to $tableName'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Column Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: typeController,
                  decoration: const InputDecoration(
                    labelText: 'Data Type',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., VARCHAR(255), INT, TEXT',
                  ),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Nullable'),
                  value: isNullable,
                  onChanged: (value) {
                    setState(() {
                      isNullable = value ?? true;
                    });
                  },
                ),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Default Value (optional)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    defaultValue = value.isEmpty ? null : value;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    typeController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name and type are required')),
                  );
                  return;
                }

                try {
                  final adapter = await ref.read(
                    databaseAdapterProvider(widget.connectionId).future,
                  );

                  final alterQuery =
                      '''
                    ALTER TABLE $tableName 
                    ADD COLUMN ${nameController.text} ${typeController.text}
                    ${isNullable ? 'NULL' : 'NOT NULL'}
                    ${defaultValue != null ? "DEFAULT '$defaultValue'" : ''}
                  ''';

                  await adapter.query(alterQuery);

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Column added successfully'),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Add Column'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditColumnDialog(
    String tableName,
    String columnName,
  ) async {
    // Note: Column editing varies greatly between databases
    // This is a simplified version
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Column editing coming soon. Use SQL ALTER TABLE for now.',
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _showTableIndexes(String tableName) async {
    try {
      final adapter = await ref.read(
        databaseAdapterProvider(widget.connectionId).future,
      );

      // Query to get index information
      final query =
          '''
        SELECT 
          indexname as index_name,
          indexdef as index_definition
        FROM pg_indexes
        WHERE tablename = '$tableName'
      ''';

      final indexes = await adapter.query(query);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Indexes: $tableName'),
          content: SizedBox(
            width: 600,
            height: 400,
            child: indexes.isEmpty
                ? const Center(child: Text('No indexes found'))
                : ListView.builder(
                    itemCount: indexes.length,
                    itemBuilder: (context, index) {
                      final idx = indexes[index];
                      return Card(
                        child: ListTile(
                          title: Text(idx['index_name']?.toString() ?? ''),
                          subtitle: Text(
                            idx['index_definition']?.toString() ?? '',
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading indexes: $e')));
      }
    }
  }
}
