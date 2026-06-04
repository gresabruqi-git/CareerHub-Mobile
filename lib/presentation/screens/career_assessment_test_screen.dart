import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/questionnaire_answers.dart';
import '../../data/models/career_field_config.dart';
import '../../services/supabase_service.dart';
import '../../providers/user_provider.dart';
import 'career_recommendations_screen.dart';

/// Career Assessment Test Screen with field-specific questionnaire
class CareerAssessmentTestScreen extends ConsumerStatefulWidget {
  const CareerAssessmentTestScreen({super.key});

  @override
  ConsumerState<CareerAssessmentTestScreen> createState() => _CareerAssessmentTestScreenState();
}

class _CareerAssessmentTestScreenState extends ConsumerState<CareerAssessmentTestScreen> {
  int _currentStep = 0;
  bool _isLoading = false;
  
  // Step 0: Career field selection
  String? _selectedCareerField;
  
  // Step 1+: Field-specific answers (supports both String and List<String>)
  final Map<String, dynamic> _fieldSpecificAnswers = {};
  final List<String> _selectedSkills = [];
  String? _skillLevel;
  String? _workPreference;
  String? _careerType;
  String? _longTermGoal;
  String? _learningTime;

  CareerFieldConfig? get _currentFieldConfig {
    if (_selectedCareerField == null) return null;
    return CareerFieldConfig.allFields[_selectedCareerField];
  }

  int get _totalSteps {
    if (_selectedCareerField == null) return 1; // Only field selection
    final config = _currentFieldConfig;
    if (config == null) return 1;
    // Field selection + field questions + general questions (6)
    // General questions: skills, skill level, work preference, career type, long-term goal, learning time
    return 1 + config.questions.length + 6;
  }

