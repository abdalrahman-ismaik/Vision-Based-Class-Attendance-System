// Basic widget test for HADIR Mobile Full Version

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hadir_mobile_full/main.dart';

void main() {
  testWidgets('HADIR app loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: HadirApp(),
      ),
    );

    // Verify that the app title is displayed
    expect(find.text('HADIR Mobile - Full Version'), findsOneWidget);
    expect(find.text('AI-Enhanced Student Registration System'), findsOneWidget);
    expect(find.text('Clean Architecture Implementation'), findsOneWidget);
    
    // Verify that the face icon is displayed
    expect(find.byIcon(Icons.face), findsOneWidget);
  });
}
