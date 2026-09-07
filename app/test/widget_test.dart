import 'package:flutter_test/flutter_test.dart';

import 'package:fatura/main.dart';

void main() {
  testWidgets('App loads and shows the Home tab with bottom navigation', (tester) async {
    await tester.pumpWidget(const FaturaApp());
    await tester.pumpAndSettle();

    expect(find.text('Fatura'), findsOneWidget);
    expect(find.text('Início'), findsOneWidget);
    expect(find.text('Compras ativas'.toUpperCase()), findsOneWidget);

    await tester.tap(find.text('Cartões'));
    await tester.pumpAndSettle();
    expect(find.text('Nubank'), findsOneWidget);
  });
}
