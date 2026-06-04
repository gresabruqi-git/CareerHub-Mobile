import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/user_provider.dart';
import '../../services/supabase_service.dart';
import '../widgets/app_sidebar.dart';
import 'career_assessment_test_screen.dart';
import 'career_recommendations_screen.dart';
import 'skills_to_improve_screen.dart';
import 'saved_careers_screen.dart';

/// Personal Dashboard Screen - Clean and Modern Design
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isLoading = true;
  String _userName = 'User';
  int _savedCareersCount = 0;
  int _skillsUnlocked = 0;
  int _profileCompletion = 0;
  List<String> _topStrengths = [];
  List<Map<String, dynamic>> _savedCareers = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  /// Remove a saved career
  Future<void> _removeCareer(String jobTitle) async {
    try {
      final supabaseService = ref.read(supabaseServiceProvider);
      await supabaseService.removeSavedCareer(jobTitle);
      await _loadDashboardData(); // Reload to refresh the list
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$jobTitle removed from saved careers'),
            backgroundColor: const Color(0xFF00D9FF),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove career: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Show delete confirmation dialog
  Future<void> _showDeleteConfirmation(String jobTitle) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Remove Career?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to remove "$jobTitle" from your saved careers?',
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _removeCareer(jobTitle);
    }
  }

  /// Calculate top strengths from saved careers and user answers
  List<String> _calculateTopStrengths(
    List<Map<String, dynamic>> savedCareers,
    Map<String, dynamic>? userAnswers,
  ) {
    final strengthCounts = <String, int>{};

    // Count skills from saved careers' skills_you_have
    for (var career in savedCareers) {
      final skillsYouHave = career['skills_you_have'] as List<dynamic>?;
      if (skillsYouHave != null) {
        for (var skill in skillsYouHave) {
          final skillStr = skill.toString();
          strengthCounts[skillStr] = (strengthCounts[skillStr] ?? 0) + 1;
        }
      }
    }

    // Also include skills from current_skills in user answers
    if (userAnswers != null) {
      final currentSkills = userAnswers['current_skills'] as List<dynamic>? ?? [];
      for (var skill in currentSkills) {
        final skillStr = skill.toString();
        strengthCounts[skillStr] = (strengthCounts[skillStr] ?? 0) + 2; // Weight higher
      }
    }

    // Sort by count and get top 3
    if (strengthCounts.isNotEmpty) {
      final sortedStrengths = strengthCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return sortedStrengths.take(3).map((e) => e.key).toList();
    }

    // Fallback to current_skills if no saved careers
    if (userAnswers != null) {
      final skills = userAnswers['current_skills'] as List<dynamic>? ?? [];
      return skills.take(3).map((s) => s.toString()).toList();
    }

    return [];
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get Supabase service
      final supabaseService = ref.read(supabaseServiceProvider);
      
      // Get user profile from Supabase
      final userProfile = await supabaseService.getUserProfile();
      
      if (userProfile != null && userProfile['name'] != null) {
        _userName = (userProfile['name'] as String).split(' ').first;
      } else {
        // Fallback to email
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null && user.email != null) {
          _userName = user.email!.split('@').first;
        }
      }

      // Get saved careers
      final savedCareers = await supabaseService.getSavedCareers();
      _savedCareersCount = savedCareers.length;
      _savedCareers = savedCareers; // Store all for display

      // Check onboarding completion
      int onboardingScore = 0;
      if (userProfile != null) {
        if (userProfile['highest_education'] != null && 
            (userProfile['highest_education'] as String).isNotEmpty) {
          onboardingScore += 1;
        }
        if (userProfile['career_interests'] != null && 
            (userProfile['career_interests'] as List).isNotEmpty) {
          onboardingScore += 1;
        }
      }

      // Get user answers to calculate profile completion and skills
      final userAnswers = await supabaseService.getUserAnswers();
      int assessmentScore = 0;
      int totalAssessmentFields = 0;
      
      if (userAnswers != null) {
        // Core assessment fields (weighted)
        final fields = {
          'selected_career_field': 2, // Important field
          'field_specific_answers': 1, // Count as 1 if exists (not per answer)
          'current_skills': 2, // Important
          'skill_level': 1,
          'work_preference': 1,
          'career_type': 1,
          'long_term_goal': 1,
          'learning_time': 1,
        };

        for (var entry in fields.entries) {
          totalAssessmentFields += entry.value;
          final fieldValue = userAnswers[entry.key];
          
          if (fieldValue != null) {
            if (entry.key == 'field_specific_answers') {
              // Count as completed if map is not empty
              if (fieldValue is Map && fieldValue.isNotEmpty) {
                assessmentScore += entry.value;
              }
            } else if (fieldValue is List) {
              // Count as completed if list is not empty
              if (fieldValue.isNotEmpty) {
                assessmentScore += entry.value;
              }
            } else if (fieldValue is String) {
              // Count as completed if string is not empty
              if (fieldValue.isNotEmpty) {
                assessmentScore += entry.value;
              }
            } else {
              // Other types (numbers, booleans) count as completed
              assessmentScore += entry.value;
            }
          }
        }

        // Calculate skills unlocked from user answers
        final skills = userAnswers['current_skills'] as List<dynamic>? ?? [];
        final skillsFromAnswers = skills.map((s) => s.toString()).toSet();
        
        // Also count skills from saved careers' skills_you_have
        final allSkills = <String>{};
        allSkills.addAll(skillsFromAnswers);
        
        for (var career in _savedCareers) {
          final skillsYouHave = career['skills_you_have'] as List<dynamic>? ?? [];
          allSkills.addAll(skillsYouHave.map((s) => s.toString()));
        }
        
        _skillsUnlocked = allSkills.length;
      } else {
        // If no user answers, count from saved careers only
        final allSkills = <String>{};
        for (var career in _savedCareers) {
          final skillsYouHave = career['skills_you_have'] as List<dynamic>? ?? [];
          allSkills.addAll(skillsYouHave.map((s) => s.toString()));
        }
        _skillsUnlocked = allSkills.length;
      }

      // Calculate top strengths from saved careers
      _topStrengths = _calculateTopStrengths(_savedCareers, userAnswers);
      
      // Set default total if no answers
      if (userAnswers == null) {
        totalAssessmentFields = 10; // Default total if no answers
      }

      // Calculate total completion (onboarding + assessment)
      // Onboarding: 2 fields, Assessment: variable (max 10)
      int totalFields = 2 + totalAssessmentFields; // Onboarding (2) + Assessment
      int completedFields = onboardingScore + assessmentScore;
      
      _profileCompletion = totalFields > 0 
          ? ((completedFields / totalFields) * 100).round().clamp(0, 100)
          : 0;

    } catch (e) {
      // Handle error silently
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23), // Dark blue background
      drawer: const AppSidebar(currentScreen: 'dashboard'),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        leading: Builder(
          builder: (context) {
            // Show back button if we can pop, otherwise show menu
            final canPop = Navigator.of(context).canPop();
            if (canPop) {
              return IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              );
            } else {
              return IconButton(
                icon: const Icon(
                  Icons.menu,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            }
          },
        ),
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D9FF)),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadDashboardData,
                color: const Color(0xFF00D9FF),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Overview Section
                      _buildQuickOverview(),
                      const SizedBox(height: 24),

                      // Progress Box
                      _buildProgressBox(),
                      const SizedBox(height: 24),

                      // Quick Actions
                      _buildQuickActions(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildQuickOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00D9FF).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting + next steps summary
          Text(
            'Hello, $_userName! Your Next Steps',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pick an action below to continue your career journey.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 20),

          // Saved Careers
          if (_savedCareers.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Saved Careers',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF00D9FF),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SavedCareersScreen(),
                      ),
                    ).then((_) {
                      // Reload data when returning from saved careers screen
                      _loadDashboardData();
                    });
                  },
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF00D9FF),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._savedCareers.take(5).map((career) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B9D),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          career['job_title'] ?? 'Career',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      if (career['match_score'] != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            '${career['match_score']}%',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF00D9FF),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Colors.red,
                        ),
                        onPressed: () => _showDeleteConfirmation(career['job_title'] ?? 'Career'),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                )),
            if (_savedCareers.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SavedCareersScreen(),
                      ),
                    ).then((_) {
                      _loadDashboardData();
                    });
                  },
                  child: Text(
                    'View ${_savedCareers.length - 5} more...',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF00D9FF),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],

          // Top Strengths
          if (_topStrengths.isNotEmpty) ...[
            const Text(
              'Your Top Strengths',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF00D9FF),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _topStrengths.map((strength) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B9D).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFF6B9D).withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    strength,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFFF6B9D),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Continue Improving Skills Shortcut
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SkillsToImproveScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00D9FF).withOpacity(0.2),
                      const Color(0xFFFF6B9D).withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00D9FF).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.trending_up,
                      color: Color(0xFF00D9FF),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Continue improving skills',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Color(0xFF00D9FF),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00D9FF).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),

          // Profile Completion
          _buildProgressItem(
            icon: Icons.person,
            label: 'Profile Completed',
            value: '$_profileCompletion%',
            color: const Color(0xFF00D9FF),
            progress: _profileCompletion / 100,
          ),
          const SizedBox(height: 16),

          // Saved Careers Count
          _buildProgressItem(
            icon: Icons.bookmark,
            label: 'Saved Careers',
            value: '$_savedCareersCount',
            color: const Color(0xFFFF6B9D),
            progress: _savedCareersCount > 0 ? 1.0 : 0.0,
          ),
          const SizedBox(height: 16),

          // Skills Unlocked
          _buildProgressItem(
            icon: Icons.star,
            label: 'Skills Unlocked',
            value: '$_skillsUnlocked',
            color: const Color(0xFF00D9FF),
            progress: _skillsUnlocked > 0 
                ? (_skillsUnlocked / 20).clamp(0.0, 1.0) // Scale to 20 skills max
                : 0.0,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required double progress,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        _buildActionCard(
          icon: Icons.quiz,
          title: 'Take Assessment',
          description: 'Discover your ideal career path',
          color: const Color(0xFF00D9FF),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const CareerAssessmentTestScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          icon: Icons.trending_up,
          title: 'Improve Skills',
          description: 'Build skills for your career goals',
          color: const Color(0xFFFF6B9D),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const SkillsToImproveScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          icon: Icons.bookmark,
          title: 'View Saved Careers',
          description: 'See your saved career matches',
          color: const Color(0xFF00D9FF),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const SavedCareersScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

