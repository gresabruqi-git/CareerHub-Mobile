import '../data/models/questionnaire_answers.dart';
import '../data/models/career_field_config.dart';

/// Career recommendation engine with field-specific logic
class RecommendationEngine {
  /// Generate career recommendations based on questionnaire answers
  static List<CareerRecommendation> generateRecommendations(
    QuestionnaireAnswers answers,
  ) {
    final recommendations = <CareerRecommendation>[];

    // Get field-specific configuration
    final fieldConfig = CareerFieldConfig.allFields[answers.selectedCareerField];
    if (fieldConfig == null) {
      // Fallback to generic recommendations if field not found
      return _generateGenericRecommendations(answers);
    }

    // Get field-specific careers
    final fieldCareers = _getFieldSpecificCareers(fieldConfig);
    
    // Ensure we have at least 2 careers - if empty or only 1, create default careers
    if (fieldCareers.isEmpty) {
      if (fieldConfig.relatedCareers.isNotEmpty) {
        // Create first career from related careers
        fieldCareers.add(_createFieldSpecificCareer(
          fieldConfig.relatedCareers.first,
          fieldConfig,
        ));
        // Create second career if available
        if (fieldConfig.relatedCareers.length > 1) {
          fieldCareers.add(_createFieldSpecificCareer(
            fieldConfig.relatedCareers[1],
            fieldConfig,
          ));
        } else {
          // Create a variation if only one related career exists
          fieldCareers.add(_createFieldSpecificCareer(
            '${fieldConfig.fieldName} Specialist',
            fieldConfig,
          ));
        }
      } else {
        // Edge case: relatedCareers is empty, create two default careers
        fieldCareers.add(_createFieldSpecificCareer(
          'Career in ${fieldConfig.fieldName}',
          fieldConfig,
        ));
        fieldCareers.add(_createFieldSpecificCareer(
          '${fieldConfig.fieldName} Specialist',
          fieldConfig,
        ));
      }
    } else if (fieldCareers.length == 1 && fieldConfig.relatedCareers.length > 1) {
      // If we only have one career, add a second one from related careers
      final existingTitle = fieldCareers.first['job_title']?.toString().toLowerCase() ?? '';
      final secondCareerTitle = fieldConfig.relatedCareers.firstWhere(
        (title) => title.toLowerCase() != existingTitle,
        orElse: () => fieldConfig.relatedCareers.length > 1 
            ? fieldConfig.relatedCareers[1]
            : '${fieldConfig.fieldName} Specialist',
      );
      fieldCareers.add(_createFieldSpecificCareer(secondCareerTitle, fieldConfig));
    } else if (fieldCareers.length == 1) {
      // If only one related career exists, create a variation
      fieldCareers.add(_createFieldSpecificCareer(
        '${fieldConfig.fieldName} Specialist',
        fieldConfig,
      ));
    }
    
    // Score each career based on field-specific criteria
    for (final career in fieldCareers) {
      try {
        final score = _calculateFieldSpecificScore(answers, career, fieldConfig);
        // Ensure minimum score for field-specific careers (they should always be included)
        final finalScore = score < 25 ? 25 : score;
        
        recommendations.add(
          CareerRecommendation(
            jobTitle: career['job_title']?.toString() ?? 'Career',
            sector: career['sector']?.toString() ?? fieldConfig.fieldName,
            summary: career['summary']?.toString() ?? 'A ${fieldConfig.fieldName} role that matches your interests',
            matchScore: finalScore,
            whyItFits: _generateFieldSpecificWhyItFits(answers, career, fieldConfig),
            skillsYouHave: _getMatchingSkills(answers.currentSkills, career),
            skillsToLearn: _getSkillsToLearn(answers.currentSkills, career, fieldConfig),
            learningPath: _generateFieldSpecificLearningPath(career, answers.learningTime, fieldConfig),
            salaryRange: career['salary_range']?.toString() ?? _getSalaryRangeForField(fieldConfig.fieldId),
            futureDemand: career['future_demand']?.toString() ?? 'High',
          ),
        );
      } catch (e) {
        // If there's an error creating a recommendation, skip it and continue
        // We'll ensure at least one recommendation exists at the end
        continue;
      }
    }

    // CRITICAL: Ensure we always return at least TWO recommendations
    // If somehow we have no recommendations, create default ones
    if (recommendations.isEmpty) {
      // Create first default career
      final firstCareerTitle = fieldConfig.relatedCareers.isNotEmpty 
          ? fieldConfig.relatedCareers.first 
          : 'Career in ${fieldConfig.fieldName}';
      final defaultCareer1 = _createFieldSpecificCareer(firstCareerTitle, fieldConfig);
      recommendations.add(
        CareerRecommendation(
          jobTitle: defaultCareer1['job_title'] as String,
          sector: defaultCareer1['sector'] as String,
          summary: defaultCareer1['summary'] as String,
          matchScore: 30,
          whyItFits: 'This career matches your selected field of ${fieldConfig.fieldName}',
          skillsYouHave: _getMatchingSkills(answers.currentSkills, defaultCareer1),
          skillsToLearn: _getSkillsToLearn(answers.currentSkills, defaultCareer1, fieldConfig),
          learningPath: _generateFieldSpecificLearningPath(defaultCareer1, answers.learningTime, fieldConfig),
          salaryRange: defaultCareer1['salary_range'] as String,
          futureDemand: defaultCareer1['future_demand'] as String,
        ),
      );
      
      // Create second default career (different from first)
      final secondCareerTitle = fieldConfig.relatedCareers.length > 1
          ? fieldConfig.relatedCareers[1]
          : (fieldConfig.relatedCareers.isNotEmpty 
              ? '${fieldConfig.fieldName} Specialist'
              : 'Alternative Career in ${fieldConfig.fieldName}');
      final defaultCareer2 = _createFieldSpecificCareer(secondCareerTitle, fieldConfig);
      recommendations.add(
        CareerRecommendation(
          jobTitle: defaultCareer2['job_title'] as String,
          sector: defaultCareer2['sector'] as String,
          summary: defaultCareer2['summary'] as String,
          matchScore: 28,
          whyItFits: 'Another ${fieldConfig.fieldName} career path that aligns with your interests',
          skillsYouHave: _getMatchingSkills(answers.currentSkills, defaultCareer2),
          skillsToLearn: _getSkillsToLearn(answers.currentSkills, defaultCareer2, fieldConfig),
          learningPath: _generateFieldSpecificLearningPath(defaultCareer2, answers.learningTime, fieldConfig),
          salaryRange: defaultCareer2['salary_range'] as String,
          futureDemand: defaultCareer2['future_demand'] as String,
        ),
      );
    } else if (recommendations.length == 1) {
      // If we only have one recommendation, add a second one
      final existingJobTitle = recommendations.first.jobTitle;
      String secondCareerTitle;
      
      // Find a different career from related careers
      if (fieldConfig.relatedCareers.length > 1) {
        // Find first related career that's different from existing one
        secondCareerTitle = fieldConfig.relatedCareers.firstWhere(
          (title) => title.toLowerCase() != existingJobTitle.toLowerCase(),
          orElse: () => fieldConfig.relatedCareers.length > 1 
              ? fieldConfig.relatedCareers[1]
              : '${fieldConfig.fieldName} Specialist',
        );
      } else {
        // Create a variation of the existing career
        secondCareerTitle = '${fieldConfig.fieldName} Specialist';
      }
      
      final secondCareer = _createFieldSpecificCareer(secondCareerTitle, fieldConfig);
      recommendations.add(
        CareerRecommendation(
          jobTitle: secondCareer['job_title'] as String,
          sector: secondCareer['sector'] as String,
          summary: secondCareer['summary'] as String,
          matchScore: recommendations.first.matchScore - 2, // Slightly lower score
          whyItFits: 'Another ${fieldConfig.fieldName} career path that matches your profile',
          skillsYouHave: _getMatchingSkills(answers.currentSkills, secondCareer),
          skillsToLearn: _getSkillsToLearn(answers.currentSkills, secondCareer, fieldConfig),
          learningPath: _generateFieldSpecificLearningPath(secondCareer, answers.learningTime, fieldConfig),
          salaryRange: secondCareer['salary_range'] as String,
          futureDemand: secondCareer['future_demand'] as String,
        ),
      );
    }

    // Sort by match score (highest first) and return top 10
    recommendations.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    // Return top 10 (we've already ensured at least 2 exist above)
    return recommendations.take(10).toList();
  }

