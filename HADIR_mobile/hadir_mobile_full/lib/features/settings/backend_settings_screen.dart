import 'package:flutter/material.dart';
import '../../../core/services/backend_config_service.dart';
import '../../../core/services/error_log_service.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_spacing.dart';

/// Backend Configuration Screen
/// 
/// Allows users to:
/// - Configure backend server URL
/// - Test connection to backend
/// - View connection status and history
class BackendSettingsScreen extends StatefulWidget {
  const BackendSettingsScreen({super.key});

  @override
  State<BackendSettingsScreen> createState() => _BackendSettingsScreenState();
}

class _BackendSettingsScreenState extends State<BackendSettingsScreen> {
  final _urlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _isTesting = false;
  String? _statusMessage;
  bool? _connectionSuccess;
  
  BackendConfigService? _configService;
  
  @override
  void initState() {
    super.initState();
    _initializeService();
  }
  
  Future<void> _initializeService() async {
    setState(() => _isLoading = true);
    
    try {
      _configService = await BackendConfigService.initialize();
      _urlController.text = _configService!.backendUrl;
    } catch (e) {
      await ErrorLogService.instance.logError(
        'BackendSettings',
        'Failed to initialize backend config service: $e',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isTesting = true;
      _statusMessage = null;
      _connectionSuccess = null;
    });
    
    try {
      final result = await _configService!.testConnection(
        customUrl: _urlController.text.trim(),
      );
      
      setState(() {
        _connectionSuccess = result.success;
        _statusMessage = result.success ? result.message : result.error;
      });
      
      if (result.success) {
        await ErrorLogService.instance.logInfo(
          'BackendSettings',
          'Backend connection test successful: ${_urlController.text}',
        );
      } else {
        await ErrorLogService.instance.logWarning(
          'BackendSettings',
          'Backend connection test failed: ${result.error}',
          context: {'url': _urlController.text},
        );
      }
    } catch (e) {
      setState(() {
        _connectionSuccess = false;
        _statusMessage = 'Test failed: $e';
      });
      
      await ErrorLogService.instance.logError(
        'BackendSettings',
        'Backend connection test error: $e',
        stackTrace: e.toString(),
        context: {'url': _urlController.text},
      );
    } finally {
      setState(() => _isTesting = false);
    }
  }
  
  Future<void> _saveUrl() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      await _configService!.setBackendUrl(_urlController.text.trim());
      
      setState(() {
        _statusMessage = 'Backend URL saved successfully!';
        _connectionSuccess = true;
      });
      
      await ErrorLogService.instance.logInfo(
        'BackendSettings',
        'Backend URL updated: ${_urlController.text}',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Backend URL saved successfully'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to save: $e';
        _connectionSuccess = false;
      });
      
      await ErrorLogService.instance.logError(
        'BackendSettings',
        'Failed to save backend URL: $e',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _resetToDefault() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset to Default?', style: AppTextStyles.headingMedium),
        content: Text(
          'This will reset the backend URL to the default value.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.primaryBlue),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _configService!.resetToDefault();
      _urlController.text = _configService!.backendUrl;
      
      setState(() {
        _statusMessage = 'Reset to default URL';
        _connectionSuccess = null;
      });
      
      await ErrorLogService.instance.logInfo(
        'BackendSettings',
        'Backend URL reset to default',
      );
    }
  }
  
  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Backend Settings', style: AppTextStyles.headingMedium),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Backend Settings', style: AppTextStyles.headingMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetToDefault,
            tooltip: 'Reset to Default',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Card
              Card(
                color: AppColors.primaryBlue.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.primaryBlue),
                          const SizedBox(width: AppSpacing.sm),
                          Text('Backend Configuration', style: AppTextStyles.headingSmall),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Configure the backend server URL for student registration and face recognition.',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // URL Input
              Text('Backend URL', style: AppTextStyles.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _urlController,
                decoration: InputDecoration(
                  hintText: 'http://your-server-ip:5000/api',
                  prefixIcon: const Icon(Icons.link),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                  helperText: 'Enter the full URL including /api suffix',
                  helperMaxLines: 2,
                ),
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a URL';
                  }
                  if (!value.startsWith('http://') && !value.startsWith('https://')) {
                    return 'URL must start with http:// or https://';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Quick Presets
              Text('Quick Presets', style: AppTextStyles.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _buildPresetChip('Android Emulator', BackendConfigService.defaultAndroidEmulator),
                  _buildPresetChip('iOS Simulator', BackendConfigService.defaultIOSSimulator),
                  _buildPresetChip('Physical Device', BackendConfigService.defaultPhysicalDevice),
                ],
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Test Connection Button
              ElevatedButton.icon(
                onPressed: _isTesting ? null : _testConnection,
                icon: _isTesting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi_find),
                label: Text(_isTesting ? 'Testing...' : 'Test Connection'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  backgroundColor: AppColors.secondaryPurple,
                ),
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Save Button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveUrl,
                icon: const Icon(Icons.save),
                label: const Text('Save Configuration'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(AppSpacing.md),
                ),
              ),
              
              // Status Message
              if (_statusMessage != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: _connectionSuccess == true
                        ? AppColors.successGreen.withOpacity(0.1)
                        : _connectionSuccess == false
                            ? AppColors.warningRed.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                    border: Border.all(
                      color: _connectionSuccess == true
                          ? AppColors.successGreen
                          : _connectionSuccess == false
                              ? AppColors.warningRed
                              : Colors.grey,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _connectionSuccess == true
                            ? Icons.check_circle
                            : _connectionSuccess == false
                                ? Icons.error
                                : Icons.info,
                        color: _connectionSuccess == true
                            ? AppColors.successGreen
                            : _connectionSuccess == false
                                ? AppColors.warningRed
                                : Colors.grey,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: _connectionSuccess == true
                                ? AppColors.successGreen
                                : _connectionSuccess == false
                                    ? AppColors.warningRed
                                    : Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Connection History
              if (_configService?.lastSuccessfulConnection != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.history, color: AppColors.successGreen),
                    title: const Text('Last Successful Connection'),
                    subtitle: Text(
                      _formatDateTime(_configService!.lastSuccessfulConnection!),
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: AppSpacing.lg),
              
              // Current Configuration Info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Current Configuration', style: AppTextStyles.labelLarge),
                      const SizedBox(height: AppSpacing.sm),
                      _buildInfoRow('Full URL', _configService?.backendUrl ?? 'Not set'),
                      _buildInfoRow('Base URL', _configService?.baseUrl ?? 'Not set'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPresetChip(String label, String url) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        _urlController.text = url;
      },
      avatar: const Icon(Icons.settings_suggest, size: 18),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
