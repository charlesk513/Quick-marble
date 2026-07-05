import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_marble/main.dart';

void main() {
  testWidgets('Quick Marble app boots', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: QuickMarbleApp()));
    expect(find.text('Quick Marble & Granite'), findsNothing);
  });
}
