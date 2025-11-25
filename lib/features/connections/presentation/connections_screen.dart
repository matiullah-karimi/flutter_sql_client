import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_sql_client/features/connections/domain/connection_config.dart';
import 'package:flutter_sql_client/features/connections/presentation/connections_provider.dart';
import 'package:flutter_sql_client/features/query/domain/database_adapter.dart';
import 'package:flutter_sql_client/features/query/data/postgres_adapter.dart';
import 'package:flutter_sql_client/features/query/data/mysql_adapter.dart';
import 'package:flutter_sql_client/features/query/data/sqlite_adapter.dart';
import 'package:flutter_sql_client/features/query/data/mssql_adapter.dart';

class ConnectionsScreen extends ConsumerWidget {
  const ConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(connectionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Connections')),
      body: connectionsAsync.when(
        data: (connections) {
          if (connections.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.storage_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No connections found',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showConnectionDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Connection'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: connections.length,
            itemBuilder: (context, index) {
              final connection = connections[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(_getIconForType(connection.type)),
                  title: Text(connection.name),
                  subtitle: Text(
                    '${connection.username}@${connection.host}:${connection.port}',
                  ),
                  onTap: () {
                    context.go('/workspace/${connection.id}');
                  },
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showConnectionDialog(context, ref, connection);
                      } else if (value == 'delete') {
                        ref
                            .read(connectionsProvider.notifier)
                            .deleteConnection(connection.id);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showConnectionDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _getIconForType(DatabaseType type) {
    switch (type) {
      case DatabaseType.postgres:
        return Icons.dns; // Placeholder for Postgres
      case DatabaseType.mysql:
        return Icons.storage; // Placeholder for MySQL
      case DatabaseType.sqlite:
        return Icons.folder; // Placeholder for SQLite
      case DatabaseType.mssql:
        return Icons.cloud; // Placeholder for MSSQL
    }
  }

  void _showConnectionDialog(
    BuildContext context,
    WidgetRef ref, [
    ConnectionConfig? existing,
  ]) {
    showDialog(
      context: context,
      builder: (context) => ConnectionDialog(existing: existing),
    );
  }
}

class ConnectionDialog extends ConsumerStatefulWidget {
  final ConnectionConfig? existing;
  const ConnectionDialog({super.key, this.existing});

  @override
  ConsumerState<ConnectionDialog> createState() => _ConnectionDialogState();
}

class _ConnectionDialogState extends ConsumerState<ConnectionDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _hostController;
  late TextEditingController _portController;
  late TextEditingController _dbController;
  late TextEditingController _userController;
  late TextEditingController _passwordController;
  late DatabaseType _type;
  bool _isTestingConnection = false;
  String? _connectionError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _hostController = TextEditingController(
      text: widget.existing?.host ?? 'localhost',
    );
    _portController = TextEditingController(
      text: widget.existing?.port.toString() ?? '5432',
    );
    _dbController = TextEditingController(
      text: widget.existing?.database ?? '',
    );
    _userController = TextEditingController(
      text: widget.existing?.username ?? '',
    );
    _passwordController = TextEditingController(
      text: widget.existing?.password ?? '',
    );
    _type = widget.existing?.type ?? DatabaseType.postgres;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null ? 'New Connection' : 'Edit Connection',
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isTestingConnection)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Testing connection...'),
                      ],
                    ),
                  ),
                if (_connectionError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _connectionError!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                DropdownButtonFormField<DatabaseType>(
                  initialValue: _type,
                  items: DatabaseType.values.map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Text(t.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: _isTestingConnection
                      ? null
                      : (val) {
                          if (val != null) {
                            setState(() {
                              _type = val;
                              _connectionError = null;
                              if (_type == DatabaseType.postgres) {
                                _portController.text = '5432';
                              }
                              if (_type == DatabaseType.mysql) {
                                _portController.text = '3306';
                              }
                              if (_type == DatabaseType.mssql) {
                                _portController.text = '1433';
                              }
                            });
                          }
                        },
                  decoration: const InputDecoration(labelText: 'Type'),
                ),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                  enabled: !_isTestingConnection,
                ),
                if (_type != DatabaseType.sqlite) ...[
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _hostController,
                          decoration: const InputDecoration(labelText: 'Host'),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                          enabled: !_isTestingConnection,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _portController,
                          decoration: const InputDecoration(labelText: 'Port'),
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                          enabled: !_isTestingConnection,
                        ),
                      ),
                    ],
                  ),
                  TextFormField(
                    controller: _dbController,
                    decoration: const InputDecoration(labelText: 'Database'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                    enabled: !_isTestingConnection,
                  ),
                  TextFormField(
                    controller: _userController,
                    decoration: const InputDecoration(labelText: 'Username'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                    enabled: !_isTestingConnection,
                  ),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    enabled: !_isTestingConnection,
                  ),
                ] else ...[
                  TextFormField(
                    controller:
                        _dbController, // Reuse db controller for file path
                    decoration: const InputDecoration(labelText: 'File Path'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                    enabled: !_isTestingConnection,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isTestingConnection ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isTestingConnection
              ? null
              : () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      _isTestingConnection = true;
                      _connectionError = null;
                    });

                    final config = ConnectionConfig(
                      id: widget.existing?.id ?? 0,
                      name: _nameController.text,
                      type: _type,
                      host: _hostController.text,
                      port: int.tryParse(_portController.text) ?? 5432,
                      database: _dbController.text,
                      username: _userController.text,
                      password: _passwordController.text,
                      filePath: _type == DatabaseType.sqlite
                          ? _dbController.text
                          : null,
                    );

                    // Test connection before saving
                    try {
                      // Create adapter and test connection
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
                        case DatabaseType.mssql:
                          adapter = MssqlAdapter(config);
                          break;
                      }

                      await adapter.connect();
                      await adapter.disconnect();

                      // Connection successful, save it
                      ref
                          .read(connectionsProvider.notifier)
                          .addConnection(config);

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Connection successful!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        setState(() {
                          _isTestingConnection = false;
                          _connectionError = 'Connection failed: $e';
                        });
                      }
                    }
                  }
                },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
