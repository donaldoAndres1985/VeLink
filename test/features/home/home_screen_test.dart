import 'package:flutter_test/flutter_test.dart';
import 'package:velink/features/home/screens/home_screen.dart';
import '../../helpers/provider_helper.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('muestra la pantalla de inicio', (tester) async {
      await tester.pumpWidget(buildTestWidget(const HomeScreen()));
      await tester.pumpAndSettle();
      expect(find.text('VeLink'), findsOneWidget);
    });
  });
}
