# Fine-Tuning FaceNet - Complete Guide

## 📋 Overview

This script allows you to fine-tune the pre-trained FaceNet model on your custom faces (e.g., students in a class). This improves accuracy for your specific use case.

## 🗂️ Dataset Preparation

### Required Structure

Organize your images in folders by person:

```
data/
├── student_1/
│   ├── photo1.jpg
│   ├── photo2.jpg
│   └── photo3.jpg
├── student_2/
│   ├── photo1.jpg
│   └── photo2.jpg
└── student_3/
    ├── photo1.jpg
    ├── photo2.jpg
    └── photo3.jpg
```

### Recommendations

- **Minimum images per person**: 3-5 (more is better)
- **Image quality**: Clear, well-lit faces
- **Face size**: At least 50x50 pixels
- **Variety**: Different angles, expressions, lighting
- **Total dataset**: At least 50-100 images for good results

## 🚀 Quick Start

### 1. Prepare Your Dataset

```bash
# Use the backend/uploads/students structure
# Each student ID should be a folder with their photos
```

### 2. Configure the Script

Edit `fine_tune_facenet.py`:

```python
# Dataset location
DATA_DIR = '../backend/uploads/students'

# Pre-trained model
PRETRAINED_CHECKPOINT = '../FaceNet/mobilefacenet_arcface/best_model_epoch43_acc100.00.pth'

# Output directory
OUTPUT_DIR = './fine_tuned_model'

# Training parameters
NUM_EPOCHS = 50
BATCH_SIZE = 16
LEARNING_RATE = 0.001
FREEZE_BACKBONE = True  # Recommended for small datasets
```

### 3. Run Fine-Tuning

```bash
cd /home/mohamed/Code/Vision-Based-Class-Attendance-System/playground
python fine_tune_facenet.py
```

## ⚙️ Configuration Options

### Training Modes

#### 1. **Freeze Backbone (Recommended for small datasets)**

```python
FREEZE_BACKBONE = True
LEARNING_RATE = 0.001
NUM_EPOCHS = 50
```

- ✅ Fast training (5-10 minutes)
- ✅ Less data needed (3-5 images per person)
- ✅ Less risk of overfitting
- ❌ Less adaptation to new domain

#### 2. **Full Fine-Tuning (For larger datasets)**

```python
FREEZE_BACKBONE = False
LEARNING_RATE = 0.0001  # Lower LR for stability
NUM_EPOCHS = 100
```

- ✅ Better accuracy on your domain
- ✅ More flexible adaptation
- ❌ Requires more data (10+ images per person)
- ❌ Longer training time
- ❌ Risk of overfitting

### Batch Size Guidelines

| GPU VRAM | Recommended Batch Size |
| -------- | ---------------------- |
| 4 GB     | 8                      |
| 6 GB     | 16                     |
| 8 GB+    | 32                     |
| CPU      | 4                      |

### Learning Rate

- **Freeze backbone**: 0.001 - 0.01
- **Full fine-tuning**: 0.0001 - 0.001
- **If loss explodes**: Decrease by 10x
- **If training too slow**: Increase by 2x

## 📊 Monitoring Training

### Console Output

```
Epoch 1/50
----------------------------------------
Training: 100%|████████| 10/10 [00:05<00:00, loss=2.1234, acc=45.67%]
Validation: 100%|████████| 3/3 [00:01<00:00]

Epoch 1 Summary:
  Train Loss: 2.1234, Train Acc: 45.67%
  Val Loss: 1.8901, Val Acc: 52.33%
  Learning Rate: 0.001000
  🎉 New best accuracy: 52.33%
```

### What to Look For

✅ **Good Training:**

- Train acc steadily increases
- Val acc increases (may fluctuate)
- Val acc stays close to train acc
- Loss decreases

⚠️ **Overfitting:**

- Train acc >> Val acc (gap > 20%)
- Val loss increases while train loss decreases
- **Solutions**: Add more data, use FREEZE_BACKBONE=True, reduce epochs

❌ **Not Learning:**

- Accuracy stays near random (1/num_classes)
- Loss doesn't decrease
- **Solutions**: Increase learning rate, check data quality

## 📁 Output Files

After training completes:

```
fine_tuned_model/
├── best_model_epoch25_acc95.50.pth    # Best model checkpoint
├── latest_checkpoint.pth               # Latest checkpoint
├── training_history.png                # Loss/accuracy plots
└── training_config.json                # Training configuration
```

### Checkpoint Contents

```python
checkpoint = {
    'epoch': 25,
    'backbone_state_dict': {...},      # Model weights
    'classifier_state_dict': {...},    # Classifier weights
    'optimizer_state_dict': {...},     # Optimizer state
    'best_acc': 95.50
}
```

## 🔄 Using the Fine-Tuned Model

### Update face_detection_embedding.py

