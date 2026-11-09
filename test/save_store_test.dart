import 'package:app_core/app_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round-trips data', () async {
    final save = SaveStore(MemoryStore(), key: 'progress');
    expect(save.load(), isEmpty);

    await save.save({'level': 3, 'name': 'Ada'});
    expect(save.load(), {'level': 3, 'name': 'Ada'});
  });

  test(
    'runs migrations from the stored version up to the current one',
    () async {
      final store = MemoryStore();
      await SaveStore(store, key: 'progress').save({'level': 3});

      final v3 = SaveStore(
        store,
        key: 'progress',
        version: 3,
        migrations: {
          1: (data) => {...data, 'stars': 0},
          2: (data) => {...data, 'level': (data['level'] as int) + 1},
        },
      );
      expect(v3.load(), {'level': 4, 'stars': 0});
    },
  );

  test('corrupt data loads as empty', () {
    final store = MemoryStore({'progress': '{oops'});
    expect(SaveStore(store, key: 'progress').load(), isEmpty);
  });
}
