# HADIR_web Setup Script
# Automates the setup process for HADIR_web

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  HADIR_web Setup Script" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Check if we're in the correct directory
if (-not (Test-Path "app.py")) {
    Write-Host "Error: Please run this script from the HADIR_web directory" -ForegroundColor Red
    exit 1
}

# Step 1: Check Python
Write-Host ""
Write-Host "Step 1: Checking Python installation..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version 2>&1
    Write-Host "Python found: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "Python not found. Please install Python 3.8+ first." -ForegroundColor Red
    exit 1
}

# Step 2: Check backend
Write-Host ""
Write-Host "Step 2: Checking backend..." -ForegroundColor Yellow
if (Test-Path "..\backend\app.py") {
    Write-Host "Backend found at ..\backend\app.py" -ForegroundColor Green
} else {
    Write-Host "Backend not found. Ensure backend directory exists." -ForegroundColor Yellow
}

# Step 3: Check YuNet model
Write-Host ""
Write-Host "Step 3: Checking YuNet face detection model..." -ForegroundColor Yellow
$modelFile = "face_detection_yunet_2023mar.onnx"

if (Test-Path $modelFile) {
    Write-Host "YuNet model already exists" -ForegroundColor Green
} else {
    Write-Host "YuNet model not found" -ForegroundColor Yellow
    
    # Try to copy from demo
    $demoModel = "..\intro to ai demo\attendance_demo\$modelFile"
    if (Test-Path $demoModel) {
        Write-Host "   Copying from demo..." -ForegroundColor Cyan
        Copy-Item $demoModel . -ErrorAction Stop
        Write-Host "Model copied successfully" -ForegroundColor Green
    } else {
        Write-Host "   Downloading YuNet model..." -ForegroundColor Cyan
        $url = "https://github.com/opencv/opencv_zoo/raw/main/models/face_detection_yunet/face_detection_yunet_2023mar.onnx"
        try {
            Invoke-WebRequest -Uri $url -OutFile $modelFile
            Write-Host "Model downloaded successfully" -ForegroundColor Green
        } catch {
            Write-Host "Failed to download model. Please download manually from:" -ForegroundColor Red
            Write-Host "   $url" -ForegroundColor Yellow
            Write-Host "   and save it to the HADIR_web directory" -ForegroundColor Yellow
        }
    }
}

# Step 4: Install dependencies
Write-Host ""
Write-Host "Step 4: Installing Python dependencies..." -ForegroundColor Yellow
try {
    pip install -r requirements.txt
    Write-Host "Dependencies installed successfully" -ForegroundColor Green
} catch {
    Write-Host "Failed to install dependencies" -ForegroundColor Red
    Write-Host "   Try running manually: pip install -r requirements.txt" -ForegroundColor Yellow
}

# Step 5: Summary
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Setup Complete!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Start the backend (in another terminal):" -ForegroundColor White
Write-Host "   cd ..\backend" -ForegroundColor Cyan
Write-Host "   python app.py" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. Start HADIR_web:" -ForegroundColor White
Write-Host "   python app.py" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. Open in browser:" -ForegroundColor White
Write-Host "   http://127.0.0.1:5001" -ForegroundColor Cyan
Write-Host ""
Write-Host "For more information, see QUICKSTART.md" -ForegroundColor Yellow
Write-Host ""
