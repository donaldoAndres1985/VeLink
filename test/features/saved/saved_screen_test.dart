import 'package:flutter_test/flutter_test.dart';
import 'package:velink/features/saved/screens/saved_screen.dart';
import '../../helpers/provider_helper.dart';

void main() {
  group('SavedScreen', () {
    testWidgets('muestra la pantalla de guardados', (tester) async {
      await tester.pumpWidget(buildTestWidget(const SavedScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Guardados'), findsOneWidget);
    });
  });
}
