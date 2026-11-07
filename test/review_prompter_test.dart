import 'package:app_core/app_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('counts positive events and stops after asking', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final store = MemoryStore();
    final prompter = ReviewPrompter(store, threshold: 2);

    await prompter.recordPositiveEvent();
    expect(prompter.positiveEvents, 1);
    expect(prompter.hasAsked, isFalse);

    // Second event reaches the threshold; the platform call fails in tests
    // (no plugin) but is caught, and we never ask twice.
    await prompter.recordPositiveEvent();
    expect(prompter.hasAsked, isTrue);

    await prompter.recordPositiveEvent();
    expect(prompter.positiveEvents, 2);
  });
}
