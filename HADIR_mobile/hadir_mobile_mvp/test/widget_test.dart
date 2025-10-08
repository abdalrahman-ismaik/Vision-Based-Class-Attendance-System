// Basic widget test for HADIR Mobile MVP
import 'package:flutter_test/flutter_test.dart';
import 'package:hadir_mobile_mvp/main.dart';

void main() {
  testWidgets('App launches with login screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HadirMVPApp());

    // Verify that login screen is displayed
    expect(find.text('Administrator Login'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
