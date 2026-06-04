import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_provider.dart';
import '../../services/supabase_service.dart';
import '../../data/models/career_field_config.dart';
import '../widgets/app_sidebar.dart';
import 'saved_careers_screen.dart';

/// Discover Screen - Browse trending and popular careers for 2025
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _popularTrendingCareers = [];
  List<Map<String, dynamic>> _mostSavedCareers = [];
  List<Map<String, dynamic>> _highDemandCareers = [];
  Map<String, List<Map<String, dynamic>>> _trendingByField = {};

  // 2025 Career Discovery Report - Based on Real Market Data
  
  // Popular/Trending Careers - Highest growth in interest and social media buzz
  final List<Map<String, dynamic>> _popularTrending2025 = [
    {
      'job_title': 'AI Prompt Engineer',
      'sector': 'Technology / IT',
      'summary': 'Design and optimize prompts for AI systems like ChatGPT, Claude, and other LLMs. Bridge between human intent and AI capabilities. Essential for maximizing AI model performance and accuracy.',
      'salary_range': r'$100,000 - $180,000',
      'future_demand': 'Very High',
      'trend_reason': 'Explosive growth in Generative AI adoption across industries - 300% increase in job postings',
      'key_skill': 'Prompt Engineering & AI Model Optimization',
    },
    {
      'job_title': 'Sustainability Consultant',
      'sector': 'Business',
      'summary': 'Help organizations achieve carbon neutrality and implement ESG strategies. Critical role in the green transition. Advise on sustainable practices, regulatory compliance, and environmental impact reduction.',
      'salary_range': r'$70,000 - $140,000',
      'future_demand': 'Very High',
      'trend_reason': 'Corporate sustainability mandates and climate regulations driving 200% demand increase',
      'key_skill': 'ESG Strategy & Carbon Footprint Analysis',
    },
    {
      'job_title': 'AI Ethics Specialist',
      'sector': 'Technology / IT',
      'summary': 'Ensure AI systems are developed and deployed responsibly, addressing bias, fairness, and ethical concerns. Develop governance frameworks and audit AI systems for compliance.',
      'salary_range': r'$95,000 - $160,000',
      'future_demand': 'Very High',
      'trend_reason': 'Growing need for responsible AI governance - EU AI Act and global regulations',
      'key_skill': 'AI Ethics & Responsible AI Frameworks',
    },
    {
      'job_title': 'Remote Work Coordinator',
      'sector': 'Business',
      'summary': 'Optimize remote and hybrid work environments, managing distributed teams and virtual collaboration tools. Implement policies and technologies for effective remote operations.',
      'salary_range': r'$65,000 - $120,000',
      'future_demand': 'High',
      'trend_reason': 'Permanent shift to hybrid/remote work models - 42% of workforce now remote',
      'key_skill': 'Virtual Team Management & Collaboration Tools',
    },
    {
      'job_title': 'Renewable Energy Engineer',
      'sector': 'Science & Laboratory',
      'summary': 'Design and implement solar, wind, and other renewable energy systems. Drive the clean energy transition. Work on grid integration and energy storage solutions.',
      'salary_range': r'$85,000 - $150,000',
      'future_demand': 'Very High',
      'trend_reason': 'Global push for renewable energy and net-zero goals - \$4.5T investment by 2030',
      'key_skill': 'Renewable Energy Systems Design',
    },
    {
      'job_title': 'Quantum Computing Engineer',
      'sector': 'Technology / IT',
      'summary': 'Develop quantum algorithms and applications for solving complex computational problems. Work on quantum hardware and software systems for next-generation computing.',
      'salary_range': r'$130,000 - $220,000',
      'future_demand': 'Very High',
      'trend_reason': 'Quantum computing market projected to reach \$65B by 2030',
      'key_skill': 'Quantum Algorithms & Quantum Programming',
    },
    {
      'job_title': 'Carbon Accounting Specialist',
      'sector': 'Business',
      'summary': 'Measure, track, and report organizational carbon emissions. Develop carbon reduction strategies and ensure compliance with climate reporting standards.',
      'salary_range': r'$75,000 - $130,000',
      'future_demand': 'Very High',
      'trend_reason': 'Mandatory carbon reporting requirements in 50+ countries',
      'key_skill': 'Carbon Footprint Measurement & GHG Protocol',
    },
    {
      'job_title': 'Virtual Reality Developer',
      'sector': 'Technology / IT',
      'summary': 'Create immersive VR experiences for training, entertainment, and business applications. Develop VR applications using Unity, Unreal Engine, and WebXR technologies.',
      'salary_range': r'$90,000 - $160,000',
      'future_demand': 'High',
      'trend_reason': 'VR/AR market growing 25% annually, enterprise adoption accelerating',
      'key_skill': 'VR Development & 3D Modeling',
    },
  ];

  // Trending by Field - Top 3 Industries with Multiple Trending Roles
  final Map<String, List<Map<String, dynamic>>> _trending2025Careers = {
    'green_tech': [
      {
        'job_title': 'Solar Energy Systems Engineer',
        'sector': 'Green Tech / Renewable Energy',
        'summary': 'Design and implement solar power systems for residential, commercial, and utility-scale projects. Optimize system performance and integrate with energy storage solutions. Leading role in renewable energy revolution.',
        'salary_range': r'$85,000 - $150,000',
        'future_demand': 'Very High',
        'trend_reason': 'Global push for net-zero: \$4.5T invested in renewables by 2030, 50% annual growth',
        'key_skill': 'Solar PV System Design & Energy Storage',
      },
      {
        'job_title': 'Wind Energy Engineer',
        'sector': 'Green Tech / Renewable Energy',
        'summary': 'Design and develop wind turbine systems and wind farms. Conduct site assessments, optimize turbine placement, and ensure efficient energy generation from wind resources.',
        'salary_range': r'$80,000 - $145,000',
        'future_demand': 'Very High',
        'trend_reason': 'Wind energy capacity doubling every 3 years, offshore wind expansion',
        'key_skill': 'Wind Turbine Design & Energy Systems',
      },
      {
        'job_title': 'Energy Storage Systems Engineer',
        'sector': 'Green Tech / Renewable Energy',
        'summary': 'Develop battery storage and grid-scale energy storage solutions. Design systems for renewable energy integration and grid stability. Critical for renewable energy reliability.',
        'salary_range': r'$90,000 - $160,000',
        'future_demand': 'Very High',
        'trend_reason': 'Energy storage market growing 30% annually, essential for grid stability',
        'key_skill': 'Battery Technology & Grid Integration',
      },
      {
        'job_title': 'Environmental Compliance Specialist',
        'sector': 'Green Tech / Renewable Energy',
        'summary': 'Ensure organizations meet environmental regulations and sustainability standards. Conduct environmental audits and develop compliance strategies for carbon reduction goals.',
        'salary_range': r'$70,000 - $125,000',
        'future_demand': 'High',
        'trend_reason': 'Stricter environmental regulations, ESG reporting requirements',
        'key_skill': 'Environmental Regulations & Compliance',
      },
    ],
    'health_tech': [
      {
        'job_title': 'Health Informatics Specialist',
        'sector': 'Health-Tech / Digital Health',
        'summary': 'Bridge healthcare and technology, managing electronic health records and telemedicine platforms. Implement health information systems and ensure data interoperability. Critical for modern healthcare delivery.',
        'salary_range': r'$75,000 - $135,000',
        'future_demand': 'Very High',
        'trend_reason': 'Digital health market growing 25% annually, telemedicine expansion, \$659B market by 2025',
        'key_skill': 'Health Information Systems & Telemedicine Platforms',
      },
      {
        'job_title': 'Medical AI Developer',
        'sector': 'Health-Tech / Digital Health',
        'summary': 'Develop AI applications for medical diagnosis, drug discovery, and patient care. Create machine learning models for medical imaging, predictive analytics, and personalized treatment recommendations.',
        'salary_range': r'$110,000 - $190,000',
        'future_demand': 'Very High',
        'trend_reason': 'AI in healthcare market reaching \$102B by 2028, diagnostic AI adoption',
        'key_skill': 'Medical AI & Machine Learning for Healthcare',
      },
      {
        'job_title': 'Telemedicine Coordinator',
        'sector': 'Health-Tech / Digital Health',
        'summary': 'Manage virtual healthcare delivery systems and remote patient monitoring. Coordinate telemedicine services, train staff, and ensure quality virtual care delivery.',
        'salary_range': r'$65,000 - $115,000',
        'future_demand': 'High',
        'trend_reason': 'Telemedicine usage increased 38x since 2020, permanent shift to virtual care',
        'key_skill': 'Telemedicine Systems & Virtual Care Management',
      },
      {
        'job_title': 'Healthcare Data Analyst',
        'sector': 'Health-Tech / Digital Health',
        'summary': 'Analyze healthcare data to improve patient outcomes and operational efficiency. Extract insights from electronic health records and clinical data to support evidence-based decision making.',
        'salary_range': r'$70,000 - $130,000',
        'future_demand': 'High',
        'trend_reason': 'Healthcare analytics market growing 22% annually, data-driven care',
        'key_skill': 'Healthcare Data Analysis & Clinical Informatics',
      },
    ],
    'fintech': [
      {
        'job_title': 'Blockchain Developer',
        'sector': 'Fintech / Financial Technology',
        'summary': 'Build decentralized financial applications and smart contracts. Develop DeFi protocols, cryptocurrency platforms, and blockchain-based payment systems. Driving innovation in digital finance.',
        'salary_range': r'$110,000 - $200,000',
        'future_demand': 'Very High',
        'trend_reason': 'Fintech market valued at \$310B, blockchain adoption accelerating, DeFi growth',
        'key_skill': 'Smart Contracts & DeFi Protocol Development',
      },
      {
        'job_title': 'Fintech Product Manager',
        'sector': 'Fintech / Financial Technology',
        'summary': 'Lead development of financial technology products including mobile banking apps, payment systems, and investment platforms. Bridge business strategy and technical implementation.',
        'salary_range': r'$100,000 - $180,000',
        'future_demand': 'Very High',
        'trend_reason': 'Digital banking adoption, mobile payments growth, fintech innovation',
        'key_skill': 'Fintech Product Strategy & Digital Banking',
      },
      {
        'job_title': 'Cryptocurrency Analyst',
        'sector': 'Fintech / Financial Technology',
        'summary': 'Analyze cryptocurrency markets, blockchain projects, and digital asset trends. Provide investment insights and risk assessment for crypto assets and DeFi protocols.',
        'salary_range': r'$85,000 - $160,000',
        'future_demand': 'High',
        'trend_reason': 'Crypto market maturation, institutional adoption, regulatory clarity',
        'key_skill': 'Cryptocurrency Analysis & Blockchain Technology',
      },
      {
        'job_title': 'Payment Systems Engineer',
        'sector': 'Fintech / Financial Technology',
        'summary': 'Design and develop secure payment processing systems and digital wallet solutions. Implement payment gateways, fraud detection, and ensure PCI compliance.',
        'salary_range': r'$95,000 - $170,000',
        'future_demand': 'High',
        'trend_reason': 'Digital payments growing 15% annually, contactless payment adoption',
        'key_skill': 'Payment Processing & Security Systems',
      },
    ],
  };

  // High-Demand Careers (Hard Data) - Highest job openings and fastest growth rates
  final List<Map<String, dynamic>> _highDemand2025 = [
    {
      'job_title': 'Nurse Practitioner',
      'sector': 'Healthcare & Pharmacy',
      'summary': 'Advanced practice nurses providing primary and specialty care. Diagnose conditions, prescribe medications, and manage patient care independently. Highest job growth rate in healthcare sector with excellent job security.',
      'salary_range': r'$110,000 - $150,000',
      'future_demand': 'Very High',
      'demand_reason': '45% projected growth by 2032, aging population needs, 112,700 new positions',
      'key_skill': 'Advanced Clinical Assessment & Patient Care',
    },
    {
      'job_title': 'Cybersecurity Analyst',
      'sector': 'Technology / IT',
      'summary': 'Protect organizations from cyber threats and data breaches. Monitor security systems, investigate incidents, and implement security measures. Critical role in protecting digital infrastructure.',
      'salary_range': r'$90,000 - $160,000',
      'future_demand': 'Very High',
      'demand_reason': '35% growth rate, 750,000+ job openings in 2025, 3.4M global shortage',
      'key_skill': 'Threat Detection & Security Incident Response',
    },
    {
      'job_title': 'Software Developer',
      'sector': 'Technology / IT',
      'summary': 'Build applications and systems using programming languages. Design, develop, test, and maintain software solutions. Essential for digital transformation across all industries.',
      'salary_range': r'$100,000 - $180,000',
      'future_demand': 'Very High',
      'demand_reason': '1.2M+ job openings projected in 2025, 25% growth rate, highest demand in tech',
      'key_skill': 'Full-Stack Development & Cloud Technologies',
    },
    {
      'job_title': 'Data Scientist',
      'sector': 'Science & Laboratory',
      'summary': 'Extract insights from big data using AI/ML algorithms and statistical methods. Build predictive models and create data-driven solutions for business problems.',
      'salary_range': r'$95,000 - $170,000',
      'future_demand': 'Very High',
      'demand_reason': '36% growth rate, 11.5M new jobs by 2026, data-driven decision making standard',
      'key_skill': 'Machine Learning & Statistical Analysis',
    },
    {
      'job_title': 'Medical and Health Services Manager',
      'sector': 'Healthcare & Pharmacy',
      'summary': 'Plan, direct, and coordinate healthcare services. Manage medical facilities, oversee budgets, and ensure compliance with healthcare regulations. Critical for efficient healthcare delivery.',
      'salary_range': r'$80,000 - $140,000',
      'future_demand': 'Very High',
      'demand_reason': '28% growth rate, 144,700 new positions by 2032, healthcare expansion',
      'key_skill': 'Healthcare Administration & Operations Management',
    },
    {
      'job_title': 'Information Security Analyst',
      'sector': 'Technology / IT',
      'summary': 'Plan and implement security measures to protect computer networks and systems. Conduct security audits, vulnerability assessments, and develop security policies.',
      'salary_range': r'$95,000 - $165,000',
      'future_demand': 'Very High',
      'demand_reason': '32% growth rate, 53,200 new jobs annually, critical infrastructure protection',
      'key_skill': 'Network Security & Vulnerability Assessment',
    },
    {
      'job_title': 'Physician Assistant',
      'sector': 'Healthcare & Pharmacy',
      'summary': 'Practice medicine under physician supervision. Examine patients, diagnose illnesses, and provide treatment. High demand in primary care and specialty settings.',
      'salary_range': r'$105,000 - $145,000',
      'future_demand': 'Very High',
      'demand_reason': '27% growth rate, 39,300 new positions, addressing physician shortage',
      'key_skill': 'Clinical Diagnosis & Patient Treatment',
    },
    {
      'job_title': 'Operations Research Analyst',
      'sector': 'Business',
      'summary': 'Use advanced analytical methods to help organizations solve problems and make better decisions. Apply mathematical modeling and optimization techniques.',
      'salary_range': r'$85,000 - $150,000',
      'future_demand': 'High',
      'demand_reason': '23% growth rate, 10,300 new jobs, data-driven optimization demand',
      'key_skill': 'Mathematical Modeling & Optimization',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadDiscoverData();
  }

  Future<void> _loadDiscoverData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final supabaseService = ref.read(supabaseServiceProvider);
      
      // Load most saved careers
      _mostSavedCareers = await supabaseService.getMostSavedCareers(limit: 8);
      
      // Set high demand careers (2025 hard data)
      _highDemandCareers = List.from(_highDemand2025);
      
      // Set trending by field (Top 3 industries)
      _trendingByField = Map.from(_trending2025Careers);
      
      // Set popular/trending careers (social media buzz and interest)
      _popularTrendingCareers = List.from(_popularTrending2025);
      
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveCareer(Map<String, dynamic> career) async {
    try {
      final supabaseService = ref.read(supabaseServiceProvider);
      await supabaseService.saveCareer(
        jobTitle: career['job_title'] as String,
        sector: career['sector'] as String?,
        salaryRange: career['salary_range'] as String?,
        futureDemand: career['future_demand'] as String?,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${career['job_title']} saved to your list'),
            backgroundColor: const Color(0xFF00D9FF),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('already saved')
                  ? 'This career is already saved'
                  : 'Failed to save career. Please try again.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      drawer: const AppSidebar(currentScreen: 'discover'),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Discover Careers',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SavedCareersScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D9FF)),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadDiscoverData,
              color: const Color(0xFF00D9FF),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    const Text(
                      'Trending Careers in 2025',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Explore the most in-demand careers based on current market trends',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 1. Popular/Trending Careers Section
                    _buildSectionHeader(
                      'Popular & Trending Careers',
                      'The hottest careers everyone is talking about',
                      Icons.local_fire_department,
                      const Color(0xFFFF6B9D),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 420,
                      child: Builder(
                        builder: (context) {
                          final controller = ScrollController();
                          return Scrollbar(
                            controller: controller,
                            thumbVisibility: true,
                            scrollbarOrientation: ScrollbarOrientation.bottom,
                            child: ListView.builder(
                              controller: controller,
                              scrollDirection: Axis.horizontal,
                              itemCount: _popularTrendingCareers.length,
                              itemBuilder: (context, index) {
                                return _buildTrendingCareerCard(
                                  _popularTrendingCareers[index],
                                  isHighDemand: true,
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 40),

                    // 2. High Demand Careers Section
                    _buildSectionHeader(
                      'High Demand Careers',
                      'Most sought-after roles in 2025',
                      Icons.trending_up,
                      const Color(0xFFFF6B9D),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 420,
                      child: Builder(
                        builder: (context) {
                          final controller = ScrollController();
                          return Scrollbar(
                            controller: controller,
                            thumbVisibility: true,
                            scrollbarOrientation: ScrollbarOrientation.bottom,
                            child: ListView.builder(
                              controller: controller,
                              scrollDirection: Axis.horizontal,
                              itemCount: _highDemandCareers.length,
                              itemBuilder: (context, index) {
                                return _buildTrendingCareerCard(
                                  _highDemandCareers[index],
                                  isHighDemand: true,
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 40),

                    // 3. Most Saved Careers Section
                    if (_mostSavedCareers.isNotEmpty) ...[
                      _buildSectionHeader(
                        'Most Saved by Users',
                        'Popular careers our community is exploring',
                        Icons.bookmark,
                        const Color(0xFF00D9FF),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 420,
                        child: Builder(
                          builder: (context) {
                            final controller = ScrollController();
                            return Scrollbar(
                              controller: controller,
                              thumbVisibility: true,
                              scrollbarOrientation: ScrollbarOrientation.bottom,
                              child: ListView.builder(
                                controller: controller,
                                scrollDirection: Axis.horizontal,
                                itemCount: _mostSavedCareers.length,
                                itemBuilder: (context, index) {
                                  return _buildTrendingCareerCard(
                                    _mostSavedCareers[index],
                                    saveCount: _mostSavedCareers[index]['count'] as int?,
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],

                    // 4. Trending by Field Section
                    _buildSectionHeader(
                      'Trending by Field',
                      'Hot careers in each industry',
                      Icons.category,
                      const Color(0xFF00D9FF),
                    ),
                    const SizedBox(height: 16),
                    ..._trendingByField.entries.map((entry) {
                      final fieldId = entry.key;
                      final careers = entry.value;
                      final fieldConfig = CareerFieldConfig.allFields[fieldId];
                      final fieldName = fieldConfig?.fieldName ?? fieldId;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12, top: 8),
                            child: Text(
                              fieldName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF00D9FF),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 420,
                            child: Builder(
                              builder: (context) {
                                final controller = ScrollController();
                                return Scrollbar(
                                  controller: controller,
                                  thumbVisibility: true,
                                  scrollbarOrientation: ScrollbarOrientation.bottom,
                                  child: ListView.builder(
                                    controller: controller,
                                    scrollDirection: Axis.horizontal,
                                    itemCount: careers.length,
                                    itemBuilder: (context, index) {
                                      return _buildTrendingCareerCard(
                                        careers[index],
                                        showTrendReason: true,
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingCareerCard(
    Map<String, dynamic> career, {
    bool isHighDemand = false,
    int? saveCount,
    bool showTrendReason = false,
  }) {
    final jobTitle = career['job_title'] as String? ?? 'Career';
    final sector = career['sector'] as String? ?? '';
    final summary = career['summary'] as String? ?? '';
    final salaryRange = career['salary_range'] as String? ?? '';
    final futureDemand = career['future_demand'] as String? ?? '';
    final trendReason = career['trend_reason'] as String? ?? career['demand_reason'] as String? ?? '';

    return Container(
      width: 320,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00D9FF).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with badge
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00D9FF).withOpacity(0.2),
                  const Color(0xFF00D9FF).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        jobTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (sector.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          sector,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isHighDemand || futureDemand == 'Very High')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B9D).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFF6B9D),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          size: 14,
                          color: Color(0xFFFF6B9D),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Hot',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF6B9D),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Summary
                  if (summary.isNotEmpty) ...[
                    Flexible(
                      child: Text(
                        summary,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Trend reason
                  if (showTrendReason && trendReason.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D9FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF00D9FF).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.trending_up,
                              size: 14,
                              color: Color(0xFF00D9FF),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              trendReason,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF00D9FF),
                                fontWeight: FontWeight.w500,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Stats
                  Row(
                    children: [
                      if (salaryRange.isNotEmpty) ...[
                        Expanded(
                          child: _buildStatChip(
                            Icons.attach_money,
                            salaryRange,
                            const Color(0xFF00D9FF),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (futureDemand.isNotEmpty)
                        Expanded(
                          child: _buildStatChip(
                            Icons.trending_up,
                            futureDemand,
                            const Color(0xFFFF6B9D),
                          ),
                        ),
                    ],
                  ),

                  if (saveCount != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D9FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.bookmark,
                            size: 12,
                            color: Color(0xFF00D9FF),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$saveCount saved',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF00D9FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Key Skill for 2025
                  if (career['key_skill'] != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B9D).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFFF6B9D).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: Color(0xFFFF6B9D),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Key Skill: ${career['key_skill']}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFFFF6B9D),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Save Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _saveCareer(career),
                icon: const Icon(Icons.bookmark_border, size: 18),
                label: const Text('Save Career'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D9FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

