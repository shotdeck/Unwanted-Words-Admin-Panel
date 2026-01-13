import 'package:flutter_test/flutter_test.dart';

import 'package:unwanted_words_admin/main.dart';

void main() {
  testWidgets('App loads configuration screen', (WidgetTester tester) async {
    await tester.pumpWidget(const UnwantedWordsAdminApp());

    expect(find.text('Unwanted Words Admin'), findsOneWidget);
    expect(find.text('Configure your API connection'), findsOneWidget);
    expect(find.text('Connect'), findsOneWidget);
  });
}
