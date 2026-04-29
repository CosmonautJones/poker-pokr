import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/core/progression/achievement_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AchievementService> _service([
  Map<String, Object> seed = const {},
]) async {
  SharedPreferences.setMockInitialValues(seed);
  final prefs = await SharedPreferences.getInstance();
  return AchievementService(prefs);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AchievementService', () {
    test('loadUnlocked returns empty set on a fresh install', () async {
      final svc = await _service();
      expect(svc.loadUnlocked(), isEmpty);
    });

    test('saveUnlocked / loadUnlocked round-trip preserves the set',
        () async {
      final svc = await _service();
      final ids = <String>{'firstHand', 'tenHands', 'firstWin'};
      await svc.saveUnlocked(ids);
      final reloaded = svc.loadUnlocked();
      expect(reloaded, ids);
    });

    test('round-trips an empty set', () async {
      final svc = await _service();
      await svc.saveUnlocked(<String>{});
      expect(svc.loadUnlocked(), isEmpty);
    });

    test('corrupt JSON falls back to empty set', () async {
      final svc =
          await _service({AchievementService.storageKey: '!! not json !!'});
      expect(svc.loadUnlocked(), isEmpty);
    });

    test('non-list JSON falls back to empty set', () async {
      final svc =
          await _service({AchievementService.storageKey: '{"a":1}'});
      expect(svc.loadUnlocked(), isEmpty);
    });

    test('persistence survives across service instances using the same prefs',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs1 = await SharedPreferences.getInstance();
      final svc1 = AchievementService(prefs1);
      await svc1.saveUnlocked({'firstLesson', 'weekStreak'});

      // Same prefs, brand-new service instance.
      final svc2 = AchievementService(prefs1);
      expect(svc2.loadUnlocked(), {'firstLesson', 'weekStreak'});
    });
  });
}
