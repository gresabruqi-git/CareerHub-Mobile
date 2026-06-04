import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../providers/user_provider.dart';
import '../screens/home_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/career_assessment_test_screen.dart';
import '../screens/career_recommendations_screen.dart';
import '../screens/skills_to_improve_screen.dart';
import '../screens/discover_screen.dart';

/// Reusable sidebar widget with profile and navigation
class AppSidebar extends ConsumerStatefulWidget {
  final String currentScreen; // 'home', 'profile', 'dashboard', etc.
  final VoidCallback? onProfilePhotoTap;

  const AppSidebar({
    super.key,
    required this.currentScreen,
    this.onProfilePhotoTap,
  });

  @override
  ConsumerState<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends ConsumerState<AppSidebar> {
  String _userName = 'User';
  String? _profilePhotoUrl;
  String? _selectedCareerField;
  List<String> _careerInterests = [];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final supabaseService = ref.read(supabaseServiceProvider);
      
      final userProfile = await supabaseService.getUserProfile();
      if (userProfile != null) {
        setState(() {
          _userName = (userProfile['name'] as String?) ?? 
                      (userProfile['email'] as String? ?? 'User').split('@').first;
          _profilePhotoUrl = userProfile['profile_photo_url'] as String?;
          _careerInterests = (userProfile['career_interests'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ?? [];
        });
      } else {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null && user.email != null) {
          setState(() {
            _userName = user.email!.split('@').first;
          });
        }
      }

      final userAnswers = await supabaseService.getUserAnswers();
      if (userAnswers != null) {
        setState(() {
          _selectedCareerField = userAnswers['selected_career_field'] as String?;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _showImagePickerOptions() async {
    if (widget.onProfilePhotoTap != null) {
      widget.onProfilePhotoTap!();
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Change Profile Photo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF00D9FF)),
                title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProfileScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.white70),
                title: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String subtitle = 'Career Enthusiast';
    if (_careerInterests.isNotEmpty) {
      subtitle = _careerInterests.first;
    } else if (_selectedCareerField != null) {
      subtitle = _selectedCareerField!;
    }

    return Container(
      width: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF2A2A3E), // Darker brown/grey at top
            const Color(0xFF3A3A4E), // Medium
            const Color(0xFFE8E8E0), // Lighter beige at bottom
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // User Profile Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: _showImagePickerOptions,
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D9FF).withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF00D9FF),
                          width: 2,
                        ),
                      ),
                      child: _profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                _profilePhotoUrl!,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Text(
                                      _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF00D9FF),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : Center(
                              child: Text(
                                _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00D9FF),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Navigation Menu Items
            Expanded(
              child: Column(
                children: [
                  _buildNavItem(
                    icon: Icons.home,
                    label: 'Home',
                    screenName: 'home',
                    onTap: () {
                      Navigator.of(context).pop(); // Close drawer
                      if (widget.currentScreen != 'home') {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const HomeScreen(),
                          ),
                          (route) => false, // Remove all previous routes
                        );
                      }
                    },
                  ),
                  _buildNavItem(
                    icon: Icons.quiz,
                    label: 'Career Quiz / Assessment',
                    screenName: 'quiz',
                    onTap: () {
                      Navigator.of(context).pop(); // Close drawer
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CareerAssessmentTestScreen(),
                        ),
                      );
                    },
                  ),
                  _buildNavItem(
                    icon: Icons.school,
                    label: 'Skills / Learning Paths',
                    screenName: 'skills',
                    onTap: () {
                      Navigator.of(context).pop(); // Close drawer
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SkillsToImproveScreen(),
                        ),
                      );
                    },
                  ),
                  _buildNavItem(
                    icon: Icons.explore,
                    label: 'Discover',
                    screenName: 'discover',
                    onTap: () {
                      Navigator.of(context).pop(); // Close drawer
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const DiscoverScreen(),
                        ),
                      );
                    },
                  ),
                  _buildNavItem(
                    icon: Icons.person,
                    label: 'Profile / Account',
                    screenName: 'profile',
                    onTap: () {
                      Navigator.of(context).pop(); // Close drawer
                      if (widget.currentScreen != 'profile') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            // Feedback Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: TextButton(
                onPressed: () {
                  // Handle feedback
                },
                child: const Text(
                  'Feedback',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required String screenName,
    required VoidCallback onTap,
  }) {
    final isSelected = widget.currentScreen == screenName;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.8),
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.8),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

