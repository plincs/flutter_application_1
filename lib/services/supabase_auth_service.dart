import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user.dart';

class AppAuthState {
  final bool isLoading;
  final AppUser? user;

  const AppAuthState({required this.isLoading, this.user});
}

class SupabaseAuthService {
  final _supabase = Supabase.instance.client;

  Stream<AppAuthState> get authStateChanges async* {
    yield const AppAuthState(isLoading: true);

    // Get initial session
    final session = _supabase.auth.currentSession;
    AppUser? user;

    if (session != null) {
      user = await _getUserProfile(session.user.id);
    }

    yield AppAuthState(isLoading: false, user: user);

    // Listen for auth changes
    await for (final authState in _supabase.auth.onAuthStateChange) {
      if (authState.session != null) {
        final profile = await _getUserProfile(authState.session!.user.id);
        yield AppAuthState(isLoading: false, user: profile);
      } else {
        yield const AppAuthState(isLoading: false, user: null);
      }
    }
  }

  Future<AppUser?> _getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single()
          .timeout(const Duration(seconds: 5));

      return AppUser.fromJson(response);
        } catch (e) {
      print('Error getting user profile: $e');

      // If profile doesn't exist, create one from auth data
      final user = _supabase.auth.currentUser;
      if (user != null) {
        return AppUser(
          id: user.id,
          email: user.email!,
          displayName:
              user.userMetadata?['full_name'] ?? user.email!.split('@').first,
          profilePhotoUrl: user.userMetadata?['avatar_url'],
          createdAt: DateTime.parse(user.createdAt),
          updatedAt: DateTime.now(),
        );
      }
    }
    return null;
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // Sign up with Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': displayName},
      );

      if (response.user != null) {
        // Create user profile in users table
        await _supabase.from('users').insert({
          'id': response.user!.id,
          'email': email,
          'display_name': displayName,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Sign up error: $e');
      rethrow;
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      print('Sign in error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }

  Future<void> updateProfile({
    String? displayName,
    String? profilePhotoUrl,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final updates = <String, dynamic>{};
      if (displayName != null) {
        updates['display_name'] = displayName;
        // Also update in auth metadata
        await _supabase.auth.updateUser(
          UserAttributes(data: {'full_name': displayName}),
        );
      }
      if (profilePhotoUrl != null) {
        updates['profile_photo_url'] = profilePhotoUrl;
      }
      updates['updated_at'] = DateTime.now().toIso8601String();

      if (updates.isNotEmpty) {
        await _supabase.from('users').update(updates).eq('id', user.id);
      }
    } catch (e) {
      print('Update profile error: $e');
      rethrow;
    }
  }
}
