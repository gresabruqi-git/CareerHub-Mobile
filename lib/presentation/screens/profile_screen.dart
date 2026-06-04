import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/user_provider.dart';
import '../../services/supabase_service.dart';
import '../../data/repositories/profile_repository.dart';
import '../widgets/app_sidebar.dart';
import 'auth_screens.dart';
import 'onboarding_screen.dart';
import 'career_assessment_test_screen.dart';

/// Profile Screen - View and Edit User Profile
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isLoading = true;
  String _userName = 'User';
  String? _userEmail;
  String? _highestEducation;
  List<String> _careerInterests = [];
  int _savedCareersCount = 0;
  int _skillsUnlocked = 0;
  String? _selectedCareerField;
  bool _hasCompletedAssessment = false;
  String? _profilePhotoUrl;
  final ImagePicker _imagePicker = ImagePicker();

  // Education options
  final List<String> _educationOptions = [
    'High School',
    'Associate Degree',
    "Bachelor's Degree",
    "Master's Degree",
    'Doctorate',
    'Professional Certification',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final supabaseService = ref.read(supabaseServiceProvider);
      
      // Get user profile
      final userProfile = await supabaseService.getUserProfile();
      if (userProfile != null) {
        setState(() {
          _userName = (userProfile['name'] as String?) ?? 
                      (userProfile['email'] as String? ?? 'User').split('@').first;
          _userEmail = userProfile['email'] as String?;
          _highestEducation = userProfile['highest_education'] as String?;
          _careerInterests = (userProfile['career_interests'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ?? [];
          _profilePhotoUrl = userProfile['profile_photo_url'] as String?;
        });
      } else {
        // Fallback to auth user
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null && user.email != null) {
          setState(() {
            _userName = user.email!.split('@').first;
            _userEmail = user.email;
          });
        }
      }

      // Get user answers
      final userAnswers = await supabaseService.getUserAnswers();
      if (userAnswers != null) {
        _selectedCareerField = userAnswers['selected_career_field'] as String?;
        _hasCompletedAssessment = true;
        
        // Calculate skills unlocked
        if (userAnswers['current_skills'] != null && 
            (userAnswers['current_skills'] as List).isNotEmpty) {
          _skillsUnlocked = (userAnswers['current_skills'] as List).length;
        }
      }

      // Get saved careers count
      final savedCareers = await supabaseService.getSavedCareers();
      _savedCareersCount = savedCareers.length;
      
      // Count unique skills from saved careers
      final allSkills = <String>{};
      for (var career in savedCareers) {
        final skillsYouHave = career['skills_you_have'] as List<dynamic>? ?? [];
        allSkills.addAll(skillsYouHave.map((s) => s.toString()));
      }
      if (userAnswers != null) {
        final currentSkills = userAnswers['current_skills'] as List<dynamic>? ?? [];
        allSkills.addAll(currentSkills.map((s) => s.toString()));
      }
      _skillsUnlocked = allSkills.length;

    } catch (e) {
      // Handle error
    } finally {
      if (showLoading) {
        setState(() {
          _isLoading = false;
        });
      } else {
        // Still update state even if not showing loading
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      drawer: AppSidebar(
        currentScreen: 'profile',
        onProfilePhotoTap: _showImagePickerOptions,
      ),
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
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D9FF)),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadProfileData,
              color: const Color(0xFF00D9FF),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Modern Profile Header
                    _buildModernProfileHeader(),
                    
                    // Statistics Cards - Modern Design
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildModernStatCard(
                              icon: Icons.bookmark_rounded,
                              label: 'Saved Careers',
                              value: '$_savedCareersCount',
                              gradient: const [
                                Color(0xFF00D9FF),
                                Color(0xFF0099CC),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildModernStatCard(
                              icon: Icons.star_rounded,
                              label: 'Skills',
                              value: '$_skillsUnlocked',
                              gradient: const [
                                Color(0xFFFF6B9D),
                                Color(0xFFFF4D7A),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quick Info Cards
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          _buildModernInfoCard(
                            icon: Icons.email_rounded,
                            title: 'Email',
                            value: _userEmail ?? 'Not set',
                            onTap: null,
                          ),
                          const SizedBox(height: 12),
                          _buildModernInfoCard(
                            icon: Icons.school_rounded,
                            title: 'Education',
                            value: _highestEducation ?? 'Not set',
                            onTap: _showEducationDialog,
                            isEditable: true,
                          ),
                          const SizedBox(height: 12),
                          _buildModernInfoCard(
                            icon: Icons.work_outline_rounded,
                            title: 'Career Interests',
                            value: _careerInterests.isEmpty 
                                ? 'Tap to add interests' 
                                : _careerInterests.join(', '),
                            onTap: _showCareerInterestDialog,
                            isEditable: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Assessment Card
                    if (_hasCompletedAssessment && _selectedCareerField != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildAssessmentCard(),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildEmptyAssessmentCard(),
                      ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }


  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00D9FF).withOpacity(0.3),
            const Color(0xFFFF6B9D).withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00D9FF).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showImagePickerOptions,
            child: Container(
              width: 80,
              height: 80,
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
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text(
                              _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00D9FF),
                              ),
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D9FF)),
                            ),
                          );
                        },
                      ),
                    )
                  : Center(
                      child: Text(
                        _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00D9FF),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (_userEmail != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _userEmail!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard({
    required IconData icon,
    required String title,
    required String message,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white.withOpacity(0.5), size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.5),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.white.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEditableInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: value == 'Not set' 
                            ? Colors.white.withOpacity(0.5)
                            : Colors.white,
                        fontStyle: value == 'Not set' 
                            ? FontStyle.italic 
                            : FontStyle.normal,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.edit,
                size: 18,
                color: Colors.white.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditableInterestsCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showCareerInterestDialog,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF00D9FF).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D9FF).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.work_outline,
                      color: Color(0xFF00D9FF),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Career Interests',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.edit,
                    size: 18,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ],
              ),
              if (_careerInterests.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _careerInterests.map((interest) {
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
                        interest,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFFF6B9D),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ] else ...[
                const SizedBox(height: 12),
                Text(
                  'Not set',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.5),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEducationDialog() async {
    final selectedEducation = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text(
            'Select Education',
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Your education will be saved permanently in your profile and used across the app. You can edit it anytime.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _educationOptions.length,
                    itemBuilder: (context, index) {
                      final education = _educationOptions[index];
                      final isSelected = _highestEducation == education;
                      return ListTile(
                        title: Text(
                          education,
                          style: TextStyle(
                            color: isSelected 
                                ? const Color(0xFF00D9FF) 
                                : Colors.white,
                            fontWeight: isSelected 
                                ? FontWeight.bold 
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Color(0xFF00D9FF),
                              )
                            : null,
                        onTap: () {
                          Navigator.of(context).pop(education);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedEducation != null && selectedEducation != _highestEducation) {
      await _updateEducation(selectedEducation);
    }
  }

  Future<void> _showCareerInterestDialog() async {
    final TextEditingController controller = TextEditingController(
      text: _careerInterests.join(', '),
    );

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: const Text(
            'Career Interests',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Your career interests will be saved permanently in your profile and used across the app. You can edit them anytime.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter your career interests (comma separated)',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Color(0xFF00D9FF),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 3,
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () {
                final interests = controller.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
                Navigator.of(context).pop(interests);
              },
              child: const Text(
                'Save',
                style: TextStyle(color: Color(0xFF00D9FF)),
              ),
            ),
          ],
        );
      },
    ).then((interests) async {
      if (interests != null && interests is List<String>) {
        await _updateCareerInterests(interests);
      }
    });
  }

  Future<void> _updateEducation(String education) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not authenticated'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Update UI immediately (optimistic update)
    setState(() {
      _highestEducation = education;
    });

    try {
      final profileRepository = ref.read(profileRepositoryProvider);
      await profileRepository.updateProfile(
        userId: user.id,
        highestEducation: education,
        careerInterests: _careerInterests,
      );

      // Ensure state is updated (in case it wasn't already)
      if (mounted) {
        setState(() {
          _highestEducation = education;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Education saved permanently to your profile'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        // Reload profile data in background without showing loading to sync other data
        _loadProfileData(showLoading: false);
      }
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          _highestEducation = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update education: $e'),
            backgroundColor: Colors.red,
          ),
        );
        // Reload to get correct state
        _loadProfileData(showLoading: false);
      }
    }
  }

  Future<void> _updateCareerInterests(List<String> interests) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not authenticated'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Store previous state for potential revert
    final previousInterests = List<String>.from(_careerInterests);

    // Update UI immediately (optimistic update)
    setState(() {
      _careerInterests = interests;
    });

    try {
      final profileRepository = ref.read(profileRepositoryProvider);
      await profileRepository.updateProfile(
        userId: user.id,
        highestEducation: _highestEducation,
        careerInterests: interests,
      );

      // Ensure state is updated (in case it wasn't already)
      if (mounted) {
        setState(() {
          _careerInterests = interests;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Career interests saved permanently to your profile'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        // Reload profile data in background without showing loading to sync other data
        _loadProfileData(showLoading: false);
      }
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          _careerInterests = previousInterests;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update career interests: $e'),
            backgroundColor: Colors.red,
          ),
        );
        // Reload to get correct state
        _loadProfileData(showLoading: false);
      }
    }
  }

  Future<void> _showImagePickerOptions() async {
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
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF00D9FF)),
                title: const Text('Take Photo', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _removeProfilePhoto();
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadProfilePhoto(image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadProfilePhoto(XFile image) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not authenticated'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Uploading photo...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }

      // Generate unique filename
      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final storage = Supabase.instance.client.storage.from('avatars');

      if (kIsWeb) {
        // On web we must upload bytes instead of a File
        final bytes = await image.readAsBytes();
        await storage.uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );
      } else {
        // On mobile/desktop we can upload a File
        final file = File(image.path);
        await storage.upload(
          fileName,
          file,
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: true,
          ),
        );
      }

      // Get public URL
      final photoUrl = storage.getPublicUrl(fileName);

      // Delete old photo if exists
      if (_profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty) {
        try {
          // Extract filename from URL
          final urlParts = _profilePhotoUrl!.split('/');
          final oldFileName = urlParts.last.split('?').first; // Remove query params if any
          await Supabase.instance.client.storage
              .from('avatars')
              .remove([oldFileName]);
        } catch (e) {
          // Ignore errors when deleting old photo
        }
      }

      // Update profile with photo URL
      await Supabase.instance.client
          .from('profiles')
          .update({
            'profile_photo_url': photoUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      // Update local state
      setState(() {
        _profilePhotoUrl = photoUrl;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        _loadProfileData(showLoading: false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeProfilePhoto() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not authenticated'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // Delete photo from storage
      if (_profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty) {
        try {
          // Extract filename from URL
          final urlParts = _profilePhotoUrl!.split('/');
          final oldFileName = urlParts.last.split('?').first; // Remove query params if any
          await Supabase.instance.client.storage
              .from('avatars')
              .remove([oldFileName]);
        } catch (e) {
          // Ignore errors when deleting photo
        }
      }

      // Update profile to remove photo URL
      await Supabase.instance.client
          .from('profiles')
          .update({
            'profile_photo_url': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      // Update local state
      setState(() {
        _profilePhotoUrl = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo removed'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        _loadProfileData(showLoading: false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Modern Profile Header
  Widget _buildModernProfileHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A2E),
            const Color(0xFF2A2A3E),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Profile Photo
              GestureDetector(
                onTap: _showImagePickerOptions,
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF00D9FF),
                            const Color(0xFFFF6B9D),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00D9FF).withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: _profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                _profilePhotoUrl!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Text(
                                      _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                                      style: const TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
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
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00D9FF),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF0F0F23),
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Name
              Text(
                _userName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (_userEmail != null) ...[
                const SizedBox(height: 4),
                Text(
                  _userEmail!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Modern Stat Card
  Widget _buildModernStatCard({
    required IconData icon,
    required String label,
    required String value,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Modern Info Card
  Widget _buildModernInfoCard({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
    bool isEditable = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF00D9FF).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D9FF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF00D9FF),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 15,
                        color: value.contains('Not set') || value.contains('Tap to add')
                            ? Colors.white.withOpacity(0.5)
                            : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isEditable)
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withOpacity(0.5),
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Assessment Card
  Widget _buildAssessmentCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFF6B9D).withOpacity(0.2),
            const Color(0xFF00D9FF).withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFF6B9D).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B9D).withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.quiz_rounded,
              color: Color(0xFFFF6B9D),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Career Field',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedCareerField ?? 'Not set',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B9D).withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Completed',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFFF6B9D),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Empty Assessment Card
  Widget _buildEmptyAssessmentCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CareerAssessmentTestScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.quiz_outlined,
                  color: Colors.white.withOpacity(0.5),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Career Assessment',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Take the assessment to discover your career path',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withOpacity(0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


