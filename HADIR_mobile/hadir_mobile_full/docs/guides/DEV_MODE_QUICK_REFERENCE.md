# 🚀 Development Mode Quick Reference

## ❗ Important: Hot Restart Required

When testing changes to the Student ID validation or development mode features, you **MUST use Hot Restart** instead of Hot Reload.

### Why?
Flutter's hot reload doesn't refresh:
- `const` values (like `kDevelopmentMode`)
- Initial widget state
- Constructor parameters
- Pre-filled form data

### How to Hot Restart

#### Method 1: VS Code Keyboard Shortcut
```
Windows/Linux: Ctrl + Shift + F5
Mac: Cmd + Shift + F5
```

#### Method 2: VS Code Command Palette
1. Press `Ctrl+Shift+P` (Windows/Linux) or `Cmd+Shift+P` (Mac)
2. Type "Flutter: Hot Restart"
3. Press Enter

#### Method 3: Terminal Command
```bash
# Stop the current app (Ctrl+C)
# Then run again:
flutter run
```

#### Method 4: VS Code Debug Toolbar
Click the green circular arrow icon (🔄) in the debug toolbar

---

## 🧪 Testing Student ID Validation

### Expected Behavior

#### 1. Student ID Field
```
┌─────────────────────────────────┐
│ Student ID *                    │
│ ┌─────────────────────────────┐ │
│ │ 1000 | 12345               │ │  ← Fixed "1000" + 5 digits input
│ └─────────────────────────────┘ │
│ Enter the last 5 digits         │
└─────────────────────────────────┘
```

**What to check:**
- ✅ Prefix "1000" is displayed and cannot be edited
- ✅ User can only enter 5 digits after the prefix
- ✅ Counter shows "0/5" characters
- ✅ Only numeric input allowed

#### 2. Email Field (Auto-generated)
```
┌─────────────────────────────────┐
│ Email Address *                 │
│ ┌─────────────────────────────┐ │
│ │ 100012345@ku.ac.ae          │ │  ← Grey, read-only
│ └─────────────────────────────┘ │
│ Auto-generated from Student ID  │
└─────────────────────────────────┘
```

**What to check:**
- ✅ Email updates instantly as you type Student ID
- ✅ Email text appears in grey color
- ✅ Cannot click or edit the email field
- ✅ Format is always `1000XXXXX@ku.ac.ae`

#### 3. Real-time Validation
**Test Sequence:**
1. Clear Student ID field → Email becomes empty
2. Type "1" → Email still empty (needs 5 digits)
3. Type "12" → Email still empty
4. Type "123" → Email still empty
5. Type "1234" → Email still empty
6. Type "12345" → Email becomes "100012345@ku.ac.ae" ✅

---

## 🎯 Development Mode Features

### Current Settings (in `lib/main.dart`)
```dart
const bool kDevelopmentMode = true;  // Development mode ENABLED
```

### What Development Mode Does

#### ✅ Enabled Features
1. **Skip Login Screen**
   - App starts directly at Registration Screen
   - No authentication required

2. **Pre-filled Mock Data**
   - Student ID: `12345` (shown as "1000 | 12345")
   - First Name: `John`
   - Last Name: `Doe`
   - Email: `100012345@ku.ac.ae` (auto-generated)
   - Phone: `+971501234567`
   - Major: `Computer Science`
   - Nationality: `United Arab Emirates`
   - Date of Birth: `January 15, 2000`
   - Gender: `Male`
   - Academic Level: `Undergraduate`
   - Enrollment Year: `2024`

3. **Fast Testing**
   - Click "Next" immediately to test pose capture
   - No need to fill form manually every time

### How to Toggle Development Mode

#### Enable Development Mode (Current State)
```dart
// lib/main.dart line 9
const bool kDevelopmentMode = true;
```
**Result:** 
- ✅ Start at registration screen
- ✅ Form pre-filled with mock data
- ✅ No login required

#### Disable Development Mode (Production)
```dart
// lib/main.dart line 9
const bool kDevelopmentMode = false;
```
**Result:**
- ❌ Start at login screen
- ❌ Empty registration form
- ❌ Authentication required

