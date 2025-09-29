// Flutter LMS App Widget Tests
//
// These tests verify the core functionality of the LMS application,
// including app initialization, navigation, and main screen components.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertest/main.dart';
import 'package:fluttertest/student/screens/auth/LoginPage.dart';

void main() {
  group('LMS App Tests', () {
    testWidgets('App should launch and display LoginPage', (
      WidgetTester tester,
    ) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const ScreenPage());

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Verify that LoginPage is displayed as the home page
      expect(find.byType(LoginPage), findsOneWidget);

      // Verify that the app has no debug banner
      final MaterialApp materialApp = tester.widget(find.byType(MaterialApp));
      expect(materialApp.debugShowCheckedModeBanner, false);
    });

    testWidgets('App should have correct route configuration', (
      WidgetTester tester,
    ) async {
      // Build our app
      await tester.pumpWidget(const ScreenPage());
      await tester.pumpAndSettle();

      // Get the MaterialApp widget to check routes
      final MaterialApp materialApp = tester.widget(find.byType(MaterialApp));

      // Verify that essential routes are configured
      expect(materialApp.routes, isNotNull);
      expect(materialApp.routes!.containsKey('/loginpage'), true);
      expect(materialApp.routes!.containsKey('/signuppage'), true);
      expect(materialApp.routes!.containsKey('/interestpage'), true);
    });

    testWidgets('ScreenPage should be a StatelessWidget', (
      WidgetTester tester,
    ) async {
      // Create an instance of ScreenPage
      const screenPage = ScreenPage();

      // Verify it's a StatelessWidget
      expect(screenPage, isA<StatelessWidget>());

      // Build the widget to ensure it renders without errors
      await tester.pumpWidget(screenPage);
      await tester.pumpAndSettle();

      // Verify no exceptions were thrown during build
      expect(tester.takeException(), isNull);
    });
  });
}
