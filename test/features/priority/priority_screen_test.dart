import 'package:flutter_test/flutter_test.dart';
import 'package:velink/features/priority/screens/priority_screen.dart';
import '../../helpers/provider_helper.dart';

void main() {
  group('PriorityScreen', () {
    testWidgets('muestra la pantalla de prioritarios', (tester) async {
      await tester.pumpWidget(buildTestWidget(const PriorityScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Prioritarios'), findsOneWidget);
    });
  });
}
