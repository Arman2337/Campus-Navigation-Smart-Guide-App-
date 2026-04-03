import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../core/services/firestore_service.dart';
import '../core/services/cache_service.dart';
import '../core/utils/location_utils.dart';
import '../models/location_model.dart';
import '../models/announcement_model.dart';

class LocationProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final CacheService _cacheService = CacheService();

  List<LocationModel> _allLocations = [];
  List<LocationModel> _filteredLocations = [];
  List<LocationModel> _nearbyLocations = [];
  List<LocationModel> _savedLocations = [];
  List<AnnouncementModel> _announcements = [];
  String _selectedCategory = 'All';
  bool _isLoading = false;
  bool _isOffline = false;
  String? _error;

  List<LocationModel> get allLocations => _allLocations;
  List<LocationModel> get filteredLocations => _filteredLocations;
  List<LocationModel> get nearbyLocations => _nearbyLocations;
  List<LocationModel> get savedLocations => _savedLocations;
  List<AnnouncementModel> get announcements => _announcements;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  bool get isOffline => _isOffline;
  String? get error => _error;

  Future<void> fetchLocations({LatLng? userPosition}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final hasInternet = await _cacheService.hasInternetConnection();

    if (hasInternet) {
      try {
        _allLocations = await _firestoreService.getAllLocations();
        await _cacheService.cacheLocations(_allLocations);
        _isOffline = false;
      } catch (e) {
        _error = e.toString();
        _allLocations = await _cacheService.getCachedLocations();
        _isOffline = true;
      }
    } else {
      _allLocations = await _cacheService.getCachedLocations();
      _isOffline = true;
    }

    _filteredLocations = _allLocations;

    if (userPosition != null) {
      _updateNearbyLocations(userPosition);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAnnouncements() async {
    try {
      _announcements = await _firestoreService.getAnnouncements();
      notifyListeners();
    } catch (_) {}
  }

  void filterByCategory(String category) {
    _selectedCategory = category;
    if (category == 'All') {
      _filteredLocations = _allLocations;
    } else {
      _filteredLocations = _allLocations
          .where((l) => l.category.toLowerCase() == category.toLowerCase())
          .toList();
    }
    notifyListeners();
  }

  Future<List<LocationModel>> searchLocations({
    required String query,
    String? category,
  }) async {
    if (query.isEmpty && (category == null || category == 'All')) {
      return _allLocations;
    }

    final hasInternet = await _cacheService.hasInternetConnection();

    if (hasInternet) {
      try {
        return await _firestoreService.searchLocations(
          query: query,
          category: category,
        );
      } catch (_) {}
    }

    // Fallback to in-memory search
    final q = query.toLowerCase();
    return _allLocations.where((loc) {
      final matchesQuery = q.isEmpty ||
          loc.name.toLowerCase().contains(q) ||
          loc.building.toLowerCase().contains(q) ||
          loc.tags.any((t) => t.toLowerCase().contains(q));

      final matchesCategory = category == null || category == 'All'
          ? true
          : loc.category.toLowerCase() == category.toLowerCase();

      return matchesQuery && matchesCategory;
    }).toList();
  }

  void _updateNearbyLocations(LatLng position) {
    _nearbyLocations = LocationUtils.filterByRadius(
      locations: _allLocations,
      userPosition: position,
      radiusKm: 0.5,
      getLat: (l) => l.latitude,
      getLng: (l) => l.longitude,
    );

    LocationUtils.sortByDistance(
      locations: _nearbyLocations,
      userPosition: position,
      getLat: (l) => l.latitude,
      getLng: (l) => l.longitude,
    );
  }

  Future<void> loadSavedLocations(String uid) async {
    try {
      _savedLocations = await _firestoreService.getSavedLocations(uid);
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> saveLocation(String uid, String locationId) async {
    try {
      await _firestoreService.saveLocation(uid, locationId);
      await loadSavedLocations(uid);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeSavedLocation(String uid, String locationId) async {
    try {
      await _firestoreService.removeSavedLocation(uid, locationId);
      _savedLocations.removeWhere((l) => l.id == locationId);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  bool isLocationSaved(String uid, String locationId) {
    return _savedLocations.any((l) => l.id == locationId);
  }

  void updateUserPosition(LatLng position) {
    _updateNearbyLocations(position);
    notifyListeners();
  }
}
