// test/automation/app_automation_helper.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'dart:math';

/// A comprehensive helper class for automating Flutter app testing
class AppAutomationHelper {
  final WidgetTester tester;

  AppAutomationHelper(this.tester);

  /// Generate a unique email for testing
  static String generateTestEmail() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(10000);
    return 'test_$timestamp$random@automation.test';
  }

  /// Generate a test password
  static String generateTestPassword() {
    return 'TestPass123!';
  }

  /// Wait for loading indicators to disappear
  Future<void> waitForLoading() async {
    await tester.pumpAndSettle(Duration(seconds: 5));

    // Wait for any CircularProgressIndicator to disappear
    int attempts = 0;
    while (find.byType(CircularProgressIndicator).evaluate().isNotEmpty && attempts < 30) {
      await tester.pump(Duration(milliseconds: 500));
      attempts++;
    }
  }

  /// Fill a text field by its label text
  Future<void> fillFieldByLabel(String label, String text) async {
    final field = find.ancestor(
      of: find.text(label),
      matching: find.byType(TextFormField),
    );
    expect(field, findsOneWidget, reason: 'Could not find field with label: $label');

    await tester.enterText(field, text);
    await tester.pump();
  }

  /// Fill a text field by its position (0-indexed)
  Future<void> fillFieldByIndex(int index, String text) async {
    final fields = find.byType(TextFormField);
    expect(fields.evaluate().length, greaterThan(index),
        reason: 'Field index $index not found');

    await tester.enterText(fields.at(index), text);
    await tester.pump();
  }

  /// Tap a button by its text
  Future<void> tapButtonByText(String buttonText) async {
    final button = find.text(buttonText);
    expect(button, findsOneWidget, reason: 'Could not find button: $buttonText');

    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  /// Tap an ElevatedButton by its text
  Future<void> tapElevatedButtonByText(String buttonText) async {
    final button = find.widgetWithText(ElevatedButton, buttonText);
    expect(button, findsOneWidget, reason: 'Could not find elevated button: $buttonText');

    await tester.tap(button);
    await waitForLoading();
  }

  /// Check if we're on a specific page by looking for unique text
  bool isOnPage(String uniqueText) {
    return find.text(uniqueText).evaluate().isNotEmpty;
  }

  /// Navigate to signup page from login page
  Future<void> goToSignupFromLogin() async {
    if (isOnPage('Welcome back!')) {
      await tapButtonByText('Sign up');
    }
  }

  /// Navigate to login page from signup page
  Future<void> goToLoginFromSignup() async {
    if (isOnPage('Create your account')) {
      await tapButtonByText('Log in');
    }
  }

  /// Select a role on signup page
  Future<void> selectRole(String role) async {
    expect(['Student', 'Homeowner'].contains(role), isTrue,
        reason: 'Role must be Student or Homeowner');

    await tapButtonByText(role);
  }

  /// Toggle password visibility
  Future<void> togglePasswordVisibility(int fieldIndex) async {
    final passwordFields = find.byType(TextFormField);
    final targetField = passwordFields.at(fieldIndex);

    final visibilityToggle = find.descendant(
      of: targetField,
      matching: find.byType(IconButton),
    );

    if (visibilityToggle.evaluate().isNotEmpty) {
      await tester.tap(visibilityToggle);
      await tester.pump();
    }
  }

  /// Complete signup flow with custom or generated data
  Future<SignupResult> completeSignupFlow({
    String? email,
    String? password,
    String? confirmPassword,
    String role = 'Student',
  }) async {
    final testEmail = email ?? generateTestEmail();
    final testPassword = password ?? generateTestPassword();
    final testConfirmPassword = confirmPassword ?? testPassword;

    // Ensure we're on signup page
    await goToSignupFromLogin();
    expect(find.text('Create your account'), findsOneWidget);

    // Fill form
    await fillFieldByIndex(0, testEmail);
    await fillFieldByIndex(1, testPassword);
    await fillFieldByIndex(2, testConfirmPassword);

    // Select role
    await selectRole(role);

    // Submit form
    await tapElevatedButtonByText('Create Account');

    // Check for errors or success
    await tester.pump(Duration(seconds: 1));

    bool hasError = find.byIcon(Icons.error_outline).evaluate().isNotEmpty;
    String? errorMessage;

    if (hasError) {
      final errorContainer = find.ancestor(
        of: find.byIcon(Icons.error_outline),
        matching: find.byType(Container),
      );
      if (errorContainer.evaluate().isNotEmpty) {
        // Try to extract error message
        final textWidgets = find.descendant(
          of: errorContainer.first,
          matching: find.byType(Text),
        );
        if (textWidgets.evaluate().length > 1) {
          final errorText = textWidgets.last.evaluate().first.widget as Text;
          errorMessage = errorText.data;
        }
      }
    }

    return SignupResult(
      email: testEmail,
      password: testPassword,
      role: role,
      success: !hasError,
      errorMessage: errorMessage,
    );
  }

  /// Complete login flow
  Future<LoginResult> completeLoginFlow({
    required String email,
    required String password,
  }) async {
    // Ensure we're on login page
    await goToSignupFromLogin();
    expect(find.text('Welcome back!'), findsOneWidget);

    // Fill form
    await fillFieldByIndex(0, email);
    await fillFieldByIndex(1, password);

    // Submit form
    await tapElevatedButtonByText('Log in');

    // Check for errors or success
    await tester.pump(Duration(seconds: 1));

    bool hasError = find.byIcon(Icons.error_outline).evaluate().isNotEmpty;
    String? errorMessage;

    if (hasError) {
      final errorContainer = find.ancestor(
        of: find.byIcon(Icons.error_outline),
        matching: find.byType(Container),
      );
      if (errorContainer.evaluate().isNotEmpty) {
        final textWidgets = find.descendant(
          of: errorContainer.first,
          matching: find.byType(Text),
        );
        if (textWidgets.evaluate().length > 1) {
          final errorText = textWidgets.last.evaluate().first.widget as Text;
          errorMessage = errorText.data;
        }
      }
    }

    return LoginResult(
      email: email,
      success: !hasError,
      errorMessage: errorMessage,
    );
  }

  /// Take a screenshot (useful for debugging)
  Future<void> takeScreenshot(String name) async {
    // Note: Screenshots work better in integration tests
    try {
      final binding = tester.binding as IntegrationTestWidgetsFlutterBinding?;
      if (binding != null) {
        await binding.takeScreenshot('test_screenshots_$name');
      }
    } catch (e) {
      print('Screenshot failed: $e');
    }
  }

  /// Verify specific validation message appears
  void expectValidationMessage(String message) {
    expect(find.text(message), findsOneWidget,
        reason: 'Expected validation message: $message');
  }

  /// Verify no validation messages are present
  void expectNoValidationMessages() {
    final commonValidations = [
      'Please enter your email',
      'Please enter a valid email',
      'Please enter a password',
      'Password must be at least 6 characters',
      'Please confirm your password',
      'Passwords do not match',
    ];

    for (final message in commonValidations) {
      expect(find.text(message), findsNothing,
          reason: 'Unexpected validation message: $message');
    }
  }
}

/// Result class for signup operations
class SignupResult {
  final String email;
  final String password;
  final String role;
  final bool success;
  final String? errorMessage;

  SignupResult({
    required this.email,
    required this.password,
    required this.role,
    required this.success,
    this.errorMessage,
  });

  @override
  String toString() {
    return 'SignupResult(email: $email, role: $role, success: $success, error: $errorMessage)';
  }
}

/// Result class for login operations
class LoginResult {
  final String email;
  final bool success;
  final String? errorMessage;

  LoginResult({
    required this.email,
    required this.success,
    this.errorMessage,
  });

  @override
  String toString() {
    return 'LoginResult(email: $email, success: $success, error: $errorMessage)';
  }
}