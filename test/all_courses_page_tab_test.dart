import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertest/student/screens/courses/AllCoursesPage_Tab.dart';

void main() {
  group('AllCoursesPageTab Tests', () {
    testWidgets('should display search bar and filter button', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AllCoursesPageTab(selectedLanguage: 'English'),
          ),
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Verify search bar is present
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search courses...'), findsOneWidget);

      // Verify filter button is present
      expect(find.byIcon(Icons.filter_list), findsOneWidget);

      // Verify courses are displayed
      expect(find.text('courses found'), findsOneWidget);
    });

    testWidgets('should filter courses by search query', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AllCoursesPageTab(selectedLanguage: 'English'),
          ),
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Find the search field and enter a search query
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Flutter');
      await tester.pumpAndSettle();

      // Verify that Flutter courses are shown
      expect(find.text('Flutter Development Fundamentals'), findsOneWidget);
      expect(find.text('Complete Flutter Development'), findsOneWidget);
      
      // Verify that non-Flutter courses are not shown
      expect(find.text('Digital Marketing Mastery'), findsNothing);
    });

    testWidgets('should open filter dialog when filter button is tapped', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AllCoursesPageTab(selectedLanguage: 'English'),
          ),
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Tap the filter button
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Verify filter dialog is shown
      expect(find.text('Filter Courses'), findsOneWidget);
      expect(find.text('Minimum Rating:'), findsOneWidget);
      expect(find.text('Maximum Price:'), findsOneWidget);
      expect(find.byType(Slider), findsNWidgets(2));
    });

    testWidgets('should display course ratings and prices', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AllCoursesPageTab(selectedLanguage: 'English'),
          ),
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Verify that ratings are displayed (star icons)
      expect(find.byIcon(Icons.star), findsWidgets);

      // Verify that prices are displayed
      expect(find.textContaining('\$'), findsWidgets);
    });
  });
}
