import 'package:flutter/material.dart';
import '../../../shared/data/data_sources/database_helper.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_spacing.dart';

/// Debug screen for database operations
/// Access via: Settings > Developer Options > Database Tools
class DatabaseToolsScreen extends StatefulWidget {
  const DatabaseToolsScreen({super.key});

  @override
  State<DatabaseToolsScreen> createState() => _DatabaseToolsScreenState();
}

class _DatabaseToolsScreenState extends State<DatabaseToolsScreen> {
  int? _currentVersion;
  bool _isLoading = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    setState(() => _isLoading = true);
    try {
      final version = await DatabaseHelper.getDatabaseVersion();
      setState(() {
        _currentVersion = version;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _message = 'Error loading version: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _forceUpgrade() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      await DatabaseHelper.forceUpgrade();
      await _loadVersion();
      setState(() {
        _message = '✅ Database upgraded successfully!';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _message = '❌ Error upgrading database: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _resetDatabase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Database?', style: AppTextStyles.headingMedium),
        content: Text(
          'This will delete ALL data including students, sessions, and frames. This action cannot be undone!',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.warningRed),
            child: const Text('Delete All Data'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
        _message = null;
      });

      try {
        await DatabaseHelper.resetDatabase();
        await _loadVersion();
        setState(() {
          _message = '✅ Database reset successfully!';
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _message = '❌ Error resetting database: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Tools'),
      ),
      body: Padding(
        padding: AppSpacing.paddingMD,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: AppSpacing.paddingMD,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Database Information', style: AppTextStyles.headingSmall),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Current Version:', style: AppTextStyles.bodyMedium),
                        Text(
                          _currentVersion?.toString() ?? 'Loading...',
                          style: AppTextStyles.headingSmall.copyWith(
                            color: AppColors.primaryIndigo,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Required Version:', style: AppTextStyles.bodyMedium),
                        Text(
                          '5',
                          style: AppTextStyles.headingSmall.copyWith(
                            color: AppColors.successGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_message != null)
              Card(
                color: _message!.contains('❌')
                    ? AppColors.warningRed.withOpacity(0.1)
                    : AppColors.successGreen.withOpacity(0.1),
                child: Padding(
                  padding: AppSpacing.paddingMD,
                  child: Text(
                    _message!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: _message!.contains('❌')
                          ? AppColors.warningRed
                          : AppColors.successGreen,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _forceUpgrade,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upgrade),
              label: const Text('Upgrade Database'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryIndigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(AppSpacing.md),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Run this if you see "no such column: sync_status" errors',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            const Divider(),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Danger Zone',
              style: AppTextStyles.headingSmall.copyWith(
                color: AppColors.warningRed,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _resetDatabase,
              icon: const Icon(Icons.delete_forever),
              label: const Text('Reset Database (Delete All Data)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.warningRed,
                side: const BorderSide(color: AppColors.warningRed),
                padding: const EdgeInsets.all(AppSpacing.md),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
