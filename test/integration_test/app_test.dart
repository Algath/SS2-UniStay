// test/integration_test/app_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:unistay/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('UniStay App Integration Tests', () {
    testWidgets('Complete user signup flow', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to signup if not already there
      // Look for "Sign up" button/link
      if (find.text("Don't have an account?").evaluate().isNotEmpty) {
        await tester.tap(find.text('Sign up'));
        await tester.pumpAndSettle();
      }

      // Verify we're on signup page
      expect(find.text('Create your account'), findsOneWidget);
      expect(find.text('UniStay'), findsOneWidget);

      // Fill in signup form
      await tester.enterText(
        find.byType(TextFormField).at(0), // Email field
        'test${DateTime.now().millisecondsSinceEpoch}@example.com',
      );

      await tester.enterText(
        find.byType(TextFormField).at(1), // Password field
        'testpassword123',
      );

      await tester.enterText(
        find.byType(TextFormField).at(2), // Confirm password field
        'testpassword123',
      );

      // Select role (default is student, but let's test homeowner)
      await tester.tap(find.text('Homeowner'));
      await tester.pumpAndSettle();

      // Submit the form
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle(Duration(seconds: 5)); // Wait for network call

      // Check if we navigated to edit profile or got an error
      // Note: This might fail if Firebase auth is not set up for testing
      // You might see an error about existing email or network issues

      print('Signup flow completed - check for navigation or error messages');
    });

    testWidgets('User login flow', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to login if not already there
      if (find.text('Create your account').evaluate().isNotEmpty) {
        await tester.tap(find.text('Log in'));
        await tester.pumpAndSettle();
      }

      // Verify we're on login page
      expect(find.text('Welcome back!'), findsOneWidget);
      expect(find.text('UniStay'), findsOneWidget);

      // Fill in login form with test credentials
      await tester.enterText(
        find.byType(TextFormField).at(0), // Email field
        'test@example.com',
      );

      await tester.enterText(
        find.byType(TextFormField).at(1), // Password field
        'testpassword123',
      );

      // Submit the form
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle(Duration(seconds: 5)); // Wait for network call

      print('Login flow completed - check for navigation or error messages');
    });

    testWidgets('Form validation tests', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Go to signup page
      if (find.text("Don't have an account?").evaluate().isNotEmpty) {
        await tester.tap(find.text('Sign up'));
        await tester.pumpAndSettle();
      }

      // Test empty form submission
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      // Should show validation errors
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter a password'), findsOneWidget);

      // Test invalid email
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'invalid-email',
      );
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email'), findsOneWidget);

      // Test short password
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'test@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        '123', // Too short
      );
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 6 characters'), findsOneWidget);

      // Test password mismatch
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'password123',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'different123',
      );
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);

      print('Form validation tests completed');
    });

    testWidgets('Password visibility toggle test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Go to signup page
      if (find.text("Don't have an account?").evaluate().isNotEmpty) {
        await tester.tap(find.text('Sign up'));
        await tester.pumpAndSettle();
      }

      // Find password field
      final passwordField = find.byType(TextFormField).at(1);
      await tester.enterText(passwordField, 'testpassword');

      // Find and tap visibility toggle for password
      final passwordToggle = find.descendant(
        of: passwordField,
        matching: find.byType(IconButton),
      );
      await tester.tap(passwordToggle);
      await tester.pumpAndSettle();

      // Test confirm password toggle too
      final confirmField = find.byType(TextFormField).at(2);
      await tester.enterText(confirmField, 'testpassword');

      final confirmToggle = find.descendant(
        of: confirmField,
        matching: find.byType(IconButton),
      );
      await tester.tap(confirmToggle);
      await tester.pumpAndSettle();

      print('Password visibility toggle tests completed');
    });

    testWidgets('Role selection test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Go to signup page
      if (find.text("Don't have an account?").evaluate().isNotEmpty) {
        await tester.tap(find.text('Sign up'));
        await tester.pumpAndSettle();
      }

      // Test role selection
      expect(find.text('Student'), findsOneWidget);
      expect(find.text('Homeowner'), findsOneWidget);

      // Tap homeowner
      await tester.tap(find.text('Homeowner'));
      await tester.pumpAndSettle();

      // Tap back to student
      await tester.tap(find.text('Student'));
      await tester.pumpAndSettle();

      print('Role selection tests completed');
    });

    testWidgets('Navigation between login and signup', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Should start on one of the auth pages
      bool isOnLogin = find.text('Welcome back!').evaluate().isNotEmpty;
      bool isOnSignup = find.text('Create your account').evaluate().isNotEmpty;

      expect(isOnLogin || isOnSignup, isTrue);

      if (isOnLogin) {
        // Go to signup
        await tester.tap(find.text('Sign up'));
        await tester.pumpAndSettle();
        expect(find.text('Create your account'), findsOneWidget);

        // Go back to login
        await tester.tap(find.text('Log in'));
        await tester.pumpAndSettle();
        expect(find.text('Welcome back!'), findsOneWidget);
      } else {
        // Go to login
        await tester.tap(find.text('Log in'));
        await tester.pumpAndSettle();
        expect(find.text('Welcome back!'), findsOneWidget);

        // Go back to signup
        await tester.tap(find.text('Sign up'));
        await tester.pumpAndSettle();
        expect(find.text('Create your account'), findsOneWidget);
      }

      print('Navigation tests completed');
    });
  });
}