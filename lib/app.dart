import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'core/constants/app_routes.dart';
import 'core/theme/app_theme.dart';

class GarageApp extends HookConsumerWidget {
  const GarageApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    
    return MaterialApp.router(
      title: 'Taller Integrale\$',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}

