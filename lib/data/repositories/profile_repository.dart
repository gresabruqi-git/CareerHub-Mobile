import 'package:supabase_flutter/supabase_flutter.dart';

/// Abstract contract for profile repository
abstract class ProfileRepository {
  /// Update user profile with highest education and career interests
  Future<void> updateProfile({
    required String userId,
    required String? highestEducation,
    required List<String> careerInterests,
  });

  /// Get user profile
  Future<Map<String, dynamic>?> getProfile(String userId);
}

/// Supabase implementation of ProfileRepository
class SupabaseProfileRepository implements ProfileRepository {
  final SupabaseClient _supabase;

  SupabaseProfileRepository(this._supabase);

  @override
  Future<void> updateProfile({
    required String userId,
    required String? highestEducation,
    required List<String> careerInterests,
  }) async {
    try {
      // Use upsert to create profile if it doesn't exist
      // Note: created_at will be set automatically by the database default
      // updated_at will be set automatically by the trigger
      await _supabase.from('profiles').upsert({
        'id': userId,
        'highest_education': highestEducation,
        'career_interests': careerInterests,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  @override
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }
}



