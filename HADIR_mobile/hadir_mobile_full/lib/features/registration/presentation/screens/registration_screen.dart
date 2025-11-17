import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hadir_mobile_full/shared/domain/entities/student.dart';
import 'package:hadir_mobile_full/shared/domain/entities/selected_frame.dart';
import 'package:hadir_mobile_full/shared/domain/entities/registration_session.dart';
import 'package:hadir_mobile_full/shared/domain/entities/captured_frame.dart';
import 'package:hadir_mobile_full/core/computer_vision/pose_type.dart';
import 'package:hadir_mobile_full/core/services/frame_selection_service.dart';
import 'package:hadir_mobile_full/features/registration/presentation/widgets/guided_pose_capture.dart';
import 'package:hadir_mobile_full/shared/data/repositories/local_student_repository.dart';
import 'package:hadir_mobile_full/shared/data/repositories/local_registration_repository.dart';
import 'package:hadir_mobile_full/shared/data/data_sources/local_database_data_source.dart';
import 'package:hadir_mobile_full/core/services/backend_registration_service.dart';
import 'package:hadir_mobile_full/core/providers/backend_providers.dart';
import 'package:hadir_mobile_full/app/theme/app_colors.dart';
import 'package:hadir_mobile_full/app/theme/app_spacing.dart';
import 'package:hadir_mobile_full/app/theme/app_text_styles.dart';

/// Registration screen for student enrollment with guided pose capture
/// 
/// This implements a 3-step wizard:
/// Step 1: Student Information Collection
/// Step 2: Guided 5-Pose Capture (Frontal, Left, Right, Up, Down)
/// Step 3: Completion Summary
class RegistrationScreen extends ConsumerStatefulWidget {
  final bool developmentMode;
  
  const RegistrationScreen({
    super.key,
    this.developmentMode = false,
  });

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  // Page navigation
  final _pageController = PageController();
  int _currentStep = 0;
  
  // Form state
  final _formKey = GlobalKey<FormState>();
  
  // Student Information Controllers
  final _studentIdController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _majorController = TextEditingController();
  final _nationalityController = TextEditingController();
  
  // Optional fields
  DateTime? _selectedDateOfBirth;
  Gender _selectedGender = Gender.male;
  AcademicLevel _selectedAcademicLevel = AcademicLevel.undergraduate;
  int? _selectedEnrollmentYear;
  
  // Pose capture state
  final List<SelectedFrame> _capturedFrames = [];
  bool _poseCaptureComplete = false;
  String? _registrationSessionId;
  int _currentPoseIndex = 0;
  PoseType _currentPoseType = PoseType.frontal;
  String _currentPoseInstruction = 'Position student';

  // Repositories (lazy initialized)
  LocalStudentRepository? _studentRepository;
  LocalRegistrationRepository? _registrationRepository;

  // University Programs (Khalifa University example)
  static const List<String> _programs = [
    'Aerospace Engineering',
    'Applied Mathematics & Data Science',
    'Artificial Intelligence',
    'Biomedical Engineering',
    'Chemical Engineering',
    'Civil Engineering',
    'Computer Engineering',
    'Computer Science',
    'Cyber Security',
    'Data Science',
    'Electrical Engineering',
    'Electronic Engineering',
    'Information Technology',
    'Mechanical Engineering',
    'Petroleum Engineering',
    'Physics',
    'Software Engineering',
  ];

  List<String> _filteredPrograms = [];
  bool _showProgramDropdown = false;

  @override
  void initState() {
    super.initState();
    _filteredPrograms = _programs;
    _majorController.addListener(_filterPrograms);
    
    // Generate session ID
    _registrationSessionId = 'REG_${DateTime.now().millisecondsSinceEpoch}';
    
    // Initialize repositories
    _initializeRepositories();
    
    // Pre-fill form with mock data in development mode
    if (widget.developmentMode) {
      _prefillMockData();
    }
  }
  
  /// Pre-fill the registration form with mock data for development
  void _prefillMockData() {
    // Student ID: Only the 5 digits after 1000 prefix
    _studentIdController.text = '12345';
    _firstNameController.text = 'John';
    _lastNameController.text = 'Doe';
    // Email is auto-generated from student ID (100012345@ku.ac.ae)
    _emailController.text = '100012345@ku.ac.ae';
    _phoneController.text = '+971501234567';
    _majorController.text = 'Computer Science';
    _nationalityController.text = 'United Arab Emirates';
    _selectedDateOfBirth = DateTime(2000, 1, 15);
    _selectedGender = Gender.male;
    _selectedAcademicLevel = AcademicLevel.undergraduate;
    _selectedEnrollmentYear = 2024;
  }

