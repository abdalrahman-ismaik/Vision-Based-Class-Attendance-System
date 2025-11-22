# Face Comparison Guide

## Overview

This guide explains how to compare faces in two images using the FaceNet model.

## Quick Start

### Method 1: Using the Standalone Script (Recommended)

```bash
cd playground
python compare_faces.py image1.jpg image2.jpg
```

### Method 2: Using the Main Script

Edit `face_detection_embedding_v2.py`:

```python
# Set these variables in main()
COMPARE_MODE = True
IMAGE1_PATH = "your_image1.jpg"
IMAGE2_PATH = "your_image2.jpg"
THRESHOLD = 0.5
```

Then run:

```bash
python face_detection_embedding_v2.py
```

### Method 3: In Your Own Code

```python
from face_detection_embedding_v2 import (
    load_facenet_model,
    get_facenet_transform,
    compare_two_images
)
from utils.utils import RetinaFacePyPIAdapter
import torch

# Setup
device = 'cuda' if torch.cuda.is_available() else 'cpu'
model = load_facenet_model("../FaceNet/mobilefacenet_arcface/best_model_epoch43_acc100.00.pth", device)
detector = RetinaFacePyPIAdapter(threshold=0.9)
transform = get_facenet_transform()

# Compare
result = compare_two_images(
    image1_path="person1.jpg",
    image2_path="person2.jpg",
    model=model,
    face_detector=detector,
    transform=transform,
    device=device,
    threshold=0.5
)

if result:
    print(f"Same person: {result['same_person']}")
    print(f"Similarity: {result['similarity']:.4f}")
```

## Command-Line Options

### Basic Usage

```bash
python compare_faces.py image1.jpg image2.jpg
```

### Custom Threshold

```bash
python compare_faces.py image1.jpg image2.jpg --threshold 0.6
```

### No Visualization (faster)

```bash
python compare_faces.py image1.jpg image2.jpg --no-visualize
```

### Force CPU Mode

```bash
python compare_faces.py image1.jpg image2.jpg --cpu
```

### Custom Model Checkpoint

```bash
python compare_faces.py image1.jpg image2.jpg --checkpoint /path/to/model.pth
```

### Adjust Face Crop Margin

```bash
python compare_faces.py image1.jpg image2.jpg --margin 0.3
```

### All Options Together

```bash
python compare_faces.py img1.jpg img2.jpg \
    --threshold 0.6 \
    --margin 0.25 \
    --checkpoint ../FaceNet/mobilefacenet_arcface/best_model_epoch43_acc100.00.pth \
    --no-visualize
```

## Understanding the Results

### Similarity Score

The similarity score is a number between -1 and 1:

- **1.0**: Identical embeddings (same face)
- **0.6 - 1.0**: Very high similarity (likely same person)
- **0.4 - 0.6**: Medium similarity (uncertain, might be same person)
- **0.0 - 0.4**: Low similarity (likely different people)
- **< 0.0**: Very different (definitely different people)

### Confidence Levels

| Similarity Range | Verdict            | Confidence |
| ---------------- | ------------------ | ---------- |
| ≥ 0.6            | ✓ SAME PERSON      | High       |
| 0.5 - 0.6        | ? POSSIBLY SAME    | Medium     |
| < 0.5            | ✗ DIFFERENT PEOPLE | High       |

### Example Output

```
======================================================================
COMPARISON RESULTS
======================================================================
Cosine Similarity: 0.7234
Threshold: 0.5000
Verdict: ✓ SAME PERSON (High Confidence)
======================================================================
```

## Adjusting the Threshold

The default threshold is **0.5**, but you may need to adjust it based on your use case:

### Strict Matching (fewer false positives)

```bash
python compare_faces.py img1.jpg img2.jpg --threshold 0.7
```

- Use when you need high certainty
- Reduces false matches
- May miss some valid matches

### Lenient Matching (fewer false negatives)

```bash
python compare_faces.py img1.jpg img2.jpg --threshold 0.3
```

- Use when you want to catch all possible matches
- May include some false matches
- Better for initial screening

### Recommended by Use Case

| Use Case                | Threshold   | Reasoning                     |
| ----------------------- | ----------- | ----------------------------- |
| Security/Access Control | 0.6 - 0.7   | Need high certainty           |
| Photo Organization      | 0.4 - 0.5   | Balance accuracy and coverage |
| Finding Duplicates      | 0.3 - 0.4   | Don't want to miss anything   |
| Identity Verification   | 0.65 - 0.75 | Critical accuracy             |

## Return Value Structure

The `compare_two_images()` function returns a dictionary:

```python
{
    'similarity': 0.7234,           # Cosine similarity score
    'threshold': 0.5,               # Threshold used
    'verdict': '✓ SAME PERSON...',  # Human-readable verdict
    'same_person': True,            # Boolean: similarity >= threshold
    'face1': {                      # First face data
        'face_id': 1,
        'bbox': [x1, y1, x2, y2],
        'image': numpy_array,
        'embedding': 512-d numpy array,
        'embedding_norm': 1.0
    },
    'face2': { ... }                # Second face data
}
```

## Troubleshooting

### "No faces detected in one or both images"

**Solutions:**

1. Ensure faces are clearly visible
2. Check image quality (not too blurry)
3. Verify proper lighting
4. Lower detector threshold (in code, change `RetinaFacePyPIAdapter(threshold=0.9)` to `threshold=0.5`)

### High Similarity for Different People

**Possible causes:**

1. Similar facial features (siblings, family members)
2. Similar angles/expressions
3. Threshold too low

**Solutions:**

- Increase threshold to 0.6 or higher
- Test with more diverse images
- Verify model checkpoint is correct

### Low Similarity for Same Person

**Possible causes:**

1. Very different lighting conditions
2. Different ages (childhood vs adult)
3. Different angles (profile vs frontal)
4. Accessories (glasses, hats, masks)

**Solutions:**

- Lower threshold to 0.4
- Use images with similar conditions
- Increase face crop margin: `--margin 0.3`

### "Import could not be resolved"

Make sure you're in the correct directory:

```bash
cd /home/mohamed/Code/Vision-Based-Class-Attendance-System/playground
```

## Best Practices

### Image Quality

- ✓ Clear, well-lit faces
- ✓ Frontal or near-frontal angles
- ✓ Minimal occlusion
- ✗ Avoid very blurry images
- ✗ Avoid extreme angles
- ✗ Avoid heavy shadows

### Preprocessing

- The script uses the correct FaceNet normalization (no changes needed)
- L2 normalization is applied automatically
- Face alignment has been removed (it was causing issues)

### Performance

- GPU is ~10-20x faster than CPU
- First run loads the model (takes a few seconds)
- Subsequent comparisons are fast (<1 second per pair)

## Advanced Usage

### Batch Comparison

Compare one person against multiple images:

```python
import os
from face_detection_embedding_v2 import *

# Load model once
model = load_facenet_model(checkpoint_path, device)
detector = RetinaFacePyPIAdapter(threshold=0.9)
transform = get_facenet_transform()

reference_image = "person1.jpg"
test_images = ["test1.jpg", "test2.jpg", "test3.jpg"]

for test_img in test_images:
    result = compare_two_images(
        reference_image, test_img,
        model, detector, transform,
        visualize=False  # Skip visualization for batch
    )
    if result:
        print(f"{test_img}: {result['similarity']:.4f} - {result['verdict']}")
```

### Save Results to File

```python
import json

result = compare_two_images(...)
if result:
    # Convert numpy arrays to lists for JSON serialization
    output = {
        'similarity': float(result['similarity']),
        'same_person': bool(result['same_person']),
        'verdict': result['verdict']
    }
    with open('result.json', 'w') as f:
        json.dump(output, f, indent=2)
```

## Examples

### Example 1: Same Person, Different Photos

```bash
$ python compare_faces.py john_photo1.jpg john_photo2.jpg

Cosine Similarity: 0.7856
Verdict: ✓ SAME PERSON (High Confidence)
```

### Example 2: Different People

```bash
$ python compare_faces.py alice.jpg bob.jpg

Cosine Similarity: 0.2341
Verdict: ✗ DIFFERENT PEOPLE (High Confidence)
```

### Example 3: Uncertain Case

```bash
$ python compare_faces.py person1.jpg person2.jpg

Cosine Similarity: 0.5123
Verdict: ? POSSIBLY SAME (Medium Confidence)
```

## Related Files

- `face_detection_embedding_v2.py` - Main implementation
- `compare_faces.py` - Standalone comparison script
- `WHY_NO_FINETUNING_NEEDED.md` - Explains why pretrained model works
- `../FaceNet/test_model.py` - Reference implementation

## Notes

1. **No Fine-Tuning Needed**: The pretrained model works well for general face comparison. See `WHY_NO_FINETUNING_NEEDED.md` for details.

2. **Preprocessing is Critical**: The script uses the exact same normalization as FaceNet training. Don't modify the `get_facenet_transform()` function.

3. **L2 Normalization**: Embeddings are L2-normalized before comparison. This is essential for accurate cosine similarity.

4. **Single Face per Image**: If multiple faces are detected, only the first one is used. You can modify the code to select by size or position.