  static int _calculateFieldSpecificScore(
    QuestionnaireAnswers answers,
    Map<String, dynamic> career,
    CareerFieldConfig fieldConfig,
  ) {
    int score = 0;

    // Base score for field match (30 points)
    final careerSector = (career['sector'] ?? '').toString().toLowerCase();
    final fieldName = fieldConfig.fieldName.toLowerCase();
    final fieldId = fieldConfig.fieldId.toLowerCase();
    
    // Match by field ID, field name, or sector
    if (careerSector.contains(fieldId) || 
        careerSector.contains(fieldName) ||
        fieldName.contains(careerSector) ||
        fieldId.contains(careerSector)) {
      score += 30;
    } else {
      // Give base score for field-specific careers (they're already filtered)
      score += 20;
    }

    // Field-specific skills match (25 points)
    final careerSkills = List<String>.from(career['required_skills'] ?? []);
    int matchingSkills = 0;
    for (final skill in answers.currentSkills) {
      if (careerSkills.any((cs) => 
          cs.toLowerCase().contains(skill.toLowerCase()) ||
          skill.toLowerCase().contains(cs.toLowerCase()))) {
        matchingSkills++;
      }
    }
    if (answers.currentSkills.isNotEmpty) {
      score += (matchingSkills / answers.currentSkills.length * 25).round();
    }

    // Field-specific question answers (20 points)
    score += _scoreFieldSpecificAnswers(answers, career, fieldConfig);

    // Skill level match (10 points)
    final skillLevelScore = _getSkillLevelScore(answers.skillLevel);
    score += skillLevelScore;

    // Work preference match (10 points)
    score += _getWorkPreferenceScore(answers.workPreference, career, fieldConfig);

    // Long-term goal match (5 points)
    score += _getGoalScore(answers.longTermGoal, career);

    return score.clamp(0, 100);
  }

