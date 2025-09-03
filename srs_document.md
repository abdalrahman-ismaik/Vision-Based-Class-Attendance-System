# Software Requirements Specification (SRS)
## Vision-based Class Attendance System

### Document Information
- **Project**: Vision-based Class Attendance System
- **Course**: COSC3030 - Introduction to Artificial Intelligence
- **Version**: 1.0
- **Date**: September 2025

---

## 1. Introduction

### 1.1 Purpose
This document specifies the requirements for an automated class attendance system that leverages computer vision and deep learning techniques to identify and track student attendance using existing CCTV infrastructure.

### 1.2 Scope
The system will provide:
- Automated face detection and recognition
- Student enrollment via mobile application
- Real-time attendance tracking
- Integration with existing classroom CCTV cameras
- Performance analytics and reporting

### 1.3 Definitions and Acronyms
- **CCTV**: Closed-Circuit Television
- **FaceNet**: Deep neural network for face recognition
- **SRS**: Software Requirements Specification
- **API**: Application Programming Interface
- **GUI**: Graphical User Interface

---

## 2. System Overview

### 2.1 System Description
The Vision-based Class Attendance System is an AI-powered solution that automates attendance tracking by analyzing video feeds from classroom cameras. The system uses deep learning models to detect, extract, and match facial features against a pre-enrolled student database.

### 2.2 System Architecture
- **Mobile Enrollment App**: Student registration interface
- **Core Recognition Engine**: FaceNet-based face recognition system
- **Database Server**: Student gallery and attendance records
- **Web Dashboard**: Attendance monitoring and management
- **CCTV Integration Module**: Camera feed processing

---

## 3. Functional Requirements

### 3.1 Face Detection and Recognition (FR-01)
- **FR-01.1**: System shall detect human faces in video streams with minimum 95% accuracy
- **FR-01.2**: System shall extract 128-dimensional face embeddings using FaceNet architecture
- **FR-01.3**: System shall compare face signatures using cosine distance metric
- **FR-01.4**: System shall classify faces as "enrolled" or "unknown" based on similarity threshold

### 3.2 Student Enrollment (FR-02)
- **FR-02.1**: Mobile app shall capture student photos using device camera
- **FR-02.2**: System shall require student ID input during enrollment
- **FR-02.3**: System shall crop and preprocess face images automatically
- **FR-02.4**: System shall store face embeddings and metadata in secure database
- **FR-02.5**: System shall prevent duplicate enrollments for same student ID

### 3.3 Attendance Tracking (FR-03)
- **FR-03.1**: System shall process live CCTV feeds in real-time
- **FR-03.2**: System shall log attendance timestamps for recognized students
- **FR-03.3**: System shall handle multiple face detections in single frame
- **FR-03.4**: System shall maintain attendance records with date/time stamps

### 3.4 System Validation (FR-04)
- **FR-04.1**: System shall correctly identify enrolled students in test scenarios
- **FR-04.2**: System shall label unrecognized individuals as "unknown"
- **FR-04.3**: System shall maintain performance across varying conditions:
  - Different distances from camera (1-5 meters)
  - Various lighting conditions (indoor/outdoor, natural/artificial)
  - Multiple face poses (frontal, profile, tilted)

### 3.5 Reporting and Analytics (FR-05)
- **FR-05.1**: System shall generate attendance reports by date/class
- **FR-05.2**: System shall calculate attendance statistics (present/absent rates)
- **FR-05.3**: System shall export attendance data in CSV/PDF formats
- **FR-05.4**: System shall provide real-time attendance dashboard

---

## 4. Non-Functional Requirements

### 4.1 Performance Requirements (NFR-01)
- **NFR-01.1**: Face detection processing time ≤ 100ms per frame
- **NFR-01.2**: Face recognition accuracy ≥ 95% under standard conditions
- **NFR-01.3**: System shall process up to 30 FPS video streams
- **NFR-01.4**: Database query response time ≤ 200ms

### 4.2 Scalability Requirements (NFR-02)
- **NFR-02.1**: System shall support up to 500 enrolled students per class
- **NFR-02.2**: System shall handle up to 10 concurrent CCTV streams
- **NFR-02.3**: Database shall store attendance records for minimum 2 years

### 4.3 Reliability Requirements (NFR-03)
- **NFR-03.1**: System uptime ≥ 99% during class hours
- **NFR-03.2**: False positive rate ≤ 5%
- **NFR-03.3**: False negative rate ≤ 10%

### 4.4 Security Requirements (NFR-04)
- **NFR-04.1**: All student data shall be encrypted at rest and in transit
- **NFR-04.2**: System shall implement user authentication and authorization
- **NFR-04.3**: Face images shall be stored securely with access controls

### 4.5 Usability Requirements (NFR-05)
- **NFR-05.1**: Mobile app enrollment process ≤ 2 minutes per student
- **NFR-05.2**: Web dashboard shall be intuitive with minimal training required
- **NFR-05.3**: System shall provide clear error messages and status indicators

---

## 5. System Constraints

### 5.1 Technical Constraints
- Must use FaceNet architecture for face recognition
- Must integrate with existing CCTV infrastructure
- Must support mobile platforms (iOS/Android) for enrollment
- Must use cosine distance for face similarity comparison

### 5.2 Hardware Requirements
- Server with GPU support for deep learning inference
- Mobile devices with camera capability
- Existing CCTV cameras with network connectivity
- Minimum 1080p video resolution for optimal performance

### 5.3 Software Dependencies
- Python 3.8+ for backend development
- TensorFlow/PyTorch for deep learning models
- OpenCV for computer vision operations
- SQLite/PostgreSQL for database management

---

## 6. Performance Evaluation Metrics

### 6.1 Primary Metrics
- **Accuracy**: Overall correct identification rate
- **Precision**: True positives / (True positives + False positives)
- **Recall**: True positives / (True positives + False negatives)
- **F1-Score**: Harmonic mean of precision and recall

### 6.2 Secondary Metrics
- **Processing Speed**: Frames per second
- **Response Time**: Time from detection to identification
- **Throughput**: Students processed per minute
- **System Availability**: Uptime percentage

---

## 7. Acceptance Criteria

### 7.1 Functional Acceptance
- All functional requirements (FR-01 through FR-05) implemented and tested
- System successfully processes test video containing enrolled and unknown individuals
- Mobile enrollment app successfully registers new students
- Attendance reports generated accurately

### 7.2 Performance Acceptance
- Recognition accuracy ≥ 95% on validation dataset
- System processes real-time video without significant delays
- All non-functional requirements met or exceeded

### 7.3 Integration Acceptance
- Successful integration with CCTV camera system
- Mobile app communicates reliably with server
- Database operations perform within specified time limits