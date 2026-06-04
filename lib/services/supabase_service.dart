import 'package:supabase_flutter/supabase_flutter.dart';

/// Service class for Supabase integration
class SupabaseService {
  final SupabaseClient _supabase;

  SupabaseService(this._supabase);

  /// Initialize the service
  /// TODO: Add initialization logic
  Future<void> initialize() async {
    // TODO: Implement
  }

  /// Get the current user's profile from Supabase
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      // Get profile from profiles table
      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      // Get user metadata from auth for name/email
      final user = _supabase.auth.currentUser;
      final userData = <String, dynamic>{};
      
      if (profile != null) {
        userData.addAll(Map<String, dynamic>.from(profile));
      }
      
      // Add name from email or user metadata
      if (user?.email != null) {
        userData['email'] = user!.email;
        // Extract name from email if no name in profile
        if (userData['name'] == null || (userData['name'] as String).isEmpty) {
          userData['name'] = user.email!.split('@').first;
        }
      }
      
      // Add name from user metadata if available
      if (user?.userMetadata?['name'] != null) {
        userData['name'] = user!.userMetadata!['name'];
      }

      return userData.isEmpty ? null : userData;
    } catch (e) {
      return null;
    }
  }

  /// Save user answers/assessment data to Supabase
  Future<void> saveUserAnswers({required Map<String, dynamic> answers}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Save to profiles table or create a separate user_answers table
      // For now, we'll store it in profiles table as JSON
      await _supabase.from('profiles').update({
        'questionnaire_answers': answers,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      throw Exception('Failed to save answers: $e');
    }
  }

  /// Get user's questionnaire answers
  Future<Map<String, dynamic>?> getUserAnswers() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final profile = await _supabase
          .from('profiles')
          .select('questionnaire_answers')
          .eq('id', userId)
          .single();

      return profile['questionnaire_answers'] as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  /// Fetch all career paths from Supabase
  Future<List<Map<String, dynamic>>> fetchCareerData() async {
    try {
      final response = await _supabase
          .from('career_paths')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Get most saved careers (aggregated across all users)
  Future<List<Map<String, dynamic>>> getMostSavedCareers({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('saved_careers')
          .select('job_title, sector, salary_range')
          .limit(1000); // Get a large sample
      
      // Count occurrences
      final careerCounts = <String, Map<String, dynamic>>{};
      for (var career in response) {
        final title = career['job_title'] as String? ?? '';
        if (title.isNotEmpty) {
          if (careerCounts.containsKey(title)) {
            careerCounts[title]!['count'] = (careerCounts[title]!['count'] as int) + 1;
          } else {
            careerCounts[title] = {
              'job_title': title,
              'sector': career['sector'],
              'salary_range': career['salary_range'],
              'count': 1,
            };
          }
        }
      }
      
      // Sort by count and return top N
      final sorted = careerCounts.values.toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
      
      return sorted.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetch skills data from Supabase
  /// TODO: Implement fetching skills data from the database
  Future<List<Map<String, dynamic>>> fetchSkillsData() async {
    // TODO: Implement
    return [];
  }

  /// Save a career to user's saved careers list
  Future<void> saveCareer({
    required String jobTitle,
    String? sector,
    int? matchScore,
    String? whyItFits,
    List<String>? skillsYouHave,
    List<String>? skillsToLearn,
    List<String>? learningPath,
    String? salaryRange,
    String? futureDemand,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase.from('saved_careers').insert({
        'user_id': userId,
        'job_title': jobTitle,
        'sector': sector,
        'match_score': matchScore,
        'why_it_fits': whyItFits,
        'skills_you_have': skillsYouHave ?? [],
        'skills_to_learn': skillsToLearn ?? [],
        'learning_path': learningPath ?? [],
        'salary_range': salaryRange,
        'future_demand': futureDemand,
      });
    } catch (e) {
      // If it's a unique constraint violation, the career is already saved
      if (e.toString().contains('unique') || e.toString().contains('duplicate')) {
        throw Exception('This career is already saved');
      }
      throw Exception('Failed to save career: $e');
    }
  }

  /// Get all saved careers for the current user
  Future<List<Map<String, dynamic>>> getSavedCareers() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('saved_careers')
          .select()
          .eq('user_id', userId)
          .order('saved_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Remove a saved career
  Future<void> removeSavedCareer(String jobTitle) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase
          .from('saved_careers')
          .delete()
          .eq('user_id', userId)
          .eq('job_title', jobTitle);
    } catch (e) {
      throw Exception('Failed to remove saved career: $e');
    }
  }

  /// Check if a career is already saved
  Future<bool> isCareerSaved(String jobTitle) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .from('saved_careers')
          .select('id')
          .eq('user_id', userId)
          .eq('job_title', jobTitle)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }
}
