#!/usr/bin/env python3
"""
Script to clean up remaining ML Kit references in guided_pose_capture.dart
"""

import re

filepath = r"d:\Education\University\Fall 2025\COSC 330 - Intro to Artificial Intelligence\Project\HADIR\HADIR\hadir_mobile_full\lib\features\registration\presentation\widgets\guided_pose_capture.dart"

with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace _isPoseValid checks with true (always enabled in manual mode)
# In capture button: _isPoseValid ? ... : ... becomes just the true branch
content = re.sub(r'_isCameraReady && !_isCapturing && _isPoseValid', '_isCameraReady && !_isCapturing', content)
content = re.sub(r'_isPoseValid \? _captureFrame : null', '_captureFrame', content)

# Replace color checks: _isPoseValid ? Colors.green : Colors.orange -> Colors.green
content = re.sub(r'_isPoseValid \? Colors\.green : Colors\.orange', 'Colors.green', content)
content = re.sub(r'_isPoseValid \? Colors\.green : Colors\.grey', 'Colors.green', content)
content = re.sub(r'_isPoseValid \? Colors\.white : Colors\.grey\[400\]', 'Colors.white', content)

# Replace icon checks
content = re.sub(r'_isPoseValid \? Icons\.check : Icons\.face', 'Icons.face', content)
content = re.sub(r'_isPoseValid \? Icons\.check_circle : Icons\.face', 'Icons.check_circle', content)

# Replace text checks
content = re.sub(r'_isPoseValid \? \'Valid\' : \'Position\'', '\'Ready\'', content)

# Replace conditional scaling
content = re.sub(r'scale: _isPoseValid \? _pulseAnimation\.value : 1\.0', 'scale: _pulseAnimation.value', content)

# Replace color with isCapturing check
content = re.sub(r'color: _isCapturing \? Colors\.blue : _isPoseValid \? Colors\.green : Colors\.grey\[700\]!', 'color: _isCapturing ? Colors.blue : Colors.green', content)

# Replace onPressed with isCapturing check for multiple buttons
content = re.sub(r'onPressed: _isCameraReady && !_isCapturing && _isPoseValid\n\s+\? _captureFrame\n\s+: null', 'onPressed: _isCameraReady && !_isCapturing\n                              ? _captureFrame\n                              : null', content)

# Replace backgroundColor with isCapturing checks
content = re.sub(r'backgroundColor: _isCapturing\n\s+\? Colors\.red\n\s+: _isPoseValid\s*\n\s+\? Colors\.green\n\s+: Colors\.grey', 'backgroundColor: _isCapturing\n                              ? Colors.red\n                              : Colors.green', content)

# Replace child icon with isCapturing checks  
content = re.sub(r'child: Icon\(\n\s+_isCapturing \? Icons\.stop : Icons\.camera_alt,\n\s+color: _isCapturing\s*\n\s+\? Colors\.white\s*\n\s+: _isPoseValid\n\s+\? Colors\.white\n\s+: Colors\.grey\[300\]', 'child: Icon(\n                            _isCapturing ? Icons.stop : Icons.camera_alt,\n                            color: Colors.white', content)

# Remove _faceDetector references
content = re.sub(r'_faceDetector\.close\(\)\.catchError\(\(e\) \{[^}]+\}\);', '// Face detector closed (removed in manual mode)', content)

# Remove _isProcessingFrame, _autoCaptureTimer, _poseValidStartTime, _holdDuration references
content = re.sub(r'_isProcessingFrame = false;', '// Processing frame flag removed', content)
content = re.sub(r'_autoCaptureTimer\?\.cancel\(\);', '// Auto-capture timer removed', content)

# Remove validation progress indicators and timers conditionals
# Remove entire _buildPoseValidationIndicator method calls and conditionals with _poseValidStartTime
lines = content.split('\n')
filtered_lines = []
skip_until_brace = 0

for i, line in enumerate(lines):
    # Skip lines with _poseValidStartTime, _holdDuration, _isPoseValid checks
    if '_poseValidStartTime' in line or '_holdDuration' in line:
        # Check if this is part of a conditional block
        if 'if (' in line:
            # Count braces to skip the entire block
            skip_until_brace = 1
            continue
    
    if skip_until_brace > 0:
        # Count braces
        skip_until_brace += line.count('{') - line.count('}')
        if skip_until_brace <= 0:
            skip_until_brace = 0
        continue
    
    # Skip lines with remaining _isPoseValid checks that weren't caught by regex
    if '_isPoseValid' in line and '?' in line:
        continue
    
    # Skip _calculateFaceSize and _calculateQualityScore references
    if '_calculateFaceSize' in line or '_calculateQualityScore' in line:
        continue
    
    # Skip _detectedFaces references
    if '_detectedFaces' in line:
        continue
    
    # Skip _sensorOrientation references
    if '_sensorOrientation' in line:
        continue
    
    # Skip boundingBox without face. references
    if 'boundingBox.' in line and 'face.boundingBox' not in line and 'BoundingBox(' not in line:
        continue
    
    # Skip return 0.0 orphaned line
    if line.strip() == 'if (cameraSize == null) return 0.0;':
        continue
    if line.strip().startswith('final faceArea = boundingBox'):
        continue
    if line.strip().startswith('final frameArea = cameraSize'):
        continue
    if line.strip() == 'return faceArea / frameArea;':
        continue
    
    filtered_lines.append(line)

content = '\n'.join(filtered_lines)

# Write back
with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)

print("Cleaned up ML Kit references successfully!")
