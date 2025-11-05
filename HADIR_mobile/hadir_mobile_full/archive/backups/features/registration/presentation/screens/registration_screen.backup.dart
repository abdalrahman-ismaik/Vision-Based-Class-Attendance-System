import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import 'package:hadir_mobile_full/shared/domain/entities/student.dart';
import 'package:hadir_mobile_full/shared/domain/entities/selected_frame.dart';
import 'package:hadir_mobile_full/features/auth/presentation/providers/auth_provider_setup.dart';

import 'package:hadir_mobile_full/features/registration/presentation/widgets/guided_pose_capture.dart';


/// Registration screen for student data entry and pose capture
class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _studentIdController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _majorController = TextEditingController();
  final _nationalityController = TextEditingController();
  
  DateTime? _selectedDateOfBirth;
  Gender _selectedGender = Gender.male;
  AcademicLevel _selectedAcademicLevel = AcademicLevel.undergraduate;
  int? _selectedEnrollmentYear;
  
  // Pose capture data
  final List<SelectedFrame> _capturedFrames = [];
  bool _poseCaptureComplete = false;
  bool _isCameraActive = false;
  String? _cameraSessionId;

  // Khalifa University Programs (Simplified and Alphabetical)
  static const List<String> _kuPrograms = [
    'Aerospace Engineering',
    'Applied Mathematics, Statistics, and Data Science',
    'Artificial Intelligence Concentration',
    'Biomedical Engineering',
    'Cell and Molecular Biology',
    'Chemical Engineering',
    'Chemistry',
    'Civil Engineering',
    'Computer Engineering',
    'Computer Science',
    'Cybersecurity Concentration',
    'Earth and Planetary Sciences',
    'Electrical Engineering',
    'Energy Engineering',
    'Engineering Systems And Management',
    'Mechanical Engineering',
    'Petroleum Engineering',
    'Physics',
    'Robotics And Artificial Intelligence (AI)',
    'Software Systems Concentration',
  ];

  List<String> _filteredPrograms = [];
  bool _showProgramDropdown = false;

  @override
  void initState() {
    super.initState();
    _filteredPrograms = List.from(_kuPrograms);
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

  /// Auto-generate email address from student ID
  void _onStudentIdChanged(String value) {
    if (value.isNotEmpty && RegExp(r'^\d{5}$').hasMatch(value)) {
      // Auto-fill email with 1000 + last 5 digits + @ku.ac.ae
      final fullStudentId = '1000$value';
      _emailController.text = '$fullStudentId@ku.ac.ae';
    } else {
      // Clear email if student ID is invalid
      _emailController.text = '';
    }
  }

  /// Filter programs based on search query
  void _onMajorSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPrograms = List.from(_kuPrograms);
        _showProgramDropdown = false;
      } else {
        _filteredPrograms = _kuPrograms
            .where((program) => program.toLowerCase().contains(query.toLowerCase()))
            .toList();
        _showProgramDropdown = true;
      }
    });
  }

  /// Select a program from the filtered list
  void _selectProgram(String program) {
    setState(() {
      _majorController.text = program;
      _showProgramDropdown = false;
    });
  }



  /// Get current pose instruction
  String _getCurrentPoseInstruction() {
    const poses = [
      'Front Face',
      'Left Profile',
      'Right Profile', 
      'Looking Up',
      'Looking Down'
    ];
    
    if (_capturedFrames.length < poses.length) {
      return poses[_capturedFrames.length];
    }
    return 'All Complete';
  }

  /// Get current pose description
  String _getCurrentPoseDescription() {
    const descriptions = [
      'Look directly at the camera with your face centered',
      'Turn your head to show your left profile',
      'Turn your head to show your right profile',
      'Tilt your head up to look at the ceiling',
      'Tilt your head down to look at the floor'
    ];
    
    if (_capturedFrames.length < descriptions.length) {
      return descriptions[_capturedFrames.length];
    }
    return 'All poses have been successfully captured!';
  }

  /// Toggle inline camera for pose capture
  Future<void> _launchPoseCapture() async {
    // Check available cameras and handle permissions
    List<CameraDescription> cameras;
    
    try {
      cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No cameras found on this device'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
    } catch (e) {
      // Camera permission denied or other error
      if (mounted) {
        _showPermissionDialog();
      }
      return;
    }
    
    // Toggle camera active state
    setState(() {
      _isCameraActive = !_isCameraActive;
      if (_isCameraActive) {
        _cameraSessionId = 'registration_${DateTime.now().millisecondsSinceEpoch}';
      } else {
        _cameraSessionId = null;
      }
    });
  }
  
  /// Show dialog for camera permission or access issues
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Access Required'),
        content: const Text(
          'Camera access is required for pose capture. Please ensure the camera permission is granted and the camera is not being used by another app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Registration'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentStep + 1) / 3,
            backgroundColor: Colors.grey[300],
          ),
          
          // Step indicator
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _buildStepIndicator(0, 'Student Info'),
                const Expanded(child: Divider()),
                _buildStepIndicator(1, 'Pose Capture'),
                const Expanded(child: Divider()),
                _buildStepIndicator(2, 'Complete'),
              ],
            ),
          ),

          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
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

          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _goToPreviousStep,
                      child: const Text('Back'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleNextStep,
                    child: Text(_currentStep == 2 ? 'Finish' : 'Next'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int stepIndex, String title) {
    final isActive = stepIndex == _currentStep;
    final isCompleted = stepIndex < _currentStep;
    
    return Column(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: isCompleted
              ? Colors.green
              : isActive
                  ? Theme.of(context).primaryColor
                  : Colors.grey[300],
          child: Icon(
            isCompleted ? Icons.check : Icons.circle,
            color: isCompleted || isActive ? Colors.white : Colors.grey[600],
            size: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Theme.of(context).primaryColor : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStudentInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Student Information',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            // === MANDATORY FIELDS ===
            Text(
              'Required Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Student ID with fixed 1000 prefix
            TextFormField(
              controller: _studentIdController,
              decoration: InputDecoration(
                labelText: 'Student ID',
                prefixIcon: const Icon(Icons.badge),
                prefixText: '1000',
                prefixStyle: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87,
                  fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16,
                  fontWeight: FontWeight.normal,
                ),
                border: const OutlineInputBorder(),
                helperText: 'Enter the last 5 digits (e.g., 64692)',
              ),
              style: TextStyle(
                fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16,
              ),
              keyboardType: TextInputType.number,
              maxLength: 5,
              onChanged: _onStudentIdChanged,
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
            const SizedBox(height: 16),

            // First and Last Name
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'First Name',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter first name';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Last Name',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter last name';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Email (auto-generated from Student ID)
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
                helperText: 'Auto-generated from Student ID',
              ),
              readOnly: true,
              style: TextStyle(color: Colors.grey[600]),
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
            const SizedBox(height: 16),

            // Major (Searchable Khalifa University Programs)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _majorController,
                  decoration: const InputDecoration(
                    labelText: 'Major/Program',
                    prefixIcon: Icon(Icons.school),
                    border: OutlineInputBorder(),
                    helperText: 'Type to search Khalifa University programs',
                  ),
                  onChanged: _onMajorSearchChanged,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please select your major/program';
                    }
                    if (!_kuPrograms.contains(value.trim())) {
                      return 'Please select a valid program from the list';
                    }
                    return null;
                  },
                ),
                if (_showProgramDropdown && _filteredPrograms.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredPrograms.length,
                      itemBuilder: (context, index) {
                        final program = _filteredPrograms[index];
                        return ListTile(
                          dense: true,
                          title: Text(
                            program,
                            style: const TextStyle(fontSize: 14),
                          ),
                          onTap: () => _selectProgram(program),
                        );
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Nationality
            TextFormField(
              controller: _nationalityController,
              decoration: const InputDecoration(
                labelText: 'Nationality',
                prefixIcon: Icon(Icons.flag),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter nationality';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Gender
            DropdownButtonFormField<Gender>(
              value: _selectedGender,
              decoration: const InputDecoration(
                labelText: 'Gender',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              items: Gender.values.map((gender) {
                return DropdownMenuItem(
                  value: gender,
                  child: Text(gender.toString()),
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
            const SizedBox(height: 16),

            // Academic Level
            DropdownButtonFormField<AcademicLevel>(
              value: _selectedAcademicLevel,
              decoration: const InputDecoration(
                labelText: 'Academic Level',
                prefixIcon: Icon(Icons.school),
                border: OutlineInputBorder(),
              ),
              items: AcademicLevel.values.map((level) {
                return DropdownMenuItem(
                  value: level,
                  child: Text(level.toString()),
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
            const SizedBox(height: 24),

            // === OPTIONAL FIELDS ===
            Divider(color: Colors.grey[300], thickness: 1),
            const SizedBox(height: 16),
            Text(
              'Optional Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Phone Number (Optional)
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number (Optional)',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
                helperText: 'Format: +1234567890',
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                // Optional field - only validate if not empty
                if (value != null && value.trim().isNotEmpty) {
                  if (!RegExp(r'^\+\d{10,15}$').hasMatch(value)) {
                    return 'Please enter a valid phone number with country code';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Date of Birth (Optional)
            InkWell(
              onTap: _selectDateOfBirth,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date of Birth (Optional)',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _selectedDateOfBirth != null
                      ? '${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year}'
                      : 'Select date of birth (optional)',
                  style: TextStyle(
                    color: _selectedDateOfBirth != null ? null : Colors.grey[600],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Enrollment Year (Optional)
            DropdownButtonFormField<int?>(
              value: _selectedEnrollmentYear,
              decoration: const InputDecoration(
                labelText: 'Enrollment Year (Optional)',
                prefixIcon: Icon(Icons.date_range),
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Select year (optional)'),
                ),
                ...List.generate(10, (index) {
                  final year = DateTime.now().year - index;
                  return DropdownMenuItem<int?>(
                    value: year,
                    child: Text(year.toString()),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedEnrollmentYear = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoseCaptureStep() {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'Pose Capture',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Please follow the instructions to capture your face from different angles',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              // Progress indicator
              LinearProgressIndicator(
                value: _capturedFrames.length / 5, // 5 poses total
                backgroundColor: Colors.grey[300],
              ),
              const SizedBox(height: 8),
              Text(
                '${_capturedFrames.length}/5 poses captured',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        
        // Pose capture interface
        Expanded(
          child: _poseCaptureComplete
              ? _buildPoseCaptureComplete()
              : _buildPoseCaptureInterface(),
        ),
      ],
    );
  }

  Widget _buildPoseCaptureInterface() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Camera preview area with proper 3:4 aspect ratio (portrait camera)
          AspectRatio(
            aspectRatio: 3 / 4, // Standard front-facing camera aspect ratio
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _isCameraActive ? _buildInlineCamera() : _buildCameraPlaceholder(),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Current pose instruction (flexible container)
          Flexible(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Current Pose: ${_getCurrentPoseInstruction()}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _getCurrentPoseDescription(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Capture button (compact)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _launchPoseCapture,
              icon: Icon(_isCameraActive ? Icons.close : Icons.camera_alt),
              label: Text(_isCameraActive 
                ? 'Close Camera'
                : _capturedFrames.length < 5 
                  ? 'Open Camera for Pose Capture'
                  : 'All Poses Captured - Tap to Reopen Camera'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: _isCameraActive 
                  ? Colors.red
                  : _capturedFrames.length < 5 
                    ? Theme.of(context).primaryColor
                    : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoseCaptureComplete() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            size: 64,
            color: Colors.green,
          ),
          SizedBox(height: 16),
          Text(
            'Pose Capture Complete!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'All poses have been successfully captured',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteStep() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            size: 64,
            color: Colors.green,
          ),
          SizedBox(height: 16),
          Text(
            'Registration Complete',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Student has been successfully registered',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPlaceholder() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt,
            size: 64,
            color: Colors.white54,
          ),
          SizedBox(height: 16),
          Text(
            'Camera Preview',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 18,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Live pose detection will appear here',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineCamera() {
    if (!_isCameraActive || _cameraSessionId == null) {
      return _buildCameraPlaceholder();
    }

    return GuidedPoseCapture(
      sessionId: _cameraSessionId!,
      embedded: true,
      onFrameCaptured: (frame) {
            if (mounted) {
              setState(() {
                _capturedFrames.add(frame);
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Captured pose ${_capturedFrames.length}!'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 1),
                ),
              );
            }
          },
        onComplete: () {
          if (mounted) {
            setState(() {
              _poseCaptureComplete = true;
              _isCameraActive = false;
              _cameraSessionId = null;
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🎉 All poses captured successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isCameraActive = false;
              _cameraSessionId = null;
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Camera error: $error'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
    );
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

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleNextStep() {
    if (_currentStep == 0) {
      // Validate student info form (date of birth is now optional)
      if (_formKey.currentState!.validate()) {
        _goToNextStep();
      }
    } else if (_currentStep == 1) {
      // Handle pose capture completion
      if (_poseCaptureComplete) {
        _goToNextStep();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please complete all pose captures before proceeding'),
          ),
        );
      }
    } else if (_currentStep == 2) {
      // Complete registration
      _completeRegistration();
    }
  }

  void _goToNextStep() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeRegistration() {
    // TODO: Implement registration completion
    context.go('/dashboard');
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      // Use auth provider to logout
      final authController = ref.read(authControllerProvider.notifier);
      await authController.logout();
      
      // Navigate back to login
      if (mounted) {
        context.go('/login');
      }
    }
  }
}