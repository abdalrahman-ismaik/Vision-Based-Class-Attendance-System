"""
Diversity Scorer Service
Uses scikit-learn clustering to score frame diversity and select representative frames
"""

import numpy as np
from sklearn.cluster import KMeans, DBSCAN
from sklearn.preprocessing import StandardScaler
from sklearn.decomposition import PCA
from typing import List, Tuple, Dict, Any
import logging
import cv2

logger = logging.getLogger(__name__)

class DiversityScorer:
    """Score frame diversity using clustering and feature analysis"""
    
    def __init__(self, clustering_method: str = 'kmeans'):
        """
        Initialize diversity scorer
        
        Args:
            clustering_method: 'kmeans' or 'dbscan'
        """
        self.clustering_method = clustering_method
        self.scaler = StandardScaler()
        self.pca = PCA(n_components=0.95)  # Keep 95% of variance
    
    def calculate_diversity_scores(self, frames_data: List[Tuple], 
                                 n_clusters: int = 8) -> List[Tuple]:
        """
        Calculate diversity scores for frames using clustering
        
        Args:
            frames_data: List of (frame, timestamp, quality_data, pose_data) tuples
            n_clusters: Number of clusters for diversity analysis
            
        Returns:
            List of frames with diversity scores added
        """
        if len(frames_data) < 2:
            logger.warning("Not enough frames for diversity analysis")
            return [(frame, timestamp, quality, pose, {'diversity_score': 1.0, 'cluster': 0}) 
                   for frame, timestamp, quality, pose in frames_data]
        
        try:
            # Extract features for clustering
            features = self._extract_features(frames_data)
            
            # Normalize features
            features_scaled = self.scaler.fit_transform(features)
            
            # Apply PCA for dimensionality reduction
            if features_scaled.shape[1] > 10:
                features_pca = self.pca.fit_transform(features_scaled)
            else:
                features_pca = features_scaled
            
            # Perform clustering
            cluster_labels = self._perform_clustering(features_pca, n_clusters)
            
            # Calculate diversity scores
            diversity_scores = self._calculate_cluster_diversity_scores(
                features_pca, cluster_labels
            )
            
            # Add diversity data to frames
            frames_with_diversity = []
            for i, (frame, timestamp, quality, pose) in enumerate(frames_data):
                diversity_data = {
                    'diversity_score': diversity_scores[i],
                    'cluster': cluster_labels[i],
                    'features': features[i].tolist()
                }
                frames_with_diversity.append((frame, timestamp, quality, pose, diversity_data))
            
            logger.info(f"Calculated diversity scores for {len(frames_data)} frames "
                       f"using {len(set(cluster_labels))} clusters")
            
            return frames_with_diversity
            
        except Exception as e:
            logger.error(f"Error calculating diversity scores: {str(e)}")
            # Return frames with default diversity scores
            return [(frame, timestamp, quality, pose, {'diversity_score': 0.5, 'cluster': 0}) 
                   for frame, timestamp, quality, pose in frames_data]
    
    def _extract_features(self, frames_data: List[Tuple]) -> np.ndarray:
        """Extract visual and pose features for clustering"""
        features = []
        
        for frame, timestamp, quality_data, pose_data in frames_data:
            frame_features = []
            
            # Visual quality features
            quality_features = [
                quality_data.get('sharpness', 0) / 1000,  # Normalize
                quality_data.get('brightness', 0) / 255,
                quality_data.get('contrast', 0) / 100,
                quality_data.get('blur_score', 0) / 100
            ]
            frame_features.extend(quality_features)
            
            # Pose features
            head_pose = pose_data.get('head_pose', {})
            pose_features = [
                head_pose.get('yaw', 0) / 90,    # Normalize to [-1, 1]
                head_pose.get('pitch', 0) / 45,  # Normalize to [-1, 1]
                head_pose.get('roll', 0) / 45    # Normalize to [-1, 1]
            ]
            frame_features.extend(pose_features)
            
            # Color histogram features (simplified)
            color_features = self._extract_color_features(frame)
            frame_features.extend(color_features)
            
            # Timestamp feature (normalized)
            frame_features.append(timestamp / 30.0)  # Assuming max 30 seconds
            
            features.append(frame_features)
        
        return np.array(features)
    
    def _extract_color_features(self, frame: np.ndarray) -> List[float]:
        """Extract simplified color histogram features"""
        try:
            # Convert to HSV for better color representation
            hsv = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)
            
            # Calculate histogram for each channel (simplified)
            h_hist = cv2.calcHist([hsv], [0], None, [8], [0, 180])
            s_hist = cv2.calcHist([hsv], [1], None, [8], [0, 256])
            v_hist = cv2.calcHist([hsv], [2], None, [8], [0, 256])
            
            # Normalize histograms
            h_hist = h_hist.flatten() / h_hist.sum()
            s_hist = s_hist.flatten() / s_hist.sum()
            v_hist = v_hist.flatten() / v_hist.sum()
            
            # Return top few bins to keep feature count manageable
            color_features = []
            color_features.extend(h_hist[:4].tolist())
            color_features.extend(s_hist[:4].tolist())
            color_features.extend(v_hist[:4].tolist())
            
            return color_features
            
        except Exception as e:
            logger.warning(f"Error extracting color features: {str(e)}")
            return [0.0] * 12  # Return default features
    
    def _perform_clustering(self, features: np.ndarray, n_clusters: int) -> np.ndarray:
        """Perform clustering based on selected method"""
        if self.clustering_method == 'kmeans':
            # Adjust n_clusters if we have fewer samples
            n_clusters = min(n_clusters, len(features))
            clusterer = KMeans(n_clusters=n_clusters, random_state=42, n_init=10)
            cluster_labels = clusterer.fit_predict(features)
            
        elif self.clustering_method == 'dbscan':
            clusterer = DBSCAN(eps=0.5, min_samples=2)
            cluster_labels = clusterer.fit_predict(features)
            
            # Handle noise points (label -1) by assigning them to separate clusters
            max_label = max(cluster_labels) if len(cluster_labels) > 0 else -1
            for i, label in enumerate(cluster_labels):
                if label == -1:
                    max_label += 1
                    cluster_labels[i] = max_label
        
        else:
            raise ValueError(f"Unknown clustering method: {self.clustering_method}")
        
        return cluster_labels
    
    def _calculate_cluster_diversity_scores(self, features: np.ndarray, 
                                          cluster_labels: np.ndarray) -> List[float]:
        """Calculate diversity scores based on cluster analysis"""
        diversity_scores = []
        
        # Calculate cluster statistics
        unique_labels = np.unique(cluster_labels)
        cluster_sizes = {label: np.sum(cluster_labels == label) for label in unique_labels}
        
        for i, label in enumerate(cluster_labels):
            # Base score: smaller clusters get higher diversity scores
            cluster_size = cluster_sizes[label]
            base_score = 1.0 / cluster_size if cluster_size > 0 else 1.0
            
            # Distance from cluster center
            cluster_mask = cluster_labels == label
            cluster_features = features[cluster_mask]
            
            if len(cluster_features) > 1:
                cluster_center = np.mean(cluster_features, axis=0)
                distance_from_center = np.linalg.norm(features[i] - cluster_center)
                
                # Higher distance from center = more representative of cluster edge
                max_distance = np.max([np.linalg.norm(f - cluster_center) 
                                     for f in cluster_features])
                distance_score = distance_from_center / max_distance if max_distance > 0 else 0.5
            else:
                distance_score = 1.0  # Single item in cluster
            
            # Combine scores (base cluster diversity + position within cluster)
            diversity_score = 0.7 * base_score + 0.3 * distance_score
            diversity_scores.append(min(diversity_score, 1.0))
        
        return diversity_scores
    
    def select_representative_frames(self, frames_with_diversity: List[Tuple], 
                                   target_count: int,
                                   pose_requirements: Dict[str, int] = None) -> List[Tuple]:
        """
        Select representative frames ensuring diversity and pose coverage
        
        Args:
            frames_with_diversity: Frames with diversity data
            target_count: Target number of frames to select
            pose_requirements: Dict with required counts for each pose type
            
        Returns:
            Selected frames ensuring diversity and pose coverage
        """
        if len(frames_with_diversity) <= target_count:
            return frames_with_diversity
        
        selected_frames = []
        remaining_frames = frames_with_diversity.copy()
        
        # First, ensure pose coverage requirements if specified
        if pose_requirements:
            selected_frames = self._ensure_pose_coverage(
                remaining_frames, pose_requirements
            )
            # Remove selected frames from remaining
            selected_indices = set(id(frame) for frame in selected_frames)
            remaining_frames = [frame for frame in remaining_frames 
                              if id(frame) not in selected_indices]
        
        # Fill remaining slots with highest diversity scores
        remaining_slots = target_count - len(selected_frames)
        if remaining_slots > 0 and remaining_frames:
            # Sort by diversity score
            remaining_frames.sort(
                key=lambda x: x[4]['diversity_score'], reverse=True
            )
            selected_frames.extend(remaining_frames[:remaining_slots])
        
        logger.info(f"Selected {len(selected_frames)} representative frames "
                   f"from {len(frames_with_diversity)} candidates")
        
        return selected_frames[:target_count]
    
    def _ensure_pose_coverage(self, frames: List[Tuple], 
                            requirements: Dict[str, int]) -> List[Tuple]:
        """Select frames to meet pose coverage requirements"""
        selected = []
        
        # Group frames by dominant pose type
        pose_groups = {'frontal': [], 'left_profile': [], 'right_profile': []}
        
        for frame_data in frames:
            pose_coverage = frame_data[3].get('pose_coverage', {})
            
            # Determine dominant pose type
            max_coverage = max(pose_coverage.values()) if pose_coverage else 0
            if max_coverage > 0.3:  # Minimum threshold for pose classification
                dominant_pose = max(pose_coverage.keys(), key=pose_coverage.get)
                pose_groups[dominant_pose].append(frame_data)
        
        # Select required frames from each pose group
        for pose_type, required_count in requirements.items():
            available_frames = pose_groups.get(pose_type, [])
            
            if available_frames:
                # Sort by pose score and diversity
                available_frames.sort(
                    key=lambda x: (x[3].get('pose_score', 0) + 
                                 x[4].get('diversity_score', 0)) / 2,
                    reverse=True
                )
                
                # Take required number
                selected.extend(available_frames[:required_count])
        
        return selected