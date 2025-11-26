# Vision-Based Class Attendance System - Backend

A Flask-based REST API for managing student registration and attendance using face recognition.

## Features

- 🎓 **Student Registration**: Register students with ID, name, email, department, and face image
- 📸 **Image Upload**: Secure image upload and validation
- 🔍 **Student Search**: Search students by name or ID
- 📊 **Student Management**: List, view, and delete student records
- 📝 **Swagger Documentation**: Interactive API documentation at `/api/docs`
- ✅ **Health Check**: Monitor API status

## Quick Start

### 1. Install Dependencies

```bash
pip install -r requirements.txt
```

### 2. Run the Server

**Windows (with virtual environment):**
```powershell
cd c:\Users\4bais\Vision-Based-Class-Attendance-System\backend
C:\Users\4bais\Vision-Based-Class-Attendance-System\.venv\Scripts\python.exe app.py
```

**Or if virtual environment is activated:**
```bash
python app.py
```

The server will start at `http://localhost:5000`

### 3. Access Swagger UI

Open your browser and navigate to:

```
http://localhost:5000/api/docs
```

You can test all API endpoints directly from the Swagger interface!

## API Endpoints

### Health Check

- **GET** `/api/health/status` - Check if API is running

### Students

- **GET** `/api/students/` - List all registered students
- **POST** `/api/students/` - Register a new student with face image
- **GET** `/api/students/<student_id>` - Get specific student details
- **DELETE** `/api/students/<student_id>` - Delete a student
- **GET** `/api/students/search?query=<name>` - Search students

### Attendance

- **POST** `/api/attendance/mark` - Mark attendance (placeholder for face recognition)

## How to Test with Swagger

1. **Start the server**: Run `python app.py`
2. **Open Swagger UI**: Go to `http://localhost:5000/api/docs`
3. **Test Student Registration**:

   - Click on `POST /api/students/`
   - Click "Try it out"
   - Fill in the form:
     - `student_id`: e.g., "S12345"
     - `name`: e.g., "John Doe"
     - `email`: e.g., "john@university.edu"
     - `department`: e.g., "Computer Science"
     - `year`: e.g., 3
     - `image`: Upload a face image (JPG, PNG, or BMP)
   - Click "Execute"
   - See the response below!

4. **Test Other Endpoints**:
   - List all students: `GET /api/students/`
   - Get specific student: `GET /api/students/S12345`
   - Search students: `GET /api/students/search?query=John`
   - Delete student: `DELETE /api/students/S12345`

## Project Structure

```
backend/
├── app.py                  # Main Flask application
├── requirements.txt        # Python dependencies
├── README.md              # This file
├── database.json          # JSON database (auto-created)
└── uploads/               # Uploaded images directory
    └── students/          # Student face images
        └── <student_id>/  # Organized by student ID
```

## Configuration

The application uses the following default configuration:

- **Host**: `0.0.0.0` (accessible from network)
- **Port**: `5000`
- **Max Upload Size**: 16 MB
- **Allowed Image Formats**: PNG, JPG, JPEG, BMP
- **Database**: JSON file (can be upgraded to SQLite/PostgreSQL)

## Example: Register Student with cURL

```bash
curl -X POST "http://localhost:5000/api/students/" \
  -F "student_id=S12345" \
  -F "name=John Doe" \
  -F "email=john@university.edu" \
  -F "department=Computer Science" \
  -F "year=3" \
  -F "image=@/path/to/face_image.jpg"
```

## Example: Register Student with Python

```python
import requests

url = "http://localhost:5000/api/students/"

data = {
    'student_id': 'S12345',
    'name': 'John Doe',
    'email': 'john@university.edu',
    'department': 'Computer Science',
    'year': 3
}

files = {
    'image': open('face_image.jpg', 'rb')
}

response = requests.post(url, data=data, files=files)
print(response.json())
```

## Next Steps

- Integrate FaceNet model for face recognition
- Add authentication and authorization
- Implement attendance tracking and reporting
- Add database migrations
- Deploy to production server

## Environment Variables

You can configure the application using environment variables:

```bash
export FLASK_ENV=development
export SECRET_KEY=your-secret-key
export DATABASE_URL=sqlite:///students.db
```

## Security Notes

⚠️ **Important for Production**:

- Change the `SECRET_KEY` in production
- Enable HTTPS
- Add authentication (JWT tokens)
- Implement rate limiting
- Use a proper database (PostgreSQL, MySQL)
- Add input sanitization
- Implement file scanning for malware

## License

MIT License
