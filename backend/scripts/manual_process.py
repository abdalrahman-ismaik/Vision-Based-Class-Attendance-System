#!/usr/bin/env python3
"""
Quick test script to manually process a student's face
"""

import requests
import sys

BASE_URL = "http://localhost:5000/api"

def process_student(student_id):
    """Manually trigger face processing for a student"""
    print(f"Processing student: {student_id}")
    
    response = requests.post(f"{BASE_URL}/students/{student_id}/process")
    
    print(f"Status: {response.status_code}")
    print(f"Response: {response.json()}")
    
    return response.json()

if __name__ == "__main__":
    if len(sys.argv) > 1:
        student_id = sys.argv[1]
    else:
        student_id = "100064000"  # Default
    
    result = process_student(student_id)
