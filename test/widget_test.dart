// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../lib/main.dart'; // ou le bon chemin vers ton MyApp
import '../lib/app_state.dart'; // ou le bon chemin

void main() {
  testWidgets('Basic rendering', (WidgetTester tester) async {
    // On wrappe MyApp avec le provider
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ApplicationState(),
        child: App(),
      ),
    );

    // Verify that our counter starts at 0.
    expect(find.text('Firebase Meetup'), findsOneWidget);
    expect(find.text('January 1st'), findsNothing);
  });
}
