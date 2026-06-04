import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/supabase_service.dart';
import '../../providers/user_provider.dart';
import '../../data/models/career_field_config.dart';

/// Skills to Improve Screen
class SkillsToImproveScreen extends ConsumerStatefulWidget {
  const SkillsToImproveScreen({super.key});

  @override
  ConsumerState<SkillsToImproveScreen> createState() => _SkillsToImproveScreenState();
}

class _SkillsToImproveScreenState extends ConsumerState<SkillsToImproveScreen> {
  bool _isLoading = true;
  Map<String, List<Map<String, dynamic>>> _skillsByField = {};
  String _selectedCareerField = '';

  @override
  void initState() {
    super.initState();
    _loadSkills();
  }

  Future<void> _loadSkills() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final supabaseService = ref.read(supabaseServiceProvider);
      final userAnswers = await supabaseService.getUserAnswers();
      
      if (userAnswers != null) {
        _selectedCareerField = userAnswers['selected_career_field'] ?? '';
      }
      
      final savedCareers = await supabaseService.getSavedCareers();
      
      // Group skills by career field
      final skillsByField = <String, Map<String, dynamic>>{};
      
      for (final career in savedCareers) {
        final skills = career['skills_to_learn'] as List<dynamic>? ?? [];
        final learningPath = career['learning_path'] as List<dynamic>? ?? [];
        final jobTitle = career['job_title'] as String? ?? 'Career';
        final sector = career['sector'] as String? ?? '';
        
        // Determine field based on sector or job title
        String fieldId = _determineFieldFromCareer(sector, jobTitle);
        String fieldName = CareerFieldConfig.allFields[fieldId]?.fieldName ?? 
                          _getFieldNameFromId(fieldId);
        
        if (!skillsByField.containsKey(fieldId)) {
          skillsByField[fieldId] = {
            'fieldName': fieldName,
            'fieldId': fieldId,
            'skills': <String, Map<String, dynamic>>{},
          };
        }
        
        final fieldData = skillsByField[fieldId]!;
        final fieldSkills = fieldData['skills'] as Map<String, Map<String, dynamic>>;
        
        for (final skill in skills) {
          final skillStr = skill.toString();
          // Create a unique key combining field, skill, and career to ensure different learning paths
          // This ensures the same skill in different fields gets different paths
          final skillCareerKey = '$fieldId|$skillStr|$jobTitle';
          
          // Only create if it doesn't exist to avoid duplicates
          if (!fieldSkills.containsKey(skillCareerKey)) {
            // Generate unique learning path for this specific field-skill-career combination
            final uniqueLearningPath = _generateSkillSpecificLearningPath(
              skillStr, 
              fieldId, 
              fieldName,
              jobTitle, // Pass job title to make it career-specific
            );
            
            fieldSkills[skillCareerKey] = {
              'skill': skillStr,
              'career': jobTitle,
              'careers': <String>[jobTitle],
              'learning_path': uniqueLearningPath,
            };
          }
          // Don't add to careers list if key already exists - this prevents duplicates
        }
      }
      
      // Convert to list format grouped by field
      _skillsByField = {};
      for (var entry in skillsByField.entries) {
        final fieldData = entry.value;
        _skillsByField[entry.key] = [
          {
            'fieldName': fieldData['fieldName'] as String,
            'fieldId': fieldData['fieldId'] as String,
            'isHeader': true,
          },
          ...(fieldData['skills'] as Map<String, Map<String, dynamic>>).values.toList(),
        ];
      }
      
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _determineFieldFromCareer(String? sector, String jobTitle) {
    final titleLower = jobTitle.toLowerCase();
    final sectorLower = (sector ?? '').toLowerCase();
    
    // Check against all field IDs
    for (var fieldId in CareerFieldConfig.allFields.keys) {
      final config = CareerFieldConfig.allFields[fieldId]!;
      final fieldNameLower = config.fieldName.toLowerCase();
      
      // Check if job title or sector matches field
      if (titleLower.contains(fieldNameLower.split(' ').first.toLowerCase()) ||
          sectorLower.contains(fieldNameLower.split(' ').first.toLowerCase())) {
        return fieldId;
      }
      
      // Check related careers
      for (var career in config.relatedCareers) {
        if (titleLower.contains(career.toLowerCase())) {
          return fieldId;
        }
      }
    }
    
    // Default fallback
    return 'technology';
  }

  String _getFieldNameFromId(String fieldId) {
    return CareerFieldConfig.allFields[fieldId]?.fieldName ?? 
           fieldId.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
  }