  static int _scoreFieldSpecificAnswers(
    QuestionnaireAnswers answers,
    Map<String, dynamic> career,
    CareerFieldConfig fieldConfig,
  ) {
    int score = 0;
    final answersMap = answers.fieldSpecificAnswers;
    
    // Score based on field-specific question answers
    // Each question can contribute up to 5 points
    for (int i = 0; i < fieldConfig.questions.length; i++) {
      final answerKey = 'q$i';
      if (answersMap.containsKey(answerKey)) {
        final answer = answersMap[answerKey]!.toLowerCase();
        // Higher scores for more advanced/experienced answers
        if (answer.contains('expert') || answer.contains('experienced') || 
            answer.contains('excel') || answer.contains('innovative')) {
          score += 5;
        } else if (answer.contains('can') || answer.contains('enjoy') || 
                   answer.contains('comfortable')) {
          score += 3;
        } else {
          score += 1;
        }
      }
    }

    return (score / fieldConfig.questions.length * 20).round().clamp(0, 20);
  }

  static int _getSkillLevelScore(String skillLevel) {
    switch (skillLevel.toLowerCase()) {
      case 'advanced':
        return 10;
      case 'intermediate':
        return 6;
      case 'beginner':
        return 3;
      default:
        return 0;
    }
  }

  static int _getWorkPreferenceScore(
    String workPreference,
    Map<String, dynamic> career,
    CareerFieldConfig fieldConfig,
  ) {
    final pref = workPreference.toLowerCase();
    final sector = (career['sector'] ?? '').toString().toLowerCase();
    
    if (fieldConfig.fieldId == 'technology' && pref.contains('technology')) return 10;
    if (fieldConfig.fieldId == 'design' && pref.contains('creativity')) return 10;
    if (fieldConfig.fieldId == 'finance' && pref.contains('data')) return 10;
    if (fieldConfig.fieldId == 'marketing' && (pref.contains('creativity') || pref.contains('people'))) return 10;
    if (fieldConfig.fieldId == 'business' && pref.contains('people')) return 10;
    
    return 5; // Default score
  }

  static int _getGoalScore(String goal, Map<String, dynamic> career) {
    final goalLower = goal.toLowerCase();
    final salaryRange = (career['salary_range'] ?? '').toString();
    
    if (goalLower.contains('salary') && salaryRange.contains('high')) return 5;
    if (goalLower.contains('stability') && career['future_demand'] == 'High') return 5;
    final careerType = (career['career_type'] ?? '').toString();
    if (goalLower.contains('remote') && careerType.contains('Remote')) return 5;
    
    return 2;
  }

