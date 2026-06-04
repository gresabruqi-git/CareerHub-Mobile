import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/profile_repository.dart';
import 'auth_screens.dart';
import 'home_screen.dart';

/// Onboarding Screen with multi-step form
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentStep = 0;
  String? _selectedEducation;
  final List<String> _selectedInterests = [];
  bool _isSaving = false;

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

  // Career interest options
  final List<String> _careerInterestOptions = [
    'Software Development',
    'Data Science',
    'Product Management',
    'UX/UI Design',
    'Marketing',
    'Sales',
    'Finance',
    'Healthcare',
    'Education',
    'Engineering',
    'Consulting',
    'Entrepreneurship',
    'Research',
    'Operations',
    'Human Resources',
    'Healthcare & Pharmacy',
    'Science & Laboratory',
    'Education & Teaching',
    'Psychology & Social Work',
    'Law & Public Administration',
    'Tourism & Hospitality',
    'Sales & Retail',
  ];

  Future<void> _saveProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not authenticated'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedEducation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your highest education level'),
          backgroundColor: Colors.orange,
        ),
      );
      setState(() {
        _currentStep = 0;
      });
      return;
    }

    if (_selectedInterests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one career interest'),
          backgroundColor: Colors.orange,
        ),
      );
      setState(() {
        _currentStep = 1;
      });
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final profileRepository = ref.read(profileRepositoryProvider);
      await profileRepository.updateProfile(
        userId: user.id,
        highestEducation: _selectedEducation,
        careerInterests: _selectedInterests,
      );

      if (mounted) {
        // Navigate to HomeScreen after successful save
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final userEmail = user?.email ?? 'User';

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Onboarding', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              final authRepository = ref.read(authRepositoryProvider);
              await authRepository.signOut();
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: SafeArea(
        child: Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00D9FF),
              secondary: Color(0xFFFF6B9D),
            ),
          ),
          child: Stepper(
            currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep == 0) {
              if (_selectedEducation == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select your highest education level'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
            } else if (_currentStep == 1) {
              if (_selectedInterests.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select at least one career interest'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
            }

            if (_currentStep < 2) {
              setState(() {
                _currentStep += 1;
              });
            } else {
              _saveProfile();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() {
                _currentStep -= 1;
              });
            }
          },
          steps: [
            // Step 1: Welcome
            Step(
              title: const Text('Welcome'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Welcome, ${userEmail.split('@')[0]}!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "We're excited to help you on your career journey. Let's get started by learning a bit about you.",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'This will only take a few moments.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              isActive: _currentStep >= 0,
              state: _currentStep > 0
                  ? StepState.complete
                  : (_currentStep == 0 ? StepState.indexed : StepState.disabled),
            ),
            // Step 2: Education Level
            Step(
              title: const Text('Education Level'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'What is your highest level of education?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ..._educationOptions.map((education) {
                    return RadioListTile<String>(
                      title: Text(
                        education,
                        style: const TextStyle(color: Colors.white),
                      ),
                      value: education,
                      groupValue: _selectedEducation,
                      activeColor: const Color(0xFF00D9FF),
                      onChanged: (value) {
                        setState(() {
                          _selectedEducation = value;
                        });
                      },
                    );
                  }),
                ],
              ),
              isActive: _currentStep >= 1,
              state: _currentStep > 1
                  ? StepState.complete
                  : (_currentStep == 1 ? StepState.indexed : StepState.disabled),
            ),
            // Step 3: Career Interests
            Step(
              title: const Text('Career Interests'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Select your career fields of interest (up to 5):',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selected: ${_selectedInterests.length}/5',
                    style: TextStyle(
                      fontSize: 14,
                      color: _selectedInterests.length >= 5
                          ? const Color(0xFFFF6B9D)
                          : Colors.white.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _careerInterestOptions.map((interest) {
                      final isSelected = _selectedInterests.contains(interest);
                      final canSelect = _selectedInterests.length < 5 || isSelected;

                      return FilterChip(
                        label: Text(
                          interest,
                          style: TextStyle(
                            color: isSelected 
                                ? Colors.white 
                                : Colors.white.withOpacity(0.7),
                          ),
                        ),
                        selected: isSelected,
                        onSelected: canSelect
                            ? (selected) {
                                setState(() {
                                  if (selected) {
                                    if (_selectedInterests.length < 5) {
                                      _selectedInterests.add(interest);
                                    }
                                  } else {
                                    _selectedInterests.remove(interest);
                                  }
                                });
                              }
                            : null,
                        selectedColor: const Color(0xFF00D9FF).withOpacity(0.3),
                        checkmarkColor: const Color(0xFF00D9FF),
                        backgroundColor: const Color(0xFF1A1A2E),
                        side: BorderSide(
                          color: isSelected 
                              ? const Color(0xFF00D9FF) 
                              : Colors.white.withOpacity(0.2),
                        ),
                      );
                    }).toList(),
                  ),
                  if (_selectedInterests.length >= 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        'Maximum 5 interests selected',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFFFF6B9D),
                        ),
                      ),
                    ),
                ],
              ),
              isActive: _currentStep >= 2,
              state: _currentStep == 2 ? StepState.indexed : StepState.disabled,
            ),
          ],
        ),
          ),
        ),
      bottomNavigationBar: _isSaving
          ? const LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D9FF)),
            )
          : null,
    );
  }
}

