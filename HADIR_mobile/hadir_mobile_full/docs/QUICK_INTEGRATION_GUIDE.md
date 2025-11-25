# Quick Integration Guide: Backend Upload

**Goal:** Add backend upload to registration screen  
**Time:** 15 minutes  
**File:** `lib/features/registration/presentation/screens/registration_screen.dart`

---

## Step 1: Add Imports (Top of File)

Add these imports after existing imports:

```dart
import 'dart:io';
import 'package:hadir_mobile_full/core/providers/backend_providers.dart';
import 'package:hadir_mobile_full/core/services/backend_registration_service.dart';
```

---

## Step 2: Modify `_completeRegistration()` Method

Find the `_completeRegistration()` method (around line 267).

**ADD THIS CODE** right after saving frames to database (after the `for` loop that calls `insertFrame`):

```dart
      // ==================== NEW: Backend Upload ====================
      // Try to upload to backend (optional - works offline if backend unavailable)
      try {
        // Select best quality image for backend
        final bestFrame = _capturedFrames.reduce((a, b) => 
          a.qualityScore > b.qualityScore ? a : b
        );
        final imageFile = File(bestFrame.imageFilePath);
        
        // Close "Saving..." dialog
        if (mounted) {
          Navigator.of(context).pop();
        }
        
        // Show "Uploading to server..." dialog
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Uploading to server...'),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        
        // Upload to backend
        final backendService = ref.read(backendRegistrationServiceProvider);
        final result = await backendService.registerStudent(
          student: student,
          imageFile: imageFile,
        );
        
        // Close "Uploading..." dialog
        if (mounted) {
          Navigator.of(context).pop();
        }
        
        // Show result
        if (mounted) {
          if (result.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ ${result.message}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('⚠️ Saved locally. Backend: ${result.error}'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'OK',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );
          }
        }
      } catch (e) {
        // Backend upload failed - continue anyway (offline mode)
        print('[REGISTRATION] Backend upload failed: $e');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Saved locally (offline mode)'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
      // ==================== END: Backend Upload ====================
```

**IMPORTANT:** Add this code BEFORE the existing line that closes the loading dialog and navigates to dashboard.

---

## Step 3: Update Existing Dialog Close Logic

Find this existing code (around line 400):

```dart
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Registration completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
```

**REMOVE** the `Navigator.of(context).pop();` line - we already close it in the backend upload section.

**CHANGE** the success message to:

```dart
      // Show success message (registration saved locally)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Student registered successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
```

---

## Step 4: (Optional) Add Backend Status Indicator

In the `build()` method, find the `AppBar` widget and add this to `actions`:

```dart
AppBar(
  title: const Text('Register Student'),
  actions: [
    // Backend status indicator
    Consumer(
      builder: (context, ref, child) {
        final backendStatus = ref.watch(backendAvailabilityProvider);
        
        return backendStatus.when(
          data: (available) => Tooltip(
            message: available ? 'Backend online' : 'Backend offline',
            child: Icon(
              available ? Icons.cloud_done : Icons.cloud_off,
              color: available ? Colors.green : Colors.grey,
            ),
          ),
          loading: () => const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (_, __) => const Icon(Icons.cloud_off, color: Colors.red),
        );
      },
    ),
    const SizedBox(width: 16),
  ],
),
```

---

## 🧪 Testing

### Test 1: With Backend Running
```powershell
# Terminal 1: Start backend
cd backend
python app.py

# Terminal 2: Run app
cd HADIR_mobile/hadir_mobile_full
flutter run
```

**Expected:**
1. Register student
2. See "Saving registration..." dialog
3. See "Uploading to server..." dialog
4. See ✅ "Student registered successfully!" (green)
5. Backend console shows student received
6. `backend/database.json` has new student

### Test 2: Without Backend (Offline Mode)
```powershell
# Don't start backend, just run app
flutter run
```

**Expected:**
1. Register student
2. See "Saving registration..." dialog
3. See "Uploading to server..." dialog (brief)
4. See ⚠️ "Saved locally. Backend: Cannot connect..." (orange)
5. Student saved to local database
6. Can still use app normally

---

## 🎯 Success Criteria

- [ ] App compiles without errors
- [ ] Registration saves to local database
- [ ] Backend upload attempted automatically
- [ ] Success message shown when backend available
- [ ] Warning message shown when backend unavailable
- [ ] App doesn't crash if backend offline
- [ ] Backend processes face (check `database.json`)

---

## 🐛 Troubleshooting

### "Cannot connect to backend"
**Fix:** Update backend URL in `backend_registration_service.dart`:

```dart
// For Android Emulator
static const String backendBaseUrl = 'http://10.0.2.2:5000/api';

// For Physical Device (find your IP with ipconfig)
static const String backendBaseUrl = 'http://192.168.1.XXX:5000/api';
```

### Import errors
Make sure these files exist:
- `lib/core/services/backend_registration_service.dart` ✅
- `lib/core/providers/backend_providers.dart` ✅

### Backend returns 409 (Conflict)
This means student already exists. **This is OK!** The code treats it as success.

---

## 📝 Summary of Changes

**Files Modified:** 1  
**Lines Added:** ~80 lines  
**Lines Removed:** ~2 lines  

**What Changed:**
- Added backend upload after local save
- Added loading dialogs for better UX
- Added error handling for offline mode
- Added success/error messages

**What Stayed Same:**
- Local database save (works offline)
- Form validation
- Face capture flow
- Navigation logic

---

**Ready to implement!** 🚀

Just follow steps 1-3, test, and you're done!
