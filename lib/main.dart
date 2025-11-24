import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sql_client/core/router.dart';
import 'package:flutter_sql_client/core/theme/app_theme.dart';

import 'package:flutter_sql_client/core/data/objectbox.dart';
import 'package:flutter_sql_client/features/connections/data/connection_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final objectBox = await ObjectBox.create();

  runApp(
    ProviderScope(
      overrides: [objectBoxProvider.overrideWithValue(objectBox)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SQL Client',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
