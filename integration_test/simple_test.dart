import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:oxicloud_app/presentation/app.dart';
import 'package:oxicloud_app/src/rust/frb_generated.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => RustLib.init());
  testWidgets('Can call rust function', (tester) async {
    await tester.pumpWidget(const OxiCloudApp());
    expect(find.textContaining('Result: `Hello, Tom!`'), findsOneWidget);
  });
}
