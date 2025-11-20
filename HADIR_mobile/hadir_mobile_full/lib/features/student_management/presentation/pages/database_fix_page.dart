import 'package:flutter/material.dart';
import '../../../../shared/data/data_sources/database_helper.dart';

/// Quick fix page for database migration issues
class DatabaseFixPage extends StatefulWidget {
  const DatabaseFixPage({super.key});

  @override
  State<DatabaseFixPage> createState() => _DatabaseFixPageState();
}

class _DatabaseFixPageState extends State<DatabaseFixPage> {
  bool _isProcessing = false;
  String? _message;
  int? _currentVersion;

  @override
  void initState() {
    super.initState();
    _checkVersion();
  }

  Future<void> _checkVersion() async {
    try {
      final version = await DatabaseHelper.getDatabaseVersion();
      setState(() {
        _currentVersion = version;
        _message = 'Current database version: $version';
      });
    } catch (e) {
      setState(() {
        _message = 'Error checking version: $e';
      });
    }
  }

  Future<void> _forceUpgrade() async {
    setState(() {
      _isProcessing = true;
      _message = 'Running database upgrade...';
    });

    try {
      await DatabaseHelper.forceUpgrade();
      setState(() {
        _isProcessing = false;
        _message = '✅ Database upgraded successfully!\n\nPlease restart the app.';
      });
      await _checkVersion();
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _message = '❌ Error during upgrade: $e';
      });
    }
  }

  Future<void> _resetDatabase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Confirm Reset'),
        content: const Text(
          'This will DELETE ALL DATA in the database.\n\n'
          'Are you sure you want to continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
      _message = 'Resetting database...';
    });

    try {
      await DatabaseHelper.resetDatabase();
      setState(() {
        _isProcessing = false;
        _message = '✅ Database reset successfully!\n\nPlease restart the app.';
        _currentVersion = null;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _message = '❌ Error during reset: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Fix Tool'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Database Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_currentVersion != null)
                      Text(
                        'Current Version: $_currentVersion',
                        style: const TextStyle(fontSize: 16),
                      ),
                    if (_message != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _message!,
                        style: TextStyle(
                          color: _message!.contains('Error') || _message!.contains('❌')
                              ? Colors.red
                              : _message!.contains('✅')
                                  ? Colors.green
                                  : Colors.grey[700],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'If you\'re experiencing database errors (like missing columns), '
              'try upgrading first. This will add missing columns without losing data.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _forceUpgrade,
              icon: const Icon(Icons.upgrade),
              label: const Text('Force Upgrade Database'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              '⚠️ DANGER ZONE',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Reset will DELETE ALL DATA. Only use this as a last resort.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isProcessing ? null : _resetDatabase,
              icon: const Icon(Icons.delete_forever),
              label: const Text('Reset Database'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
            if (_isProcessing) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}
