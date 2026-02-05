import 'package:flutter/material.dart';
import '../models/app_user.dart';

class SupabaseService extends ChangeNotifier {
  bool _isAuthenticated = false;
  AppUser? _currentUser;

  bool get isAuthenticated => _isAuthenticated;
  AppUser? get currentUser => _currentUser;

  SupabaseService() {
    _initializeMockUser();
  }

  void _initializeMockUser() {
    _isAuthenticated = true;
    _currentUser = AppUser(
      id: 'mock-user-id',
      email: 'test@example.com',
      displayName: 'John Doe',
      profilePhotoUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> getCurrentSession() async {
    await Future.delayed(const Duration(milliseconds: 500));
    notifyListeners();
  }

  Future<void> signIn({required String email, required String password}) async {
    await Future.delayed(const Duration(seconds: 1));

    _isAuthenticated = true;
    _currentUser = AppUser(
      id: 'mock-user-id',
      email: email,
      displayName: email.split('@').first,
      profilePhotoUrl: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    _isAuthenticated = true;
    _currentUser = AppUser(
      id: 'new-mock-user-id',
      email: email,
      displayName: displayName,
      profilePhotoUrl: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _isAuthenticated = false;
    _currentUser = null;
    notifyListeners();
  }

  Future<void> updateProfile({
    String? displayName,
    String? profilePhotoUrl,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    if (_currentUser != null) {
      _currentUser = AppUser(
        id: _currentUser!.id,
        email: _currentUser!.email,
        displayName: displayName ?? _currentUser!.displayName,
        profilePhotoUrl: profilePhotoUrl ?? _currentUser!.profilePhotoUrl,
        createdAt: _currentUser!.createdAt,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }
}