  static String _generateFieldSpecificWhyItFits(
    QuestionnaireAnswers answers,
    Map<String, dynamic> career,
    CareerFieldConfig fieldConfig,
  ) {
    final reasons = <String>[];

    // Field match
    reasons.add('Perfect match for ${fieldConfig.fieldName} field');

    // Skills match
    final matchingSkills = _getMatchingSkills(answers.currentSkills, career);
    if (matchingSkills.isNotEmpty) {
      reasons.add('You already have ${matchingSkills.length} relevant ${fieldConfig.fieldName.toLowerCase()} skills');
    }

    // Skill level
    if (answers.skillLevel.toLowerCase() == 'advanced') {
      reasons.add('Your advanced skill level aligns well with this role');
    } else if (answers.skillLevel.toLowerCase() == 'intermediate') {
      reasons.add('Your intermediate experience is a good foundation');
    }

    // Field-specific insights
    final fieldAnswers = answers.fieldSpecificAnswers;
    if (fieldAnswers.isNotEmpty) {
      final firstAnswer = fieldAnswers.values.first.toLowerCase();
      if (firstAnswer.contains('expert') || firstAnswer.contains('experienced')) {
        reasons.add('Your experience matches the requirements');
      }
    }

    // Career type match
    final sector = (career['sector'] ?? '').toString().toLowerCase();
    if (answers.careerType.toLowerCase().contains('remote') && sector.contains('tech')) {
      reasons.add('Offers remote work opportunities');
    }

    return reasons.join('. ') + '.';
  }

  static List<String> _getMatchingSkills(
    List<String> userSkills,
    Map<String, dynamic> career,
  ) {
    final careerSkills = List<String>.from(career['required_skills'] ?? []);
    return userSkills.where((skill) {
      return careerSkills.any((cs) => 
          cs.toLowerCase().contains(skill.toLowerCase()) ||
          skill.toLowerCase().contains(cs.toLowerCase()));
    }).toList();
  }

  static List<String> _getSkillsToLearn(
    List<String> userSkills,
    Map<String, dynamic> career,
    CareerFieldConfig fieldConfig,
  ) {
    final careerSkills = List<String>.from(career['required_skills'] ?? []);
    final skillsToLearn = <String>[];
    
    for (final careerSkill in careerSkills) {
      final hasSkill = userSkills.any((skill) => 
          skill.toLowerCase().contains(careerSkill.toLowerCase()) ||
          careerSkill.toLowerCase().contains(skill.toLowerCase()));
      if (!hasSkill) {
        skillsToLearn.add(careerSkill);
      }
    }

    // If no specific skills found, use field-specific skills
    if (skillsToLearn.isEmpty) {
      for (final fieldSkill in fieldConfig.specificSkills) {
        final hasSkill = userSkills.any((skill) => 
            skill.toLowerCase().contains(fieldSkill.toLowerCase()));
        if (!hasSkill && skillsToLearn.length < 5) {
          skillsToLearn.add(fieldSkill);
        }
      }
    }

    return skillsToLearn.take(5).toList();
  }

  static List<String> _generateFieldSpecificLearningPath(
    Map<String, dynamic> career,
    String learningTime,
    CareerFieldConfig fieldConfig,
  ) {
    final path = <String>[];
    final jobTitle = career['job_title']?.toString() ?? '';
    final fieldName = fieldConfig.fieldName;

    // Step 1: Foundation
    path.add('Learn ${fieldName} fundamentals and core concepts');

    // Step 2: Field-specific skills
    if (fieldConfig.specificSkills.isNotEmpty) {
      path.add('Master ${fieldConfig.specificSkills.take(2).join(" and ")}');
    }

    // Step 3: Practical experience
    path.add('Build projects or gain hands-on experience in ${fieldName}');

    // Step 4: Specialization
    path.add('Focus on ${jobTitle} specific skills and tools');

    // Step 5: Career preparation
    if (learningTime.contains('1+ year')) {
      path.add('Pursue certifications or advanced training in ${fieldName}');
    } else {
      path.add('Create a portfolio and prepare for ${jobTitle} roles');
    }

    return path;
  }

