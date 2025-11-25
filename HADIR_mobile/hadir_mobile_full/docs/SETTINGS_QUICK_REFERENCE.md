# 🎯 Backend Settings & Error Logs - Quick Reference

## 📱 What You Got

### 3 New Screens
1. **Settings Screen** - Main settings hub
2. **Backend Settings** - Configure server connection
3. **Error Logs** - View app diagnostics

### 2 New Services  
1. **BackendConfigService** - Manages backend URL
2. **ErrorLogService** - Logs all errors

## 🚀 Quick Start

### Step 1: Add Settings to Navigation
Add this button to your dashboard or app bar:

```dart
import 'package:hadir_mobile_full/features/settings/settings_screen.dart';

IconButton(
  icon: Icon(Icons.settings),
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const SettingsScreen()),
  ),
)
```

### Step 2: Configure Backend
1. Tap Settings icon
2. Tap "Backend Settings"  
3. Enter your server URL
4. Tap "Test Connection"
5. Tap "Save Configuration"

### Step 3: View Logs
1. Tap Settings icon
2. Tap "Error Logs"
3. View all app errors and diagnostics

## 💡 Key Features

| Feature | What It Does |
|---------|--------------|
| 🌐 Backend URL Config | Set server address dynamically |
| 🔌 Connection Test | Verify backend is reachable |
| 📊 Error Logs | View all app errors with details |
| 🔍 Filters | Filter logs by severity/category |
| 📋 Copy Logs | Copy error details to clipboard |
| 🗑️ Clear Logs | Remove old or all logs |
| 💾 Persistence | Settings saved across restarts |
| 📈 Statistics | View error count dashboard |

## 🎨 Quick Presets

Tap presets in Backend Settings for instant configuration:

- **Android Emulator**: `http://10.0.2.2:5000/api`
- **iOS Simulator**: `http://localhost:5000/api`  
- **Physical Device**: `http://YOUR_IP:5000/api`

## 📝 Log Severity Levels

| Icon | Level | Use Case |
|------|-------|----------|
| ℹ️ | Info | App started, config changed |
| ⚠️ | Warning | Connection issues, retries |
| ❌ | Error | Operation failed |
| 🚨 | Critical | System failure |

## 🔧 Developer Usage

### Log an Error
```dart
await ErrorLogService.instance.logError(
  'Category',
  'Message',
  stackTrace: stackTrace,
  context: {'key': 'value'},
);
```

### Get Backend URL
```dart
final url = BackendConfigService.instance.backendUrl;
```

### Test Connection
```dart
final result = await BackendConfigService.instance.testConnection();
if (result.success) print('Connected!');
```

## ✅ What's Automatic

The app automatically:
- ✅ Initializes services on startup
- ✅ Logs important events
- ✅ Uses configured backend URL
- ✅ Persists settings
- ✅ Tracks connection history

## 📁 Files Added

```
lib/
├── core/services/
│   ├── backend_config_service.dart
│   └── error_log_service.dart
└── features/settings/
    ├── settings_screen.dart
    ├── backend_settings_screen.dart
    └── error_logs_screen.dart
```

## 🐛 Troubleshooting

**Connection fails?**
- Check backend is running
- Verify URL includes `/api`
- Check same network (physical device)

**Logs not showing?**
- Check services initialized in main.dart
- Restart app
- Check console for errors

**Settings not saving?**
- Check device storage
- Reinstall if needed

## 📚 Documentation

- `BACKEND_SETTINGS_GUIDE.md` - Full documentation
- `SETTINGS_IMPLEMENTATION_SUMMARY.md` - Technical details
- `SETTINGS_NAVIGATION_GUIDE.md` - Integration guide

## 🎯 Next Steps

1. ✅ Run `flutter run`
2. ✅ Add settings icon to your UI
3. ✅ Configure backend URL
4. ✅ Test connection
5. ✅ Start using the app!

---

**Need Help?** Check Error Logs screen for diagnostic info!
