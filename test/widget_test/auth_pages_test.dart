// test/widget_test/auth_pages_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unistay/views/sign_up.dart';
import 'package:unistay/views/log_in.dart';

void main() {
  group('SignUpPage Widget Tests', () {
    testWidgets('SignUpPage renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SignUpPage(),
        ),
      );

      // Check if key elements are present
      expect(find.text('UniStay'), findsOneWidget);
      expect(find.text('Create your account'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Student'), findsOneWidget);
      expect(find.text('Homeowner'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Already have an account?'), findsOneWidget);
    });

    testWidgets('Email validation works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SignUpPage(),
        ),
      );

      // Try to submit without email
      await tester.tap(find.text('Create Account'));
      await tester.pump();

      expect(find.text('Please enter your email'), findsOneWidget);

      // Enter invalid email
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'invalid-email',
      );
      await tester.tap(find.text('Create Account'));
      await tester.pump();

      expect(find.text('Please enter a valid email'), findsOneWidget);

      // Enter valid email
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );
      await tester.tap(find.text('Create Account'));
      await tester.pump();

      expect(find.text('Please enter your email'), findsNothing);
      expect(find.text('Please enter a valid email'), findsNothing);
    });

    testWidgets('Password validation works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SignUpPage(),
        ),
      );

      // Try to submit without password
      await tester.tap(find.text('Create Account'));
      await tester.pump();

      expect(find.text('Please enter a password'), findsOneWidget);

      // Enter short password
      final passwordField = find.ancestor(
        of: find.text('Password'),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(passwordField, '123');
      await tester.tap(find.text('Create Account'));
      await tester.pump();

      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('Password confirmation validation works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SignUpPage(),
        ),
      );

      final passwordField = find.ancestor(
        of: find.text('Password'),
        matching: find.byType(TextFormField),
      );
      final confirmField = find.ancestor(
        of: find.text('Confirm Password'),
        matching: find.byType(TextFormField),
      );

      // Enter different passwords
      await tester.enterText(passwordField, 'password123');
      await tester.enterText(confirmField, 'different123');
      await tester.tap(find.text('Create Account'));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);

      // Enter matching passwords
      await tester.enterText(confirmField, 'password123');
      await tester.tap(find.text('Create Account'));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsNothing);
    });

    testWidgets('Role selection works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SignUpPage(),
        ),
      );

      // Student should be selected by default (you can verify this by checking colors)
      expect(find.text('Student'), findsOneWidget);
      expect(find.text('Homeowner'), findsOneWidget);

      // Tap homeowner
      await tester.tap(find.text('Homeowner'));
      await tester.pump();

      // Tap back to student
      await tester.tap(find.text('Student'));
      await tester.pump();
    });

    testWidgets('Password visibility toggle works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SignUpPage(),
        ),
      );

      // Find password visibility toggles
      final visibilityIcons = find.byIcon(Icons.visibility_off);
      expect(visibilityIcons, findsNWidgets(2)); // Password and confirm password

      // Tap first toggle (password field)
      await tester.tap(visibilityIcons.first);
      await tester.pump();

      // Should now show visibility icon
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });
  });

  group('LoginPage Widget Tests', () {
    testWidgets('LoginPage renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(),
        ),
      );

      // Check if key elements are present
      expect(find.text('UniStay'), findsOneWidget);
      expect(find.text('Welcome back!'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Log in'), findsNWidgets(2)); // Button and link
      expect(find.text("Don't have an account?"), findsOneWidget);
    });

    testWidgets('Login form validation works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(),
        ),
      );

      // Try to submit empty form
      await tester.tap(find.widgetWithText(ElevatedButton, 'Log in'));
      await tester.pump();

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);

      // Enter invalid email
      final emailField = find.ancestor(
        of: find.text('Email'),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(emailField, 'invalid-email');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Log in'));
      await tester.pump();

      expect(find.text('Please enter a valid email'), findsOneWidget);

      // Enter valid email but short password
      await tester.enterText(emailField, 'admin@admin.ch');
      final passwordField = find.ancestor(
        of: find.text('Password'),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(passwordField, '123456');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Log in'));
      await tester.pump();

      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });
  });
}

// Helper class for creating mock authentication scenarios
class MockAuthTest {
  static Widget createSignUpPageWithMockAuth() {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => SignUpPage(),
        ),
      ),
    );
  }

  static Widget createLoginPageWithMockAuth() {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => LoginPage(),
        ),
      ),
    );
  }
}