  static List<Map<String, dynamic>> _getFieldSpecificCareers(CareerFieldConfig fieldConfig) {
    // Map field-specific careers with realistic data
    final allCareers = _getCareerDatabase();
    final fieldCareers = <Map<String, dynamic>>[];

    // Always ensure we process all related careers
    for (final careerTitle in fieldConfig.relatedCareers) {
      try {
        final matchingCareer = allCareers.firstWhere(
          (c) => c['job_title']?.toString().toLowerCase() == careerTitle.toLowerCase(),
          orElse: () => _createFieldSpecificCareer(careerTitle, fieldConfig),
        );
        fieldCareers.add(matchingCareer);
      } catch (e) {
        // If there's any error, create a career for this title
        fieldCareers.add(_createFieldSpecificCareer(careerTitle, fieldConfig));
      }
    }

    // CRITICAL: If for some reason we have no careers, create at least two
    if (fieldCareers.isEmpty && fieldConfig.relatedCareers.isNotEmpty) {
      fieldCareers.add(_createFieldSpecificCareer(
        fieldConfig.relatedCareers.first,
        fieldConfig,
      ));
      // Add second career if available
      if (fieldConfig.relatedCareers.length > 1) {
        fieldCareers.add(_createFieldSpecificCareer(
          fieldConfig.relatedCareers[1],
          fieldConfig,
        ));
      } else {
        // Create a variation if only one related career exists
        fieldCareers.add(_createFieldSpecificCareer(
          '${fieldConfig.fieldName} Specialist',
          fieldConfig,
        ));
      }
    } else if (fieldCareers.length == 1) {
      // If we only have one career, ensure we have at least two
      if (fieldConfig.relatedCareers.length > 1) {
        final existingTitle = fieldCareers.first['job_title']?.toString().toLowerCase() ?? '';
        final secondCareerTitle = fieldConfig.relatedCareers.firstWhere(
          (title) => title.toLowerCase() != existingTitle,
          orElse: () => fieldConfig.relatedCareers.length > 1 
              ? fieldConfig.relatedCareers[1]
              : '${fieldConfig.fieldName} Specialist',
        );
        fieldCareers.add(_createFieldSpecificCareer(secondCareerTitle, fieldConfig));
      } else {
        // Create a variation
        fieldCareers.add(_createFieldSpecificCareer(
          '${fieldConfig.fieldName} Specialist',
          fieldConfig,
        ));
      }
    }

    return fieldCareers;
  }

  static Map<String, dynamic> _createFieldSpecificCareer(
    String jobTitle,
    CareerFieldConfig fieldConfig,
  ) {
    return {
      'job_title': jobTitle,
      'sector': fieldConfig.fieldName,
      'summary': 'A ${fieldConfig.fieldName.toLowerCase()} role that matches your interests and skills',
      'required_skills': fieldConfig.specificSkills.take(5).toList(),
      'salary_range': _getSalaryRangeForField(fieldConfig.fieldId),
      'future_demand': 'High',
    };
  }

  static String _getSalaryRangeForField(String fieldId) {
    switch (fieldId) {
      case 'technology':
        return r'$70,000 - $150,000';
      case 'marketing':
        return r'$50,000 - $120,000';
      case 'finance':
        return r'$60,000 - $130,000';
      case 'design':
        return r'$55,000 - $110,000';
      case 'business':
        return r'$65,000 - $140,000';
      case 'healthcare':
        return r'$55,000 - $120,000';
      case 'science':
        return r'$50,000 - $110,000';
      case 'education':
        return r'$45,000 - $90,000';
      case 'psychology':
        return r'$50,000 - $100,000';
      case 'law':
        return r'$45,000 - $95,000';
      case 'tourism':
        return r'$35,000 - $75,000';
      case 'sales':
        return r'$40,000 - $120,000';
      default:
        return r'$50,000 - $100,000';
    }
  }

