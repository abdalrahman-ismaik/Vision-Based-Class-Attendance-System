# How to Add Settings to Your App Navigation

## Quick Integration Guide

The settings screens have been created, but you need to add them to your app's navigation. Here's how:

## Option 1: Add to Dashboard/Home Screen

Add a settings button/icon to your dashboard that navigates to the settings screen:

```dart
// In your dashboard screen
IconButton(
  icon: Icon(Icons.settings),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  },
)
```

Don't forget to import:
```dart
import 'package:hadir_mobile_full/features/settings/settings_screen.dart';
```

## Option 2: Add to App Drawer

If your app has a navigation drawer:

```dart
// In your drawer widget
ListTile(
  leading: Icon(Icons.settings),
  title: Text('Settings'),
  onTap: () {
    Navigator.pop(context); // Close drawer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  },
)
```

## Option 3: Add to Bottom Navigation Bar

If using a bottom navigation bar, add settings as one of the tabs:

```dart
// In your main screen with BottomNavigationBar
BottomNavigationBarItem(
  icon: Icon(Icons.settings),
  label: 'Settings',
)

// And in the body:
pages: [
  DashboardPage(),
  RegistrationPage(),
  SettingsScreen(), // Add this
]
```

## Option 4: Direct Access for Testing

For quick testing, you can temporarily make it the initial route:

```dart
// In main.dart or your router
MaterialApp(
  home: SettingsScreen(), // Temporary for testing
)
```

## Example: Adding to a Typical Dashboard

Here's a complete example of adding settings to a dashboard screen:

```dart
import 'package:flutter/material.dart';
import 'package:hadir_mobile_full/features/settings/settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('HADIR Dashboard'),
        actions: [
          // Add settings icon to app bar
          IconButton(
            icon: Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Your dashboard content here
            
            // Or add a settings card
            Card(
              child: ListTile(
                leading: Icon(Icons.settings),
                title: Text('Settings'),
                subtitle: Text('Configure app and view logs'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Accessing Individual Screens Directly

You can also navigate directly to specific settings screens:

```dart
// Navigate to Backend Settings
import 'package:hadir_mobile_full/features/settings/backend_settings_screen.dart';

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const BackendSettingsScreen(),
  ),
);

// Navigate to Error Logs
import 'package:hadir_mobile_full/features/settings/error_logs_screen.dart';

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const ErrorLogsScreen(),
  ),
);
```

## Using GoRouter (if you're using it)

If your app uses GoRouter for navigation:

```dart
// Add to your route configuration
GoRoute(
  path: '/settings',
  builder: (context, state) => const SettingsScreen(),
),
GoRoute(
  path: '/settings/backend',
  builder: (context, state) => const BackendSettingsScreen(),
),
GoRoute(
  path: '/settings/logs',
  builder: (context, state) => const ErrorLogsScreen(),
),

// Navigate using:
context.go('/settings');
```

## Testing the Integration

1. **Run the app**: `flutter run`
2. **Find your navigation entry** (button, drawer item, etc.)
3. **Tap to open settings**
4. **Verify screens load** and navigation works
5. **Test backend configuration**
6. **Generate some logs** and verify they appear

## Troubleshooting

### Import Errors
Make sure you have the correct imports:
```dart
import 'package:hadir_mobile_full/features/settings/settings_screen.dart';
import 'package:hadir_mobile_full/features/settings/backend_settings_screen.dart';
import 'package:hadir_mobile_full/features/settings/error_logs_screen.dart';
```

### Navigation Not Working
- Check that Navigator is available in your context
- Ensure you're using MaterialApp or similar
- Verify the import paths are correct

### Screens Not Found
- Run `flutter pub get` to ensure dependencies are installed
- Rebuild the app if hot reload doesn't work
- Check that files exist in `lib/features/settings/`

## Current App Structure

Based on your project, you likely want to add settings access from:
- ✅ Dashboard screen (recommended)
- ✅ App drawer if you have one
- ✅ Profile/user menu

Look for files like:
- `lib/features/dashboard/presentation/pages/` or similar
- Main navigation widget
- App drawer widget

Add the navigation code there using the examples above.
