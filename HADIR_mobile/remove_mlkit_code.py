#!/usr/bin/env python3
"""
Script to remove ML Kit code from guided_pose_capture.dart
This removes specific line ranges to simplify the file.
"""

import re

# Read the file
filepath = r"d:\Education\University\Fall 2025\COSC 330 - Intro to Artificial Intelligence\Project\HADIR\HADIR\hadir_mobile_full\lib\features\registration\presentation\widgets\guided_pose_capture.dart"

with open(filepath, 'r', encoding='utf-8') as f:
    lines = f.readlines()

print(f"Original file: {len(lines)} lines")

# Remove specific line ranges (0-indexed, so subtract 1 from line numbers)
# Ranges to remove:
# 1. _processCameraImage method (lines 168-395)
# 2. _convertCameraImage method (lines 396-522)
# 3. _validateCurrentPose method (lines 524-655)
# 4. _calculateQualityScore method (lines 656-705)
# 5. _buildFaceOverlay method (lines 1395-1415)
# 6. MLKitFaceOverlayPainter class (lines 1451-end of class ~1575)

ranges_to_remove = [
    (167, 522),  # _processCameraImage and _convertCameraImage (lines 168-523)
    (523, 655),  # _validateCurrentPose (lines 524-656)
    (655, 705),  # _calculateQualityScore (lines 656-706)
    (1394, 1415),  # _buildFaceOverlay (lines 1395-1416)
    (1450, 1576),  # MLKitFaceOverlayPainter class (lines 1451-1577)
]

# Sort ranges in reverse to remove from bottom to top
ranges_to_remove.sort(reverse=True)

# Remove lines
for start, end in ranges_to_remove:
    print(f"Removing lines {start+1} to {end}")
    del lines[start:end]

print(f"After removal: {len(lines)} lines")

# Write back
with open(filepath, 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("File updated successfully!")
print(f"Removed approximately {1576 - len(lines)} lines")
