import 'package:flutter_test/flutter_test.dart';
import 'package:velink/features/search/screens/search_screen.dart';
import '../../helpers/provider_helper.dart';

void main() {
  group('SearchScreen', () {
    testWidgets('muestra la pantalla de busqueda', (tester) async {
      await tester.pumpWidget(buildTestWidget(const SearchScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Buscar'), findsOneWidget);
    });
  });
}
