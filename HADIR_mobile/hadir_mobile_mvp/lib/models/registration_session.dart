// Registration session model for MVP
import 'student.dart';

class RegistrationSession {
  final String id;
  final Student student;
  final String videoPath;
  final List<String> selectedFramePaths;
  final DateTime createdAt;
  final String status; // 'recording', 'processing', 'completed', 'failed'

  RegistrationSession({
    required this.id,
    required this.student,
    required this.videoPath,
    List<String>? selectedFramePaths,
    DateTime? createdAt,
    this.status = 'recording',
  }) : selectedFramePaths = selectedFramePaths ?? [],
       createdAt = createdAt ?? DateTime.now();

  // Create a copy with updated fields
  RegistrationSession copyWith({
    String? id,
    Student? student,
    String? videoPath,
    List<String>? selectedFramePaths,
    DateTime? createdAt,
    String? status,
  }) {
    return RegistrationSession(
      id: id ?? this.id,
      student: student ?? this.student,
      videoPath: videoPath ?? this.videoPath,
      selectedFramePaths: selectedFramePaths ?? this.selectedFramePaths,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student': student.toJson(),
      'videoPath': videoPath,
      'selectedFramePaths': selectedFramePaths,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }

  factory RegistrationSession.fromJson(Map<String, dynamic> json) {
    return RegistrationSession(
      id: json['id'] as String,
      student: Student.fromJson(json['student'] as Map<String, dynamic>),
      videoPath: json['videoPath'] as String,
      selectedFramePaths: List<String>.from(json['selectedFramePaths'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: json['status'] as String,
    );
  }

  // Database serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': student.id,
      'video_path': videoPath,
      'selected_frames': selectedFramePaths.join(','),
      'created_at': createdAt.millisecondsSinceEpoch,
      'status': status,
    };
  }

  factory RegistrationSession.fromMap(Map<String, dynamic> map, Student student) {
    final framesString = map['selected_frames'] as String? ?? '';
    final framesList = framesString.isEmpty ? <String>[] : framesString.split(',');
    
    return RegistrationSession(
      id: map['id'] as String,
      student: student,
      videoPath: map['video_path'] as String,
      selectedFramePaths: framesList,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      status: map['status'] as String,
    );
  }

  @override
  String toString() {
    return 'RegistrationSession(id: $id, student: ${student.name}, status: $status)';
  }
}