import 'package:go_router/go_router.dart';
import 'package:flutter_sql_client/features/connections/presentation/connections_screen.dart';
import 'package:flutter_sql_client/features/query/presentation/workspace_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const ConnectionsScreen()),
    GoRoute(
      path: '/workspace/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return WorkspaceScreen(connectionId: id);
      },
    ),
  ],
);
