/// Model for storing questionnaire answers
class QuestionnaireAnswers {
  final String selectedCareerField; // NEW: Single career field selected
  final List<String> interestedAreas;
  final String skillLevel;
  final List<String> currentSkills; // Field-specific skills
  final String workPreference;
  final String careerType;
  final String longTermGoal;
  final String learningTime;
  final Map<String, dynamic> fieldSpecificAnswers; // Supports both String (single) and List<String> (multi-select)

  const QuestionnaireAnswers({
    required this.selectedCareerField,
    required this.interestedAreas,
    required this.skillLevel,
    required this.currentSkills,
    required this.workPreference,
    required this.careerType,
    required this.longTermGoal,
    required this.learningTime,
    this.fieldSpecificAnswers = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'selected_career_field': selectedCareerField,
      'interested_areas': interestedAreas,
      'skill_level': skillLevel,
      'current_skills': currentSkills,
      'work_preference': workPreference,
      'career_type': careerType,
      'long_term_goal': longTermGoal,
      'learning_time': learningTime,
      'field_specific_answers': fieldSpecificAnswers,
      'completed_at': DateTime.now().toIso8601String(),
    };
  }

  factory QuestionnaireAnswers.fromMap(Map<String, dynamic> map) {
    return QuestionnaireAnswers(
      selectedCareerField: map['selected_career_field'] ?? '',
      interestedAreas: List<String>.from(map['interested_areas'] ?? []),
      skillLevel: map['skill_level'] ?? '',
      currentSkills: List<String>.from(map['current_skills'] ?? []),
      workPreference: map['work_preference'] ?? '',
      careerType: map['career_type'] ?? '',
      longTermGoal: map['long_term_goal'] ?? '',
      learningTime: map['learning_time'] ?? '',
      fieldSpecificAnswers: Map<String, dynamic>.from(map['field_specific_answers'] ?? {}),
    );
  }
}

/// Career recommendation model
class CareerRecommendation {
  final String jobTitle;
  final String sector;
  final String summary;
  final int matchScore;
  final String whyItFits;
  final List<String> skillsYouHave;
  final List<String> skillsToLearn;
  final List<String> learningPath;
  final String salaryRange;
  final String futureDemand;

  const CareerRecommendation({
    required this.jobTitle,
    required this.sector,
    required this.summary,
    required this.matchScore,
    required this.whyItFits,
    required this.skillsYouHave,
    required this.skillsToLearn,
    required this.learningPath,
    required this.salaryRange,
    required this.futureDemand,
  });

  Map<String, dynamic> toMap() {
    return {
      'job_title': jobTitle,
      'sector': sector,
      'summary': summary,
      'match_score': matchScore,
      'why_it_fits': whyItFits,
      'skills_you_have': skillsYouHave,
      'skills_to_learn': skillsToLearn,
      'learning_path': learningPath,
      'salary_range': salaryRange,
      'future_demand': futureDemand,
    };
  }

  factory CareerRecommendation.fromMap(Map<String, dynamic> map) {
    return CareerRecommendation(
      jobTitle: map['job_title'] ?? '',
      sector: map['sector'] ?? '',
      summary: map['summary'] ?? '',
      matchScore: map['match_score'] ?? 0,
      whyItFits: map['why_it_fits'] ?? '',
      skillsYouHave: List<String>.from(map['skills_you_have'] ?? []),
      skillsToLearn: List<String>.from(map['skills_to_learn'] ?? []),
      learningPath: List<String>.from(map['learning_path'] ?? []),
      salaryRange: map['salary_range'] ?? '',
      futureDemand: map['future_demand'] ?? '',
    );
  }
}