  /// Generate a unique learning path for a specific skill based on field and career
  List<String> _generateSkillSpecificLearningPath(String skill, String fieldId, String fieldName, [String? careerTitle]) {
    final skillLower = skill.toLowerCase().trim();
    final careerLower = (careerTitle ?? '').toLowerCase();
    
    // Debug: Print skill name to verify matching
    // print('Generating path for skill: "$skill" (lowercase: "$skillLower") in field: $fieldId');
    
    // Create unique variation index based on skill name, field, and career
    // This ensures each skill gets a different learning path across different fields
    // Use the entire skill string to create a truly unique hash
    int skillHash = skill.hashCode;
    int fieldHash = fieldId.hashCode;
    int skillLength = skill.length;
    int skillFirstChar = skill.isNotEmpty ? skill.codeUnitAt(0) : 0;
    int skillLastChar = skill.length > 1 ? skill.codeUnitAt(skill.length - 1) : 0;
    int skillMiddleChar = skill.length > 2 ? skill.codeUnitAt(skill.length ~/ 2) : 0;
    // Sum all character codes for maximum uniqueness
    int skillCharSum = skill.codeUnits.fold(0, (sum, code) => sum + code);
    int careerHash = careerTitle?.hashCode ?? 0;
    // Include fieldId in hash to ensure different fields get different paths
    int combinedHash = ((skillHash * 53) + (fieldHash * 47) + (skillLength * 37) + (skillFirstChar * 23) + (skillLastChar * 17) + (skillMiddleChar * 13) + (skillCharSum * 7) + (careerHash * 5)).abs();
    int variationIndex = combinedHash % 5; // 5 different variations for more diversity
    
    // TECHNOLOGY / IT FIELD
    if (fieldId == 'technology') {
      if (skillLower.contains('problem') || skillLower.contains('debugging') || skillLower.contains('logic')) {
        final variations = [
          [
            'Start with coding challenges on platforms like HackerRank and LeetCode',
            'Learn debugging techniques and use debugging tools (Chrome DevTools, VS Code debugger)',
            'Study algorithms and data structures (Big O notation, sorting, searching)',
            'Practice solving real-world software engineering problems',
            'Build complex applications that require advanced problem-solving skills',
          ],
          [
            'Begin with algorithmic thinking exercises and logic puzzles',
            'Master systematic debugging approaches and error analysis',
            'Learn computational thinking and algorithm design patterns',
            'Apply problem-solving frameworks to software development challenges',
            'Develop critical thinking through code review and refactoring practice',
          ],
          [
            'Practice with competitive programming platforms (Codeforces, AtCoder)',
            'Study software troubleshooting methodologies and root cause analysis',
            'Learn advanced data structures and algorithmic complexity',
            'Work on open-source projects that require complex problem-solving',
            'Create technical solutions for real-world business problems',
          ],
          [
            'Master systematic problem decomposition and solution design',
            'Learn to use debugging tools effectively (breakpoints, logging, profiling)',
            'Study design patterns and architectural problem-solving approaches',
            'Practice solving complex algorithmic challenges and optimization problems',
            'Build projects that require multi-step problem-solving and system design',
          ],
          [
            'Develop logical reasoning through structured programming exercises',
            'Learn advanced debugging techniques for distributed systems and microservices',
            'Study problem-solving methodologies (divide and conquer, dynamic programming)',
            'Practice analyzing and fixing bugs in existing codebases',
            'Create innovative solutions to challenging technical problems',
          ],
        ];
        return variations[variationIndex % variations.length];
      }
      if (skillLower.contains('math') || skillLower.contains('statistic') || skillLower.contains('calculus')) {
        final variations = [
          [
            'Review discrete mathematics and linear algebra fundamentals',
            'Learn computational mathematics and algorithm complexity theory',
            'Study statistics for data science and machine learning applications',
            'Apply mathematical concepts to cryptography and security',
            'Take advanced courses in computer science mathematics',
          ],
          [
            'Master mathematical foundations: algebra, calculus, and discrete math',
            'Study probability theory and statistical methods for tech applications',
            'Learn mathematical modeling for software and system design',
            'Apply quantitative analysis to optimize algorithms and systems',
            'Explore advanced mathematics relevant to your specific tech domain',
          ],
          [
            'Build strong mathematical foundations through targeted courses',
            'Practice applying statistics and probability to data analysis',
            'Learn mathematical optimization techniques for software engineering',
            'Study numerical methods and computational mathematics',
            'Apply advanced math concepts to solve complex technical problems',
          ],
          [
            'Study graph theory and combinatorics for algorithm design',
            'Learn statistical analysis and hypothesis testing for data science',
            'Master linear algebra for machine learning and computer graphics',
            'Practice mathematical problem-solving through coding challenges',
            'Apply calculus and differential equations to system modeling',
          ],
          [
            'Develop mathematical reasoning through proof-based learning',
            'Study advanced statistics including regression analysis and Bayesian methods',
            'Learn mathematical optimization and linear programming',
            'Practice applying mathematical concepts to real-world tech problems',
            'Build expertise in mathematical foundations essential for advanced computing',
          ],
        ];
        return variations[variationIndex % variations.length];
      }
      if (skillLower.contains('programming') || skillLower.contains('coding') || skillLower.contains('python') || skillLower.contains('java')) {
        final variations = [
          [
            'Choose a language (Python, Java, JavaScript) and master its syntax',
            'Build projects: web apps, APIs, or desktop applications',
            'Learn software engineering principles (SOLID, design patterns)',
            'Contribute to open-source projects on GitHub',
            'Create a portfolio showcasing your programming projects',
          ],
          [
            'Start with fundamentals: variables, loops, functions, and data structures',
            'Practice coding daily through exercises and small projects',
            'Learn version control (Git) and collaborative development workflows',
            'Study code quality, testing, and documentation best practices',
            'Build a comprehensive portfolio demonstrating your coding abilities',
          ],
          [
            'Master core programming concepts and language-specific features',
            'Develop projects that solve real problems in your domain',
            'Learn advanced programming techniques and architectural patterns',
            'Participate in coding communities and peer code reviews',
            'Showcase your skills through GitHub contributions and personal projects',
          ],
          [
            'Learn object-oriented programming and functional programming paradigms',
            'Practice building full-stack applications with modern frameworks',
            'Study advanced language features and best practices',
            'Master debugging, testing, and code optimization techniques',
            'Create production-ready applications with proper error handling',
          ],
          [
            'Develop proficiency in multiple programming languages',
            'Learn to write clean, maintainable, and scalable code',
            'Practice implementing algorithms and data structures',
            'Study software architecture and system design principles',
            'Build complex applications demonstrating advanced programming skills',
          ],
        ];
        return variations[variationIndex % variations.length];
      }
      if (skillLower.contains('database') || skillLower.contains('sql')) {
        return [
          'Master SQL fundamentals and advanced querying techniques',
          'Learn database design principles and normalization',
          'Practice with different database systems (PostgreSQL, MySQL, MongoDB)',
          'Understand database optimization and indexing strategies',
          'Build applications with database integration',
        ];
      }
      if (skillLower.contains('cloud') || skillLower.contains('aws') || skillLower.contains('azure')) {
        return [
          'Get familiar with cloud platforms (AWS, Azure, or GCP)',
          'Learn cloud architecture patterns and best practices',
          'Practice deploying applications to the cloud',
          'Study containerization (Docker) and orchestration (Kubernetes)',
          'Pursue cloud certifications (AWS Certified Solutions Architect, etc.)',
        ];
      }
      // Default for Technology - multiple variations for uniqueness
      final defaultVariations = [
        [
          'Research $skill fundamentals in software development context',
          'Find tech-specific tutorials and documentation',
          'Build a tech project that uses $skill',
          'Join tech communities (Stack Overflow, GitHub, Reddit)',
          'Create a portfolio demonstrating your $skill proficiency',
        ],
        [
          'Learn $skill through hands-on coding projects and exercises',
          'Study technical documentation and API references',
          'Practice $skill by contributing to open-source projects',
          'Engage with developer communities and forums',
          'Build a comprehensive portfolio showcasing $skill applications',
        ],
        [
          'Master $skill through structured learning paths and courses',
          'Explore technical blogs and tutorials specific to $skill',
          'Apply $skill in real-world software development scenarios',
          'Participate in coding challenges and hackathons',
          'Document your $skill journey and create technical content',
        ],
        [
          'Understand $skill principles through practical implementation',
          'Study best practices and design patterns related to $skill',
          'Practice $skill by building scalable applications',
          'Connect with tech professionals and mentors',
          'Showcase $skill expertise through GitHub projects and demos',
        ],
        [
          'Explore $skill through interactive coding platforms',
          'Learn from technical case studies and real-world examples',
          'Practice $skill by solving complex technical problems',
          'Join developer meetups and tech conferences',
          'Build advanced projects that demonstrate mastery of $skill',
        ],
      ];
      return defaultVariations[variationIndex % defaultVariations.length];
    }

    // MARKETING FIELD
    if (fieldId == 'marketing') {
      if (skillLower.contains('problem') || skillLower.contains('analytical')) {
        return [
          'Learn marketing analytics and data interpretation',
          'Study consumer behavior analysis and market research methods',
          'Practice analyzing campaign performance metrics',
          'Learn to identify and solve marketing challenges',
          'Apply problem-solving to optimize marketing ROI',
        ];
      }
      if (skillLower.contains('math') || skillLower.contains('statistic') || skillLower.contains('data')) {
        return [
          'Learn marketing analytics and conversion rate optimization',
          'Study statistical analysis for A/B testing and experiments',
          'Master Excel and data visualization tools (Tableau, Google Analytics)',
          'Practice analyzing customer data and market trends',
          'Apply data-driven insights to marketing strategies',
        ];
      }
      if (skillLower.contains('communication') || skillLower.contains('writing') || skillLower.contains('content')) {
        return [
          'Learn copywriting techniques and persuasive writing',
          'Master social media communication and engagement strategies',
          'Practice creating compelling marketing messages for different channels',
          'Study brand voice and tone development',
          'Build a portfolio of marketing content and campaigns',
        ];
      }
      if (skillLower.contains('digital') || skillLower.contains('seo') || skillLower.contains('social')) {
        return [
          'Master digital marketing platforms (Google Ads, Facebook Ads, LinkedIn)',
          'Learn SEO fundamentals and keyword research strategies',
          'Study social media marketing and content creation',
          'Practice running paid advertising campaigns',
          'Analyze campaign performance and optimize based on data',
        ];
      }
      // Default for Marketing - multiple variations for uniqueness
      final defaultVariations = [
        [
          'Research $skill in marketing and advertising context',
          'Study successful marketing campaigns using $skill',
          'Practice $skill through real marketing projects',
          'Learn from marketing experts and case studies',
          'Build a marketing portfolio showcasing your $skill',
        ],
        [
          'Learn $skill fundamentals in digital marketing and brand management',
          'Study how $skill drives customer engagement and conversions',
          'Practice $skill by creating marketing campaigns and content',
          'Follow marketing thought leaders and industry publications',
          'Build a portfolio showcasing $skill in marketing contexts',
        ],
        [
          'Master $skill through marketing analytics and performance tracking',
          'Explore case studies of successful brands using $skill',
          'Apply $skill to optimize marketing funnels and customer journeys',
          'Learn from marketing certifications and professional courses',
          'Develop expertise in $skill through hands-on marketing projects',
        ],
        [
          'Understand $skill in the context of consumer psychology and behavior',
          'Study how $skill influences brand perception and customer loyalty',
          'Practice $skill through A/B testing and campaign optimization',
          'Connect with marketing professionals and join industry groups',
          'Create marketing strategies that leverage $skill effectively',
        ],
        [
          'Explore $skill through marketing automation and technology tools',
          'Learn how $skill integrates with modern marketing platforms',
          'Practice $skill by analyzing market trends and competitor strategies',
          'Study marketing metrics and KPIs related to $skill',
          'Build advanced marketing campaigns that showcase $skill mastery',
        ],
      ];
      return defaultVariations[variationIndex % defaultVariations.length];
    }

    // HEALTHCARE & PHARMACY FIELD
    if (fieldId == 'healthcare') {
      if (skillLower.contains('problem') || skillLower.contains('critical thinking')) {
        final variations = [
          [
            'Learn clinical reasoning and diagnostic thinking processes',
            'Study case-based learning and medical problem-solving',
            'Practice analyzing patient symptoms and medical histories',
            'Learn evidence-based medicine and clinical decision-making',
            'Apply problem-solving to patient care scenarios',
          ],
          [
            'Develop analytical thinking for clinical diagnosis and treatment planning',
            'Study medical case studies and differential diagnosis approaches',
            'Practice critical thinking in emergency and routine healthcare situations',
            'Learn systematic approaches to identifying and solving healthcare problems',
            'Apply problem-solving frameworks to improve patient outcomes',
          ],
          [
            'Master clinical decision-making and diagnostic reasoning',
            'Study evidence-based problem-solving in healthcare contexts',
            'Practice analyzing complex medical cases and developing treatment plans',
            'Learn to identify and address healthcare challenges systematically',
            'Develop expertise in clinical problem-solving through practice and mentorship',
          ],
        ];
        return variations[variationIndex % variations.length];
      }
      if (skillLower.contains('math') || skillLower.contains('calculation') || skillLower.contains('dosage')) {
        final variations = [
          [
            'Master medical mathematics and dosage calculations',
            'Learn pharmaceutical calculations and compounding',
            'Study biostatistics for healthcare research',
            'Practice medication dosage calculations and conversions',
            'Apply mathematical skills to patient care and medication management',
          ],
          [
            'Learn pharmaceutical mathematics and drug dosage calculations',
            'Master medication dosing formulas and conversion factors',
            'Study pharmacokinetics and medication administration calculations',
            'Practice calculating dosages for different patient populations',
            'Apply mathematical precision to ensure safe medication administration',
          ],
          [
            'Build strong mathematical foundations for healthcare applications',
            'Learn dosage calculation methods and medication math',
            'Study statistical analysis for healthcare research and quality improvement',
            'Practice medical calculations including IV rates and drug concentrations',
            'Develop mathematical competency essential for safe healthcare practice',
          ],
        ];
        return variations[variationIndex % variations.length];
      }
      if (skillLower.contains('communication') || skillLower.contains('patient')) {
        final variations = [
          [
            'Learn patient communication and empathy techniques',
            'Study medical terminology and professional healthcare language',
            'Practice explaining complex medical information to patients',
            'Learn interprofessional communication in healthcare settings',
            'Develop skills in patient counseling and education',
          ],
          [
            'Master therapeutic communication and active listening skills',
            'Learn to communicate effectively with patients and their families',
            'Practice delivering difficult medical news with compassion',
            'Study cultural competency and patient-centered communication',
            'Develop skills in patient advocacy and health education',
          ],
          [
            'Build strong interpersonal communication skills for healthcare',
            'Learn to adapt communication style for different patient needs',
            'Practice clear and empathetic patient interactions',
            'Study effective communication in multidisciplinary healthcare teams',
            'Develop expertise in patient counseling and health promotion',
          ],
        ];
        return variations[variationIndex % variations.length];
      }
      if (skillLower.contains('medical') || skillLower.contains('clinical') || skillLower.contains('patient care') || skillLower.contains('documentation')) {
        final variations = [
          [
            'Learn medical terminology and anatomy basics',
            'Study patient care protocols and safety standards',
            'Practice clinical skills through simulation training',
            'Gain hands-on experience through clinical rotations',
            'Pursue relevant healthcare certifications (CPR, BLS, etc.)',
          ],
          [
            'Master healthcare documentation standards and medical record keeping',
            'Learn clinical documentation requirements and regulatory compliance',
            'Practice accurate and thorough patient charting and documentation',
            'Study electronic health records (EHR) systems and documentation software',
            'Develop skills in medical coding and billing documentation',
          ],
          [
            'Understand medical terminology and clinical language',
            'Learn healthcare documentation best practices and standards',
            'Practice creating comprehensive patient care documentation',
            'Study legal and ethical aspects of medical documentation',
            'Gain experience with healthcare documentation in real clinical settings',
          ],
        ];
        return variations[variationIndex % variations.length];
      }
      // Default for Healthcare
      final defaultVariations = [
        [
          'Research $skill fundamentals in healthcare context',
          'Study medical guidelines and best practices for $skill',
          'Practice $skill through healthcare training programs',
          'Gain clinical experience applying $skill',
          'Pursue continuing education and certifications in $skill',
        ],
        [
          'Learn $skill principles specific to healthcare and patient care',
          'Study how $skill is applied in clinical and medical settings',
          'Practice $skill through healthcare simulations and case studies',
          'Gain hands-on experience with $skill in healthcare environments',
          'Pursue professional development and certifications related to $skill',
        ],
        [
          'Master $skill fundamentals relevant to healthcare professions',
          'Study evidence-based practices for $skill in healthcare',
          'Apply $skill through supervised clinical practice',
          'Learn from experienced healthcare professionals using $skill',
          'Build expertise in $skill through continuing education and training',
        ],
      ];
      return defaultVariations[variationIndex % defaultVariations.length];
    }

    // SCIENCE & LABORATORY FIELD
    if (fieldId == 'science') {
      if (skillLower.contains('problem') || skillLower.contains('analytical')) {
        return [
          'Learn scientific method and experimental design',
          'Study hypothesis formation and testing procedures',
          'Practice analyzing experimental data and drawing conclusions',
          'Learn to troubleshoot laboratory procedures and experiments',
          'Apply analytical thinking to scientific research problems',
        ];
      }
      if (skillLower.contains('math') || skillLower.contains('statistic') || skillLower.contains('calculation')) {
        return [
          'Master statistical analysis for scientific research',
          'Learn to use statistical software (R, SPSS, Python)',
          'Study experimental design and data interpretation',
          'Practice calculating concentrations, dilutions, and measurements',
          'Apply mathematics to analyze scientific data',
        ];
      }
      if (skillLower.contains('laboratory') || skillLower.contains('lab') || skillLower.contains('experiment')) {
        return [
          'Learn laboratory safety protocols and procedures',
          'Master laboratory techniques and equipment operation',
          'Practice following experimental protocols accurately',
          'Study quality control and quality assurance in labs',
          'Gain hands-on experience through laboratory internships',
        ];
      }
      // Default for Science - multiple variations for uniqueness
      final defaultVariations = [
        [
          'Research $skill fundamentals in scientific context',
          'Study scientific literature and research methods',
          'Practice $skill through laboratory work or experiments',
          'Learn from scientific experts and research papers',
          'Apply $skill to scientific research projects',
        ],
        [
          'Learn $skill principles through scientific methodology and experimentation',
          'Study peer-reviewed research and scientific publications on $skill',
          'Practice $skill through hands-on laboratory techniques and procedures',
          'Engage with scientific communities and research institutions',
          'Build expertise in $skill through scientific research and analysis',
        ],
        [
          'Master $skill fundamentals in experimental and theoretical contexts',
          'Explore scientific databases and research repositories for $skill',
          'Apply $skill through controlled experiments and data collection',
          'Learn from scientific mentors and research collaborations',
          'Develop proficiency in $skill through scientific writing and presentation',
        ],
        [
          'Understand $skill in the context of scientific inquiry and discovery',
          'Study how $skill contributes to scientific knowledge and understanding',
          'Practice $skill through scientific observation and measurement',
          'Connect with researchers and scientists working with $skill',
          'Create scientific projects that demonstrate mastery of $skill',
        ],
        [
          'Explore $skill through interdisciplinary scientific approaches',
          'Learn how $skill integrates with various scientific disciplines',
          'Practice $skill by analyzing scientific data and results',
          'Study scientific protocols and standards related to $skill',
          'Build advanced scientific capabilities in $skill through research',
        ],
      ];
      return defaultVariations[variationIndex % defaultVariations.length];
    }

    // EDUCATION & TEACHING FIELD
    if (fieldId == 'education') {
      // Specific skill: Lesson Planning - check for exact match or contains both words
      if (skillLower.contains('lesson') && skillLower.contains('plan')) {
        final variations = [
          [
            'Learn backward design principles (start with learning objectives)',
            'Study curriculum standards and learning outcomes alignment',
            'Practice creating detailed lesson plans with clear structure',
            'Master differentiation strategies for diverse learners',
            'Develop skills in creating engaging and interactive lesson activities',
          ],
          [
            'Study lesson plan templates and frameworks (5E, Bloom\'s Taxonomy)',
            'Learn to incorporate multiple learning modalities in lessons',
            'Practice writing clear learning objectives and success criteria',
            'Master time management and pacing in lesson delivery',
            'Create a portfolio of effective lesson plans across subjects',
          ],
          [
            'Learn to design lessons that accommodate different learning styles',
            'Study how to integrate technology and multimedia in lesson planning',
            'Practice creating formative and summative assessments within lessons',
            'Master the art of sequencing learning activities logically',
            'Develop expertise in adapting lessons for special needs students',
          ],
          [
            'Understand curriculum mapping and lesson alignment strategies',
            'Learn to create culturally responsive and inclusive lesson plans',
            'Practice designing project-based and inquiry-based learning experiences',
            'Study how to incorporate real-world applications in lessons',
            'Build skills in creating differentiated instruction plans',
          ],
          [
            'Master the components of effective lesson planning (hook, instruction, practice, closure)',
            'Learn to design lessons that promote critical thinking and problem-solving',
            'Practice creating cross-curricular lesson plans',
            'Study assessment integration strategies in lesson design',
            'Develop expertise in creating engaging and student-centered lessons',
          ],
        ];
        return variations[variationIndex % variations.length];
      }
      
      // Specific skill: Student Assessment - check for exact match or contains both words
      if (skillLower.contains('student') && skillLower.contains('assess')) {
        final variations = [
          [
            'Learn formative assessment techniques (exit tickets, quick checks)',
            'Study summative assessment design and rubrics creation',
            'Practice creating authentic assessments that measure real understanding',
            'Master different assessment types (quizzes, projects, portfolios, presentations)',
            'Develop skills in providing constructive feedback to students',
          ],
          [
            'Understand assessment for learning vs assessment of learning',
            'Learn to design rubrics and scoring guides for various assignments',
            'Practice using technology tools for assessment (Kahoot, Google Forms)',
            'Study differentiated assessment strategies for diverse learners',
            'Master the art of creating fair and unbiased assessments',
          ],
          [
            'Learn to use data from assessments to inform instruction',
            'Study alternative assessment methods (peer assessment, self-assessment)',
            'Practice creating performance-based and project-based assessments',
            'Master portfolio assessment and student reflection techniques',
            'Develop skills in analyzing assessment results and identifying learning gaps',
          ],
          [
            'Understand standards-based assessment and grading practices',
            'Learn to create assessments that align with learning objectives',
            'Study authentic assessment design (real-world tasks and projects)',
            'Practice developing assessment tools for different learning styles',
            'Master the use of assessment data to differentiate instruction',
          ],
          [
            'Learn to design diagnostic assessments to identify student needs',
            'Study how to create valid and reliable assessment instruments',
            'Practice using assessment results to provide targeted feedback',
            'Master portfolio-based and competency-based assessment approaches',
            'Develop expertise in using assessments to track student progress over time',
          ],
        ];
        return variations[variationIndex % variations.length];
      }
      
      if (skillLower.contains('problem') || skillLower.contains('critical')) {
        final variations = [
          [
            'Learn pedagogical problem-solving and teaching strategies',
            'Study how to help students develop critical thinking skills',
            'Practice creating problem-based learning activities',
            'Learn to identify and address learning challenges',
            'Apply problem-solving to classroom management and instruction',
          ],
          [
            'Master Socratic questioning techniques to develop student thinking',
            'Learn to design inquiry-based learning experiences',
            'Practice creating scenarios that require analytical thinking',
            'Study methods for teaching problem-solving frameworks to students',
            'Develop skills in facilitating student-led problem-solving sessions',
          ],
          [
            'Understand how to scaffold critical thinking skills development',
            'Learn to create open-ended questions that promote deep thinking',
            'Practice designing activities that challenge student assumptions',
            'Master techniques for teaching logical reasoning and argumentation',
            'Develop expertise in fostering metacognitive skills in students',
          ],
          [
            'Study cognitive development theories and their application to teaching',
            'Learn to design lessons that promote higher-order thinking skills',
            'Practice creating case studies and real-world problem scenarios',
            'Master the art of facilitating classroom discussions and debates',
            'Build skills in teaching students to evaluate evidence and sources',
          ],
          [
            'Learn to integrate critical thinking across all subject areas',
            'Study methods for teaching students to identify bias and perspective',
            'Practice creating learning experiences that require synthesis and evaluation',
            'Master techniques for developing student reasoning and argumentation skills',
            'Develop expertise in fostering independent and creative problem-solving',
          ],
        ];
        return variations[variationIndex % variations.length];
      }
      if (skillLower.contains('communication') || skillLower.contains('presentation')) {
        final variations = [
          [
            'Learn effective teaching communication techniques',
            'Study how to explain complex concepts simply',
            'Practice engaging different learning styles',
            'Master classroom presentation and public speaking',
            'Develop skills in parent-teacher communication',
          ],
          [
            'Master active listening skills for understanding student needs',
            'Learn to adapt communication style for different age groups',
            'Practice using visual aids and multimedia in teaching',
            'Study non-verbal communication and classroom presence',
            'Develop skills in facilitating student-to-student communication',
          ],
          [
            'Understand how to communicate learning objectives clearly to students',
            'Learn to use storytelling and narrative techniques in teaching',
            'Practice creating engaging presentations that capture student attention',
            'Master the art of asking questions that promote discussion',
            'Develop expertise in communicating feedback effectively',
          ],
          [
            'Study cross-cultural communication in diverse classrooms',
            'Learn to use technology tools for enhanced communication',
            'Practice developing clear and concise explanations of complex topics',
            'Master techniques for managing classroom discussions and debates',
            'Build skills in communicating with parents and guardians',
          ],
          [
            'Learn to use body language and voice modulation effectively',
            'Study methods for making abstract concepts concrete and understandable',
            'Practice creating interactive presentations that engage students',
            'Master the skill of adapting communication for special needs students',
            'Develop expertise in using communication to build positive classroom culture',
          ],
        ];
        return variations[variationIndex % variations.length];
      }
      if (skillLower.contains('teaching') || skillLower.contains('instruction') || skillLower.contains('pedagogy')) {
        final variations = [
          [
            'Learn teaching methodologies and pedagogical approaches',
            'Study curriculum development and lesson planning',
            'Practice classroom management and student engagement',
            'Gain experience through student teaching or tutoring',
            'Pursue teaching certifications and professional development',
          ],
          [
            'Master differentiated instruction strategies for diverse learners',
            'Learn to apply various teaching models (direct instruction, inquiry-based, cooperative learning)',
            'Study educational psychology and learning theories',
            'Practice creating inclusive and culturally responsive classrooms',
            'Develop skills in using educational technology effectively',
          ],
          [
            'Understand constructivist and student-centered teaching approaches',
            'Learn to design engaging and interactive learning experiences',
            'Study classroom management techniques and behavior strategies',
            'Practice adapting instruction based on student assessment data',
            'Master the art of creating positive learning environments',
          ],
          [
            'Study curriculum design and instructional planning frameworks',
            'Learn to integrate multiple subjects and cross-curricular connections',
            'Practice using formative assessment to guide instruction',
            'Master techniques for engaging reluctant learners',
            'Develop expertise in creating project-based and experiential learning',
          ],
          [
            'Learn to apply Universal Design for Learning (UDL) principles',
            'Study methods for teaching students with diverse learning needs',
            'Practice creating collaborative and cooperative learning activities',
            'Master the use of educational technology and digital tools',
            'Develop skills in reflective teaching and continuous improvement',
          ],
        ];
        return variations[variationIndex % variations.length];
      }
      // Default for Education - use variationIndex that includes fieldHash for uniqueness
      final defaultVariations = [
        [
          'Research $skill in educational context',
          'Study teaching methods that incorporate $skill',
          'Practice $skill through teaching or tutoring',
          'Learn from experienced educators and educational research',
          'Apply $skill to improve student learning outcomes',
        ],
        [
          'Learn $skill fundamentals relevant to education and teaching',
          'Study how $skill is applied in classroom settings',
          'Practice $skill through educational workshops and training',
          'Gain experience applying $skill in teaching or tutoring contexts',
          'Pursue professional development opportunities focused on $skill',
        ],
        [
          'Master $skill principles specific to educational environments',
          'Study evidence-based practices for $skill in teaching',
          'Practice $skill through lesson planning and classroom activities',
          'Learn from educational experts and peer collaboration',
          'Build expertise in $skill through continuous practice and reflection',
        ],
        [
          'Understand $skill in the context of student learning and development',
          'Study pedagogical approaches that emphasize $skill',
          'Practice $skill through hands-on teaching experiences',
          'Learn to adapt $skill for different grade levels and subjects',
          'Develop proficiency in $skill through mentorship and professional learning communities',
        ],
        [
          'Explore $skill through educational research and best practices',
          'Study how $skill enhances teaching effectiveness and student engagement',
          'Practice $skill in diverse educational settings',
          'Learn to integrate $skill with curriculum standards and learning objectives',
          'Build mastery in $skill through ongoing professional development and practice',
        ],
      ];
      return defaultVariations[variationIndex % defaultVariations.length];
    }

    // PSYCHOLOGY & SOCIAL WORK FIELD
    if (fieldId == 'psychology') {
      if (skillLower.contains('problem') || skillLower.contains('analytical')) {
        return [
          'Learn psychological assessment and diagnostic thinking',
          'Study case formulation and treatment planning',
          'Practice analyzing client behaviors and mental health patterns',
          'Learn evidence-based therapeutic problem-solving',
          'Apply analytical skills to psychological research',
        ];
      }
      if (skillLower.contains('communication') || skillLower.contains('listening') || skillLower.contains('counseling')) {
        return [
          'Learn active listening and therapeutic communication',
          'Study counseling techniques and empathy building',
          'Practice conducting intake interviews and assessments',
          'Master non-verbal communication and rapport building',
          'Develop skills in crisis intervention and support',
        ];
      }
      // Default for Psychology - multiple variations for uniqueness
      final defaultVariations = [
        [
          'Research $skill in psychology and mental health context',
          'Study psychological theories and practices related to $skill',
          'Practice $skill through counseling or social work',
          'Learn from licensed professionals and case studies',
          'Apply $skill to support client well-being and mental health',
        ],
        [
          'Learn $skill fundamentals in clinical psychology and therapy',
          'Study evidence-based psychological interventions using $skill',
          'Practice $skill through supervised clinical experiences',
          'Engage with psychology professionals and therapeutic communities',
          'Build expertise in $skill through psychology training and certification',
        ],
        [
          'Master $skill principles in counseling and mental health support',
          'Explore psychological research and studies related to $skill',
          'Apply $skill through case management and client support',
          'Learn from psychology mentors and professional development programs',
          'Develop proficiency in $skill for mental health practice',
        ],
        [
          'Understand $skill in the context of human behavior and cognition',
          'Study how $skill applies to psychological assessment and treatment',
          'Practice $skill through therapeutic techniques and interventions',
          'Connect with psychology professionals and mental health organizations',
          'Create therapeutic approaches that incorporate $skill effectively',
        ],
        [
          'Explore $skill through psychological assessment and evaluation',
          'Learn how $skill integrates with various therapeutic modalities',
          'Practice $skill by analyzing psychological data and client needs',
          'Study psychology ethics and professional standards related to $skill',
          'Build advanced psychological capabilities in $skill through practice',
        ],
      ];
      return defaultVariations[variationIndex % defaultVariations.length];
    }

    // LAW & PUBLIC ADMINISTRATION FIELD
    if (fieldId == 'law') {
      if (skillLower.contains('problem') || skillLower.contains('analytical')) {
        return [
          'Learn legal reasoning and case analysis techniques',
          'Study how to identify legal issues and apply precedents',
          'Practice analyzing legal documents and contracts',
          'Learn to construct legal arguments and defenses',
          'Apply analytical thinking to legal problem-solving',
        ];
      }
      if (skillLower.contains('communication') || skillLower.contains('writing')) {
        return [
          'Learn legal writing and brief drafting',
          'Study oral advocacy and courtroom presentation',
          'Practice client communication and consultation',
          'Master legal research and citation methods',
          'Develop skills in negotiation and mediation',
        ];
      }
      // Default for Law - multiple variations for uniqueness
      final defaultVariations = [
        [
          'Research $skill in legal and administrative context',
          'Study legal precedents and regulations related to $skill',
          'Practice $skill through legal internships or paralegal work',
          'Learn from legal professionals and case law',
          'Apply $skill to legal practice or public administration',
        ],
        [
          'Learn $skill fundamentals in legal practice and jurisprudence',
          'Study how $skill is applied in legal proceedings and documentation',
          'Practice $skill through legal research and case analysis',
          'Engage with legal professionals and law communities',
          'Build expertise in $skill through legal training and certification',
        ],
        [
          'Master $skill principles in legal writing and case management',
          'Explore legal databases and resources related to $skill',
          'Apply $skill through legal drafting and document preparation',
          'Learn from legal mentors and professional development programs',
          'Develop proficiency in $skill for legal practice',
        ],
        [
          'Understand $skill in the context of legal procedures and compliance',
          'Study how $skill applies to legal research and case preparation',
          'Practice $skill through legal analysis and statutory interpretation',
          'Connect with legal professionals and bar associations',
          'Create legal strategies that leverage $skill effectively',
        ],
        [
          'Explore $skill through legal research and case law analysis',
          'Learn how $skill integrates with various areas of legal practice',
          'Practice $skill by analyzing legal documents and precedents',
          'Study legal ethics and professional standards related to $skill',
          'Build advanced legal capabilities in $skill through practice',
        ],
      ];
      return defaultVariations[variationIndex % defaultVariations.length];
    }

    // TOURISM & HOSPITALITY FIELD
    if (fieldId == 'tourism') {
      if (skillLower.contains('communication') || skillLower.contains('customer')) {
        return [
          'Learn hospitality communication and guest service',
          'Study cultural sensitivity and cross-cultural communication',
          'Practice handling customer inquiries and complaints',
          'Master multilingual communication basics',
          'Develop skills in creating memorable guest experiences',
        ];
      }
      if (skillLower.contains('management') || skillLower.contains('organization')) {
        return [
          'Learn hospitality operations and event management',
          'Study hotel and tourism industry best practices',
          'Practice coordinating travel arrangements and bookings',
          'Master customer relationship management systems',
          'Gain experience through hospitality internships',
        ];
      }
      // Default for Tourism - multiple variations for uniqueness
      final defaultVariations = [
        [
          'Research $skill in tourism and hospitality context',
          'Study industry standards and customer service practices',
          'Practice $skill through hospitality or travel work',
          'Learn from hospitality professionals and case studies',
          'Apply $skill to enhance guest experiences',
        ],
        [
          'Learn $skill fundamentals in tourism management and hospitality',
          'Study how $skill drives customer satisfaction and loyalty',
          'Practice $skill through hotel operations and guest services',
          'Engage with tourism professionals and hospitality communities',
          'Build expertise in $skill through hospitality training and certification',
        ],
        [
          'Master $skill principles in travel planning and destination management',
          'Explore tourism trends and best practices related to $skill',
          'Apply $skill through event planning and tourism operations',
          'Learn from tourism mentors and professional development programs',
          'Develop proficiency in $skill for hospitality excellence',
        ],
        [
          'Understand $skill in the context of cultural tourism and experiences',
          'Study how $skill applies to tourism marketing and promotion',
          'Practice $skill through tour guiding and customer interaction',
          'Connect with tourism professionals and industry organizations',
          'Create tourism experiences that showcase $skill effectively',
        ],
        [
          'Explore $skill through sustainable tourism and responsible travel',
          'Learn how $skill integrates with various tourism sectors',
          'Practice $skill by analyzing tourism data and guest feedback',
          'Study tourism regulations and industry standards related to $skill',
          'Build advanced tourism capabilities in $skill through practice',
        ],
      ];
      return defaultVariations[variationIndex % defaultVariations.length];
    }

    // FINANCE FIELD
    if (fieldId == 'finance') {
      if (skillLower.contains('problem') || skillLower.contains('analytical')) {
        return [
          'Learn financial analysis and risk assessment techniques',
          'Study how to identify financial problems and opportunities',
          'Practice analyzing financial statements and market trends',
          'Learn to solve complex financial modeling challenges',
          'Apply analytical thinking to investment and portfolio decisions',
        ];
      }
      if (skillLower.contains('math') || skillLower.contains('statistic') || skillLower.contains('calculation') || skillLower.contains('quantitative')) {
        return [
          'Master financial mathematics and time value of money concepts',
          'Learn statistical analysis for financial modeling and forecasting',
          'Study quantitative methods for risk assessment',
          'Practice financial calculations (NPV, IRR, ROI, etc.)',
          'Apply advanced mathematics to derivatives and portfolio theory',
        ];
      }
      if (skillLower.contains('excel') || skillLower.contains('financial modeling') || skillLower.contains('spreadsheet')) {
        return [
          'Master Excel advanced functions (VLOOKUP, INDEX/MATCH, PivotTables)',
          'Learn financial modeling best practices and techniques',
          'Study building DCF models, LBO models, and M&A models',
          'Practice creating financial dashboards and reports',
          'Learn VBA programming for financial automation',
        ];
      }
      if (skillLower.contains('analysis') || skillLower.contains('financial analysis') || skillLower.contains('investment')) {
        return [
          'Learn fundamental and technical analysis methods',
          'Study financial statement analysis and ratio calculations',
          'Practice analyzing company valuations and market trends',
          'Master investment analysis and portfolio management',
          'Learn to create investment recommendations and reports',
        ];
      }
      if (skillLower.contains('accounting') || skillLower.contains('bookkeeping') || skillLower.contains('financial reporting')) {
        return [
          'Learn accounting principles (GAAP, IFRS) and double-entry bookkeeping',
          'Study financial statement preparation and reporting',
          'Practice recording transactions and maintaining ledgers',
          'Master reconciliation and financial closing procedures',
          'Pursue accounting certifications (CPA, CMA, etc.)',
        ];
      }
      if (skillLower.contains('risk') || skillLower.contains('compliance') || skillLower.contains('regulatory')) {
        return [
          'Learn risk management frameworks and methodologies',
          'Study financial regulations and compliance requirements',
          'Practice identifying and assessing financial risks',
          'Master risk mitigation strategies and controls',
          'Understand regulatory reporting and audit processes',
        ];
      }
      if (skillLower.contains('budget') || skillLower.contains('forecast') || skillLower.contains('planning')) {
        return [
          'Learn budgeting fundamentals and variance analysis',
          'Study financial forecasting techniques and models',
          'Practice creating annual budgets and financial plans',
          'Master cash flow planning and working capital management',
          'Apply budgeting skills to strategic financial planning',
        ];
      }
      if (skillLower.contains('communication') || skillLower.contains('presentation') || skillLower.contains('reporting')) {
        return [
          'Learn to present financial data clearly and effectively',
          'Study how to explain complex financial concepts to non-financial audiences',
          'Practice creating executive financial reports and dashboards',
          'Master financial storytelling and data visualization',
          'Develop skills in financial consulting and advisory',
        ];
      }
      // Default for Finance - multiple variations for uniqueness
      final defaultVariations = [
        [
          'Research $skill fundamentals in finance and accounting context',
          'Study financial best practices and industry standards for $skill',
          'Practice $skill through financial analysis or accounting work',
          'Learn from finance professionals and financial case studies',
          'Apply $skill to improve financial decision-making and analysis',
        ],
        [
          'Learn $skill principles in financial management and investment',
          'Study how $skill is applied in corporate finance and banking',
          'Practice $skill through financial modeling and analysis',
          'Engage with finance professionals and investment communities',
          'Build expertise in $skill through finance certifications (CFA, CPA)',
        ],
        [
          'Master $skill fundamentals in accounting and financial reporting',
          'Explore financial markets and instruments related to $skill',
          'Apply $skill through portfolio management and risk analysis',
          'Learn from finance mentors and professional development programs',
          'Develop proficiency in $skill for financial advisory services',
        ],
        [
          'Understand $skill in the context of financial planning and wealth management',
          'Study how $skill applies to financial analysis and valuation',
          'Practice $skill through budgeting, forecasting, and financial modeling',
          'Connect with finance professionals and financial associations',
          'Create financial strategies that leverage $skill effectively',
        ],
        [
          'Explore $skill through financial technology and fintech applications',
          'Learn how $skill integrates with various financial services',
          'Practice $skill by analyzing financial data and market trends',
          'Study financial regulations and compliance standards related to $skill',
          'Build advanced financial capabilities in $skill through practice',
        ],
      ];
      return defaultVariations[variationIndex % defaultVariations.length];
    }

    // SALES & RETAIL FIELD
    if (fieldId == 'sales') {
      if (skillLower.contains('problem') || skillLower.contains('analytical')) {
        return [
          'Learn to identify customer needs and pain points',
          'Study sales analytics and performance metrics',
          'Practice analyzing sales data and trends',
          'Learn to overcome objections and close deals',
          'Apply problem-solving to sales challenges',
        ];
      }
      if (skillLower.contains('communication') || skillLower.contains('persuasion')) {
        return [
          'Learn sales communication and persuasion techniques',
          'Study customer psychology and buying behavior',
          'Practice product demonstrations and presentations',
          'Master objection handling and negotiation',
          'Develop skills in building long-term customer relationships',
        ];
      }
      if (skillLower.contains('sales') || skillLower.contains('retail')) {
        return [
          'Learn sales fundamentals and customer service',
          'Study product knowledge and competitive analysis',
          'Practice sales techniques through role-playing',
          'Master point-of-sale systems and sales processes',
          'Gain experience through retail or sales positions',
        ];
      }
      // Default for Sales - multiple variations for uniqueness
      final defaultVariations = [
        [
          'Research $skill in sales and retail context',
          'Study successful sales strategies using $skill',
          'Practice $skill through sales or retail work',
          'Learn from sales professionals and training programs',
          'Apply $skill to improve sales performance',
        ],
        [
          'Learn $skill fundamentals in sales techniques and customer engagement',
          'Study how $skill drives sales performance and revenue growth',
          'Practice $skill through sales calls, presentations, and negotiations',
          'Engage with sales professionals and sales communities',
          'Build expertise in $skill through sales training and certification',
        ],
        [
          'Master $skill principles in relationship selling and account management',
          'Explore sales methodologies and frameworks related to $skill',
          'Apply $skill through prospecting, qualifying, and closing deals',
          'Learn from sales mentors and professional development programs',
          'Develop proficiency in $skill for sales excellence',
        ],
        [
          'Understand $skill in the context of consultative selling and value creation',
          'Study how $skill applies to sales pipeline management and forecasting',
          'Practice $skill through customer discovery and needs analysis',
          'Connect with sales professionals and sales organizations',
          'Create sales strategies that leverage $skill effectively',
        ],
        [
          'Explore $skill through sales technology and CRM platforms',
          'Learn how $skill integrates with various sales processes and methodologies',
          'Practice $skill by analyzing sales data and performance metrics',
          'Study sales best practices and industry standards related to $skill',
          'Build advanced sales capabilities in $skill through practice',
        ],
      ];
      return defaultVariations[variationIndex % defaultVariations.length];
    }

    // DEFAULT - Field-agnostic but skill-specific
    if (skillLower.contains('problem') || skillLower.contains('debugging') || skillLower.contains('logic')) {
      return [
        'Start with basic logic puzzles and analytical exercises',
        'Learn systematic problem-solving frameworks',
        'Practice applying problem-solving to ${fieldName.toLowerCase()} scenarios',
        'Study how experts in ${fieldName.toLowerCase()} solve problems',
        'Build projects that require complex problem-solving in ${fieldName.toLowerCase()}',
      ];
    }
    if (skillLower.contains('math') || skillLower.contains('statistic') || skillLower.contains('calculation')) {
      return [
        'Review fundamental mathematics concepts relevant to ${fieldName.toLowerCase()}',
        'Learn statistics and data analysis for ${fieldName.toLowerCase()}',
        'Practice with ${fieldName.toLowerCase()}-specific calculations',
        'Apply mathematical concepts to ${fieldName.toLowerCase()} problems',
        'Take advanced courses in mathematics for ${fieldName.toLowerCase()}',
      ];
    }
    if (skillLower.contains('communication') || skillLower.contains('writing') || skillLower.contains('presentation')) {
      final variations = [
        [
          'Learn ${fieldName.toLowerCase()}-specific communication styles',
          'Practice clear and professional writing for ${fieldName.toLowerCase()}',
          'Study effective presentation techniques in ${fieldName.toLowerCase()}',
          'Learn to tailor communication to ${fieldName.toLowerCase()} audiences',
          'Build a portfolio of ${fieldName.toLowerCase()} communication work',
        ],
        [
          'Master verbal and written communication fundamentals',
          'Practice active listening and clear expression in ${fieldName.toLowerCase()} contexts',
          'Develop presentation skills through public speaking practice',
          'Learn to adapt your communication style for different ${fieldName.toLowerCase()} stakeholders',
          'Create examples of effective ${fieldName.toLowerCase()} communication',
        ],
        [
          'Study communication theory and best practices for ${fieldName.toLowerCase()}',
          'Practice professional writing: emails, reports, and documentation',
          'Learn visual communication and data presentation techniques',
          'Develop skills in cross-cultural and cross-functional communication',
          'Build a communication portfolio demonstrating your ${fieldName.toLowerCase()} expertise',
        ],
      ];
      return variations[variationIndex];
    }

    // Ultimate default
    return [
      'Research $skill fundamentals in ${fieldName.toLowerCase()} context',
      'Find ${fieldName.toLowerCase()}-specific learning resources',
      'Practice $skill through ${fieldName.toLowerCase()} projects or exercises',
      'Learn from ${fieldName.toLowerCase()} experts and professionals',
      'Apply $skill in real-world ${fieldName.toLowerCase()} scenarios',
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        title: const Text(
          'Skills to Improve',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D9FF)),
              ),
            )
          : _skillsByField.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 80,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'No Skills to Improve Yet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Save some careers to see recommended skills to learn.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00D9FF),
                            foregroundColor: const Color(0xFF0F0F23),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text('Explore Careers'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Skills to Improve',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Organized by career field',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Display skills grouped by field
                      ..._skillsByField.values.expand((fieldSkills) => fieldSkills).map((item) {
                        if (item['isHeader'] == true) {
                          return _buildFieldHeader(item['fieldName'] as String);
                        } else {
                          return _buildSkillCard(item);
                        }
                      }),
                    ],
                  ),
                ),
    );
  }

  Widget _buildFieldHeader(String fieldName) {
    return Container(
      margin: const EdgeInsets.only(top: 24, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00D9FF).withOpacity(0.2),
            const Color(0xFFFF6B9D).withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00D9FF).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00D9FF).withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.category,
              color: Color(0xFF00D9FF),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              fieldName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillCard(Map<String, dynamic> skillData) {
    final skill = skillData['skill'] as String;
    final careers = skillData['careers'] as List<String>;
    final learningPath = skillData['learning_path'] as List<String>? ?? <String>[];
    final isExpanded = skillData['expanded'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00D9FF).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Skill Header
          InkWell(
            onTap: () {
              setState(() {
                skillData['expanded'] = !isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D9FF).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.trending_up,
                      color: Color(0xFF00D9FF),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          skill,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Relevant for ${careers.length} ${careers.length == 1 ? 'career' : 'careers'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFF00D9FF),
                  ),
                ],
              ),
            ),
          ),
          
          // Expanded Content
          if (isExpanded) ...[
            Divider(
              height: 1,
              color: Colors.white.withOpacity(0.1),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Related Careers
                  if (careers.isNotEmpty) ...[
                    const Text(
                      'Related Careers:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF00D9FF),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: careers.take(3).map((career) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B9D).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFFF6B9D).withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            career,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFFF6B9D),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Learning Path
                  if (learningPath.isNotEmpty) ...[
                    const Text(
                      'Learning Path:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF00D9FF),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...learningPath.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: Color(0xFF00D9FF),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${entry.key + 1}',
                                  style: const TextStyle(
                                    color: Color(0xFF0F0F23),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.8),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

