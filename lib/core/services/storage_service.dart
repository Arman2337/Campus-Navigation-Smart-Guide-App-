import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  /// Upload profile photo and return download URL
  Future<String> uploadProfilePhoto(String uid, File file) async {
    try {
      final ext = file.path.split('.').last;
      final ref = _storage.ref().child('profile_photos/$uid.$ext');
      final uploadTask = await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/$ext'),
      );
      return await uploadTask.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw Exception('Failed to upload photo: ${e.message}');
    }
  }

  /// Upload location image and return download URL
  Future<String> uploadLocationImage(String locationId, File file) async {
    try {
      final ext = file.path.split('.').last;
      final fileName = '${locationId}_${_uuid.v4()}.$ext';
      final ref = _storage.ref().child('location_images/$fileName');
      final uploadTask = await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/$ext'),
      );
      return await uploadTask.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw Exception('Failed to upload image: ${e.message}');
    }
  }

  /// Upload floor plan and return download URL
  Future<String> uploadFloorPlan(String locationId, File file) async {
    try {
      final ext = file.path.split('.').last;
      final ref =
          _storage.ref().child('floor_plans/${locationId}_plan.$ext');
      final uploadTask = await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/$ext'),
      );
      return await uploadTask.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw Exception('Failed to upload floor plan: ${e.message}');
    }
  }

  /// Delete a file from storage by URL
  Future<void> deleteFile(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } on FirebaseException catch (_) {
      // Silently handle if file doesn't exist
    }
  }
}
