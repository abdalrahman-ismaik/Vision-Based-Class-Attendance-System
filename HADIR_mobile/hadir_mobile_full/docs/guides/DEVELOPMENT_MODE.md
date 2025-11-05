# Development Mode Configuration

## Overview
This document describes the development mode feature that allows developers to skip authentication and use pre-filled mock data for faster testing of the pose capture functionality.

## Changes Made

### 1. Main Configuration (`lib/main.dart`)
Added a global development mode flag:
```dart
const bool kDevelopmentMode = true;
```

**To enable/disable development mode:**
- Set `kDevelopmentMode = true` - Skip login, go directly to registration with mock data
- Set `kDevelopmentMode = false` - Normal app flow with authentication

### 2. Router Configuration (`lib/app/router/auth_router.dart`)
Modified the `simpleRouter` to:
- Start at `/registration` instead of `/login` when in development mode
- Pass `developmentMode` parameter to `RegistrationScreen`
- Automatically redirect root path based on mode

### 3. Registration Screen (`lib/features/registration/presentation/screens/registration_screen.dart`)
Enhanced the registration screen to:
- Accept a `developmentMode` parameter
- Pre-fill form fields with mock data when in development mode
- Fixed missing `capturedFramesCount` parameter in `RegistrationSession`

## Mock Data Used

When `kDevelopmentMode = true`, the following mock data is automatically filled:

| Field | Mock Value |
|-------|------------|
| Student ID | STU2025001 |
| First Name | John |
| Last Name | Doe |
| Email | john.doe@university.edu |
| Phone | +971501234567 |
| Major | Computer Science |
| Nationality | United Arab Emirates |
| Date of Birth | January 15, 2000 |
| Gender | Male |
| Academic Level | Undergraduate |
| Enrollment Year | 2024 |

## Usage

### For Development (Testing Pose Capture)
1. Ensure `kDevelopmentMode = true` in `lib/main.dart`
2. Run the app: `flutter run`
3. App will start directly at the registration screen with pre-filled data
4. Click "Next" to proceed to the pose capture screen

### For Production/Demo
1. Set `kDevelopmentMode = false` in `lib/main.dart`
2. Run the app: `flutter run`
3. App will start at the login screen
4. Follow normal authentication flow

## Benefits

✅ **Faster Testing** - Skip login and form filling every time
✅ **Consistent Data** - Same mock data for reproducible tests
✅ **Easy Toggle** - Single flag to enable/disable
✅ **No Code Duplication** - Same registration screen for both modes
✅ **Production Safe** - Easy to disable before deployment

## Important Notes

⚠️ **Remember to set `kDevelopmentMode = false` before production release!**

⚠️ The mock data is for development only and should not be used in production.

⚠️ Authentication is completely bypassed in development mode.

## Future Enhancements

Consider these improvements:
- Add environment-based configuration (dev/staging/prod)
- Support multiple mock user profiles
- Add mock data randomization option
- Integration with feature flags service
