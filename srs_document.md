# Software Requirements Specification (SRS)
## Research-Enhanced Vision-based Class Attendance System with AI Augmentation

### Document Information
- **Project**: Vision-based Class Attendance System with Novel AI Data Augmentation
- **Course**: COSC3030 - Introduction to Artificial Intelligence
- **Version**: 2.0 (Research-Enhanced)
- **Date**: September 2025
- **Research Focus**: AI-driven face augmentation and ensemble classification for superior accuracy

---

## 1. Introduction

### 1.1 Purpose
This document specifies the requirements for a research-oriented automated class attendance system that introduces novel AI-driven face data augmentation and ensemble classification techniques to achieve >95% recognition accuracy while investigating the impact of wired vs wireless camera connections on system performance.

### 1.2 Scope
The research-enhanced system will provide:
- **Novel AI Face Augmentation**: Generate synthetic training data using generative AI models
- **Ensemble Classification Architecture**: Multi-layer classifier system for superior accuracy
- **Video-Based Registration Protocol**: Optimized continuous video capture with real-time face extraction and quality validation protocol
- **Connection Performance Analysis**: Comparative study of wired vs wireless CCTV performance
- **Research-grade Evaluation Framework**: Comprehensive metrics and statistical validation

### 1.3 Research Objectives
- **Primary Goal**: Achieve >95% face recognition accuracy consistently
- **Innovation Focus**: Introduce AI-generated face augmentation for robust training datasets
- **Performance Study**: Quantify improvements from wired camera connections
- **Academic Contribution**: Create reproducible research methodology for attendance systems

### 1.4 Definitions and Acronyms
- **GAN**: Generative Adversarial Network
- **StyleGAN3**: State-of-the-art generative model for face synthesis
- **Ensemble Learning**: Combining multiple classifiers for improved performance
- **Ablation Study**: Systematic evaluation of individual components
- **Meta-classifier**: Higher-level classifier that combines outputs from multiple base classifiers

---

## 2. System Overview

### 2.1 Research-Enhanced System Description
The system is a research platform that advances the state-of-the-art in automated attendance tracking through three main innovations:
1. AI-powered face data augmentation using generative models
2. Novel ensemble classification architecture with specialized sub-classifiers
3. Empirical analysis of connection infrastructure impact on recognition performance

### 2.2 System Architecture
- **Enhanced Mobile App**: Continuous video capture with real-time face extraction and quality validation
- **AI Augmentation Engine**: StyleGAN3-based synthetic data generation
- **Ensemble Recognition Core**: Multi-layer classification with decision fusion
- **Performance Monitoring**: Real-time connection and accuracy metrics
- **Research Analytics Dashboard**: Statistical analysis and comparison tools

---

## 3. Functional Requirements

### 3.1 AI-Powered Face Data Augmentation (FR-01) - NOVEL
- **FR-01.1**: System shall generate minimum 50 synthetic face variations per enrolled student
- **FR-01.2**: Augmentation shall systematically vary lighting conditions (20% of synthetic data)
- **FR-01.3**: Augmentation shall generate pose variations from -30° to +30° yaw, -15° to +15° pitch (40% of synthetic data)
- **FR-01.4**: Augmentation shall create scale variations simulating 3-8 meter camera distances (40% of synthetic data)
- **FR-01.5**: Generated images shall pass quality validation with score >0.8
- **FR-01.6**: System shall maintain metadata linking synthetic images to base captures

### 3.2 Video-Based Registration Protocol (FR-02) - INNOVATIVE ENHANCEMENT
- **FR-02.1**: Mobile app shall record continuous video (8-12 seconds) with user face rotation
- **FR-02.2**: System shall perform real-time face detection and tracking during video recording
- **FR-02.3**: System shall provide real-time guidance for optimal pose coverage:
  - Frontal view (-15° to +15° yaw)
  - Left profile (15° to 60° yaw) 
  - Right profile (-60° to -15° yaw)
  - Up/down tilt variations (±20° pitch)
