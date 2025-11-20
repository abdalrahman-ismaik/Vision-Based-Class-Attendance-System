import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';

/// Search bar widget with debounce
class StudentSearchBar extends StatefulWidget {
  final String initialQuery;
  final ValueChanged<String> onSearch;
  final VoidCallback onClear;

  const StudentSearchBar({
    super.key,
    this.initialQuery = '',
    required this.onSearch,
    required this.onClear,
  });

  @override
  State<StudentSearchBar> createState() => _StudentSearchBarState();
}

class _StudentSearchBarState extends State<StudentSearchBar> {
  late final TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onSearch(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingMD,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Color(0xFFF9FAFB)],
        ),
      ),
      child: TextField(
        controller: _controller,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search by name, ID, or email...',
          hintStyle: TextStyle(color: AppColors.textSubtle),
          prefixIcon: Icon(Icons.search, color: AppColors.primaryIndigo),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: AppColors.textLight),
                  onPressed: () {
                    _controller.clear();
                    widget.onClear();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: AppRadius.circularMD,
            borderSide: BorderSide(color: AppColors.borderLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.circularMD,
            borderSide: BorderSide(color: AppColors.borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.circularMD,
            borderSide: BorderSide(color: AppColors.primaryIndigo, width: 2),
          ),
          filled: true,
          fillColor: AppColors.backgroundWhite,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
