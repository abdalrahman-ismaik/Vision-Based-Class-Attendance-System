# Vision-Based Class Attendance System

[![Python](https://img.shields.io/badge/Python-3.8+-blue.svg)](https://www.python.org/)
[![Flutter](https://img.shields.io/badge/Flutter-3.16+-blue.svg)](https://flutter.dev/)
[![Flask](https://img.shields.io/badge/Flask-3.0.0-green.svg)](https://flask.palletsprojects.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Course](https://img.shields.io/badge/Course-COSC330-orange.svg)](#)

![alt text](docs/bf017508-c5a2-4a1d-847e-357673aae70d.jpeg)

An automated class attendance system leveraging existing CCTV cameras and facial recognition technology. This project utilizes deep learning-based face detection and recognition to streamline the attendance-taking process, developed for the Introduction to Artificial Intelligence (COSC3030) course.

---

## 📋 Table of Contents

- [Project Overview](#-project-overview)
- [Key Features](#-key-features)
- [System Architecture](#-system-architecture)
- [Technology Stack](#-technology-stack)
- [Installation](#-installation)
- [Usage](#-usage)
- [Project Structure](#-project-structure)
- [Research Components](#-research-components)
- [Performance Evaluation](#-performance-evaluation)
- [Documentation](#-documentation)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🎯 Project Overview

This project aims to automate classroom attendance tracking by utilizing existing surveillance infrastructure. The system employs a **FaceNet-based face recognition pipeline** to detect, extract, and match student faces against an enrolled gallery.

### Course Requirements

**Course**: Introduction to Artificial Intelligence (COSC3030)  
**Project**: Vision-based Class Attendance

**Objectives**:
- Design an automated class attendance system using existing CCTV cameras
- Streamline attendance-taking process leveraging surveillance infrastructure
- Implement authentication-like face recognition system

**Deliverables**:
1. ✅ Full comprehensive report
2. ✅ Complete source code
3. ✅ System demonstration

---

## ✨ Key Features

### 🔐 Student Enrollment
- **Mobile-based Registration**: Capture student faces via mobile application
- **Video-based Capture**: Record 8-12 second video with guided head rotation
- **Multi-pose Collection**: Extract 15-25 high-quality frames with diverse poses
- **Real-time Quality Validation**: Live feedback on image quality and pose coverage
- **Secure Database Storage**: Store student ID, name, email, department, and face embeddings

### 🎥 Face Recognition Pipeline
1. **Face Detection**: RetinaFace detector for robust face localization
2. **Embedding Extraction**: MobileFaceNet + ArcFace (512-dimensional embeddings)
3. **Gallery Matching**: Cosine similarity comparison with enrolled students
4. **Quality Filtering**: Blur detection, brightness checks, and confidence margins
5. **Real-time Recognition**: Process CCTV feeds for automated attendance

### 📊 Recognition Improvements
- **Blur Check**: Minimum Laplacian variance = 100
- **Brightness Validation**: Range 30-225 (out of 255)
- **Confidence Threshold**: 70% minimum for recognition
- **Margin Requirement**: 15% difference between top 2 predictions
- **Unknown Handling**: Proper labeling of unregistered individuals

### 🌐 Web Dashboard
- Live video stream with real-time face detection overlay
- Visual indicators (🟢 Green for registered, 🔴 Red for unknown)
- Statistics display and recent detections list
- Fullscreen monitoring mode

### 📱 Mobile Application (HADIR)
- **YOLOv7-Pose Integration**: 5-pose facial capture system
- **Role-based Access**: Administrator authentication
- **Student Management**: Complete CRUD operations with search/filter
- **Offline Support**: Local SQLite database
- **Clean Architecture**: SOLID principles with Riverpod state management

---

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Vision-Based Attendance System                │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────┐         ┌─────────────────┐         ┌─────────────────┐
│  Mobile App     │ ─────▶  │  Backend API    │ ◀────── │   Web Dashboard │
│  (Enrollment)   │         │  (Flask REST)   │         │  (Live Monitor) │
└─────────────────┘         └─────────────────┘         └─────────────────┘
       │                             │                            │
       │                             ▼                            │
       │                    ┌─────────────────┐                  │
       │                    │  Face Processing │                  │
       │                    │     Pipeline     │                  │
       │                    └─────────────────┘                  │
       │                             │                            │
       │                             ▼                            │
       │                    ┌─────────────────┐                  │
       └──────────────────▶ │   Face Database │ ◀────────────────┘
                            │ (Embeddings +   │
                            │  Metadata)      │
                            └─────────────────┘
                                     │
                                     ▼
                            ┌─────────────────┐
                            │  FaceNet Model  │
                            │ (MobileFaceNet  │
                            │   + ArcFace)    │
                            └─────────────────┘
```

### General Pipeline

1. **Face Detection**: System detects faces using RetinaFace
2. **Signature Extraction**: Extract 512-dim face embeddings using MobileFaceNet
3. **Gallery Comparison**: Compare signatures with enrolled students using cosine distance
4. **Classification**: Assign student ID or "unknown" label based on similarity threshold

---

## 🛠️ Technology Stack

### Backend
- **Framework**: Flask 3.0.0 + Flask-RESTX (Swagger API)
- **Face Detection**: RetinaFace (retina-face >= 0.0.16)
- **Face Recognition**: MobileFaceNet + ArcFace (PyTorch)
- **Deep Learning**: PyTorch 2.0+, TensorFlow 2.16+
- **Image Processing**: OpenCV, Pillow
- **ML Tools**: scikit-learn, NumPy

### Mobile Application
- **Framework**: Flutter 3.16+
- **State Management**: Riverpod
- **Database**: SQLite with comprehensive indexing
- **Computer Vision**: YOLOv7-Pose for pose detection
- **Architecture**: Clean Architecture with SOLID principles

### Web Dashboard
- **Framework**: Flask + MJPEG streaming
- **Frontend**: HTML5, CSS3, JavaScript
- **Face Detection**: YuNet (OpenCV)
- **Real-time Processing**: OpenCV VideoCapture

### FaceNet Model
- **Architecture**: MobileFaceNet
- **Loss Function**: ArcFace (s=32.0, m=0.4)
- **Embedding Size**: 512 dimensions
- **Pre-trained Checkpoint**: `best_model_epoch43_acc100.00.pth` (100% training accuracy)
- **Source**: [CVML-KU-Research/FaceNet](https://github.com/CVML-KU-Research/FaceNet)

---

## 📦 Installation

### Prerequisites

- **Python**: 3.8 or higher
- **Flutter SDK**: 3.16 or higher (for mobile app)
- **CUDA**: Optional, for GPU acceleration
- **Camera**: Webcam or CCTV camera for validation
- **Git**: For version control

### 1. Clone Repository

```bash
git clone https://github.com/abdalrahman-ismaik/Vision-Based-Class-Attendance-System.git
cd Vision-Based-Class-Attendance-System
```

### 2. Backend Setup

```bash
# Navigate to backend directory
cd backend

# Create virtual environment (recommended)
python -m venv .venv311
source .venv311/bin/activate  # On Windows: .venv311\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Verify FaceNet model checkpoint exists
ls ../FaceNet/mobilefacenet_arcface/best_model_epoch43_acc100.00.pth
```

### 3. Configure Environment

```bash
# Copy example environment file
cp .env.example .env

# Edit .env with your configuration
# Set database paths, API keys, etc.
```

### 4. Mobile App Setup (Optional)

```bash
cd HADIR_mobile/hadir_mobile_full

# Install Flutter dependencies
flutter pub get

# Run the app
flutter run
```

### 5. Web Dashboard Setup (Optional)

```bash
cd HADIR_web

# Install dependencies
pip install -r requirements.txt

# Download YuNet face detection model
# Place face_detection_yunet_2023mar.onnx in HADIR_web/ directory
```

---

## 🚀 Usage

### Starting the Backend API

```bash
cd backend
python app.py
```

The server will start at `http://localhost:5000`

**Swagger API Documentation**: `http://localhost:5000/api/docs`

### Enrolling Students

#### Option 1: Using Mobile App
1. Launch HADIR mobile app
2. Navigate to "Register Student"
3. Fill in student details (ID, name, email, department)
4. Capture video with guided head rotation (8-12 seconds)
5. System extracts 15-25 optimal frames
6. Submit registration

#### Option 2: Using API Directly

```bash
curl -X POST http://localhost:5000/api/students/ \
  -F "student_id=202312345" \
  -F "name=John Doe" \
  -F "email=john.doe@university.edu" \
  -F "department=Computer Science" \
  -F "image=@path/to/photo.jpg"
```

### Running Live Attendance Monitoring

```bash
cd HADIR_web
python app.py
```

Open browser: `http://localhost:5001`

The system will:
- Display live camera feed
- Detect faces in real-time
- Match against enrolled students
- Show green boxes (registered) or red boxes (unknown)
- Display student name and ID for recognized faces

### System Validation

Test the system with:
1. **Known Students**: Should recognize with >70% confidence
2. **Unknown Individuals**: Should label as "unknown"
3. **Varying Conditions**: Test different distances, lighting, and poses
4. **Multiple Faces**: Process multiple individuals simultaneously

---

## 📁 Project Structure

```
Vision-Based-Class-Attendance-System/
│
├── backend/                    # Flask REST API backend
│   ├── app.py                 # Main Flask application
│   ├── face_processing_pipeline.py  # Core face recognition logic
│   ├── requirements.txt       # Python dependencies
│   ├── api/                   # API endpoints (students, attendance, etc.)
│   ├── services/              # Business logic services
│   ├── database/              # Database management
│   ├── models/                # Pre-trained model files
│   ├── storage/               # Uploaded images and processed faces
│   └── docs/                  # Backend documentation
│
├── FaceNet/                   # Official FaceNet implementation
│   ├── networks/              # Neural network architectures
│   ├── utils/                 # Utilities (RetinaFace adapter, etc.)
│   └── mobilefacenet_arcface/ # Pre-trained checkpoint (512-dim embeddings)
│
├── HADIR_mobile/              # Flutter mobile application
│   ├── hadir_mobile_full/     # Main Flutter project
│   │   ├── lib/               # Dart source code
│   │   ├── android/           # Android platform code
│   │   └── ios/               # iOS platform code
│   ├── frame_selection_service/  # YOLOv7-Pose integration
│   └── docs/                  # Mobile app documentation
│
├── HADIR_web/                 # Web dashboard for live monitoring
│   ├── app.py                 # Flask web server
│   ├── realtime_recognition.py  # Real-time face recognition
│   ├── templates/             # HTML templates
│   └── static/                # CSS, JavaScript assets
│
├── intro to ai demo/          # Demonstration scripts
│   └── attendance_demo/       # Standalone demo application
│
├── playground/                # Experimentation and testing scripts
│   ├── face_detection_embedding.py  # Face detection experiments
│   ├── classifier_comparison_example.py
│   └── docs/                  # Playground documentation
│
├── docs/                      # Project-wide documentation
│   ├── QUICK_REFERENCE.md     # Quick reference guide
│   ├── RECOGNITION_IMPROVEMENTS.md  # Recognition enhancement details
│   └── PROJECT_STATUS_ASSESSMENT.md
│
├── scripts/                   # Utility scripts
│   └── mark_attendance.py     # Manual attendance marking
│
├── project_plan.md            # Development plan and timeline
├── srs_document.md            # Software Requirements Specification
├── system_design.md           # System design document
└── README.md                  # This file
```

---

## 🔬 Research Components

### Face Data Augmentation

The system implements  data augmentation techniques to improve recognition robustness:

- **Systematic Variations**: 
  - Lighting conditions (20% of synthetic data)
  - Pose variations: -30° to +30° yaw, -15° to +15° pitch (40%)
  - Scale variations: 1-2 meter camera distances (40%)
- **Quality Validation**: All generated images pass quality score > 0.8
- **Identity Preservation**: Maintain student identity across variations

### Ensemble Classification Architecture

Novel multi-layer classifier system for superior accuracy:

**Layer 1: Specialized Classifiers**
- Pose-Specific Classifier (frontal faces)
- Lighting-Condition Classifier (low/high light)
- Distance-Based Classifier (near/far detection)
- Quality-Aware Classifier (image quality assessment)

**Layer 2: Meta-Classifier**
- Decision Fusion Network (combines Layer 1 outputs)

### Video-Based Registration Protocol

Innovative continuous video capture system:

1. **Real-time Face Tracking**: Live detection during 8-12 second recording
2. **Live User Guidance**: Provide directional feedback for optimal rotation
3. **Frame Selection**: Extract 15-25 best frames with pose diversity
4. **Quality Assessment**: Real-time quality scoring and validation

---

## 📊 Performance Evaluation

The system is evaluated using standard machine learning metrics:

### Metrics Implemented

- **Accuracy**: Overall correct predictions / total predictions
- **Precision**: True Positives / (True Positives + False Positives)
- **Recall**: True Positives / (True Positives + False Negatives)
- **F1-Score**: Harmonic mean of Precision and Recall
- **Confusion Matrix**: Detailed classification breakdown
- **Recognition Rate**: Percentage of enrolled students correctly identified

### Classifier Performance

The system uses **binary SVM classifiers** (one-vs-all approach) with the following configuration:

**Training Configuration**:
- **Kernel**: Linear (SVM with linear kernel)
- **Probability**: Enabled for confidence scores
- **Regularization**: C=1.0
- **Class Weights**: Dynamically adjusted for imbalanced data
- **Train/Test Split**: 80/20 with stratified sampling

**Typical Performance Metrics** (per student classifier):

| Metric | Value | Description |
|--------|-------|-------------|
| **Training Accuracy** | 95-100% | Accuracy on training set |
| **Test Accuracy** | 85-95% | Accuracy on held-out test set |
| **Precision** | 85-95% | Proportion of correct positive predictions |
| **Recall** | 80-95% | Proportion of actual positives correctly identified |
| **F1-Score** | 85-95% | Harmonic mean of precision and recall |

**System-wide Metrics**:
- **Average Test Accuracy**: ~90% across all student classifiers
- **Average F1-Score**: ~88% across all student classifiers
- **Recognition Confidence Threshold**: ≥70% for positive identification
- **Confidence Margin**: ≥15% gap between top predictions

**Key Features**:
- ✅ Class imbalance handling with weighted loss
- ✅ Stratified train/test split maintains class distribution
- ✅ Per-student metrics tracking for fine-grained analysis
- ✅ Probability calibration for confidence scores

### Quality Thresholds

| Metric | Threshold | Purpose |
|--------|-----------|---------|
| Blur Detection | Laplacian variance ≥ 100 | Reject blurry images |
| Brightness Range | 30-225 (of 255) | Ensure proper lighting |
| Recognition Confidence | ≥ 70% | Minimum confidence for ID |
| Confidence Margin | ≥ 15% | Gap between top 2 predictions |

### Validation Protocol

**Test Scenarios**:
1. ✅ Multiple individuals (enrolled and unenrolled)
2. ✅ Varying distances from camera (3-8 meters)
3. ✅ Diverse lighting environments
4. ✅ Different face poses and orientations
5. ✅ Mobile screen photos (should be rejected)

**Expected Performance**: >95% recognition accuracy for enrolled students under optimal conditions.

---

## 📚 Documentation

### Backend Documentation
- [Backend README](backend/README.md) - Flask API overview
- [Quick Start Guide](backend/QUICKSTART.md) - Getting started
- [Architecture](backend/ARCHITECTURE.md) - System architecture details
- [Pipeline Documentation](backend/PIPELINE_README.md) - Face processing pipeline

### Mobile App Documentation
- [HADIR Mobile README](HADIR_mobile/README.md) - Mobile app overview
- [Project Structure](HADIR_mobile/PROJECT_STRUCTURE.md) - Code organization
- [Design System](HADIR_mobile/DESIGN_SYSTEM.md) - UI/UX guidelines

### Web Dashboard Documentation
- [Web Dashboard README](HADIR_web/README.md) - Live monitoring setup
- [Testing Guide](HADIR_web/TESTING_GUIDE.md) - Testing procedures

### FaceNet Documentation
- [FaceNet README](FaceNet/README.md) - Model architecture and integration

### Research Documentation
- [Recognition Improvements](docs/RECOGNITION_IMPROVEMENTS.md) - Enhancement details
- [Quick Reference](docs/QUICK_REFERENCE.md) - System behavior reference
- [Project Status](docs/PROJECT_STATUS_ASSESSMENT.md) - Current status

### Planning Documents
- [Project Plan](project_plan.md) - Development timeline (10 weeks)
- [SRS Document](srs_document.md) - Software requirements specification
- [System Design](system_design.md) - Technical design document

---

## 🎓 Course Context

**Institution**: Khalifa University  
**Course**: COSC3030 - Introduction to Artificial Intelligence
**Instructor**: Dr. Naoufel Werghi
**Project Type**: Vision-based Class Attendance  
**Timeline**: 10 weeks (September 3 - November 12, 2025)

### Academic Contributions

This project demonstrates:
1. **Computer Vision**: Face detection and recognition pipelines
2. **Deep Learning**: Transfer learning with pre-trained models
3. **Mobile Development**: Cross-platform Flutter application
4. **API Design**: RESTful API with Swagger documentation
5. **Research Methodology**: Systematic evaluation and validation

### Report Requirements

The project report includes:
- ✅ Justification of AI techniques used (FaceNet, ArcFace)
- ✅ Description of system architecture and components
- ✅ Implementation details and code structure
- ✅ Experimental validation and performance metrics
- ✅ Comparison with baseline approaches

---

## 🐛 Troubleshooting

### Common Issues

**1. FaceNet Model Not Found**
```bash
# Ensure model checkpoint exists
ls FaceNet/mobilefacenet_arcface/best_model_epoch43_acc100.00.pth
```

**2. Import Errors**
```bash
# Reinstall dependencies
pip install --upgrade -r backend/requirements.txt
```

**3. Camera Access Issues**
- Check camera permissions
- Try different camera index (0, 1, 2)
- Ensure no other application is using the camera

**4. Low Recognition Accuracy**
- Verify image quality (not blurry, proper lighting)
- Re-register students with better quality images
- Check confidence thresholds in configuration

**5. Mobile App Build Errors**
```bash
flutter clean
flutter pub get
flutter run
```

For more details, see:
- [Backend Troubleshooting](backend/docs/QUICKSTART.md#troubleshooting)
- [Mobile Troubleshooting](HADIR_mobile/TROUBLESHOOTING.md)

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🔗 Resources

### Official Repositories
- **FaceNet Implementation**: [CVML-KU-Research/FaceNet](https://github.com/CVML-KU-Research/FaceNet)
- **RetinaFace**: [serengil/retinaface](https://github.com/serengil/retinaface)
- **YuNet Face Detection**: [OpenCV Zoo](https://github.com/opencv/opencv_zoo)

### Research Papers
- **FaceNet**: [Schroff et al., 2015 - FaceNet: A Unified Embedding for Face Recognition and Clustering](https://arxiv.org/abs/1503.03832)
- **ArcFace**: [Deng et al., 2019 - ArcFace: Additive Angular Margin Loss for Deep Face Recognition](https://arxiv.org/abs/1801.07698)
- **MobileFaceNet**: [Chen et al., 2018 - MobileFaceNets: Efficient CNNs for Accurate Real-time Face Verification on Mobile Devices](https://arxiv.org/abs/1804.07573)
- **RetinaFace**: [Deng et al., 2020 - RetinaFace: Single-shot Multi-level Face Localisation in the Wild](https://arxiv.org/abs/1905.00641)

### Useful Links
- [Flask Documentation](https://flask.palletsprojects.com/)
- [Flutter Documentation](https://flutter.dev/docs)
- [PyTorch Documentation](https://pytorch.org/docs/)
- [OpenCV Documentation](https://docs.opencv.org/)

---

## 📧 Contact

**Project Repository**: [Vision-Based-Class-Attendance-System](https://github.com/abdalrahman-ismaik/Vision-Based-Class-Attendance-System)

**Team Members**:
- Abd Alrahman Ismaik - 100064692
- Mohamed Elashmony - 100064807
- Osama Qadan - 100064881
- Hadher Alameemi - 100063102

**Course Instructor**: [Add instructor information]

---

<div align="center">

**Vision-Based Class Attendance System**  
*Automated Attendance Tracking with AI*

[⬆ Back to Top](#vision-based-class-attendance-system)

</div>
