import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/themes/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_router.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    authState.whenData((user) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.go(user != null ? AppRoutes.dashboard : AppRoutes.login);
      });
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.jpg',
              width: 220,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.diamond_outlined,
                color: AppColors.green,
                size: 96,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: AppColors.green),
          ],
        ),
      ),
    );
  }
}
