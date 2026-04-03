import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/cache_service.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'providers/auth_provider.dart';

class UniNavApp extends StatefulWidget {
  const UniNavApp({super.key});

  @override
  State<UniNavApp> createState() => _UniNavAppState();
}

class _UniNavAppState extends State<UniNavApp> {
  final CacheService _cacheService = CacheService();
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final isDark = await _cacheService.getDarkMode();
    if (mounted) {
      setState(() => _isDarkMode = isDark);
    }
  }

  void toggleTheme(bool isDark) async {
    setState(() => _isDarkMode = isDark);
    await _cacheService.setDarkMode(isDark);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final router = AppRouter.createRouter(authProvider);

    return MaterialApp.router(
      title: 'UniNav',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
    );
  }
}