  Future<void> _submitQuestionnaire() async {
    // Validate all required fields
    final config = _currentFieldConfig;
    if (config == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a career field'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check field-specific questions
    final requiredFieldQuestions = config.questions.length;
    final missingFieldQuestions = <int>[];
    for (int i = 0; i < requiredFieldQuestions; i++) {
      final answer = _fieldSpecificAnswers['q$i'];
      final question = config.questions[i];
      if (answer == null) {
        missingFieldQuestions.add(i);
      } else if (question.allowMultiple) {
        // For multi-select, check if list is not empty
        if (answer is List && answer.isEmpty) {
          missingFieldQuestions.add(i);
        }
      } else {
        // For single-select, check if string is not empty
        if (answer is String && answer.isEmpty) {
          missingFieldQuestions.add(i);
        }
      }
    }

    // Build error message with what's missing
    final missingItems = <String>[];
    if (missingFieldQuestions.isNotEmpty) {
      missingItems.add('${missingFieldQuestions.length} field-specific question(s)');
    }
    if (_selectedSkills.isEmpty) {
      missingItems.add('skills selection');
    }
    if (_skillLevel == null || _skillLevel!.isEmpty) {
      missingItems.add('skill level');
    }
    if (_workPreference == null || _workPreference!.isEmpty) {
      missingItems.add('work preference');
    }
    if (_careerType == null || _careerType!.isEmpty) {
      missingItems.add('career type');
    }
    if (_longTermGoal == null || _longTermGoal!.isEmpty) {
      missingItems.add('long-term goal');
    }
    if (_learningTime == null || _learningTime!.isEmpty) {
      missingItems.add('learning time');
    }

    if (missingItems.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please complete: ${missingItems.join(', ')}'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final answers = QuestionnaireAnswers(
        selectedCareerField: _selectedCareerField!,
        interestedAreas: [_selectedCareerField!],
        skillLevel: _skillLevel!,
        currentSkills: _selectedSkills,
        workPreference: _workPreference!,
        careerType: _careerType!,
        longTermGoal: _longTermGoal!,
        learningTime: _learningTime!,
        fieldSpecificAnswers: _fieldSpecificAnswers,
      );

      // Save answers to Supabase
      final supabaseService = ref.read(supabaseServiceProvider);
      await supabaseService.saveUserAnswers(answers: answers.toMap());

      // Navigate to recommendations screen with answers
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => CareerRecommendationsScreen(answers: answers),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving answers: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Career Assessment',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Minimal Progress Indicator
            _buildProgressIndicator(),
            
            // Question Card - Centered and Compact
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: _buildQuestionCard(),
                  ),
                ),
              ),
            ),

            // Navigation Buttons - Minimal Design
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final progress = (_currentStep + 1) / _totalSteps;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Text(
            '${_currentStep + 1}/$_totalSteps',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00D9FF)),
                minHeight: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.1, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey(_currentStep),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF00D9FF).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Title - Shorter and Cleaner
            Text(
              _getQuestionTitle(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 20),
            // Question Content
            _getQuestionContent(),
          ],
        ),
      ),
    );
  }

  String _getQuestionTitle() {
    if (_currentStep == 0) {
      return 'Choose your career field';
    }
    
    final config = _currentFieldConfig;
    if (config == null) return '';
    
    final fieldQuestionsCount = config.questions.length;
    final fieldQuestionsStart = 1;
    final skillsStep = fieldQuestionsStart + fieldQuestionsCount;
    
    if (_currentStep >= fieldQuestionsStart && _currentStep < skillsStep) {
      final questionIndex = _currentStep - fieldQuestionsStart;
      if (questionIndex < config.questions.length) {
        // Use full question text (already properly capitalized)
        final question = config.questions[questionIndex].question;
        // Ensure it starts with uppercase
        if (question.isNotEmpty) {
          return question[0].toUpperCase() + question.substring(1);
        }
        return question;
      }
    } else if (_currentStep == skillsStep) {
      return 'Select your skills';
    } else if (_currentStep == skillsStep + 1) {
      return 'Your skill level?';
    } else if (_currentStep == skillsStep + 2) {
      return 'Work preference?';
    } else if (_currentStep == skillsStep + 3) {
      return 'Work location?';
    } else if (_currentStep == skillsStep + 4) {
      return 'Long-term goal?';
    } else if (_currentStep == skillsStep + 5) {
      return 'Learning time?';
    }
    
    return '';
  }

  String _shortenQuestion(String question) {
    // Shorten common question patterns for better UI display
    // Always ensure the result starts with an uppercase letter
    if (question.contains('(Select all that apply)')) {
      question = question.replaceAll('(Select all that apply)', '');
    }
    if (question.contains('What is your')) {
      question = question.replaceFirst('What is your ', '');
    }
    if (question.contains('What is your level of')) {
      question = question.replaceFirst('What is your level of ', '');
    }
    if (question.contains('What is your comfort level')) {
      question = question.replaceFirst('What is your comfort level ', '');
    }
    if (question.contains('How comfortable')) {
      question = question.replaceFirst('How comfortable are you ', '');
    }
    if (question.contains('How do you')) {
      question = question.replaceFirst('How do you ', '');
    }
    if (question.contains('Which')) {
      question = question.replaceFirst('Which ', '');
    }
    if (question.contains('What type of')) {
      question = question.replaceFirst('What type of ', '');
    }
    if (question.contains('What types of')) {
      question = question.replaceFirst('What types of ', '');
    }
    if (question.contains('What aspect of')) {
      question = question.replaceFirst('What aspect of ', '');
    }
    if (question.contains('What areas of')) {
      question = question.replaceFirst('What areas of ', '');
    }
    question = question.trim();
    
    // Ensure first letter is uppercase
    if (question.isNotEmpty && question[0] != question[0].toUpperCase()) {
      question = question[0].toUpperCase() + question.substring(1);
    }
    
    return question;
  }

  Widget _getQuestionContent() {
    if (_currentStep == 0) {
      return _buildCareerFieldSelection();
    }
    
    final config = _currentFieldConfig;
    if (config == null) return const SizedBox();
    
    final fieldQuestionsCount = config.questions.length;
    final fieldQuestionsStart = 1;
    final skillsStep = fieldQuestionsStart + fieldQuestionsCount;
    
    if (_currentStep >= fieldQuestionsStart && _currentStep < skillsStep) {
      final questionIndex = _currentStep - fieldQuestionsStart;
      if (questionIndex < config.questions.length) {
        final question = config.questions[questionIndex];
        final currentAnswer = _fieldSpecificAnswers['q$questionIndex'];
        
        if (question.allowMultiple) {
          // Multi-select question
          final selectedList = currentAnswer is List<String> 
              ? List<String>.from(currentAnswer) 
              : <String>[];
          return _buildCompactSkills(
            question.options,
            selectedList,
            (selected) {
              setState(() {
                _fieldSpecificAnswers['q$questionIndex'] = selected;
              });
            },
          );
        } else {
          // Single-select question
          final selectedString = currentAnswer is String ? currentAnswer : null;
          return _buildCompactOptions(
            question.options,
            selectedString,
            (selected) {
              setState(() {
                _fieldSpecificAnswers['q$questionIndex'] = selected;
              });
            },
          );
        }
      }
    } else if (_currentStep == skillsStep) {
      return _buildCompactSkills(
        config.specificSkills,
        _selectedSkills,
        (selected) {
          setState(() {
            _selectedSkills.clear();
            _selectedSkills.addAll(selected);
          });
        },
      );
    } else if (_currentStep == skillsStep + 1) {
      return _buildCompactOptions(
        ['Beginner', 'Intermediate', 'Advanced'],
        _skillLevel,
        (selected) {
          setState(() {
            _skillLevel = selected;
          });
        },
      );
    } else if (_currentStep == skillsStep + 2) {
      return _buildCompactOptions(
        ['With people', 'With technology', 'With creativity', 'With data/numbers', 'With hands-on tasks'],
        _workPreference,
        (selected) {
          setState(() {
            _workPreference = selected;
          });
        },
      );
    } else if (_currentStep == skillsStep + 3) {
      return _buildCompactOptions(
        ['Remote', 'Hybrid', 'On-site', 'Flexible'],
        _careerType,
        (selected) {
          setState(() {
            _careerType = selected;
          });
        },
      );
    } else if (_currentStep == skillsStep + 4) {
      return _buildCompactOptions(
        ['High salary', 'Stability', 'Creativity', 'Flexibility', 'Own business', 'Tech career', 'Helping people'],
        _longTermGoal,
        (selected) {
          setState(() {
            _longTermGoal = selected;
          });
        },
      );
    } else if (_currentStep == skillsStep + 5) {
      return _buildCompactOptions(
        ['1–3 months', '3–6 months', '6–12 months', '1+ year'],
        _learningTime,
        (selected) {
          setState(() {
            _learningTime = selected;
          });
        },
      );
    }
    
    return const SizedBox();
  }

  Widget _buildCareerFieldSelection() {
    final fields = CareerFieldConfig.allFields;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: fields.entries.map((entry) {
        final field = entry.value;
        final isSelected = _selectedCareerField == entry.key;
        return _buildCompactOptionCard(
          field.fieldName,
          isSelected,
          () {
            setState(() {
              _selectedCareerField = entry.key;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildCompactOptions(
    List<String> options,
    String? selected,
    Function(String) onChanged,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: options.map((option) {
        final isSelected = selected == option;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildCompactOptionCard(option, isSelected, () => onChanged(option)),
        );
      }).toList(),
    );
  }

  Widget _buildCompactOptionCard(
    String text,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color(0xFF00D9FF).withOpacity(0.2) 
                : const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                  ? const Color(0xFF00D9FF) 
                  : Colors.white.withOpacity(0.1),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected 
                        ? const Color(0xFF00D9FF) 
                        : Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                  color: isSelected ? const Color(0xFF00D9FF) : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    color: isSelected 
                        ? const Color(0xFF00D9FF) 
                        : Colors.white.withOpacity(0.7),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactSkills(
    List<String> skills,
    List<String> selected,
    Function(List<String>) onChanged,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skills.map((skill) {
        final isSelected = selected.contains(skill);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              final newSelected = List<String>.from(selected);
              if (isSelected) {
                newSelected.remove(skill);
              } else {
                newSelected.add(skill);
              }
              onChanged(newSelected);
            },
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected 
                    ? const Color(0xFF00D9FF) 
                    : const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected 
                      ? const Color(0xFF00D9FF) 
                      : Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected)
                    const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  else
                    Icon(
                      Icons.add,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                  const SizedBox(width: 6),
                  Text(
                    skill,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected 
                          ? Colors.white 
                          : Colors.white.withOpacity(0.7),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF00D9FF).withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 0)
              SizedBox(
                width: 100,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _currentStep--;
                    });
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Back',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              child: _isLoading
                  ? Container(
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFF00D9FF),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: _canProceed()
                          ? () async {
                              if (_currentStep < _totalSteps - 1) {
                                setState(() {
                                  _currentStep++;
                                });
                              } else {
                                await Future.delayed(const Duration(milliseconds: 100));
                                _submitQuestionnaire();
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D9FF),
                        foregroundColor: const Color(0xFF0F0F23),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        disabledBackgroundColor: Colors.white.withOpacity(0.1),
                      ),
                      child: Text(
                        _currentStep < _totalSteps - 1 ? 'Continue' : 'Get Results',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canProceed() {
    if (_currentStep == 0) {
      return _selectedCareerField != null;
    }
    
    final config = _currentFieldConfig;
    if (config == null) return false;
    
    final fieldQuestionsCount = config.questions.length;
    final fieldQuestionsStart = 1;
    final skillsStep = fieldQuestionsStart + fieldQuestionsCount;
    
    if (_currentStep >= fieldQuestionsStart && _currentStep < skillsStep) {
      final questionIndex = _currentStep - fieldQuestionsStart;
      final question = config.questions[questionIndex];
      final answer = _fieldSpecificAnswers['q$questionIndex'];
      
      if (answer == null) return false;
      
      if (question.allowMultiple) {
        // For multi-select, check if list is not empty
        return answer is List && answer.isNotEmpty;
      } else {
        // For single-select, check if string is not empty
        return answer is String && answer.isNotEmpty;
      }
    } else if (_currentStep == skillsStep) {
      return _selectedSkills.isNotEmpty;
    } else if (_currentStep == skillsStep + 1) {
      return _skillLevel != null && _skillLevel!.isNotEmpty;
    } else if (_currentStep == skillsStep + 2) {
      return _workPreference != null && _workPreference!.isNotEmpty;
    } else if (_currentStep == skillsStep + 3) {
      return _careerType != null && _careerType!.isNotEmpty;
    } else if (_currentStep == skillsStep + 4) {
      return _longTermGoal != null && _longTermGoal!.isNotEmpty;
    } else if (_currentStep == skillsStep + 5) {
      return _learningTime != null && _learningTime!.isNotEmpty;
    }
    
    return true;
  }
}
