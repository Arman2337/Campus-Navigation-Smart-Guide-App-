import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/services/firebase_auth_service.dart';
import '../core/services/firestore_service.dart';
import '../core/services/storage_service.dart';
import '../models/user_model.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthProvider extends ChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _userModel;
  String? _errorMessage;
  bool _isLoading = false;

  AuthStatus get status => _status;
  UserModel? get userModel => _userModel;
  User? get firebaseUser => _authService.currentUser;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    _authService.authStateChanges.listen((user) async {
      if (user != null) {
        await _loadUserModel(user.uid);
        _status = AuthStatus.authenticated;
      } else {
        _userModel = null;
        _status = AuthStatus.unauthenticated;
      }
      notifyListeners();
    });
  }

  Future<void> _loadUserModel(String uid) async {
    try {
      _userModel = await _firestoreService.getUser(uid);
    } catch (_) {
      _userModel = null;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _clearError();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
    File? profilePhoto,
  }) async {
    _setLoading(true);
    try {
      final credential = await _authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
        displayName: name,
      );

      final uid = credential.user!.uid;
      String photoUrl = '';

      if (profilePhoto != null) {
        try {
          photoUrl = await _storageService.uploadProfilePhoto(uid, profilePhoto);
          await _authService.updatePhotoURL(photoUrl);
        } catch (_) {
          // Continue without photo if upload fails
        }
      }

      final userModel = UserModel(
        uid: uid,
        name: name,
        email: email,
        photoUrl: photoUrl,
        role: role,
        createdAt: DateTime.now(),
      );

      await _firestoreService.createUser(userModel);
      _userModel = userModel;
      _clearError();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> googleSignIn() async {
    _setLoading(true);
    try {
      final credential = await _authService.signInWithGoogle();
      final user = credential.user!;
      final existing = await _firestoreService.getUser(user.uid);

      if (existing == null) {
        final userModel = UserModel(
          uid: user.uid,
          name: user.displayName ?? '',
          email: user.email ?? '',
          photoUrl: user.photoURL ?? '',
          role: 'student',
          createdAt: DateTime.now(),
        );
        await _firestoreService.createUser(userModel);
        _userModel = userModel;
      } else {
        _userModel = existing;
      }

      _clearError();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    _setLoading(true);
    try {
      await _authService.sendPasswordResetEmail(email);
      _clearError();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
    _userModel = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> updateProfile({
    String? name,
    String? photoUrl,
  }) async {
    if (_userModel == null) return false;
    _setLoading(true);
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;

      await _firestoreService.updateUser(_userModel!.uid, updates);
      _userModel = _userModel!.copyWith(name: name, photoUrl: photoUrl);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshUserModel() async {
    if (firebaseUser == null) return;
    await _loadUserModel(firebaseUser!.uid);
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
