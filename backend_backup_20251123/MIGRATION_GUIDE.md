# Migration Guide: Backend Restructuring

## Overview
The backend has been reorganized from a flat structure to a modular, organized architecture.

## Changes Summary

### Directory Structure Changes

| Old Location | New Location | Description |
|--------------|--------------|-------------|
| `face_processing_pipeline.py` | `services/face_processing_pipeline.py` | Face recognition service |
| `opencv_face_processor.py` | `services/opencv_face_processor.py` | Face processing service |
| `test_*.py` | `tests/test_*.py` | Test files |
| `*.md` files | `docs/*.md` | Documentation |
| `fix_*.py`, `process_*.py` | `scripts/*.py` | Utility scripts |
| `database.json`, `classes.json` | `data/database.json`, `data/classes.json` | Data files |
| `uploads/` | `storage/uploads/` | Uploaded files |
| `processed_faces/` | `storage/processed_faces/` | Processed images |
| `classifiers/` | `storage/classifiers/` | Model files |
| `.env.example`, `.gitignore` | `config/` | Configuration files |

### Import Changes

#### In `app.py`:
```python
# Old
from face_processing_pipeline import FaceProcessingPipeline

# New
from services.face_processing_pipeline import FaceProcessingPipeline
from config import Config
```

#### In other modules:
```python
# Old
from opencv_face_processor import OpenCVFaceProcessor

# New
from services.opencv_face_processor import OpenCVFaceProcessor
```

### Configuration Changes

#### Old approach (in app.py):
```python
UPLOAD_FOLDER = os.path.join(os.path.dirname(__file__), 'uploads')
DATABASE_FILE = os.path.join(os.path.dirname(__file__), 'database.json')
```

#### New approach:
```python
from config import Config

upload_folder = Config.UPLOAD_FOLDER
database_file = Config.DATABASE_PATH
```

## Step-by-Step Migration

### 1. Update Imports
If you have custom scripts or modules that import from the backend:

```python
# Update these imports:
from face_processing_pipeline import FaceProcessingPipeline
# To:
from services.face_processing_pipeline import FaceProcessingPipeline

from opencv_face_processor import OpenCVFaceProcessor
# To:
from services.opencv_face_processor import OpenCVFaceProcessor
```

### 2. Update File Paths
If external scripts reference backend files:

```python
# Old paths
'backend/database.json'
'backend/uploads/students/'
'backend/classifiers/'

# New paths
'backend/data/database.json'
'backend/storage/uploads/students/'
'backend/storage/classifiers/'
```

### 3. Environment Variables
Create a `.env` file based on `config/.env.example`:

```bash
cd backend
cp config/.env.example .env
# Edit .env with your values
```

### 4. Verify Data Integrity
Check that all data files were moved correctly:

```bash
# Should contain your data
cat data/database.json
cat data/classes.json

# Should contain uploaded files
ls storage/uploads/students/

# Should contain processed faces
ls storage/processed_faces/
```

## Testing After Migration

### 1. Run Unit Tests
```bash
cd backend
python -m pytest tests/ -v
```

### 2. Test Individual Components
```bash
# Test pipeline
python tests/test_pipeline.py

# Test standalone
python tests/test_standalone.py
```

### 3. Run the Application
```bash
python app.py
```

### 4. Check API Endpoints
```bash
# Health check
curl http://localhost:5000/api/health

# Or visit Swagger UI
# http://localhost:5000/api/docs
```

## Common Issues and Solutions

### Issue: Import Error
```
ImportError: cannot import name 'FaceProcessingPipeline'
```
**Solution**: Update imports to use the new structure:
```python
from services.face_processing_pipeline import FaceProcessingPipeline
```

### Issue: File Not Found
```
FileNotFoundError: [Errno 2] No such file or directory: 'database.json'
```
**Solution**: Use Config paths:
```python
from config import Config
database_path = Config.DATABASE_PATH
```

### Issue: Module Not Found
```
ModuleNotFoundError: No module named 'services'
```
**Solution**: Ensure you're running from the backend directory and `__init__.py` files exist in all package directories.

## Rollback Plan

If you need to revert to the old structure:

1. Backup the current organized structure
2. Move files back to root level
3. Update imports back to old style
4. Restore old configuration

## Benefits of New Structure

✅ **Modular**: Clear separation of concerns  
✅ **Scalable**: Easy to add new features  
✅ **Testable**: Organized test structure  
✅ **Maintainable**: Easy to locate code  
✅ **Professional**: Industry-standard layout  
✅ **Collaborative**: Multiple developers can work simultaneously  

## Next Steps

1. Review `STRUCTURE_README.md` for detailed documentation
2. Update any external scripts that reference backend
3. Consider extracting API routes from `app.py` into `api/` modules
4. Implement proper database models in `models/`
5. Add comprehensive tests in `tests/`

## Questions?

Refer to:
- `STRUCTURE_README.md` - Complete structure documentation
- `docs/ARCHITECTURE.md` - System architecture
- `docs/QUICKSTART.md` - Quick start guide