  // Fallback generic recommendations
  static List<CareerRecommendation> _generateGenericRecommendations(
    QuestionnaireAnswers answers,
  ) {
    final recommendations = <CareerRecommendation>[];
    final careers = _getCareerDatabase();

    for (final career in careers) {
      final score = _calculateGenericScore(answers, career);
      if (score > 30) {
        recommendations.add(
          CareerRecommendation(
            jobTitle: career['job_title'] as String,
            sector: career['sector'] as String,
            summary: career['summary'] as String,
            matchScore: score,
            whyItFits: 'Based on your general interests and skills',
            skillsYouHave: _getMatchingSkills(answers.currentSkills, career),
            skillsToLearn: _getSkillsToLearn(answers.currentSkills, career, 
                CareerFieldConfig.allFields['technology']!),
            learningPath: ['Learn basics', 'Build projects', 'Gain experience', 'Specialize', 'Apply for roles'],
            salaryRange: career['salary_range'] as String,
            futureDemand: career['future_demand'] as String,
          ),
        );
      }
    }

    recommendations.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    
    // Ensure at least 2 recommendations
    if (recommendations.isEmpty) {
      // Create two default generic careers
      final defaultCareer1 = careers.isNotEmpty ? careers.first : {
        'job_title': 'General Career Path',
        'sector': 'General',
        'summary': 'A career path that matches your interests',
        'salary_range': r'$50,000 - $100,000',
        'future_demand': 'Moderate',
        'required_skills': <String>[],
      };
      recommendations.add(
        CareerRecommendation(
          jobTitle: defaultCareer1['job_title'] as String,
          sector: defaultCareer1['sector'] as String,
          summary: defaultCareer1['summary'] as String,
          matchScore: 30,
          whyItFits: 'Based on your general profile and interests',
          skillsYouHave: _getMatchingSkills(answers.currentSkills, defaultCareer1),
          skillsToLearn: _getSkillsToLearn(answers.currentSkills, defaultCareer1, 
              CareerFieldConfig.allFields['technology']!),
          learningPath: ['Learn basics', 'Build projects', 'Gain experience', 'Specialize', 'Apply for roles'],
          salaryRange: defaultCareer1['salary_range'] as String,
          futureDemand: defaultCareer1['future_demand'] as String,
        ),
      );
      
      final defaultCareer2 = careers.length > 1 ? careers[1] : {
        'job_title': 'Alternative Career Path',
        'sector': 'General',
        'summary': 'Another career option that aligns with your skills',
        'salary_range': r'$45,000 - $95,000',
        'future_demand': 'Moderate',
        'required_skills': <String>[],
      };
      recommendations.add(
        CareerRecommendation(
          jobTitle: defaultCareer2['job_title'] as String,
          sector: defaultCareer2['sector'] as String,
          summary: defaultCareer2['summary'] as String,
          matchScore: 28,
          whyItFits: 'Another career path based on your profile',
          skillsYouHave: _getMatchingSkills(answers.currentSkills, defaultCareer2),
          skillsToLearn: _getSkillsToLearn(answers.currentSkills, defaultCareer2, 
              CareerFieldConfig.allFields['technology']!),
          learningPath: ['Learn basics', 'Build projects', 'Gain experience', 'Specialize', 'Apply for roles'],
          salaryRange: defaultCareer2['salary_range'] as String,
          futureDemand: defaultCareer2['future_demand'] as String,
        ),
      );
    } else if (recommendations.length == 1) {
      // If only one recommendation, add a second one
      final existingCareer = recommendations.first;
      final secondCareer = careers.length > 1 
          ? careers.firstWhere(
              (c) => c['job_title'] != existingCareer.jobTitle,
              orElse: () => careers.isNotEmpty ? careers[0] : {
                'job_title': 'Alternative Career Path',
                'sector': 'General',
                'summary': 'Another career option',
                'salary_range': r'$45,000 - $95,000',
                'future_demand': 'Moderate',
                'required_skills': <String>[],
              },
            )
          : {
              'job_title': 'Alternative Career Path',
              'sector': 'General',
              'summary': 'Another career option',
              'salary_range': r'$45,000 - $95,000',
              'future_demand': 'Moderate',
              'required_skills': <String>[],
            };
      
      recommendations.add(
        CareerRecommendation(
          jobTitle: secondCareer['job_title'] as String,
          sector: secondCareer['sector'] as String,
          summary: secondCareer['summary'] as String,
          matchScore: existingCareer.matchScore - 2,
          whyItFits: 'Another career path based on your profile',
          skillsYouHave: _getMatchingSkills(answers.currentSkills, secondCareer),
          skillsToLearn: _getSkillsToLearn(answers.currentSkills, secondCareer, 
              CareerFieldConfig.allFields['technology']!),
          learningPath: ['Learn basics', 'Build projects', 'Gain experience', 'Specialize', 'Apply for roles'],
          salaryRange: secondCareer['salary_range'] as String,
          futureDemand: secondCareer['future_demand'] as String,
        ),
      );
    }
    
    return recommendations.take(10).toList();
  }

