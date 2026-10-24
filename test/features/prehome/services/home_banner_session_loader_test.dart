import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mana_poster/features/prehome/services/app_home_banner_service.dart';

void main() {
  test('startup and deferred requests share one pending load', () async {
    final loader = HomeBannerSessionLoader();
    final pending = Completer<void>();
    var calls = 0;
    Future<void> fetch() {
      calls++;
      return pending.future;
    }

    final first = loader.load(fetch);
    final second = loader.load(fetch);
    expect(identical(first, second), isTrue);
    expect(calls, 1);
    pending.complete();
    await Future.wait(<Future<void>>[first, second]);
    await loader.load(fetch);
    expect(calls, 1);
  });

  test('empty response is final for the session', () async {
    final loader = HomeBannerSessionLoader();
    var calls = 0;
    Future<void> fetch() async {
      calls++;
    }

    await loader.load(fetch);
    await loader.load(fetch);
    expect(calls, 1);
  });

  test(
    'failure does not trigger a second popup load later in the session',
    () async {
      final loader = HomeBannerSessionLoader();
      var calls = 0;
      Future<void> fetch() async {
        calls++;
        throw StateError('offline');
      }

      await expectLater(loader.load(fetch), throwsStateError);
      await expectLater(loader.load(fetch), throwsStateError);
      expect(calls, 1);
    },
  );

  test(
    'region reset starts a new load even if the old region is still pending',
    () async {
      final loader = HomeBannerSessionLoader();
      final old = Completer<void>();
      final first = loader.load(() => old.future);
      loader.reset();
      var newCalls = 0;
      await loader.load(() async {
        newCalls++;
      });
      old.complete();
      await first;
      await loader.load(() async {
        newCalls++;
      });
      expect(newCalls, 1);
    },
  );

  test('a new app session checks fresh banners again', () async {
    var calls = 0;
    Future<void> fetch() async {
      calls++;
    }

    await HomeBannerSessionLoader().load(fetch);
    await HomeBannerSessionLoader().load(fetch);
    expect(calls, 2);
  });
}
