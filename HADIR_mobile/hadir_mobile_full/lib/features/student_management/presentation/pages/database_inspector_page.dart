import 'package:flutter/material.dart';
import '../../../../shared/data/data_sources/local_database_data_source.dart';

/// Debug page to inspect database schema and test queries
class DatabaseInspectorPage extends StatefulWidget {
  const DatabaseInspectorPage({super.key});

  @override
  State<DatabaseInspectorPage> createState() => _DatabaseInspectorPageState();
}

class _DatabaseInspectorPageState extends State<DatabaseInspectorPage> {
  final LocalDatabaseDataSource _dataSource = LocalDatabaseDataSource();
  Map<String, dynamic>? _schemaInfo;
  String? _error;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _inspectSchema();
  }

  Future<void> _inspectSchema() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final db = await _dataSource.database;
      
      // Get database version
      final versionResult = await db.rawQuery('PRAGMA user_version');
      final version = versionResult.first['user_version'] as int;
      
      // Get students table schema
      final tableInfo = await db.rawQuery(
        "PRAGMA table_info(students)"
      );
      
      // Get table list
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'"
      );
      
      // Get indices
      final indices = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='students'"
      );
      
      // Get row count
      final countResult = await db.rawQuery(
        "SELECT COUNT(*) as count FROM students"
      );
      final studentCount = countResult.first['count'] as int;
      
      // Test query for student_id column
      String? testQueryResult;
      try {
        await db.rawQuery("SELECT student_id FROM students LIMIT 1");
        testQueryResult = "✅ student_id column accessible";
      } catch (e) {
        testQueryResult = "❌ Error: $e";
      }

      setState(() {
        _schemaInfo = {
          'version': version,
          'tables': tables,
          'studentColumns': tableInfo,
          'indices': indices,
          'studentCount': studentCount,
          'testQuery': testQueryResult,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Inspector'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _inspectSchema,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Error inspecting database',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(_error!, style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                )
              : _schemaInfo == null
                  ? const Center(child: Text('No data available'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildInfoCard(
                            'Database Version',
                            '${_schemaInfo!['version']}',
                            Icons.info,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoCard(
                            'Student Count',
                            '${_schemaInfo!['studentCount']}',
                            Icons.people,
                          ),
                          const SizedBox(height: 12),
                          _buildCard(
                            'Test Query Result',
                            _schemaInfo!['testQuery'] as String,
                          ),
                          const SizedBox(height: 16),
                          _buildSectionHeader('Tables'),
                          ..._buildListItems(_schemaInfo!['tables'] as List),
                          const SizedBox(height: 16),
                          _buildSectionHeader('Students Table Columns'),
                          ..._buildColumnItems(_schemaInfo!['studentColumns'] as List),
                          const SizedBox(height: 16),
                          _buildSectionHeader('Indices'),
                          ..._buildListItems(_schemaInfo!['indices'] as List),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCard(String title, String content) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(content),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  List<Widget> _buildListItems(List items) {
    return items.map((item) {
      final name = item['name'] as String;
      return Card(
        child: ListTile(
          leading: const Icon(Icons.table_chart),
          title: Text(name),
        ),
      );
    }).toList();
  }

  List<Widget> _buildColumnItems(List items) {
    return items.map((item) {
      final cid = item['cid'];
      final name = item['name'] as String;
      final type = item['type'] as String;
      final notNull = item['notnull'] == 1;
      final defaultValue = item['dflt_value'];
      final pk = item['pk'] == 1;

      return Card(
        child: ListTile(
          leading: CircleAvatar(
            child: Text('$cid'),
          ),
          title: Text(
            name,
            style: TextStyle(
              fontWeight: pk ? FontWeight.bold : FontWeight.normal,
              color: pk ? Colors.blue : null,
            ),
          ),
          subtitle: Text(
            '$type${notNull ? ' NOT NULL' : ''}${defaultValue != null ? ' DEFAULT $defaultValue' : ''}${pk ? ' PRIMARY KEY' : ''}',
          ),
        ),
      );
    }).toList();
  }
}
