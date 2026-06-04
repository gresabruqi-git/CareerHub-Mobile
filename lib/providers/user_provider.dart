import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

/// User profile data model
class UserProfile {
  final String name;
  final String? email;
  final String? highestEducation;
  final List<String> careerInterests;
  final Map<String, dynamic>? questionnaireAnswers;

  const UserProfile({
    required this.name,
    this.email,
    this.highestEducation,
    this.careerInterests = const [],
    this.questionnaireAnswers,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      name: map['name'] as String? ?? 
            (map['email'] as String? ?? 'User').split('@').first,
      email: map['email'] as String?,
      highestEducation: map['highest_education'] as String?,
      careerInterests: (map['career_interests'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      questionnaireAnswers: map['questionnaire_answers'] as Map<String, dynamic>?,
    );
  }
}

/// State Notifier for managing user profile state
class UserProfileNotifier extends StateNotifier<AsyncValue<UserProfile>> {
  final SupabaseService _supabaseService;

  UserProfileNotifier(this._supabaseService)
      : super(const AsyncValue.loading());

  /// Load user profile from Supabase
  Future<void> loadProfileFromSupabase() async {
    state = const AsyncValue.loading();
    try {
      final profileData = await _supabaseService.getUserProfile();
      if (profileData != null) {
        final profile = UserProfile.fromMap(profileData);
        state = AsyncValue.data(profile);
      } else {
        // Create default profile if none exists
        final user = Supabase.instance.client.auth.currentUser;
        final defaultProfile = UserProfile(
          name: user?.email?.split('@').first ?? 'User',
          email: user?.email,
        );
        state = AsyncValue.data(defaultProfile);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Update user profile and sync with Supabase
  Future<void> updateProfile({required UserProfile newProfile}) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await Supabase.instance.client.from('profiles').upsert({
        'id': userId,
        'highest_education': newProfile.highestEducation,
        'career_interests': newProfile.careerInterests,
        'updated_at': DateTime.now().toIso8601String(),
      });

      state = AsyncValue.data(newProfile);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

/// Provider for SupabaseService
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  final supabase = Supabase.instance.client;
  return SupabaseService(supabase);
});

/// Provider for UserProfileNotifier
final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, AsyncValue<UserProfile>>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return UserProfileNotifier(supabaseService);
});

/// Provider for sidebar open/close state
final sidebarOpenProvider = StateProvider<bool>((ref) => false);
