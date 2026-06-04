import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_provider.dart';
import '../../services/supabase_service.dart';

/// Saved Careers Screen - View all saved careers
class SavedCareersScreen extends ConsumerStatefulWidget {
  const SavedCareersScreen({super.key});

  @override
  ConsumerState<SavedCareersScreen> createState() => _SavedCareersScreenState();
}

class _SavedCareersScreenState extends ConsumerState<SavedCareersScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _savedCareers = [];

  @override
  void initState() {
    super.initState();
    _loadSavedCareers();
  }

  Future<void> _loadSavedCareers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final supabaseService = ref.read(supabaseServiceProvider);
      _savedCareers = await supabaseService.getSavedCareers();
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeCareer(String jobTitle) async {
    try {
      final supabaseService = ref.read(supabaseServiceProvider);
      await supabaseService.removeSavedCareer(jobTitle);
      await _loadSavedCareers();
      
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        title: const Text(
          'Saved Careers',
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
          : _savedCareers.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bookmark_border,
                          size: 80,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'No Saved Careers Yet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Save careers from recommendations to view them here.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSavedCareers,
                  color: const Color(0xFF00D9FF),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _savedCareers.length,
                    itemBuilder: (context, index) {
                      return _buildCareerCard(_savedCareers[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildCareerCard(Map<String, dynamic> career) {
    final jobTitle = career['job_title'] as String? ?? 'Career';
    final sector = career['sector'] as String? ?? '';
    final matchScore = career['match_score'] as int? ?? 0;
    final whyItFits = career['why_it_fits'] as String? ?? '';
    final skillsYouHave = career['skills_you_have'] as List<dynamic>? ?? [];
    final skillsToLearn = career['skills_to_learn'] as List<dynamic>? ?? [];
    final salaryRange = career['salary_range'] as String? ?? '';
    final futureDemand = career['future_demand'] as String? ?? '';
    final isExpanded = career['expanded'] as bool? ?? false;

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
          // Header
          InkWell(
            onTap: () {
              setState(() {
                career['expanded'] = !isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                        ),
                        if (sector.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            sector,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D9FF).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$matchScore%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00D9FF),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
                  // Why It Fits
                  if (whyItFits.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D9FF).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF00D9FF).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: Color(0xFF00D9FF),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              whyItFits,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Skills You Have
                  if (skillsYouHave.isNotEmpty) ...[
                    const Text(
                      'Skills You Have:',
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
                      children: skillsYouHave.take(5).map((skill) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D9FF).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF00D9FF).withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            skill.toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF00D9FF),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Skills to Learn
                  if (skillsToLearn.isNotEmpty) ...[
                    const Text(
                      'Skills to Learn:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF6B9D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: skillsToLearn.take(5).map((skill) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B9D).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFFF6B9D).withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            skill.toString(),
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

                  // Salary & Demand
                  if (salaryRange.isNotEmpty || futureDemand.isNotEmpty) ...[
                    Row(
                      children: [
                        if (salaryRange.isNotEmpty) ...[
                          Expanded(
                            child: _buildInfoChip(
                              Icons.attach_money,
                              salaryRange,
                              const Color(0xFF00D9FF),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (futureDemand.isNotEmpty)
                          Expanded(
                            child: _buildInfoChip(
                              Icons.trending_up,
                              futureDemand,
                              const Color(0xFFFF6B9D),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Remove Button
                  OutlinedButton.icon(
                    onPressed: () async {
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
                              child: const Text('Cancel'),
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
                    },
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Remove'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}