  static int _calculateGenericScore(
    QuestionnaireAnswers answers,
    Map<String, dynamic> career,
  ) {
    int score = 0;
    final careerSector = (career['sector'] ?? '').toString().toLowerCase();
    
    if (answers.interestedAreas.any((a) => careerSector.contains(a.toLowerCase()))) {
      score += 20;
    }

    final careerSkills = List<String>.from(career['required_skills'] ?? []);
    for (final skill in answers.currentSkills) {
      if (careerSkills.any((cs) => cs.toLowerCase().contains(skill.toLowerCase()))) {
        score += 10;
      }
    }

    return score.clamp(0, 100);
  }

  static List<Map<String, dynamic>> _getCareerDatabase() {
    return [
      {
        'job_title': 'Software Developer',
        'sector': 'Technology',
        'summary': 'Design and develop software applications and systems',
        'required_skills': ['Coding', 'Problem-solving', 'Math & analysis', 'Communication'],
        'salary_range': r'$70,000 - $120,000',
        'future_demand': 'High',
      },
      {
        'job_title': 'UX/UI Designer',
        'sector': 'Design',
        'summary': 'Create user-friendly and visually appealing digital interfaces',
        'required_skills': ['Creativity / design skills', 'Communication', 'Problem-solving'],
        'salary_range': r'$60,000 - $100,000',
        'future_demand': 'High',
      },
      {
        'job_title': 'Data Analyst',
        'sector': 'Technology',
        'summary': 'Analyze data to help businesses make informed decisions',
        'required_skills': ['Data skills', 'Math & analysis', 'Problem-solving'],
        'salary_range': r'$65,000 - $110,000',
        'future_demand': 'High',
      },
      {
        'job_title': 'Marketing Specialist',
        'sector': 'Marketing',
        'summary': 'Develop and execute marketing strategies to promote products',
        'required_skills': ['Communication', 'Creativity / design skills', 'Sales'],
        'salary_range': r'$50,000 - $90,000',
        'future_demand': 'Medium',
      },
      {
        'job_title': 'Project Manager',
        'sector': 'Business',
        'summary': 'Lead and coordinate projects to ensure successful completion',
        'required_skills': ['Leadership', 'Communication', 'Problem-solving'],
        'salary_range': r'$70,000 - $130,000',
        'future_demand': 'High',
      },
      {
        'job_title': 'Cybersecurity Technician',
        'sector': 'Technology',
        'summary': 'Protect systems and networks from cyber threats',
        'required_skills': ['Coding', 'Problem-solving', 'Math & analysis'],
        'salary_range': r'$75,000 - $125,000',
        'future_demand': 'Very High',
      },
      {
        'job_title': 'Content Creator',
        'sector': 'Creative Arts',
        'summary': 'Create engaging content for digital platforms',
        'required_skills': ['Creativity / design skills', 'Writing', 'Communication'],
        'salary_range': r'$40,000 - $100,000',
        'future_demand': 'High',
      },
      {
        'job_title': 'Sales Representative',
        'sector': 'Business',
        'summary': 'Build relationships and sell products or services',
        'required_skills': ['Sales', 'Communication', 'Leadership'],
        'salary_range': r'$45,000 - $120,000',
        'future_demand': 'Medium',
      },
      {
        'job_title': 'Graphic Designer',
        'sector': 'Design',
        'summary': 'Create visual concepts to communicate ideas',
        'required_skills': ['Creativity / design skills', 'Communication'],
        'salary_range': r'$45,000 - $85,000',
        'future_demand': 'Medium',
      },
      {
        'job_title': 'HR Specialist',
        'sector': 'Business',
        'summary': 'Manage human resources and employee relations',
        'required_skills': ['Communication', 'Leadership', 'Problem-solving'],
        'salary_range': r'$50,000 - $90,000',
        'future_demand': 'Medium',
      },
      {
        'job_title': 'Financial Analyst',
        'sector': 'Finance',
        'summary': 'Analyze financial data to guide business decisions',
        'required_skills': ['Math & analysis', 'Problem-solving', 'Data skills'],
        'salary_range': r'$65,000 - $110,000',
        'future_demand': 'High',
      },
    ];
  }
}
