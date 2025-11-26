import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/error_log_service.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_spacing.dart';

/// Error Logs Viewer Screen
/// 
/// Displays application error logs with:
/// - Filtering by severity and category
/// - Detailed view of each log entry
/// - Clear logs functionality
/// - Export/copy capabilities
class ErrorLogsScreen extends StatefulWidget {
  const ErrorLogsScreen({super.key});

  @override
  State<ErrorLogsScreen> createState() => _ErrorLogsScreenState();
}

class _ErrorLogsScreenState extends State<ErrorLogsScreen> {
  ErrorSeverity? _selectedSeverity;
  String? _selectedCategory;
  List<ErrorLogEntry> _filteredLogs = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadLogs();
  }
  
  void _loadLogs() {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final allLogs = ErrorLogService.instance.allLogs;
      _filteredLogs = _applyFilters(allLogs);
    } catch (e) {
      print('Error loading logs: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  List<ErrorLogEntry> _applyFilters(List<ErrorLogEntry> logs) {
    var filtered = logs;
    
    if (_selectedSeverity != null) {
      filtered = filtered.where((log) => log.severity == _selectedSeverity).toList();
    }
    
    if (_selectedCategory != null) {
      filtered = filtered.where((log) => log.category == _selectedCategory).toList();
    }
    
    return filtered;
  }
  
  void _updateFilters() {
    setState(() {
      _filteredLogs = _applyFilters(ErrorLogService.instance.allLogs);
    });
  }
  
  Future<void> _clearAllLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All Logs?', style: AppTextStyles.headingMedium),
        content: Text(
          'This will permanently delete all error logs. This action cannot be undone.',
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
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await ErrorLogService.instance.clearAll();
      _loadLogs();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ All logs cleared'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    }
  }
  
  Future<void> _clearOldLogs() async {
    final days = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Old Logs', style: AppTextStyles.headingMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Delete logs older than:', style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              title: const Text('7 days'),
              onTap: () => Navigator.pop(context, 7),
            ),
            ListTile(
              title: const Text('30 days'),
              onTap: () => Navigator.pop(context, 30),
            ),
            ListTile(
              title: const Text('90 days'),
              onTap: () => Navigator.pop(context, 90),
            ),
          ],
        ),
      ),
    );
    
    if (days != null) {
      await ErrorLogService.instance.clearOlderThan(days);
      _loadLogs();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Cleared logs older than $days days'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    }
  }
  
  void _showLogDetails(ErrorLogEntry log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                children: [
                  Text(log.severity.emoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(log.severity.displayName, style: AppTextStyles.headingMedium),
                        Text(log.category, style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () => _copyLogToClipboard(log),
                    tooltip: 'Copy',
                  ),
                ],
              ),
              const Divider(height: AppSpacing.lg),
              
              _buildDetailRow('Time', log.formattedTimestamp),
              _buildDetailRow('Category', log.category),
              _buildDetailRow('Severity', log.severity.displayName),
              
              const SizedBox(height: AppSpacing.md),
              Text('Message', style: AppTextStyles.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Text(log.message, style: AppTextStyles.bodyMedium),
              ),
              
              if (log.stackTrace != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text('Stack Trace', style: AppTextStyles.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                  child: Text(
                    log.stackTrace!,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
              
              if (log.context != null && log.context!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text('Context', style: AppTextStyles.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: log.context!.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '${entry.key}: ${entry.value}',
                          style: AppTextStyles.bodySmall,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _copyLogToClipboard(ErrorLogEntry log) async {
    final text = '''
Error Log
=========
Time: ${log.formattedTimestamp}
Severity: ${log.severity.displayName}
Category: ${log.category}

Message:
${log.message}

${log.stackTrace != null ? 'Stack Trace:\n${log.stackTrace}\n\n' : ''}
${log.context != null && log.context!.isNotEmpty ? 'Context:\n${log.context!.entries.map((e) => '${e.key}: ${e.value}').join('\n')}' : ''}
    ''';
    
    await Clipboard.setData(ClipboardData(text: text));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📋 Log copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Error Logs', style: AppTextStyles.headingMedium),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    final stats = ErrorLogService.instance.getStatistics();
    final categories = ErrorLogService.instance.categories.toList()..sort();
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Error Logs', style: AppTextStyles.headingMedium),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'clear_all':
                  _clearAllLogs();
                  break;
                case 'clear_old':
                  _clearOldLogs();
                  break;
                case 'refresh':
                  _loadLogs();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: AppSpacing.sm),
                    Text('Refresh'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_old',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep),
                    SizedBox(width: AppSpacing.sm),
                    Text('Clear Old Logs'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: AppColors.warningRed),
                    SizedBox(width: AppSpacing.sm),
                    Text('Clear All Logs'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Card
          Card(
            margin: const EdgeInsets.all(AppSpacing.md),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatChip('Total', stats['total']!, Colors.grey),
                  _buildStatChip(ErrorSeverity.info.emoji, stats['info']!, Colors.blue),
                  _buildStatChip(ErrorSeverity.warning.emoji, stats['warning']!, Colors.orange),
                  _buildStatChip(ErrorSeverity.error.emoji, stats['error']!, Colors.red),
                  _buildStatChip(ErrorSeverity.critical.emoji, stats['critical']!, Colors.purple),
                ],
              ),
            ),
          ),
          
          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<ErrorSeverity?>(
                    value: _selectedSeverity,
                    decoration: const InputDecoration(
                      labelText: 'Severity',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All'),
                      ),
                      ...ErrorSeverity.values.map((severity) {
                        return DropdownMenuItem(
                          value: severity,
                          child: Text('${severity.emoji} ${severity.displayName}'),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      _selectedSeverity = value;
                      _updateFilters();
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All'),
                      ),
                      ...categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      _selectedCategory = value;
                      _updateFilters();
                    },
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // Logs List
          Expanded(
            child: _filteredLogs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: AppColors.successGreen,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No error logs',
                          style: AppTextStyles.headingMedium,
                        ),
                        Text(
                          'Your app is running smoothly!',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    itemCount: _filteredLogs.length,
                    itemBuilder: (context, index) {
                      final log = _filteredLogs[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: ListTile(
                          leading: Text(
                            log.severity.emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                          title: Text(
                            log.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyMedium,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                '${log.category} • ${log.formattedTimestamp}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () => _showLogDetails(log),
                          ),
                          onTap: () => _showLogDetails(log),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatChip(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(color: color),
        ),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: AppTextStyles.headingMedium.copyWith(color: color),
        ),
      ],
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
}