  Future<void> _initializeRepositories() async {
    try {
      final dataSource = LocalDatabaseDataSource();
      // Database is initialized lazily on first access
      await dataSource.database;
      _studentRepository = LocalStudentRepository(dataSource);
      _registrationRepository = LocalRegistrationRepository(dataSource);
    } catch (e) {
      debugPrint('Failed to initialize repositories: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _studentIdController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _majorController.dispose();
    _nationalityController.dispose();
    super.dispose();
  }

  void _filterPrograms() {
    final query = _majorController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredPrograms = _programs;
        _showProgramDropdown = false;
      } else {
        _filteredPrograms = _programs
            .where((program) => program.toLowerCase().contains(query))
            .toList();
        _showProgramDropdown = _filteredPrograms.isNotEmpty;
      }
    });
  }

  void _selectProgram(String program) {
    setState(() {
      _majorController.text = program;
      _showProgramDropdown = false;
    });
  }

  // Helper method for pose display names
  String _getPoseDisplayName(PoseType poseType) {
    switch (poseType) {
      case PoseType.frontal:
        return 'Front Face';
      case PoseType.leftProfile:
        return 'Left Profile';
      case PoseType.rightProfile:
        return 'Right Profile';
      case PoseType.lookingUp:
        return 'Looking Up';
      case PoseType.lookingDown:
        return 'Looking Down';
    }
  }

  // Navigation methods
  void _goToNextStep() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleNextStep() async {
    if (_currentStep == 0) {
      // Validate student information
      if (_formKey.currentState!.validate()) {
        // Check if student ID already exists
        final fullStudentId = '1000${_studentIdController.text}';
        
        try {
          final studentExists = await _studentRepository!.existsByStudentId(fullStudentId);
          
          if (studentExists) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Student ID $fullStudentId is already registered'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
            return; // Don't proceed to next step
          }
          
          // Student doesn't exist, proceed to next step
          _goToNextStep();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error checking student ID: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } else if (_currentStep == 1) {
      // Check pose capture completion
      if (_poseCaptureComplete) {
        _goToNextStep();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please complete all 5 pose captures before proceeding'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else if (_currentStep == 2) {
      // Complete registration
      _completeRegistration();
    }
  }

  Future<void> _completeRegistration() async {
    if (_studentRepository == null || _registrationRepository == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Database not initialized. Please restart the app.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Saving registration...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // 1. Create Student entity
      // Construct full student ID with 1000 prefix
      final fullStudentId = '1000${_studentIdController.text}';
      final fullName = '${_firstNameController.text} ${_lastNameController.text}';
      
      final student = Student(
        id: 'STU_${DateTime.now().millisecondsSinceEpoch}', // Generate unique ID
        studentId: fullStudentId,
        fullName: fullName,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        email: _emailController.text,
        department: _majorController.text, // Using major as department
        program: _majorController.text, // Using major as program
        major: _majorController.text,
        phoneNumber: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        dateOfBirth: _selectedDateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 20)),
        gender: _selectedGender,
        nationality: _nationalityController.text.isNotEmpty 
            ? _nationalityController.text 
            : null,
        enrollmentYear: _selectedEnrollmentYear,
        academicLevel: _selectedAcademicLevel,
        status: StudentStatus.registered,
        registrationSessionId: _registrationSessionId,
        createdAt: DateTime.now(),
        lastUpdatedAt: DateTime.now(),
        faceEmbeddings: [], // Will be populated by AI augmentation later
      );

      // 2. Save student to local database
      await _studentRepository!.create(student);

      // 3. Upload to backend server
      String backendStatus = '';
      bool backendSuccess = false;
      
      try {
        // Get backend service
        final backendService = ref.read(backendRegistrationServiceProvider);
        
        // Select best quality image from captured frames
        if (_capturedFrames.isNotEmpty) {
          // Find frame with highest quality score
          final bestFrame = _capturedFrames.reduce((curr, next) => 
            curr.qualityScore > next.qualityScore ? curr : next
          );
          
          // Update loading dialog to show upload status
          if (mounted) {
            Navigator.of(context).pop(); // Close old dialog
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Uploading to server...'),
                        SizedBox(height: 8),
                        Text(
                          'This may take a few moments',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
          
          // Prepare image file
          final imageFile = File(bestFrame.imageFilePath);
          
          // Upload to backend
          final result = await backendService.registerStudent(
            student: student,
            imageFile: imageFile,
          );
          
          backendSuccess = result.success;
          backendStatus = result.success 
            ? '✓ Server: ${result.message ?? "Uploaded successfully"}'
            : '⚠️ Server: ${result.error ?? "Upload failed"}';
          
          print('Backend registration result: ${result.success ? "SUCCESS" : "FAILED"}');
          if (!result.success) {
            print('Backend error: ${result.error}');
          }
        } else {
          backendStatus = '⚠️ Server: No images available for upload';
          print('No captured frames available for backend upload');
        }
      } catch (e) {
        backendStatus = '⚠️ Server: ${e.toString()}';
        print('Backend upload error: $e');
      }

      // 4. Create and save registration session
      if (_registrationSessionId != null) {
        final session = RegistrationSession(
          id: _registrationSessionId!,
          studentId: student.id,
          administratorId: 'admin_1', // TODO: Get from auth context
          videoFilePath: 'N/A', // Not using video in this implementation
          status: SessionStatus.completed,
          startedAt: DateTime.now().subtract(const Duration(minutes: 5)), // Approximate
          completedAt: DateTime.now(),
          videoDurationMs: 0, // Not applicable for frame-by-frame capture
          totalFramesProcessed: _capturedFrames.length,
          capturedFramesCount: _capturedFrames.length,
          selectedFramesCount: _capturedFrames.length,
          overallQualityScore: _capturedFrames.isNotEmpty 
              ? _capturedFrames.map((f) => f.qualityScore).reduce((a, b) => a + b) / _capturedFrames.length
              : 0.0,
          poseCoveragePercentage: (_capturedFrames.length / 5) * 100,
          selectedFrames: _capturedFrames,
          metadata: {
            'administrator': 'admin', // TODO: Get from auth context
            'device': 'mobile',
            'app_version': '1.0.0',
            'total_poses_captured': _capturedFrames.length,
            'session_duration_seconds': 300, // Approximate
          },
        );

        // Save session to database
        await _registrationRepository!.insertSession({
          'id': session.id,
          'student_id': session.studentId,
          'administrator_id': session.administratorId,
          'video_file_path': session.videoFilePath,
          'status': session.status.name,
          'started_at': session.startedAt.toIso8601String(),
          'completed_at': session.completedAt?.toIso8601String(),
          'video_duration_ms': session.videoDurationMs,
          'total_frames_processed': session.totalFramesProcessed,
          'selected_frames_count': session.selectedFramesCount,
          'overall_quality_score': session.overallQualityScore,
          'pose_coverage_percentage': session.poseCoveragePercentage,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        // 4. Save all captured frames
        for (final frame in _capturedFrames) {
          await _registrationRepository!.insertFrame({
            'id': frame.id,
            'session_id': _registrationSessionId!,
            'image_file_path': frame.imageFilePath,
            'timestamp_ms': frame.timestampMs,
            'quality_score': frame.qualityScore,
            'pose_type': frame.poseType.name,
            'confidence_score': frame.confidenceScore,
            'extracted_at': frame.extractedAt.toIso8601String(),
            'metadata': jsonEncode({
              'capture_method': 'manual_validation',
              'frames_per_pose': 30,
              'quality_analysis': 'sharpness_based',
            }),
          });
        }
      }

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show success message with backend status
      if (mounted) {
        final messageColor = backendSuccess ? Colors.green : Colors.orange;
        final icon = backendSuccess ? Icons.check_circle : Icons.warning;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: Colors.white),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('✓ Saved locally'),
                    ),
                  ],
                ),
                if (backendStatus.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    backendStatus,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
            backgroundColor: messageColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      
      // Navigate to dashboard after short delay
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Registration failed: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _completeRegistration,
            ),
          ),
        );
      }
      
      debugPrint('Registration error: $e');
    }
  }

  Future<void> _handleLogout() async {
    // Simple navigation to login - auth state will be handled by login screen
    if (mounted) {
      context.go('/login');
    }
  }

  Future<void> _selectDateOfBirth() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 100)),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 16)),
    );

    if (date != null) {
      setState(() {
        _selectedDateOfBirth = date;
      });
    }
  }

  // ========== MODERN UI HELPER WIDGETS ==========

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    String? helperText,
    String? prefixText,
    TextInputType? keyboardType,
    int? maxLength,
    bool readOnly = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.labelMedium,
        hintText: hintText,
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSubtle),
        helperText: helperText,
        helperStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
        prefixIcon: Icon(icon, color: AppColors.primaryIndigo, size: 22),
        prefixText: prefixText,
        prefixStyle: AppTextStyles.bodyLarge.copyWith(color: AppColors.textDark),
        border: OutlineInputBorder(
          borderRadius: AppRadius.circularMD,
          borderSide: BorderSide(color: AppColors.borderMedium, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.circularMD,
          borderSide: BorderSide(color: AppColors.borderMedium, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.circularMD,
          borderSide: BorderSide(color: AppColors.primaryIndigo, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.circularMD,
          borderSide: BorderSide(color: AppColors.warningRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.circularMD,
          borderSide: BorderSide(color: AppColors.warningRed, width: 2),
        ),
        filled: true,
        fillColor: readOnly ? AppColors.backgroundGray : Colors.white,
        contentPadding: AppSpacing.paddingMD,
      ),
      style: readOnly 
        ? AppTextStyles.bodyLarge.copyWith(color: AppColors.textLight)
        : AppTextStyles.bodyLarge,
      keyboardType: keyboardType,
      maxLength: maxLength,
      readOnly: readOnly,
      textCapitalization: textCapitalization,
      validator: validator,
      onChanged: onChanged,
    );
  }

  Widget _buildModernInputDecorator({
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.labelMedium,
        prefixIcon: Icon(icon, color: AppColors.primaryIndigo, size: 22),
        border: OutlineInputBorder(
          borderRadius: AppRadius.circularMD,
          borderSide: BorderSide(color: AppColors.borderMedium, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.circularMD,
          borderSide: BorderSide(color: AppColors.borderMedium, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: AppSpacing.paddingMD,
      ),
      child: child,
    );
  }

  Widget _buildModernDropdown<T>({
    required T? value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.labelMedium,
        prefixIcon: Icon(icon, color: AppColors.primaryIndigo, size: 22),
        border: OutlineInputBorder(
          borderRadius: AppRadius.circularMD,
          borderSide: BorderSide(color: AppColors.borderMedium, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.circularMD,
          borderSide: BorderSide(color: AppColors.borderMedium, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.circularMD,
          borderSide: BorderSide(color: AppColors.primaryIndigo, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: AppSpacing.paddingMD,
      ),
      style: AppTextStyles.bodyLarge,
      items: items,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Student Registration',
          style: AppTextStyles.headingMedium.copyWith(color: AppColors.textDark),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Icon(Icons.logout, color: AppColors.warningRed),
              tooltip: 'Logout',
              onPressed: _handleLogout,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Modern gradient progress indicator
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: AppElevation.shadowSM,
            ),
            child: Column(
              children: [
                // Progress bar with gradient
                SizedBox(
                  height: 4,
                  child: LinearProgressIndicator(
                    value: (_currentStep + 1) / 3,
                    backgroundColor: AppColors.borderLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryIndigo),
                  ),
                ),
                
                // Step indicator with modern design
                Padding(
                  padding: AppSpacing.paddingMD,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStepIndicator(0, 'Student Info', Icons.person),
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            gradient: _currentStep >= 1 
                              ? AppColors.primaryGradient 
                              : null,
                            color: _currentStep >= 1 ? null : AppColors.borderLight,
                          ),
                        ),
                      ),
                      _buildStepIndicator(1, 'Pose Capture', Icons.camera_alt),
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            gradient: _currentStep >= 2 
                              ? AppColors.primaryGradient 
                              : null,
                            color: _currentStep >= 2 ? null : AppColors.borderLight,
                          ),
                        ),
                      ),
                      _buildStepIndicator(2, 'Complete', Icons.check_circle),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // Disable swipe
              onPageChanged: (index) {
                setState(() {
                  _currentStep = index;
                });
              },
              children: [
                _buildStudentInfoStep(),
                _buildPoseCaptureStep(),
                _buildCompleteStep(),
              ],
            ),
          ),

          // Navigation buttons with modern design
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int stepIndex, String title, IconData icon) {
    final isActive = stepIndex == _currentStep;
    final isCompleted = stepIndex < _currentStep;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isCompleted || isActive
                ? AppColors.primaryGradient
                : null,
            color: isCompleted || isActive ? null : AppColors.backgroundGray,
            boxShadow: isActive ? AppElevation.shadowMD : null,
          ),
          child: Icon(
            isCompleted ? Icons.check : icon,
            color: isCompleted || isActive ? Colors.white : AppColors.textSubtle,
            size: 24,
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          title,
          style: isActive 
            ? AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primaryIndigo,
              )
            : AppTextStyles.labelSmall.copyWith(
                color: AppColors.textLight,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: AppElevation.shadowMD,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _goToPreviousStep,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    side: BorderSide(color: AppColors.borderMedium, width: 1.5),
                    foregroundColor: AppColors.textMedium,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.circularMD,
                    ),
                  ),
                ),
              ),
            if (_currentStep > 0) SizedBox(width: AppSpacing.md),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: AppRadius.circularMD,
                  boxShadow: AppElevation.coloredShadow(AppColors.primaryIndigo),
                ),
                child: ElevatedButton.icon(
                  onPressed: _handleNextStep,
                  icon: Icon(_currentStep == 2 ? Icons.check : Icons.arrow_forward),
                  label: Text(
                    _currentStep == 2 ? 'Finish Registration' : 'Next',
                    style: AppTextStyles.button.copyWith(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.circularMD,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== STEP 1: STUDENT INFORMATION ==========
  
  Widget _buildStudentInfoStep() {
    return SingleChildScrollView(
      padding: AppSpacing.paddingMD,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modern header card with gradient
            Container(
              padding: AppSpacing.paddingLG,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: AppRadius.circularXL,
                boxShadow: AppElevation.coloredShadow(AppColors.primaryIndigo),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: AppRadius.circularMD,
                        ),
                        child: const Icon(Icons.person_add, color: Colors.white, size: 28),
                      ),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Student Information',
                              style: AppTextStyles.headingLarge.copyWith(color: Colors.white),
                            ),
                            SizedBox(height: AppSpacing.xs),
                            Text(
                              'Enter student details accurately',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.lg),

            // Required fields section
            _buildSectionHeader('Required Information'),
            SizedBox(height: AppSpacing.md),

            // Student ID with fixed 1000 prefix
            _buildModernTextField(
              controller: _studentIdController,
              label: 'Student ID',
              icon: Icons.badge,
              prefixText: '1000',
              helperText: 'Enter the last 5 digits (e.g., 64692)',
              keyboardType: TextInputType.number,
              maxLength: 5,
              onChanged: (value) {
                // Auto-generate email from student ID
                if (value.isNotEmpty && RegExp(r'^\d{5}$').hasMatch(value)) {
                  final fullStudentId = '1000$value';
                  _emailController.text = '$fullStudentId@ku.ac.ae';
                } else {
                  _emailController.text = '';
                }
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the 5 digits after 1000';
                }
                if (!RegExp(r'^\d{5}$').hasMatch(value)) {
                  return 'Please enter exactly 5 digits';
                }
                return null;
              },
            ),
            SizedBox(height: AppSpacing.md),

            // First Name
            _buildModernTextField(
              controller: _firstNameController,
              label: 'First Name',
              icon: Icons.person,
              hintText: 'Ahmed',
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'First name is required';
                }
                if (value.length < 2) {
                  return 'First name must be at least 2 characters';
                }
                return null;
              },
            ),
            SizedBox(height: AppSpacing.md),

            // Last Name
            _buildModernTextField(
              controller: _lastNameController,
              label: 'Last Name',
              icon: Icons.person_outline,
              hintText: 'Hassan',
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Last name is required';
                }
                if (value.length < 2) {
                  return 'Last name must be at least 2 characters';
                }
                return null;
              },
            ),
            SizedBox(height: AppSpacing.md),

            // Email (auto-generated from Student ID)
            _buildModernTextField(
              controller: _emailController,
              label: 'Email Address',
              icon: Icons.email,
              helperText: 'Auto-generated from Student ID',
              readOnly: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a valid student ID first';
                }
                if (!RegExp(r'^1000\d{5}@ku\.ac\.ae$').hasMatch(value)) {
                  return 'Email format should be studentid@ku.ac.ae';
                }
                return null;
              },
            ),
            SizedBox(height: AppSpacing.md),

            // Major (Searchable Khalifa University Programs)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dropdown appears ABOVE the text field
                if (_showProgramDropdown && _filteredPrograms.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(bottom: AppSpacing.xs),
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderMedium),
                      borderRadius: AppRadius.circularMD,
                      color: Colors.white,
                      boxShadow: AppElevation.shadowLG,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredPrograms.length,
                      itemBuilder: (context, index) {
                        final program = _filteredPrograms[index];
                        return InkWell(
                          onTap: () => _selectProgram(program),
                          child: Container(
                            padding: AppSpacing.paddingMD,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: AppColors.borderLight,
                                  width: index < _filteredPrograms.length - 1 ? 1 : 0,
                                ),
                              ),
                            ),
                            child: Text(
                              program,
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                // Text field appears below the dropdown
                _buildModernTextField(
                  controller: _majorController,
                  label: 'Major/Program',
                  icon: Icons.school,
                  helperText: 'Type to search Khalifa University programs',
                  onChanged: (query) {
                    setState(() {
                      if (query.isEmpty) {
                        _filteredPrograms = _programs;
                        _showProgramDropdown = false;
                      } else {
                        _filteredPrograms = _programs
                            .where((program) => program.toLowerCase().contains(query.toLowerCase()))
                            .toList();
                        _showProgramDropdown = _filteredPrograms.isNotEmpty;
                      }
                    });
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please select your major/program';
                    }
                    if (!_programs.contains(value.trim())) {
                      return 'Please select a valid program from the list';
                    }
                    return null;
                  },
                ),
              ],
            ),
            SizedBox(height: AppSpacing.lg),

            // Optional fields section
            _buildSectionHeader('Optional Information'),
            SizedBox(height: AppSpacing.md),

            // Phone Number
            _buildModernTextField(
              controller: _phoneController,
              label: 'Phone Number (Optional)',
              icon: Icons.phone,
              hintText: '+962 7X XXX XXXX',
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (!RegExp(r'^\+?\d{10,15}$').hasMatch(value.replaceAll(' ', ''))) {
                    return 'Please enter a valid phone number';
                  }
                }
                return null;
              },
            ),
            SizedBox(height: AppSpacing.md),

            // Date of Birth
            InkWell(
              onTap: _selectDateOfBirth,
              child: _buildModernInputDecorator(
                label: 'Date of Birth (Optional)',
                icon: Icons.calendar_today,
                child: Text(
                  _selectedDateOfBirth != null
                      ? '${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year}'
                      : 'Select date',
                  style: _selectedDateOfBirth != null 
                    ? AppTextStyles.bodyLarge 
                    : AppTextStyles.bodyLarge.copyWith(color: AppColors.textSubtle),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.md),

            // Gender
            _buildModernDropdown<Gender>(
              value: _selectedGender,
              label: 'Gender (Optional)',
              icon: Icons.wc,
              items: Gender.values.map((gender) {
                return DropdownMenuItem(
                  value: gender,
                  child: Text(gender.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedGender = value;
                  });
                }
              },
            ),
            SizedBox(height: AppSpacing.md),

            // Nationality
            _buildModernTextField(
              controller: _nationalityController,
              label: 'Nationality (Optional)',
              icon: Icons.flag,
              hintText: 'Jordanian',
              textCapitalization: TextCapitalization.words,
            ),
            SizedBox(height: AppSpacing.md),

            // Enrollment Year
            _buildModernDropdown<int>(
              value: _selectedEnrollmentYear,
              label: 'Enrollment Year (Optional)',
              icon: Icons.date_range,
              items: List.generate(10, (index) {
                final year = DateTime.now().year - index;
                return DropdownMenuItem(
                  value: year,
                  child: Text(year.toString()),
                );
              }),
              onChanged: (value) {
                setState(() {
                  _selectedEnrollmentYear = value;
                });
              },
            ),
            SizedBox(height: AppSpacing.md),

            // Academic Level
            _buildModernDropdown<AcademicLevel>(
              value: _selectedAcademicLevel,
              label: 'Academic Level (Optional)',
              icon: Icons.stairs,
              items: AcademicLevel.values.map((level) {
                return DropdownMenuItem(
                  value: level,
                  child: Text(level.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedAcademicLevel = value;
                  });
                }
              },
            ),
            SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: AppRadius.circularSM,
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: AppTextStyles.headingSmall.copyWith(
            color: AppColors.primaryIndigo,
          ),
        ),
      ],
    );
  }

  // ========== STEP 2: POSE CAPTURE ==========
  
  Widget _buildPoseCaptureStep() {
    return Column(
      children: [
        // Camera preview area - full screen with overlay header
        Expanded(
          child: Container(
            color: Colors.black,
            width: double.infinity,
            child: Stack(
              children: [
                // Camera view (full size) or completion message
                if (_poseCaptureComplete)
                  // Show completion message when poses are already captured
                  Center(
                    child: Container(
                      margin: AppSpacing.paddingXL,
                      padding: AppSpacing.paddingXL,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppRadius.circularXXL,
                        boxShadow: AppElevation.shadowLG,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: AppSpacing.paddingLG,
                            decoration: BoxDecoration(
                              gradient: AppColors.successGradient,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 64,
                            ),
                          ),
                          SizedBox(height: AppSpacing.lg),
                          Text(
                            'All Poses Captured!',
                            style: AppTextStyles.displaySmall.copyWith(
                              color: AppColors.successGreen,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: AppSpacing.sm),
                          Text(
                            '${_capturedFrames.length} poses captured successfully',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.textMedium,
                            ),
                          ),
                          SizedBox(height: AppSpacing.xl),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: AppRadius.circularMD,
                              boxShadow: AppElevation.coloredShadow(AppColors.primaryIndigo),
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () => _goToNextStep(),
                              icon: const Icon(Icons.arrow_forward),
                              label: Text(
                                'Continue',
                                style: AppTextStyles.button.copyWith(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                  vertical: AppSpacing.md,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: AppRadius.circularMD,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_registrationSessionId != null)
                  // Show camera widget when poses not yet captured  
                  GuidedPoseCapture(
                    sessionId: _registrationSessionId!,
                    embedded: true,
                    onPoseChanged: (poseIndex, poseType, instruction) {
                      if (mounted) {
                        // Defer state update to avoid calling setState during build
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() {
                              _currentPoseIndex = poseIndex;
                              _currentPoseType = poseType;
                              _currentPoseInstruction = instruction;
                            });
                          }
                        });
                      }
                    },
                    onFrameCaptured: (frame) {
                      if (mounted) {
                        setState(() {
                          _capturedFrames.add(frame);
                        });
                      }
                    },
                    onAllFramesCaptured: (List<CapturedFrame> allFrames) async {
                      // All 75 frames captured - now process in BACKGROUND
                      debugPrint('🎯 Starting background frame selection (${allFrames.length} frames)...');
                      
                      try {
                        final frameSelectionService = FrameSelectionService();
                        
                        // Select best frames: 1 frame per pose = 5 total
                        final Map<PoseType, List<SelectedFrame>> selectedByPose = 
                          await frameSelectionService.selectBestFrames(
                            capturedFrames: allFrames,
                            sessionId: _registrationSessionId!,
                            framesPerPose: 1, // Only 1 best frame per pose for backend
                          );
                        
                        // Flatten to list of 5 frames
                        final List<SelectedFrame> finalFrames = [];
                        selectedByPose.forEach((pose, frames) {
                          finalFrames.addAll(frames);
                        });
                        
                        debugPrint('✅ Selected ${finalFrames.length} best frames for upload');
                        debugPrint('   Frames: ${finalFrames.map((f) => '${f.poseType.name} (${(f.qualityScore * 100).toInt()}%)').join(', ')}');
                        
                        if (mounted) {
                          setState(() {
                            // Store selected frames for upload to backend
                            _capturedFrames.clear();
                            _capturedFrames.addAll(finalFrames);
                          });
                        }
                      } catch (e) {
                        debugPrint('❌ Frame selection error: $e');
                      }
                      
                      // Processing complete - the widget will automatically hide the overlay
                      // after this callback completes since it's async
                    },
                    onComplete: () {
                      if (mounted) {
                        setState(() {
                          _poseCaptureComplete = true;
                        });
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: AppSpacing.sm),
                                const Expanded(
                                  child: Text('✓ All poses captured successfully!'),
                                ),
                              ],
                            ),
                            backgroundColor: AppColors.successGreen,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.circularMD,
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    onError: (error) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.error, color: Colors.white),
                                SizedBox(width: AppSpacing.sm),
                                Expanded(child: Text('Error: $error')),
                              ],
                            ),
                            backgroundColor: AppColors.warningRed,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.circularMD,
                            ),
                          ),
                        );
                      }
                    },
                  )
                else
                  Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryIndigo),
                    ),
                  ),
                
                // Overlay header with translucent background
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    width: double.infinity,
                    padding: AppSpacing.paddingLG,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Column(
                        children: [
                          // Progress dots
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              final isCompleted = index < _currentPoseIndex;
                              final isCurrent = index == _currentPoseIndex;
                              
                              return Container(
                                margin: EdgeInsets.symmetric(horizontal: AppSpacing.xs / 2),
                                width: isCurrent ? 32 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isCompleted || isCurrent
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }),
                          ),
                          SizedBox(height: AppSpacing.md),
                          
                          // Pose name badge
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: AppRadius.circularXL,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _getPoseDisplayName(_currentPoseType),
                              style: AppTextStyles.headingMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SizedBox(height: AppSpacing.sm),
                          
                          // Instruction
                          Text(
                            _currentPoseInstruction,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white.withOpacity(0.95),
                            ),
                            textAlign: TextAlign.center,
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
      ],
    );
  }

  // ========== STEP 3: COMPLETION ==========
  
  Widget _buildCompleteStep() {
    return SingleChildScrollView(
      padding: AppSpacing.paddingLG,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: AppSpacing.xxl),
          
          // Success icon with gradient
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.successGradient,
              boxShadow: AppElevation.coloredShadow(AppColors.successGreen),
            ),
            child: const Icon(
              Icons.check_circle,
              size: 72,
              color: Colors.white,
            ),
          ),
          SizedBox(height: AppSpacing.lg),

          // Success message
          Text(
            'Registration Ready!',
            style: AppTextStyles.displayMedium.copyWith(
              color: AppColors.successGreen,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.sm),
          
          Text(
            'All information and poses captured successfully',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textMedium,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.xl),

          // Summary card with gradient border
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: AppRadius.circularXL,
              boxShadow: AppElevation.shadowMD,
            ),
            padding: const EdgeInsets.all(2), // Gradient border width
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.circularXL,
              ),
              padding: AppSpacing.paddingLG,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: AppRadius.circularMD,
                        ),
                        child: const Icon(Icons.summarize, color: Colors.white, size: 20),
                      ),
                      SizedBox(width: AppSpacing.md),
                      Text(
                        'Registration Summary',
                        style: AppTextStyles.headingMedium.copyWith(
                          color: AppColors.primaryIndigo,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.md),
                  Divider(color: AppColors.borderLight, height: 1),
                  SizedBox(height: AppSpacing.md),
                  
                  _buildSummaryRow('Student ID', '1000${_studentIdController.text}', Icons.badge),
                  _buildSummaryRow('Name', '${_firstNameController.text} ${_lastNameController.text}', Icons.person),
                  _buildSummaryRow('Email', _emailController.text, Icons.email),
                  _buildSummaryRow('Major', _majorController.text, Icons.school),
                  if (_phoneController.text.isNotEmpty)
                    _buildSummaryRow('Phone', _phoneController.text, Icons.phone),
                  
                  SizedBox(height: AppSpacing.sm),
                  Divider(color: AppColors.borderLight, height: 1),
                  SizedBox(height: AppSpacing.md),
                  
                  _buildSummaryRow(
                    'Poses Captured',
                    '${_capturedFrames.length} / 5',
                    Icons.camera_alt,
                    valueColor: AppColors.successGreen,
                  ),
                  _buildSummaryRow(
                    'Session ID', 
                    _registrationSessionId ?? 'N/A',
                    Icons.fingerprint,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: AppSpacing.lg),

          // Info box with modern design
          Container(
            padding: AppSpacing.paddingLG,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.secondaryCyan.withOpacity(0.1),
                  AppColors.secondaryBlue.withOpacity(0.1),
                ],
              ),
              borderRadius: AppRadius.circularXL,
              border: Border.all(
                color: AppColors.secondaryCyan.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    gradient: AppColors.secondaryGradient,
                    borderRadius: AppRadius.circularMD,
                  ),
                  child: const Icon(Icons.info_outline, color: Colors.white, size: 20),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Click "Finish Registration" to complete and save the student record.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.backgroundGray,
              borderRadius: AppRadius.circularSM,
            ),
            child: Icon(icon, size: 18, color: AppColors.primaryIndigo),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textLight,
                  ),
                ),
                SizedBox(height: AppSpacing.xs / 2),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
