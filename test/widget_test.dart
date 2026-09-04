import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:persian_universe/core/theme.dart';

void main() {
  testWidgets('Theme builds', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: const Scaffold(body: Text('hola')),
    ));
    expect(find.text('hola'), findsOneWidget);
  });

  test('conjColor maps groups', () {
    expect(conjColor('ar'), AppColors.ar);
    expect(conjColor('irregular'), AppColors.irregular);
    expect(conjColor(null), AppColors.neutral);
  });
}
