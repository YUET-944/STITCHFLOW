import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stitchflow_app/main.dart';

void main() {
  testWidgets('StitchFlow gateway screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: StitchFlowApp()),
    );
    await tester.pumpAndSettle();
    expect(find.text('StitchFlow'), findsOneWidget);
  });
}
