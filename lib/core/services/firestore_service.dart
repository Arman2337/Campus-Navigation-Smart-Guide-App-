import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/user_model.dart';
import '../../models/location_model.dart';
import '../../models/announcement_model.dart';
import '../utils/location_utils.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ──────────────── USERS ────────────────

  Future<void> createUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  // ──────────────── LOCATIONS ────────────────

  Future<List<LocationModel>> getAllLocations() async {
    final snapshot = await _db.collection('locations').get();
    return snapshot.docs
        .map((doc) => LocationModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Stream<List<LocationModel>> locationsStream() {
    return _db.collection('locations').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => LocationModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<LocationModel?> getLocationById(String id) async {
    final doc = await _db.collection('locations').doc(id).get();
    if (!doc.exists) return null;
    return LocationModel.fromMap(doc.data()!, doc.id);
  }

  /// Get nearby locations within a radius (client-side filter)
  Future<List<LocationModel>> getNearbyLocations(
    double lat,
    double lng,
    double radiusKm,
  ) async {
    final all = await getAllLocations();
    return LocationUtils.filterByRadius(
      locations: all,
      userPosition: LatLng(lat, lng),
      radiusKm: radiusKm,
      getLat: (l) => l.latitude,
      getLng: (l) => l.longitude,
    );
  }

  /// Search locations by name/tag (prefix search)
  Future<List<LocationModel>> searchLocations({
    required String query,
    String? category,
  }) async {
    final all = await getAllLocations();
    final q = query.toLowerCase();
    return all.where((loc) {
      final matchesQuery = q.isEmpty ||
          loc.name.toLowerCase().contains(q) ||
          loc.building.toLowerCase().contains(q) ||
          loc.description.toLowerCase().contains(q) ||
          loc.tags.any((tag) => tag.toLowerCase().contains(q));

      final matchesCategory =
          category == null || category.isEmpty || category == 'All'
              ? true
              : loc.category.toLowerCase() == category.toLowerCase();

      return matchesQuery && matchesCategory;
    }).toList();
  }

  Future<void> addLocation(LocationModel location) async {
    final docRef = _db.collection('locations').doc();
    await docRef.set(location.copyWith(id: docRef.id).toMap());
  }

  Future<void> deleteLocation(String locationId) async {
    await _db.collection('locations').doc(locationId).delete();
  }

  // ──────────────── SAVED LOCATIONS ────────────────

  Future<void> saveLocation(String uid, String locationId) async {
    await _db.collection('users').doc(uid).update({
      'savedLocations': FieldValue.arrayUnion([locationId]),
    });
  }

  Future<void> removeSavedLocation(String uid, String locationId) async {
    await _db.collection('users').doc(uid).update({
      'savedLocations': FieldValue.arrayRemove([locationId]),
    });
  }

  Future<List<LocationModel>> getSavedLocations(String uid) async {
    final userDoc = await _db.collection('users').doc(uid).get();
    if (!userDoc.exists) return [];
    final data = userDoc.data()!;
    final savedIds = List<String>.from(data['savedLocations'] ?? []);
    if (savedIds.isEmpty) return [];

    final futures = savedIds.map((id) => getLocationById(id));
    final results = await Future.wait(futures);
    return results.whereType<LocationModel>().toList();
  }

  // ──────────────── ANNOUNCEMENTS ────────────────

  Future<List<AnnouncementModel>> getAnnouncements() async {
    final snapshot = await _db
        .collection('announcements')
        .orderBy('timestamp', descending: true)
        .limit(5)
        .get();
    return snapshot.docs
        .map((doc) => AnnouncementModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Stream<List<AnnouncementModel>> announcementsStream() {
    return _db
        .collection('announcements')
        .orderBy('timestamp', descending: true)
        .limit(3)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AnnouncementModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}