**⚠️ Remember:** After changing `kDevelopmentMode`, you MUST use **Hot Restart**!

---

## 🧹 Testing Checklist

### Before Testing
- [ ] Latest code pulled from Git
- [ ] `flutter pub get` executed
- [ ] No compilation errors
- [ ] `kDevelopmentMode = true` in `lib/main.dart`

### During Testing
- [ ] Use Hot Restart (NOT hot reload)
- [ ] Check Student ID prefix shows "1000"
- [ ] Verify 5-digit input limitation
- [ ] Test email auto-generation
- [ ] Confirm email is read-only (grey color)
- [ ] Try changing Student ID → Email updates instantly
- [ ] Try clicking Email field → Cannot edit

### After Code Changes
- [ ] Use Hot Restart (Ctrl+Shift+F5)
- [ ] Re-verify all features
- [ ] Check console for errors

---

## 🐛 Common Issues

### Issue 1: Changes Not Showing
**Symptom:** Updated Student ID validation doesn't appear

**Solution:** Use Hot Restart instead of Hot Reload
```
Ctrl + Shift + F5  (Windows/Linux)
Cmd + Shift + F5   (Mac)
```

### Issue 2: Mock Data Not Pre-filled
**Symptom:** Registration form is empty despite development mode enabled

**Checklist:**
1. ✅ `kDevelopmentMode = true` in `lib/main.dart`?
2. ✅ Used Hot Restart after changing the flag?
3. ✅ App started at `/registration` route?
4. ✅ No errors in debug console?

### Issue 3: Email Not Auto-generating
**Symptom:** Email field stays empty when typing Student ID

**Checklist:**
1. ✅ Typed exactly 5 digits?
2. ✅ No letters or special characters?
3. ✅ Email validation passing?

**Debug:**
```dart
// Check console for this line when typing:
// "Auto-generating email for student ID: 1000XXXXX"
```

### Issue 4: Student ID Prefix Not Showing
**Symptom:** "1000" prefix doesn't appear

**Checklist:**
1. ✅ Used Hot Restart?
2. ✅ Check `registration_screen.dart` line 619
3. ✅ `prefixText: '1000'` is set?

---

## 📝 Implementation Details

### Files Involved
1. **`lib/main.dart`**
   - Contains `kDevelopmentMode` flag

2. **`lib/app/router/auth_router.dart`**
   - Routes to registration screen when in dev mode
   - Passes `developmentMode` parameter

3. **`lib/features/registration/presentation/screens/registration_screen.dart`**
   - Lines 619-649: Student ID field implementation
   - Lines 689-707: Email field implementation
   - Lines 106-113: Mock data pre-fill logic

### Validation Logic

#### Student ID Validation
```dart
validator: (value) {
  if (value == null || value.trim().isEmpty) {
    return 'Please enter the 5 digits after 1000';
  }
  if (!RegExp(r'^\d{5}$').hasMatch(value)) {
    return 'Please enter exactly 5 digits';
  }
  return null;
}
```

#### Email Auto-generation
```dart
onChanged: (value) {
  if (value.isNotEmpty && RegExp(r'^\d{5}$').hasMatch(value)) {
    final fullStudentId = '1000$value';
    _emailController.text = '$fullStudentId@ku.ac.ae';
  } else {
    _emailController.text = '';
  }
}
```

#### Email Validation
```dart
validator: (value) {
  if (value == null || value.trim().isEmpty) {
    return 'Please enter a valid student ID first';
  }
  if (!RegExp(r'^1000\d{5}@ku\.ac\.ae$').hasMatch(value)) {
    return 'Email format should be studentid@ku.ac.ae';
  }
  return null;
}
```

---

## 🎓 Additional Resources

- [STUDENT_VALIDATION_RULES.md](STUDENT_VALIDATION_RULES.md) - Complete validation documentation
- [DEVELOPMENT_MODE.md](DEVELOPMENT_MODE.md) - Development mode configuration
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - General troubleshooting guide
- [README.md](README.md) - Project overview and setup

---

**Last Updated:** October 20, 2025  
**Version:** 1.0.0