- **FR-02.4**: System shall extract 15-25 high-quality frames with diverse poses from video
- **FR-02.5**: Frame selection shall prioritize quality score >0.8 and pose diversity
- **FR-02.6**: System shall display real-time coverage percentage and missing pose areas
- **FR-02.7**: Registration shall complete when >80% pose coverage achieved or time limit reached
- **FR-02.8**: System shall automatically trigger AI augmentation using selected video frames

### 3.3 Ensemble Classification System (FR-03) - NOVEL
- **FR-03.1**: System shall implement 4 specialized classifiers:
  - Pose-specific classifier for frontal faces
  - Lighting-condition adaptive classifier
  - Distance/scale-aware classifier  
  - Quality-based classifier for high-resolution images
- **FR-03.2**: Meta-classifier shall fuse decisions from Layer 1 classifiers
- **FR-03.3**: System shall achieve >95% recognition accuracy on validation dataset
- **FR-03.4**: Ensemble shall provide confidence scores for all predictions
- **FR-03.5**: System shall automatically select optimal classifier combination based on image characteristics

### 3.4 Wired Connection Integration (FR-04) - RESEARCH
- **FR-04.1**: System shall support wired Ethernet connections for all 3 CCTV cameras
- **FR-04.2**: System shall monitor connection quality metrics in real-time:
  - Network latency
  - Packet loss percentage
  - Frame drop rate
  - Video quality scores
- **FR-04.3**: System shall log performance data for statistical analysis
- **FR-04.4**: System shall maintain backward compatibility with wireless connections for comparison

### 3.5 Research Evaluation Framework (FR-05) - NOVEL
- **FR-05.1**: System shall implement ablation testing for each component:
  - Baseline vs augmented training data
  - Single classifier vs ensemble approach
  - Wired vs wireless connection performance
- **FR-05.2**: System shall generate statistical significance reports
- **FR-05.3**: System shall create performance comparison visualizations
- **FR-05.4**: System shall export research data in academic-standard formats

### 3.6 Enhanced Attendance Tracking (FR-06)
- **FR-06.1**: System shall process live video feeds with <100ms latency
- **FR-06.2**: System shall handle up to 50 faces simultaneously per frame
- **FR-06.3**: System shall log attendance with 99.9% timestamp accuracy
- **FR-06.4**: System shall distinguish between enrolled students and unknown individuals
- **FR-06.5**: System shall prevent duplicate attendance logging within 30-minute windows

---

## 4. Non-Functional Requirements

### 4.1 Research Performance Requirements (NFR-01)
- **NFR-01.1**: Recognition accuracy ≥ 95% on standardized test dataset
- **NFR-01.2**: False positive rate ≤ 2% (research-grade requirement)
- **NFR-01.3**: False negative rate ≤ 3% (research-grade requirement)
- **NFR-01.4**: AI augmentation generation time ≤ 5 minutes per student
- **NFR-01.5**: Ensemble classification time ≤ 150ms per face

### 4.2 System Scalability (NFR-02)
- **NFR-02.1**: Support up to 1000 enrolled students per deployment
- **NFR-02.2**: Handle 10,000+ synthetic training images per student
- **NFR-02.3**: Process concurrent streams from 3 wired cameras at 30 FPS
- **NFR-02.4**: Maintain performance with 10GB+ training dataset

### 4.3 Research Reliability (NFR-03)
- **NFR-03.1**: System uptime ≥ 99.5% during evaluation periods
- **NFR-03.2**: Reproducible results within ±1% accuracy variance
- **NFR-03.3**: Consistent performance across different lighting conditions
- **NFR-03.4**: Statistical significance (p < 0.05) for claimed improvements

### 4.4 Data Quality Assurance (NFR-04)
- **NFR-04.1**: Synthetic image quality score ≥ 0.8 on LPIPS metric
- **NFR-04.2**: Generated faces shall maintain identity consistency
- **NFR-04.3**: Training dataset balance: 30% original, 70% synthetic images
- **NFR-04.4**: Metadata completeness for all generated samples

