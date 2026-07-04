import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/themes/app_theme.dart';
import 'routes/app_router.dart';

// NOTE: Firebase.initializeApp() will be added here once the Firebase
// project is created (Module: Firebase wiring). Until then, the app runs
// fully against MockAuthService so the UI can be built and tested now.
void main() {
  runApp(const ProviderScope(child: QuickMarbleApp()));
}

class QuickMarbleApp extends ConsumerWidget {
  const QuickMarbleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Quick Marble & Granite',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
