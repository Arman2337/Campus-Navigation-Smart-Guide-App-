import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/location_model.dart';

class CacheService {
  static const String _locationsKey = 'cached_locations';
  static const String _cacheTimestampKey = 'cache_timestamp';
  static const Duration _cacheExpiry = Duration(hours: 24);

  final Connectivity _connectivity = Connectivity();

  /// Check if device has internet connectivity
  Future<bool> hasInternetConnection() async {
    final result = await _connectivity.checkConnectivity();
    return result.any((r) => r != ConnectivityResult.none);
  }

  /// Stream of connectivity changes
  Stream<List<ConnectivityResult>> get connectivityStream =>
      _connectivity.onConnectivityChanged;

  /// Cache locations to SharedPreferences
  Future<void> cacheLocations(List<LocationModel> locations) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(locations.map((l) => l.toMap()).toList());
    await prefs.setString(_locationsKey, encoded);
    await prefs.setInt(
      _cacheTimestampKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Get cached locations from SharedPreferences
  Future<List<LocationModel>> getCachedLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_locationsKey);
    if (encoded == null) return [];

    try {
      final decoded = jsonDecode(encoded) as List;
      return decoded
          .map((item) => LocationModel.fromMap(
                item as Map<String, dynamic>,
                (item as Map<String, dynamic>)['id'] as String? ?? '',
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Check if cache is still valid (not expired)
  Future<bool> isCacheValid() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_cacheTimestampKey);
    if (timestamp == null) return false;
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().difference(cacheTime) < _cacheExpiry;
  }

  /// Clear location cache
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_locationsKey);
    await prefs.remove(_cacheTimestampKey);
  }

  // ──────────────── RECENT SEARCHES ────────────────

  static const String _recentSearchesKey = 'recent_searches';
  static const int _maxRecentSearches = 10;

  Future<List<String>> getRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentSearchesKey) ?? [];
  }

  Future<void> addRecentSearch(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final searches = prefs.getStringList(_recentSearchesKey) ?? [];
    searches.remove(query); // Remove if already exists
    searches.insert(0, query); // Add to front
    if (searches.length > _maxRecentSearches) {
      searches.removeLast();
    }
    await prefs.setStringList(_recentSearchesKey, searches);
  }

  Future<void> clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentSearchesKey);
  }

  // ──────────────── THEME PREFERENCE ────────────────
  static const String _themeModeKey = 'theme_mode';

  Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeModeKey) ?? false;
  }

  Future<void> setDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeModeKey, isDark);
  }

  // ──────────────── ONBOARDING ────────────────
  static const String _onboardingKey = 'onboarding_completed';

  Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> setOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }
}
