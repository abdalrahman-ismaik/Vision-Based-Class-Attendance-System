import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_spacing.dart';
import 'backend_settings_screen.dart';
import 'error_logs_screen.dart';
import 'database_tools_screen.dart';

/// Main Settings Screen
/// 
/// Central hub for all app settings:
/// - Backend configuration
/// - Error logs
/// - Database tools
/// - About app
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: AppTextStyles.headingMedium),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Backend Section
          _buildSectionHeader('Backend Configuration'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud, color: AppColors.primaryBlue),
                  title: const Text('Backend Settings'),
                  subtitle: const Text('Configure server URL and test connection'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BackendSettingsScreen(),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.bug_report, color: AppColors.warningRed),
                  title: const Text('Error Logs'),
                  subtitle: const Text('View application errors and diagnostics'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ErrorLogsScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Developer Tools Section
          _buildSectionHeader('Developer Tools'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.storage, color: AppColors.secondaryPurple),
                  title: const Text('Database Tools'),
                  subtitle: const Text('Manage database and troubleshoot issues'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DatabaseToolsScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // About Section
          _buildSectionHeader('About'),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info, color: AppColors.accentOrange),
                  title: Text('Version'),
                  subtitle: Text('HADIR Mobile v1.0.0'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description, color: AppColors.accentOrange),
                  title: const Text('About App'),
                  subtitle: const Text('AI-Enhanced Student Registration System'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showAboutDialog(context),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Footer
          Center(
            child: Text(
              'HADIR Mobile - Vision-Based Attendance System',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.sm,
        bottom: AppSpacing.sm,
        top: AppSpacing.sm,
      ),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.school, color: AppColors.primaryBlue),
            SizedBox(width: AppSpacing.sm),
            Text('About HADIR Mobile'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HADIR Mobile',
              style: AppTextStyles.headingMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Version 1.0.0',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'AI-Enhanced Student Registration System with Computer Vision',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Features:',
              style: AppTextStyles.labelLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            _buildFeatureItem('📸 Multi-pose face capture'),
            _buildFeatureItem('🤖 AI-powered quality analysis'),
            _buildFeatureItem('☁️ Backend integration'),
            _buildFeatureItem('📊 Real-time attendance tracking'),
            const SizedBox(height: AppSpacing.md),
            Text(
              '© 2025 HADIR Team',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.sm, top: 4),
      child: Text(
        text,
        style: AppTextStyles.bodySmall,
      ),
    );
  }
}
