import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../settings/settings_screen.dart';

/// Dashboard page for the HADIR Mobile application
/// 
/// This is the main screen that users see after logging in.
/// It provides navigation to all major features and shows quick stats.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  void _onSettingsTap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('🏠 [DASHBOARD] Building DashboardPage with design system');
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: AppSpacing.paddingLG,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HADIR',
                          style: AppTextStyles.displayLarge.copyWith(
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                        SizedBox(height: AppSpacing.xs),
                        Text(
                          'Student Registration System',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: AppRadius.circularMD,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white, size: 24),
                        onPressed: _onSettingsTap,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: AppSpacing.lg),
              
              // Main content area
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundWhite,
                    borderRadius: AppRadius.topXXXL,
                  ),
                  child: SingleChildScrollView(
                    padding: AppSpacing.paddingLG,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome message
                        Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: AppRadius.circularLG,
                                boxShadow: AppElevation.coloredShadow(AppColors.primaryIndigo),
                              ),
                              child: const Icon(Icons.person, color: Colors.white, size: 30),
                            ),
                            SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Welcome back!', style: AppTextStyles.displaySmall),
                                  SizedBox(height: AppSpacing.xs / 2),
                                  Text('Ready to register students?', style: AppTextStyles.bodyMedium),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: AppSpacing.xl),
                        
                        // Quick Actions
                        Text('Quick Actions', style: AppTextStyles.headingLarge),
                        SizedBox(height: AppSpacing.md),
                        
                        Row(
                          children: [
                            Expanded(
                              child: _ActionCard(
                                title: 'New Registration',
                                description: 'Register a new student',
                                icon: Icons.person_add_rounded,
                                gradient: AppColors.primaryGradient,
                                shadowColor: AppColors.primaryIndigo,
                                onTap: () => context.push('/registration'),
                              ),
                            ),
                            SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: _ActionCard(
                                title: 'View Students',
                                description: 'Browse registered students',
                                icon: Icons.list_alt_rounded,
                                gradient: AppColors.secondaryGradient,
                                shadowColor: AppColors.secondaryCyan,
                                onTap: () => context.push('/students'),
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: AppSpacing.xl),
                        
                        // Quick Stats
                        Text('Quick Stats', style: AppTextStyles.headingLarge),
                        SizedBox(height: AppSpacing.md),
                        
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: 'Students Registered',
                                value: '0',
                                icon: Icons.people_rounded,
                                gradient: AppColors.successGradient,
                              ),
                            ),
                            SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: _StatCard(
                                title: 'Today\'s Sessions',
                                value: '0',
                                icon: Icons.today_rounded,
                                gradient: AppColors.warningGradient,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Action card widget with gradient design
class _ActionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final LinearGradient gradient;
  final Color shadowColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.shadowColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.circularXL,
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: AppRadius.circularXL,
            boxShadow: AppElevation.coloredShadow(shadowColor),
          ),
          padding: AppSpacing.paddingLG,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: AppRadius.circularMD,
                ),
                child: Icon(icon, size: 32, color: Colors.white),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.cardTitle),
                  SizedBox(height: AppSpacing.xs / 2),
                  Text(description, style: AppTextStyles.cardDescription),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stat card widget with gradient accent
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final LinearGradient gradient;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: AppRadius.circularXL,
        boxShadow: AppElevation.shadowMD,
      ),
      padding: AppSpacing.paddingLG,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: AppRadius.circularMD,
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              ShaderMask(
                shaderCallback: (bounds) => gradient.createShader(bounds),
                child: Text(value, style: AppTextStyles.statValue.copyWith(color: Colors.white)),
              ),
            ],
          ),
          Text(title, style: AppTextStyles.statLabel),
        ],
      ),
    );
  }
}