### 4.5 Research Ethics and Security (NFR-05)
- **NFR-05.1**: Synthetic data generation shall not create privacy risks
- **NFR-05.2**: All biometric data encrypted with AES-256
- **NFR-05.3**: Research data shall be anonymizable for academic sharing
- **NFR-05.4**: System shall comply with university ethical guidelines

---

## 5. Research Constraints and Assumptions

### 5.1 Technical Research Constraints
- Must use StyleGAN2 or equivalent generative model for face augmentation
- Ensemble must contain minimum 4 specialized classifiers
- Must maintain comparison capability with baseline FaceNet
- Wired connection testing requires physical infrastructure modification

### 5.2 Dataset Requirements
- Minimum 100 enrolled students for statistical validity
- Balanced demographic representation in test subjects
- Controlled lighting conditions for baseline measurements
- Ground truth validation for accuracy calculations

### 5.3 Experimental Assumptions
- University provides stable wired network infrastructure
- Students consent to synthetic data generation for research
- Consistent camera positioning throughout evaluation period
- Minimal environmental changes during testing phases

---

## 6. Research Evaluation Metrics

### 6.1 Primary Research Metrics
- **Accuracy**: Overall correct identification rate (target ≥ 95%)
- **Precision**: True positives / (True positives + False positives) (target ≥ 96%)
- **Recall**: True positives / (True positives + False negatives) (target ≥ 94%)
- **F1-Score**: Harmonic mean of precision and recall (target ≥ 95%)

### 6.2 Novel Contribution Metrics
- **Augmentation Benefit**: Accuracy improvement from synthetic data
- **Ensemble Gain**: Performance boost from multi-classifier approach
- **Connection Impact**: Accuracy difference between wired vs wireless
- **Robustness Score**: Performance consistency across conditions

### 6.3 Research Quality Metrics
- **Statistical Significance**: p-values for all claimed improvements
- **Effect Size**: Cohen's d for practical significance
- **Cross-validation Score**: k-fold validation results
- **Generalization Ability**: Performance on unseen test subjects

---

## 7. Research Deliverables and Acceptance Criteria

### 7.1 Technical Deliverables
- **AI Augmentation Pipeline**: Functional system generating high-quality synthetic faces
- **Ensemble Classifier**: Multi-layer system achieving >95% accuracy
- **Wired Integration**: Physical connection setup with performance monitoring
- **Evaluation Suite**: Comprehensive testing and statistical analysis tools

### 7.2 Research Documentation
- **Technical Report**: Detailed methodology and results analysis
- **Research Paper Draft**: Academic-quality manuscript suitable for conference submission
- **Open Source Code**: Clean, documented implementation for reproducibility
- **Dataset Documentation**: Comprehensive metadata and usage guidelines

### 7.3 Performance Benchmarks
- **Baseline Comparison**: Minimum 3% improvement over standard FaceNet
- **Consistency**: <2% accuracy variance across multiple runs
- **Scalability**: Demonstrated performance with 500+ student database
- **Real-world Validation**: Successful deployment in actual classroom environment

### 7.4 Research Impact Goals
- **Academic Contribution**: Novel methodology suitable for peer review
- **Practical Application**: Deployable system for university use
- **Open Science**: Reproducible research with shared resources
- **Technology Transfer**: Framework applicable to other biometric applications

---

## 8. Success Criteria

### 8.1 Technical Success
- Recognition accuracy consistently ≥ 95% in controlled tests
- AI augmentation generates visually realistic and identity-consistent faces
- Ensemble system outperforms individual classifiers by ≥2%
- Wired connection demonstrates measurable performance improvements

### 8.2 Research Success
- Statistical significance (p < 0.05) for all claimed improvements
- Reproducible results across multiple evaluation runs
- Comprehensive documentation enabling replication
- Contribution to academic knowledge in biometric systems

### 8.3 Academic Success
- High-quality technical report demonstrating research rigor
- Implementation suitable for open-source academic community
- Methodology applicable to broader face recognition problems
- Potential for conference publication or journal submission

This research-enhanced SRS positions your project as a significant academic contribution while maintaining practical utility for real-world attendance tracking applications.
