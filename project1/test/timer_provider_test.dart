// timer_provider_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:project1/utils/database_service.dart';
import 'package:project1/utils/timer_provider.dart';
import 'timer_provider_test.mocks.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter/material.dart';

@GenerateNiceMocks([MockSpec<DatabaseService>()])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TimerProvider Tests', () {
    late TimerProvider timerProvider;
    late MockDatabaseService mockDatabaseService;
    String userId = 'test_user';

    setUp(() {
      mockDatabaseService = MockDatabaseService();
      timerProvider = TimerProvider(userId: userId, databaseService: mockDatabaseService);
      WidgetsBinding.instance.addObserver(timerProvider);
    });

    tearDown(() {
      WidgetsBinding.instance.removeObserver(timerProvider);
      timerProvider.dispose();
    });

    test('타이머 중지 테스트', () async {
      timerProvider.isRunning = true;

      timerProvider.timerData = {
        'timer_id': 'timer1',
        'user_id': userId,
      };
      timerProvider.setCurrentActivityLogIdForTest('activity_log1');

      when(mockDatabaseService.getTimer(any, any)).thenAnswer((_) async => {
            'timer_id': 'timer1',
            'user_id': userId,
          });
      when(mockDatabaseService.updateTimer(any, any, any)).thenAnswer((_) async {});
      when(mockDatabaseService.updateActivityLog(any, resetEndTime: anyNamed('resetEndTime'))).thenAnswer((_) async {});

      await timerProvider.stopTimer();

      expect(timerProvider.isRunning, false);
      verify(mockDatabaseService.updateTimer('timer1', userId, any)).called(1);
      verify(mockDatabaseService.updateActivityLog('activity_log1', resetEndTime: false)).called(1);
    });

    // 추가적인 테스트 케이스 작성...
  });
}
