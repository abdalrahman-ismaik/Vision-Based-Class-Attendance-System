# Quick Fix - Processing Students

## The Problem

Flask's debug mode with auto-reload kills background threads, so face processing doesn't complete automatically.

## The Solution

Use the standalone processing script instead!

## How to Process Students

### Option 1: Process All Pending Students (Recommended)

```bash
cd backend
python process_pending.py
```

This will:
- Find all students with `processing_status: "pending"`
- Process each one sequentially
- Update the database with results
- Show progress and summary

### Option 2: Run Flask Without Debug Mode

Edit `app.py` at the bottom:

```python
if __name__ == '__main__':
    app.run(debug=False, host='0.0.0.0', port=5000)  # Change debug=True to False
```

Then restart the server. Background processing will work correctly.

### Option 3: Manual Processing via API

With server running (even in debug mode):

```bash
# Process specific student
curl -X POST http://localhost:5000/api/students/100064000/process
```

## Checking Status

```bash
# View database
cat database.json

# Check specific student
curl http://localhost:5000/api/students/100064000

# Check processed files
ls -la processed_faces/100064000/
```

## Expected Output

After processing, you should see:

```
processed_faces/
└── 100064000/
    ├── aug_000.jpg  # Original
    ├── aug_001.jpg  # Zoom in 1.15x
    ├── aug_002.jpg  # Zoom in 1.3x
    ├── aug_003.jpg  # Zoom out 0.85x
    ├── aug_004.jpg  # Brightness 0.6x
    ... (20 total augmentations)
    ├── aug_020.jpg
    └── embeddings.npy  # (21, 512) array
```

And in `database.json`:

```json
{
  "100064000": {
    "processing_status": "completed",
    "num_augmentations": 21,
    "embeddings_path": ".../processed_faces/100064000/embeddings.npy",
    ...
  }
}
```

## Training Classifier

After processing 2+ students:

```bash
curl -X POST http://localhost:5000/api/students/train-classifier
```

## Recognizing Faces

```bash
curl -X POST http://localhost:5000/api/students/recognize \
  -F "image=@path/to/test.jpg"
```

## Quick Start

```bash
# 1. Process all pending students
cd backend
python process_pending.py

# 2. Train classifier (if 2+ students)
curl -X POST http://localhost:5000/api/students/train-classifier

# 3. Test recognition
curl -X POST http://localhost:5000/api/students/recognize \
  -F "image=@uploads/students/100064000/100064000_20251020_202240.jpeg"
```

Done! 🎉
