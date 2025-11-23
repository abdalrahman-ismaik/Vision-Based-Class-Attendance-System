# Backend - Vision-Based Class Attendance System

## 🎉 Recently Reorganized!
The backend has been reorganized for better maintainability and scalability!

## 📚 Documentation Hub

### Reorganization Resources (NEW!)
- 🗂️ [**Quick Reference**](QUICK_REFERENCE.md) - Start here! Quick commands and tips
- 📋 [**Migration Checklist**](MIGRATION_CHECKLIST.md) - Step-by-step migration guide
- 📖 [**Reorganization Guide**](REORGANIZATION_GUIDE.md) - Complete reorganization details
- 📝 [**Reorganization Summary**](REORGANIZATION_SUMMARY.md) - What changed and why
- 🎨 [**Before & After**](BEFORE_AFTER.md) - Visual comparison

### Existing Documentation
- 🏗️ [Architecture](docs/ARCHITECTURE.md) - System architecture overview
- 🚀 [Quick Start](docs/QUICKSTART.md) - Get started quickly
- 📚 [Complete README](docs/README_COMPLETE.md) - Comprehensive documentation

## Directory Structure (NEW)

```
backend/
├── api/                       # API routes and endpoints
│   ├── health.py             # Health check endpoints
│   ├── students.py           # Student management (coming soon)
│   ├── classes.py            # Class management (coming soon)
│   └── attendance.py         # Attendance tracking (coming soon)
├── config/                    # Configuration management
│   └── settings.py           # Centralized configuration
├── models/                    # Data models and schemas
│   └── schemas.py            # API schemas for Swagger
├── services/                  # Business logic
│   └── face_processing_pipeline.py
├── utils/                     # Utility functions
│   ├── database.py           # Database operations
│   └── file_handler.py       # File handling utilities
├── data/                      # JSON databases (centralized)
│   ├── database.json         # Students database
│   └── classes.json          # Classes database
├── storage/                   # File storage (centralized)
│   ├── uploads/
│   ├── processed_faces/
│   └── classifiers/
├── tests/                     # Test files
├── docs/                      # Documentation
├── scripts/                   # Maintenance scripts
│   └── reorganize_backend.ps1  # Reorganization script
├── main.py                   # NEW: Application factory (recommended)
├── app.py                    # LEGACY: Original app (still works)
└── requirements.txt          # Python dependencies
```

## Getting Started

### Prerequisites
- Python 3.11+ (recommended)
- Virtual environment activated

### Installation

```bash
# Navigate to backend
cd backend

# Activate virtual environment
.\.venv311\Scripts\Activate.ps1  # Windows PowerShell
# or
source .venv311/bin/activate     # Linux/Mac

# Install dependencies
pip install -r requirements.txt
```

### Running the Application

**Option 1: New Structure (Recommended)**
```bash
# Using new application factory pattern
python main.py
```

**Option 2: Legacy Support**
```bash
# Using original app.py (still works)
python app.py
```

The API will be available at `http://localhost:5000`  
Swagger documentation at `http://localhost:5000/api/docs`

### First Time Setup

If you're setting up the reorganized structure for the first time:

```powershell
# Run the reorganization script
.\scripts\reorganize_backend.ps1
```

This will:
- Consolidate duplicate database files
- Move storage folders to centralized location
- Backup old files (marked as `.deprecated_*`)

## Key Features

✨ **Face Recognition**: Advanced face detection and recognition pipeline  
👥 **Student Management**: Register and manage student profiles  
📸 **Image Processing**: Automated face extraction and processing  
📊 **Attendance Tracking**: Real-time attendance marking via face recognition  
🔒 **Secure API**: RESTful API with proper validation  
📖 **API Documentation**: Auto-generated Swagger UI  

## API Endpoints

- `POST /api/students/register` - Register new student with 5 face images (different poses)
- `POST /api/attendance/mark` - Mark attendance via face recognition
- `GET /api/students` - List all students
- `GET /api/classes` - List all classes
- `GET /api/health` - Health check

Full API documentation available at `/api/docs` when running the server.

### Student Registration
The registration endpoint accepts **one or more face images** (different poses/angles) in a single API call. The mobile app can send multiple images using the `images` field (with `action='append'` for multiple files).

For mobile app integration details, see [Mobile Integration Guide](docs/MOBILE_INTEGRATION_GUIDE.md).

## Configuration

Configuration is managed through the `config/` module:

```python
from config import Config

# Access configuration
database_path = Config.DATABASE_PATH
upload_folder = Config.UPLOAD_FOLDER
```

Environment variables can be set in `.env` (copy from `config/.env.example`).

## Testing

```bash
# Run all tests
python -m pytest tests/

# Run specific test
python tests/test_pipeline.py
```

## Project Structure Benefits

✅ **Organized**: Clear separation of concerns  
✅ **Scalable**: Easy to extend with new features  
✅ **Maintainable**: Straightforward to locate and modify code  
✅ **Professional**: Follows industry best practices  
✅ **Documented**: Comprehensive documentation in `docs/`  

## Recent Changes

🔄 **Backend Restructuring** (Nov 2025)
- Reorganized flat structure into modular architecture
- Created dedicated directories for different concerns
- Updated import paths and configuration management
- Consolidated storage and data directories
- Improved documentation structure

See [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md) for details on adapting to the new structure.

## Development

### Adding New Features

1. **API Endpoints**: Add routes in `api/` directory
2. **Business Logic**: Implement services in `services/`
3. **Data Models**: Define models in `models/`
4. **Utilities**: Add helpers in `utils/`
5. **Tests**: Create tests in `tests/`
6. **Documentation**: Update docs in `docs/`

### Code Style

- Follow PEP 8 guidelines
- Use type hints where appropriate
- Document functions with docstrings
- Keep functions focused and modular

## Troubleshooting

### Import Errors
Ensure you're using the new import paths:
```python
from services.face_processing_pipeline import FaceProcessingPipeline
from config import Config
```

### File Not Found
Use Config paths instead of hardcoded paths:
```python
from config import Config
path = Config.DATABASE_PATH
```

### Module Not Found
Verify you're running from the backend directory and all `__init__.py` files exist.

## Contributing

1. Keep the modular structure
2. Follow the established patterns
3. Add tests for new features
4. Update documentation
5. Use meaningful commit messages

## License

[Add your license information]

## Contact

[Add contact information]

---

**For detailed information, see:**
- [STRUCTURE_README.md](STRUCTURE_README.md) - Complete structure documentation
- [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md) - Migration instructions
- [docs/](docs/) - Additional documentation
