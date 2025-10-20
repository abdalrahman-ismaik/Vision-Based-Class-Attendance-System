# Quick Reference Card

## Compare Two Images (One-Liner)

```bash
python compare_faces.py person1.jpg person2.jpg
```

---

## What Changed

| Before                                 | After                            |
| -------------------------------------- | -------------------------------- |
| ❌ Wrong preprocessing (ImageNet)      | ✅ Correct FaceNet preprocessing |
| ❌ Complex face alignment              | ✅ Simple crop with margin       |
| ❌ Single image only                   | ✅ Two-image comparison          |
| ❌ High similarity for different faces | ✅ Accurate similarity scores    |

---

## Key Functions

### Compare Two Images

```python
result = compare_two_images(img1, img2, model, detector, transform)
# Returns: {'similarity': 0.72, 'same_person': True, ...}
```

### Detect & Embed Faces

```python
faces = detect_and_embed_faces(image_path, model, detector, transform)
# Returns: [{'embedding': array, 'bbox': [...], ...}, ...]
```

### Compute Similarity

```python
similarity = compute_cosine_similarity(embedding1, embedding2)
# Returns: float between -1 and 1
```

---

## Similarity Interpretation

| Score   | Meaning                         |
| ------- | ------------------------------- |
| ≥ 0.6   | ✓ SAME PERSON (high confidence) |
| 0.4-0.6 | ? UNCERTAIN (medium confidence) |
| < 0.4   | ✗ DIFFERENT (high confidence)   |

---

## Command-Line Options

```bash
# Basic
python compare_faces.py img1.jpg img2.jpg

# Custom threshold
python compare_faces.py img1.jpg img2.jpg --threshold 0.6

# No visualization
python compare_faces.py img1.jpg img2.jpg --no-visualize

# Force CPU
python compare_faces.py img1.jpg img2.jpg --cpu

# All options
python compare_faces.py img1.jpg img2.jpg -t 0.6 -m 0.25 --no-visualize
```

---

## In Your Code

```python
# Import
from face_detection_embedding_v2 import *
from utils.utils import RetinaFacePyPIAdapter
import torch

# Setup (once)
device = 'cuda' if torch.cuda.is_available() else 'cpu'
model = load_facenet_model("path/to/checkpoint.pth", device)
detector = RetinaFacePyPIAdapter(threshold=0.9)
transform = get_facenet_transform()

# Compare (fast)
result = compare_two_images(
    "img1.jpg", "img2.jpg",
    model, detector, transform,
    threshold=0.5
)

print(f"Similarity: {result['similarity']:.4f}")
print(f"Same: {result['same_person']}")
```

---

## Troubleshooting

| Problem                              | Solution                        |
| ------------------------------------ | ------------------------------- |
| No faces detected                    | Lower detector threshold to 0.5 |
| High similarity for different people | Increase threshold to 0.6+      |
| Low similarity for same person       | Decrease threshold to 0.4       |
| Slow performance                     | Use GPU, set `visualize=False`  |

---

## File Structure

```
playground/
├── face_detection_embedding_v2.py    # Main implementation
├── compare_faces.py                   # CLI tool
├── FACE_COMPARISON_GUIDE.md           # Detailed guide
├── WHY_NO_FINETUNING_NEEDED.md       # Model explanation
├── SUMMARY.md                         # Full changelog
└── QUICK_REFERENCE.md                 # This file
```

---

## Critical Settings

### Preprocessing (DON'T CHANGE)

```python
FACENET_MEAN = [0.3193, 0.2874, 0.2578]
FACENET_STD = [0.1980, 0.2076, 0.2109]
```

### Detector Threshold

```python
RetinaFacePyPIAdapter(threshold=0.9)  # Default: strict
RetinaFacePyPIAdapter(threshold=0.5)  # More faces
```

### Face Crop Margin

```python
margin=0.2  # Default: 20% padding
margin=0.3  # More context
```

---

## DO's and DON'Ts

### ✅ DO

- Use GPU for faster processing
- Test with clear, well-lit images
- Adjust threshold based on use case
- Use the pretrained model as-is

### ❌ DON'T

- Change preprocessing normalization
- Fine-tune without testing first
- Use very blurry images
- Expect perfect accuracy with occlusions

---

## Batch Processing Example

```python
reference = "known_person.jpg"
test_images = ["test1.jpg", "test2.jpg", "test3.jpg"]

for img in test_images:
    result = compare_two_images(
        reference, img,
        model, detector, transform,
        visualize=False
    )
    if result and result['same_person']:
        print(f"✓ Match: {img} ({result['similarity']:.3f})")
```

---

## Performance Tips

1. **Load model once** - Reuse for multiple comparisons
2. **Disable visualization** - Set `visualize=False` for speed
3. **Use GPU** - 10-20x faster than CPU
4. **Batch processing** - Don't reload model each time
5. **Lower detector threshold** - If faces aren't detected

---

## Need More Help?

- **Basic usage:** Read `FACE_COMPARISON_GUIDE.md`
- **Model details:** Read `WHY_NO_FINETUNING_NEEDED.md`
- **Full changes:** Read `SUMMARY.md`
- **Examples:** Check `FaceNet/test_model.py`
