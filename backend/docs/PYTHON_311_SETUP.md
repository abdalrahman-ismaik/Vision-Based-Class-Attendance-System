# Backend Python 3.11 Setup Guide

## Issue
Backend fails to start with Python 3.13 due to PyTorch compatibility:
```
torch==2.9.0 is incompatible with Python 3.13
```

## Solution: Use Python 3.11

### Step 1: Install Python 3.11

1. **Download Python 3.11:**
   - Go to: https://www.python.org/downloads/
   - Download: Python 3.11.9 (latest 3.11 version)
   - Choose: Windows installer (64-bit)

2. **Install:**
   - Run installer
   - ✅ Check "Add Python 3.11 to PATH"
   - Choose "Install Now"

3. **Verify Installation:**
   ```powershell
   py -3.11 --version
   # Should show: Python 3.11.9
   ```

---

### Step 2: Create New Virtual Environment with Python 3.11

```powershell
# Navigate to project root
cd c:\Users\4bais\Vision-Based-Class-Attendance-System

# Remove old venv (backup if needed)
# Option A: Delete completely
Remove-Item -Recurse -Force .venv

# Option B: Rename as backup
Rename-Item .venv .venv_old_python313

# Create new venv with Python 3.11
py -3.11 -m venv .venv

# Activate new venv
.\.venv\Scripts\Activate.ps1

# Verify Python version in venv
python --version
# Should show: Python 3.11.9
```

---

### Step 3: Install Backend Dependencies

```powershell
# Still in activated venv
cd backend

# Install requirements
pip install -r requirements.txt

# This will install:
# - torch==2.9.0 (compatible with Python 3.11)
# - torchvision==0.24.0
# - Flask and all other dependencies
```

**Expected output:**
```
Successfully installed torch-2.9.0 torchvision-0.24.0 ...
```

---

### Step 4: Start Backend

```powershell
# Still in backend folder with venv activated
python app.py
```

**Expected output:**
```
 * Serving Flask app 'app'
 * Debug mode: on
WARNING: This is a development server.
 * Running on http://127.0.0.1:5000
 * Running on http://172.18.103.83:5000
```

---

## Quick Command Summary

**All in one go:**
```powershell
# From project root
cd c:\Users\4bais\Vision-Based-Class-Attendance-System

# Create new Python 3.11 venv
py -3.11 -m venv .venv

# Activate
.\.venv\Scripts\Activate.ps1

# Install deps
cd backend
pip install -r requirements.txt

# Run backend
python app.py
```

---

## Troubleshooting

### "py -3.11: command not found"
**Problem:** Python 3.11 not installed or not in PATH

**Fix:**
1. Install Python 3.11 from python.org
2. During installation, check "Add to PATH"
3. Restart PowerShell

---

### "pip install fails"
**Problem:** Network issue or pip needs upgrade

**Fix:**
```powershell
python -m pip install --upgrade pip
pip install -r requirements.txt
```

---

### "torch still incompatible"
**Problem:** Wrong Python version in venv

**Check:**
```powershell
python --version
# Must show 3.11.x, not 3.13.x
```

**Fix:** Recreate venv with correct Python:
```powershell
deactivate
Remove-Item -Recurse .venv
py -3.11 -m venv .venv
.\.venv\Scripts\Activate.ps1
```

---

## Alternative: Use Conda (If You Have It)

```powershell
# Create conda environment with Python 3.11
conda create -n hadir python=3.11 -y

# Activate
conda activate hadir

# Install requirements
cd backend
pip install -r requirements.txt

# Run
python app.py
```

---

## After Backend is Running

1. **Test backend health:**
   ```powershell
   # In browser or new terminal
   curl http://localhost:5000/api/docs
   ```

2. **Update Flutter backend URL** (if needed):
   - File: `lib/core/services/backend_registration_service.dart`
   - Check line 52: `backendBaseUrl`
   - For Android emulator: `http://10.0.2.2:5000/api`

3. **Run Flutter app:**
   ```powershell
   cd ..\HADIR_mobile\hadir_mobile_full
   flutter run
   ```

4. **Test registration:**
   - Register student
   - Should see ✅ "Student registered successfully!"
   - Backend console should show: "Student registered: XXX"

---

## Success Checklist

- [ ] Python 3.11 installed
- [ ] New .venv created with Python 3.11
- [ ] `pip install -r requirements.txt` completed
- [ ] Backend starts without errors
- [ ] Backend shows "Running on http://..."
- [ ] Flask app accessible at http://localhost:5000/api/docs

---

**Estimated Time:** 10-15 minutes (including Python 3.11 download/install)

**Next:** Once backend is running, test with Flutter app!
