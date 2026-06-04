import 'package:supabase_flutter/supabase_flutter.dart';

/// Sealed class to handle all authentication outcomes
sealed class AuthResult {
  const AuthResult();
}

/// Success state with authenticated user
final class AuthResultSuccess extends AuthResult {
  final User user;
  const AuthResultSuccess(this.user);
}

/// Authentication error (invalid credentials, etc.)
final class AuthResultAuthError extends AuthResult {
  final String message;
  const AuthResultAuthError(this.message);
}

/// Network or connection error
final class AuthResultNetworkError extends AuthResult {
  final String message;
  const AuthResultNetworkError(this.message);
}

/// Abstract contract for authentication repository
abstract class AuthRepository {
  /// Sign in with email and password
  Future<AuthResult> signIn({
    required String email,
    required String password,
  });

  /// Sign up with email and password
  /// Upon successful sign-up, creates a profile entry in the profiles table
  Future<AuthResult> signUp({
    required String email,
    required String password,
  });

  /// Sign out the current user
  Future<void> signOut();

  /// Stream of current authenticated user
  Stream<User?> getCurrentUser();
}

/// Supabase implementation of AuthRepository
class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _supabase;

  SupabaseAuthRepository(this._supabase);

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Normalize email: trim and convert to lowercase
      final normalizedEmail = email.trim().toLowerCase();
      
      // Debug logging (remove in production)
      print('Attempting sign in with email: $normalizedEmail');
      
      final response = await _supabase.auth.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );

      if (response.user != null) {
        // Only check email confirmation if it's actually required by Supabase
        // Some Supabase projects have email confirmation disabled
        // The actual error from Supabase will handle this case
        print('Sign in successful for user: ${response.user!.email}');
        return AuthResultSuccess(response.user!);
      } else {
        return const AuthResultAuthError('Sign in failed: No user returned');
      }
    } on AuthException catch (e) {
      // Debug: Print the actual error for troubleshooting
      print('AuthException: ${e.message}');
      print('Error code: ${e.statusCode}');
      
      // Provide more user-friendly error messages
      String errorMessage = e.message;
      final lowerMessage = e.message.toLowerCase();
      
      if (lowerMessage.contains('invalid login credentials') ||
          lowerMessage.contains('invalid credentials') ||
          lowerMessage.contains('invalid_grant')) {
        errorMessage = 'Invalid email or password. Please check your credentials and try again.';
      } else if (lowerMessage.contains('email not confirmed') ||
          lowerMessage.contains('email_not_confirmed')) {
        errorMessage = 'Please confirm your email address before signing in. Check your inbox for a confirmation email.';
      } else if (lowerMessage.contains('user not found') ||
          lowerMessage.contains('no user found')) {
        errorMessage = 'No account found with this email address. Please sign up first.';
      } else if (lowerMessage.contains('too many requests')) {
        errorMessage = 'Too many sign-in attempts. Please wait a moment and try again.';
      }
      
      return AuthResultAuthError(errorMessage);
    } catch (e, stackTrace) {
      print('Unexpected error during sign in: $e');
      print('Stack trace: $stackTrace');
      return AuthResultNetworkError(
        e.toString().contains('network') || e.toString().contains('connection')
            ? 'Network error: Please check your connection'
            : 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  @override
  Future<AuthResult> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final response = await _supabase.auth.signUp(
        email: normalizedEmail,
        password: password,
      );

      if (response.user != null) {
        final userId = response.user!.id;

        // CRITICAL: Immediately insert into profiles table after sign-up
        try {
          await _supabase.from('profiles').insert({
            'id': userId,
            'highest_education': null,
            'career_interests': <String>[],
          });
        } catch (profileError) {
          // If profile creation fails, we should still return success
          // but log the error. In production, you might want to handle this differently.
          // For now, we'll return success since the user was created.
          // You could also delete the user here if profile creation is critical.
          print('Warning: Failed to create profile: $profileError');
        }

        return AuthResultSuccess(response.user!);
      } else {
        return const AuthResultAuthError('Sign up failed: No user returned');
      }
    } on AuthException catch (e) {
      return AuthResultAuthError(e.message);
    } catch (e) {
      return AuthResultNetworkError(
        e.toString().contains('network') || e.toString().contains('connection')
            ? 'Network error: Please check your connection'
            : 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      // Log error but don't throw - sign out should be best effort
      print('Error during sign out: $e');
      rethrow;
    }
  }

  @override
  Stream<User?> getCurrentUser() {
    return _supabase.auth.onAuthStateChange.map((event) => event.session?.user);
  }
}

