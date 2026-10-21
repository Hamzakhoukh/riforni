import 'package:flutter_test/flutter_test.dart';
import 'package:riforni/main.dart';

void main() {
  testWidgets('App renders MainShell smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RifornoApp());
  });
}
