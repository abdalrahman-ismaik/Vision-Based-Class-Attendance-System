import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'router/auth_router.dart';

class HadirApp extends ConsumerWidget {
  const HadirApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'HADIR Mobile - Full Version',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: simpleRouter, // Use simple router for now
      debugShowCheckedModeBanner: false,
    );
  }
}

