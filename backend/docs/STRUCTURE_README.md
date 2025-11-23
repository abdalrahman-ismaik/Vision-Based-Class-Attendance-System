# Backend Structure Documentation

## Directory Organization

The backend has been reorganized into a modular, maintainable structure:

```
backend/
├── api/                    # API routes and endpoints
│   └── __init__.py        # API initialization
├── services/              # Business logic and processing services
│   ├── __init__.py
│   ├── face_processing_pipeline.py    # Main face recognition pipeline
│   └── opencv_face_processor.py       # OpenCV-based face processor
├── models/                # Data models and schemas
│   └── __init__.py
├── utils/                 # Utility functions and helpers
│   └── __init__.py
├── config/                # Configuration files
│   ├── __init__.py        # Application configuration
│   ├── .env.example       # Environment variables template
│   └── .gitignore         # Git ignore patterns
├── tests/                 # Test files
│   ├── __init__.py
│   ├── test_load.py
│   ├── test_pipeline.py
│   ├── test_standalone.py
│   └── test_page.html
├── docs/                  # Documentation files
│   ├── ARCHITECTURE.md
│   ├── IMPLEMENTATION_SUMMARY.md
│   ├── PIPELINE_README.md
│   ├── QUICKSTART.md
│   └── README_COMPLETE.md
├── scripts/               # Utility scripts
│   ├── fix_retinaface.py
│   ├── fix_retinaface_line518.py
│   ├── inspect_checkpoint.py
│   ├── manual_process.py
│   ├── process_pending.py
│   └── process_pending_updated.py
├── data/                  # JSON databases and persistent data
│   ├── database.json      # Student database
│   └── classes.json       # Class information
├── storage/               # File storage
│   ├── uploads/          # Original uploaded images
│   │   └── students/     # Student photos by ID
│   ├── processed_faces/  # Processed face images
│   └── classifiers/      # Trained classifiers
├── app.py                # Main Flask application
├── requirements.txt      # Python dependencies
└── __init__.py          # Package initialization

```

## Module Descriptions

### `api/`
Contains all Flask-RESTX API route definitions and endpoint handlers. This separates the API layer from business logic.

### `services/`
Business logic and processing services:
- `face_processing_pipeline.py`: Core face recognition and processing logic
- `opencv_face_processor.py`: OpenCV-based face detection and processing

### `models/`
Data models, schemas, and database interfaces. Will contain Pydantic models or SQLAlchemy models when implemented.

### `utils/`
Shared utility functions, helpers, and common code used across the application.

### `config/`
Application configuration:
- Environment variables
- Path configurations
- Application settings
- Constants

### `tests/`
All test files for unit testing, integration testing, and test utilities.

### `docs/`
Documentation files including architecture, implementation guides, and API documentation.

### `scripts/`
Utility scripts for maintenance tasks, data migration, and one-off operations.

### `data/`
JSON database files and persistent data storage (can be replaced with proper database).

### `storage/`
File storage for uploads, processed images, and trained models.

## Import Examples

### Before (Old Structure)
```python
from face_processing_pipeline import FaceProcessingPipeline
```

### After (New Structure)
```python
from services.face_processing_pipeline import FaceProcessingPipeline
from config import Config
```

## Configuration Usage

Instead of hardcoded paths, use the Config class:

```python
from config import Config

# Access paths
database_path = Config.DATABASE_PATH
upload_folder = Config.UPLOAD_FOLDER

# Access settings
secret_key = Config.SECRET_KEY
max_file_size = Config.MAX_CONTENT_LENGTH
```

## Running the Application

```bash
# Navigate to backend directory
cd backend

# Activate virtual environment (if not already activated)
.venv\Scripts\activate  # Windows
source .venv/bin/activate  # Linux/Mac

# Install dependencies
pip install -r requirements.txt

# Run the application
python app.py
```

## Testing

```bash
# Run all tests
python -m pytest tests/

# Run specific test file
python tests/test_pipeline.py
```

## Migration Notes

If you have existing data:
1. Old data files (database.json, classes.json) have been moved to `data/`
2. Uploaded files remain accessible in `storage/uploads/`
3. Processed faces are in `storage/processed_faces/`
4. Update any external scripts that reference old paths

## Future Improvements

1. **API Routes**: Extract routes from `app.py` into separate files in `api/`
2. **Models**: Create proper data models in `models/` (SQLAlchemy or Pydantic)
3. **Database**: Replace JSON files with SQLite or PostgreSQL
4. **Utils**: Extract common functions from services into `utils/`
5. **Environment**: Use `.env` file for environment-specific configuration
6. **Logging**: Centralized logging configuration in `config/`

## Benefits of New Structure

1. **Modularity**: Clear separation of concerns
2. **Scalability**: Easy to add new features in appropriate directories
3. **Testability**: Tests are separate and organized
4. **Maintainability**: Easy to locate and modify specific functionality
5. **Collaboration**: Multiple developers can work on different modules
6. **Documentation**: Centralized documentation in `docs/`
