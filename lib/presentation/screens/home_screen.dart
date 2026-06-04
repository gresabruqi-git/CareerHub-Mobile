import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_provider.dart';
import '../widgets/app_sidebar.dart';
import 'auth_screens.dart';
import 'career_assessment_test_screen.dart';
import 'dashboard_screen.dart';
import 'skills_to_improve_screen.dart';
import 'profile_screen.dart';

// ============================================================================
// Home Screen
// ============================================================================

/// Main home screen matching the design reference
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    String userName = 'User';
    userProfileAsync.whenData((profile) {
      userName = profile.name;
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      drawer: const AppSidebar(currentScreen: 'home'),
      body: SafeArea(
        child: Column(
          children: [
            // Header with Menu, Logo and Logout
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFF00D9FF).withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Hamburger Menu Button
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(
                        Icons.menu,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ),
                  // Logo
                  const Text(
                    'CareerHub',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  // Logout Button
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        final authRepository = ref.read(authRepositoryProvider);
                        await authRepository.signOut();
                        // The AuthWrapper StreamBuilder will automatically detect the auth state change
                        // and navigate to SignInScreen. If that doesn't work, we'll navigate manually.
                        if (context.mounted) {
                          // Pop all routes and let AuthWrapper handle the navigation
                          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const AuthWrapper(),
                            ),
                            (route) => false,
                          );
                        }
                      } catch (e) {
                        // Show error if logout fails
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Logout failed: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D9FF),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Logout',
                      style: TextStyle(
                        color: Color(0xFF0F0F23),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Section
                    Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Unlock Your Future Career Path',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tailored AI-powered recommendations to match your skills & interests',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.7),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    // Three Feature Cards
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // For mobile, stack vertically; for larger screens, show horizontally
                          if (constraints.maxWidth < 600) {
                            return Column(
                              children: [
                                _FeatureCard(
                                  icon: Icons.quiz,
                                  title: 'Career Assessment Test',
                                  description:
                                      'Take a test to identify strengths and suitable careers.',
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const CareerAssessmentTestScreen(),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                _FeatureCard(
                                  icon: Icons.menu_book,
                                  title: 'Skills to Improve',
                                  description:
                                      'View recommended skills and learning paths.',
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const SkillsToImproveScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            );
                          } else {
                            return Row(
                              children: [
                                Expanded(
                                  child: _FeatureCard(
                                    icon: Icons.quiz,
                                    title: 'Career Assessment Test',
                                    description:
                                        'Take a test to identify strengths and suitable careers.',
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const CareerAssessmentTestScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _FeatureCard(
                                    icon: Icons.menu_book,
                                    title: 'Skills to Improve',
                                    description:
                                        'View recommended skills and learning paths.',
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const SkillsToImproveScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          }
                            },
                          ),
                        ),

                    const SizedBox(height: 40),

                    // Your Dashboard Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Dashboard',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Dashboard link card
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const DashboardScreen(),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(0xFF00D9FF).withOpacity(0.3),
                                      const Color(0xFFFF6B9D).withOpacity(0.3),
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
                                    const Icon(
                                      Icons.dashboard,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                    const SizedBox(width: 16),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'View Personal Dashboard',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'See your progress and saved careers',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Feature Card Component
// ============================================================================

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF00D9FF).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// AI Illustration Widget
// ============================================================================

class _AIIllustration extends StatelessWidget {
  final double size;

  const _AIIllustration({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: CustomPaint(
        painter: _AIIllustrationPainter(),
        child: Stack(
          children: [
            // Binary characters in background
            Positioned(
              top: 10,
              left: 10,
              child: Text(
                '01',
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.blue.shade200.withOpacity(0.3),
                  fontFamily: 'monospace',
                ),
              ),
            ),
            Positioned(
              top: 20,
              right: 15,
              child: Text(
                '10',
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.blue.shade200.withOpacity(0.3),
                  fontFamily: 'monospace',
                ),
              ),
            ),
            Positioned(
              bottom: 15,
              left: 15,
              child: Text(
                '01',
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.blue.shade200.withOpacity(0.3),
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AIIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final fillPaint = Paint()
      ..color = Colors.blue.shade100.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final brainSize = size.width * 0.35;

    // Draw brain (central)
    final brainPath = Path();
    brainPath.moveTo(center.dx, center.dy - brainSize * 0.3);
    brainPath.quadraticBezierTo(
      center.dx - brainSize * 0.4,
      center.dy - brainSize * 0.2,
      center.dx - brainSize * 0.5,
      center.dy,
    );
    brainPath.quadraticBezierTo(
      center.dx - brainSize * 0.3,
      center.dy + brainSize * 0.3,
      center.dx,
      center.dy + brainSize * 0.4,
    );
    brainPath.quadraticBezierTo(
      center.dx + brainSize * 0.3,
      center.dy + brainSize * 0.3,
      center.dx + brainSize * 0.5,
      center.dy,
    );
    brainPath.quadraticBezierTo(
      center.dx + brainSize * 0.4,
      center.dy - brainSize * 0.2,
      center.dx,
      center.dy - brainSize * 0.3,
    );
    brainPath.close();

    canvas.drawPath(brainPath, fillPaint);
    canvas.drawPath(brainPath, paint);

    // Brain internal details (curves)
    final brainDetailPaint = Paint()
      ..color = Colors.blue.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawLine(
      Offset(center.dx - brainSize * 0.2, center.dy - brainSize * 0.1),
      Offset(center.dx - brainSize * 0.15, center.dy + brainSize * 0.2),
      brainDetailPaint,
    );
    canvas.drawLine(
      Offset(center.dx + brainSize * 0.2, center.dy - brainSize * 0.1),
      Offset(center.dx + brainSize * 0.15, center.dy + brainSize * 0.2),
      brainDetailPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - brainSize * 0.05),
      Offset(center.dx, center.dy + brainSize * 0.15),
      brainDetailPaint,
    );

    // Top gear (larger)
    final topGearCenter = Offset(center.dx - size.width * 0.15, center.dy - size.height * 0.25);
    _drawGear(canvas, topGearCenter, size.width * 0.12, paint);

    // Bottom gear (smaller)
    final bottomGearCenter = Offset(center.dx + size.width * 0.15, center.dy + size.height * 0.25);
    _drawGear(canvas, bottomGearCenter, size.width * 0.08, paint);

    // Left cloud
    final leftCloudCenter = Offset(size.width * 0.15, center.dy - size.height * 0.1);
    _drawCloud(canvas, leftCloudCenter, size.width * 0.12, paint, fillPaint);

    // Right cloud (larger)
    final rightCloudCenter = Offset(size.width * 0.85, center.dy + size.height * 0.15);
    _drawCloud(canvas, rightCloudCenter, size.width * 0.15, paint, fillPaint);

    // Connecting lines from brain
    final linePaint = Paint()
      ..color = Colors.blue.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Line to top gear
    canvas.drawLine(
      Offset(center.dx - brainSize * 0.3, center.dy - brainSize * 0.2),
      topGearCenter,
      linePaint,
    );

    // Line to bottom gear
    canvas.drawLine(
      Offset(center.dx + brainSize * 0.3, center.dy + brainSize * 0.2),
      bottomGearCenter,
      linePaint,
    );

    // Arc above brain connecting gears
    final arcPath = Path();
    arcPath.moveTo(topGearCenter.dx, topGearCenter.dy);
    arcPath.quadraticBezierTo(
      center.dx,
      center.dy - size.height * 0.35,
      topGearCenter.dx + size.width * 0.2,
      topGearCenter.dy,
    );
    canvas.drawPath(arcPath, linePaint);

    // Connection points (dots)
    final dotPaint = Paint()
      ..color = Colors.blue.shade400
      ..style = PaintingStyle.fill;

    canvas.drawCircle(topGearCenter, 3, dotPaint);
    canvas.drawCircle(bottomGearCenter, 3, dotPaint);
    canvas.drawCircle(leftCloudCenter, 3, dotPaint);
    canvas.drawCircle(rightCloudCenter, 3, dotPaint);

    // Lines to clouds
    canvas.drawLine(
      Offset(center.dx - brainSize * 0.4, center.dy),
      leftCloudCenter,
      linePaint,
    );
    canvas.drawLine(
      Offset(center.dx + brainSize * 0.4, center.dy + brainSize * 0.1),
      rightCloudCenter,
      linePaint,
    );

    // Data flow lines (dashed) from clouds
    final dashPaint = Paint()
      ..color = Colors.blue.shade300.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Dashed lines from left cloud
    for (int i = 0; i < 5; i++) {
      final startY = leftCloudCenter.dy + size.height * 0.08 + (i * 4);
      canvas.drawLine(
        Offset(leftCloudCenter.dx - 3, startY),
        Offset(leftCloudCenter.dx + 3, startY + 3),
        dashPaint,
      );
    }

    // Dashed lines from right cloud
    for (int i = 0; i < 4; i++) {
      final startY = rightCloudCenter.dy + size.height * 0.08 + (i * 4);
      canvas.drawLine(
        Offset(rightCloudCenter.dx - 3, startY),
        Offset(rightCloudCenter.dx + 3, startY + 3),
        dashPaint,
      );
    }

    // Arrows on lines
    final arrowPaint = Paint()
      ..color = Colors.blue.shade400
      ..style = PaintingStyle.fill;

    // Arrow near left cloud
    _drawArrow(canvas, Offset(leftCloudCenter.dx, leftCloudCenter.dy + size.height * 0.12), arrowPaint);
    // Arrow near right cloud
    _drawArrow(canvas, Offset(rightCloudCenter.dx, rightCloudCenter.dy + size.height * 0.12), arrowPaint);
  }

  void _drawGear(Canvas canvas, Offset center, double radius, Paint paint) {
    final gearPath = Path();
    final teeth = 8;
    final toothLength = radius * 0.3;

    for (int i = 0; i < teeth; i++) {
      final angle = (i * 2 * math.pi) / teeth;
      final outerX = center.dx + (radius + toothLength) * math.cos(angle);
      final outerY = center.dy + (radius + toothLength) * math.sin(angle);
      final innerX = center.dx + radius * math.cos(angle);
      final innerY = center.dy + radius * math.sin(angle);

      if (i == 0) {
        gearPath.moveTo(outerX, outerY);
      } else {
        gearPath.lineTo(outerX, outerY);
      }
      gearPath.lineTo(innerX, innerY);
    }
    gearPath.close();

    // Inner circle
    final innerCirclePath = Path()..addOval(Rect.fromCircle(center: center, radius: radius * 0.4));
    gearPath.addPath(innerCirclePath, Offset.zero);

    canvas.drawPath(gearPath, paint);
  }

  void _drawCloud(Canvas canvas, Offset center, double size, Paint outlinePaint, Paint fillPaint) {
    final cloudPath = Path();
    cloudPath.addOval(Rect.fromCircle(center: center, radius: size * 0.4));
    cloudPath.addOval(Rect.fromCircle(center: Offset(center.dx - size * 0.2, center.dy), radius: size * 0.35));
    cloudPath.addOval(Rect.fromCircle(center: Offset(center.dx + size * 0.2, center.dy), radius: size * 0.35));
    cloudPath.addOval(Rect.fromCircle(center: Offset(center.dx, center.dy + size * 0.15), radius: size * 0.3));

    canvas.drawPath(cloudPath, fillPaint);
    canvas.drawPath(cloudPath, outlinePaint);
  }

  void _drawArrow(Canvas canvas, Offset position, Paint paint) {
    final arrowPath = Path();
    arrowPath.moveTo(position.dx, position.dy);
    arrowPath.lineTo(position.dx - 3, position.dy - 5);
    arrowPath.lineTo(position.dx + 3, position.dy - 5);
    arrowPath.close();
    canvas.drawPath(arrowPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
