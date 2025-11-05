import 'package:flutter/material.dart';
import '../../data/models/student_filter.dart';
import '../../../../shared/domain/entities/student.dart';

/// Bottom sheet for filtering students
class StudentFilterSheet extends StatefulWidget {
  final StudentFilter initialFilter;
  final ValueChanged<StudentFilter> onApply;

  const StudentFilterSheet({
    super.key,
    required this.initialFilter,
    required this.onApply,
  });

  @override
  State<StudentFilterSheet> createState() => _StudentFilterSheetState();
}

class _StudentFilterSheetState extends State<StudentFilterSheet> {
  late List<StudentStatus> _selectedStatuses;
  String? _selectedDepartment;
  DateTime? _startDate;
  DateTime? _endDate;
  int? _minFrameCount;

  @override
  void initState() {
    super.initState();
    _selectedStatuses = widget.initialFilter.statuses ?? [];
    _selectedDepartment = widget.initialFilter.department;
    _startDate = widget.initialFilter.startDate;
    _endDate = widget.initialFilter.endDate;
    _minFrameCount = widget.initialFilter.minFrameCount;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                const Text(
                  'Filter Students',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _clearAll,
                  child: const Text('Clear All'),
                ),
              ],
            ),
          ),
          
          // Filter content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status filter
                  _buildSectionTitle('Status'),
                  _buildStatusChips(),
                  const SizedBox(height: 24),
                  
                  // Department filter
                  _buildSectionTitle('Department'),
                  _buildDepartmentDropdown(),
                  const SizedBox(height: 24),
                  
                  // Date range filter
                  _buildSectionTitle('Registration Date'),
                  _buildDateRangePicker(),
                  const SizedBox(height: 24),
                  
                  // Frame count filter
                  _buildSectionTitle('Minimum Frames'),
                  _buildFrameCountSlider(),
                ],
              ),
            ),
          ),
          
          // Apply button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyFilter,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildStatusChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: StudentStatus.values.map((status) {
        final isSelected = _selectedStatuses.contains(status);
        return FilterChip(
          label: Text(status.toString().split('.').last),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedStatuses.add(status);
              } else {
                _selectedStatuses.remove(status);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildDepartmentDropdown() {
    // TODO: Fetch departments from database
    final departments = [
      'Computer Science',
      'Engineering',
      'Business',
      'Arts',
      'Sciences',
    ];

    return DropdownButtonFormField<String>(
      value: _selectedDepartment,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      hint: const Text('Select department'),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('All departments'),
        ),
        ...departments.map((dept) => DropdownMenuItem(
          value: dept,
          child: Text(dept),
        )),
      ],
      onChanged: (value) {
        setState(() {
          _selectedDepartment = value;
        });
      },
    );
  }

  Widget _buildDateRangePicker() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _selectDate(true),
            icon: const Icon(Icons.calendar_today, size: 16),
            label: Text(
              _startDate != null
                  ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                  : 'Start Date',
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Text('to'),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _selectDate(false),
            icon: const Icon(Icons.calendar_today, size: 16),
            label: Text(
              _endDate != null
                  ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                  : 'End Date',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFrameCountSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Slider(
          value: (_minFrameCount ?? 0).toDouble(),
          min: 0,
          max: 10,
          divisions: 10,
          label: _minFrameCount?.toString() ?? '0',
          onChanged: (value) {
            setState(() {
              _minFrameCount = value.toInt();
            });
          },
        ),
        Text(
          'Minimum ${_minFrameCount ?? 0} frames',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        if (isStartDate) {
          _startDate = date;
        } else {
          _endDate = date;
        }
      });
    }
  }

  void _clearAll() {
    setState(() {
      _selectedStatuses = [];
      _selectedDepartment = null;
      _startDate = null;
      _endDate = null;
      _minFrameCount = null;
    });
  }

  void _applyFilter() {
    final filter = StudentFilter(
      statuses: _selectedStatuses.isEmpty ? null : _selectedStatuses,
      department: _selectedDepartment,
      startDate: _startDate,
      endDate: _endDate,
      minFrameCount: _minFrameCount,
    );
    widget.onApply(filter);
  }
}
