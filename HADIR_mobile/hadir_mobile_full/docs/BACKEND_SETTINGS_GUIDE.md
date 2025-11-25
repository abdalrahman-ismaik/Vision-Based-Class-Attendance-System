# Backend Connection and Error Logging Features

## Overview

New settings features have been added to the HADIR Mobile app to allow users to:
1. **Configure Backend Connection** - Set and test the backend server URL
2. **View Error Logs** - Monitor application errors and diagnostics

## Features

### 1. Backend Settings Screen

**Location**: Settings → Backend Settings

**Features**:
- Configure backend server URL
- Test connection to backend
- Quick preset URLs for different environments:
  - Android Emulator
  - iOS Simulator
  - Physical Device
- View connection history
- Reset to default configuration

**How to Use**:
1. Open the app and navigate to Settings
2. Tap on "Backend Settings"
3. Enter your backend server URL (e.g., `http://192.168.1.100:5000/api`)
4. Tap "Test Connection" to verify the backend is reachable
5. If successful, tap "Save Configuration"

**Quick Presets**:
- Use the preset chips to quickly select common configurations
- Android Emulator: `http://10.0.2.2:5000/api`
- iOS Simulator: `http://localhost:5000/api`
- Physical Device: Update IP address as needed

### 2. Error Logs Screen

**Location**: Settings → Error Logs

**Features**:
- View all application errors with timestamps
- Filter by severity level (Info, Warning, Error, Critical)
- Filter by category (Application, Backend, Database, etc.)
- View detailed information for each log entry
- Copy log details to clipboard
- Clear logs (all or by age)
- Statistics dashboard showing error counts

**Log Severity Levels**:
- ℹ️ **Info** - Informational messages (app started, configuration changed)
- ⚠️ **Warning** - Warning messages (connection test failed)
- ❌ **Error** - Error messages (operation failed)
- 🚨 **Critical** - Critical errors (system failure)

**How to Use**:
1. Open Settings → Error Logs
2. Use the dropdown filters to narrow down logs
3. Tap on any log entry to see full details
4. Use the menu (⋮) to clear old or all logs

### 3. Settings Main Menu

**Location**: Accessible from dashboard or app drawer

**Sections**:
- **Backend Configuration**
  - Backend Settings
  - Error Logs
- **Developer Tools**
  - Database Tools
- **About**
  - Version Info
  - App Information

## Technical Implementation

### Services

#### BackendConfigService
- Manages backend URL configuration
- Persists settings using SharedPreferences
- Provides connection testing functionality
- Auto-initialized on app startup

#### ErrorLogService
- Centralized error logging
- Stores up to 500 log entries
- Persists logs across app restarts
- Provides filtering and search capabilities
- Auto-initialized on app startup

### Integration with Existing Code

The `BackendRegistrationService` has been updated to automatically use the configured backend URL from `BackendConfigService`. No changes required in existing registration code.

### Automatic Logging

The app automatically logs:
- App startup/shutdown
- Database operations
- Backend connection attempts
- Registration successes/failures
- Configuration changes

## Usage Examples

### Configure Backend for Physical Device

```dart
// The settings screen handles this, but programmatically:
final configService = await BackendConfigService.initialize();
await configService.setBackendUrl('http://192.168.1.100:5000/api');
final result = await configService.testConnection();
if (result.success) {
  print('Connected!');
}
```

### Log Custom Errors

```dart
// Log an error
await ErrorLogService.instance.logError(
  'Registration',
  'Failed to process face image',
  stackTrace: stackTrace,
  context: {'studentId': 'FP123456'},
);

// Log a warning
await ErrorLogService.instance.logWarning(
  'Camera',
  'Low light conditions detected',
  context: {'brightness': '0.3'},
);
```

## Dependencies Added

- `shared_preferences: ^2.2.2` - For persisting configuration and logs

## Files Created/Modified

### New Files
- `lib/core/services/backend_config_service.dart` - Backend configuration management
- `lib/core/services/error_log_service.dart` - Error logging service
- `lib/features/settings/backend_settings_screen.dart` - Backend settings UI
- `lib/features/settings/error_logs_screen.dart` - Error logs viewer UI
- `lib/features/settings/settings_screen.dart` - Main settings menu

### Modified Files
- `lib/main.dart` - Initialize services on app startup
- `lib/core/services/backend_registration_service.dart` - Use configurable URL
- `lib/app/theme/app_colors.dart` - Added missing color constants
- `pubspec.yaml` - Added shared_preferences dependency

## Testing

### Test Backend Connection
1. Open Settings → Backend Settings
2. Enter a test URL
3. Tap "Test Connection"
4. Verify success/failure message appears

### Test Error Logging
1. Trigger an error (e.g., try registering without backend)
2. Open Settings → Error Logs
3. Verify the error appears in the list
4. Tap on the error to view details

### Test Persistence
1. Configure backend URL and save
2. Close and restart the app
3. Open Backend Settings
4. Verify URL is still configured

## Troubleshooting

### Backend Connection Fails
- Verify the backend server is running
- Check the URL format (must include `/api` suffix)
- Ensure device and backend are on the same network (for physical devices)
- Check firewall settings

### Logs Not Appearing
- Verify ErrorLogService is initialized in main.dart
- Check console for initialization errors
- Try clearing app data and reinstalling

### URL Not Persisting
- Check SharedPreferences permissions
- Verify device storage is not full
- Look for initialization errors in logs

## Future Enhancements

Potential improvements:
- Export logs to file
- Remote logging to backend
- Push notifications for critical errors
- Network diagnostics tools
- Performance monitoring
- Crash reporting integration

## Support

For issues or questions:
1. Check the Error Logs screen for diagnostic information
2. Review the logs for specific error messages
3. Verify backend configuration in Settings
4. Consult the app documentation