```python
# Change this line:
CHECKPOINT_PATH = '../FaceNet/mobilefacenet_arcface/best_model_epoch43_acc100.00.pth'

# To:
CHECKPOINT_PATH = './fine_tuned_model/best_model_epoch25_acc95.50.pth'
```

### Load for Inference

```python
import torch
from networks.models_facenet import MobileFaceNet

# Load model
device = 'cuda'
backbone = MobileFaceNet(embedding_size=512).to(device)

# Load fine-tuned weights
checkpoint = torch.load('./fine_tuned_model/best_model_epoch25_acc95.50.pth')
backbone.load_state_dict(checkpoint['backbone_state_dict'])
backbone.eval()

# Use for embeddings
with torch.no_grad():
    embedding = backbone(image_tensor)
    embedding = torch.nn.functional.normalize(embedding, p=2, dim=1)
```

## 🎯 Expected Results

### Small Dataset (3-5 images per person, 10 people)

| Metric         | Expected                |
| -------------- | ----------------------- |
| Training Time  | 5-10 minutes            |
| Final Accuracy | 80-95%                  |
| Improvement    | +10-20% over base model |

### Medium Dataset (10+ images per person, 20+ people)

| Metric         | Expected                |
| -------------- | ----------------------- |
| Training Time  | 20-30 minutes           |
| Final Accuracy | 90-98%                  |
| Improvement    | +15-30% over base model |

## 🐛 Troubleshooting

### Error: "No subdirectories found"

- Check DATA_DIR path is correct
- Ensure images are in person folders

### Error: CUDA out of memory

```python
BATCH_SIZE = 8  # Reduce batch size
# Or use CPU
DEVICE = 'cpu'
```

### Low Accuracy (<60%)

- Add more images per person (minimum 5)
- Ensure face images are clear and well-cropped
- Try FREEZE_BACKBONE = False for more adaptation
- Check data quality (blur, lighting, occlusion)

### Overfitting (Train 95%, Val 70%)

```python
FREEZE_BACKBONE = True  # Only train classifier
NUM_EPOCHS = 30         # Reduce epochs
# Add more validation data
```

### Training Too Slow

```python
BATCH_SIZE = 32         # Increase batch size
# Or use fewer data augmentations
```

## 📈 Advanced Options

### Custom Data Augmentation

Edit `get_transforms()` in the script:

```python
# Light augmentation (recommended)
transforms.RandomHorizontalFlip(p=0.5),
transforms.ColorJitter(brightness=0.2, contrast=0.2),

# Heavy augmentation (for more data)
transforms.RandomHorizontalFlip(p=0.5),
transforms.ColorJitter(brightness=0.3, contrast=0.3, saturation=0.2),
transforms.RandomRotation(degrees=15),
transforms.RandomAffine(degrees=0, translate=(0.1, 0.1)),
```

### Custom Learning Rate Schedule

```python
# Step decay (current)
scheduler = optim.lr_scheduler.StepLR(optimizer, step_size=10, gamma=0.5)

# Cosine annealing (smoother)
scheduler = optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=NUM_EPOCHS)

# Reduce on plateau (adaptive)
scheduler = optim.lr_scheduler.ReduceLROnPlateau(optimizer, patience=5)
```

### Multiple Training Stages

```python
# Stage 1: Train classifier only (fast)
FREEZE_BACKBONE = True
LEARNING_RATE = 0.001
NUM_EPOCHS = 30

# Stage 2: Fine-tune full model (better accuracy)
# Load best checkpoint from stage 1
FREEZE_BACKBONE = False
LEARNING_RATE = 0.0001
NUM_EPOCHS = 20
```

## 🔍 Validation

### Test Your Fine-Tuned Model

```bash
# Update face_detection_embedding.py with new checkpoint
# Then run comparison
python face_detection_embedding.py
```

### Compare Results

| Model      | Same Person Similarity | Different Person Similarity |
| ---------- | ---------------------- | --------------------------- |
| Base Model | 0.50-0.60              | 0.20-0.35                   |
| Fine-Tuned | 0.65-0.80              | 0.10-0.25                   |

Better separation = Better model!

## 💡 Tips for Best Results

1. **Data Quality > Quantity**

   - 5 good images > 20 poor images
   - Clear faces, good lighting, minimal blur

2. **Balanced Dataset**

   - Similar number of images per person
   - If imbalanced, collect more for underrepresented people

3. **Diverse Images**

   - Different angles (front, side profiles)
   - Different expressions
   - Different lighting conditions
   - With/without glasses (if applicable)

4. **Start Conservative**

   - Begin with FREEZE_BACKBONE=True
   - Use early stopping
   - Monitor validation accuracy

5. **Iterate**
   - Add more data if needed
   - Try different hyperparameters
   - Compare before/after results

## 📚 References

- Original FaceNet paper: L2-normalized embeddings
- MobileFaceNet: Efficient face recognition
- ArcFace loss: Better angular margin

---

**Need Help?** Check the console output for detailed error messages and training progress.
