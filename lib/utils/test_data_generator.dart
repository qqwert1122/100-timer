import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:project1/utils/database_service.dart';

/// 테스트용 가짜 데이터를 생성하고 데이터베이스에 주입하는 클래스
class TestDataGenerator {
  final DatabaseService _dbService;
  final Random _random = Random();
  final Uuid _uuid = const Uuid();

  TestDataGenerator(this._dbService);

  /// 테스트 데이터 생성 및 주입 실행
  /// 기본값을 12개월로 설정하여 1년치 더미 데이터를 생성합니다.
  Future<void> generateAndInsertTestData({int monthsOfHistory = 12}) async {
    await _insertTestActivities();
    await _insertTestTimers(monthsOfHistory);
    await _insertTestSessions(monthsOfHistory);
    await _insertTestTodos();

    print('모든 테스트 데이터가 성공적으로 주입되었습니다. $monthsOfHistory개월치 세션 이력이 생성되었습니다.');
  }

  /// 테스트용 활동 데이터 생성 및 주입
  Future<void> _insertTestActivities() async {
    List<Map<String, dynamic>> activities = [
      _createActivity('공부', 'book', '#FF5733', isDefault: true),
      _createActivity('운동', 'fitness_center', '#33FF57'),
      _createActivity('독서', 'menu_book', '#3357FF'),
      _createActivity('코딩', 'code', '#F3FF33'),
      _createActivity('명상', 'self_improvement', '#FF33F6'),
    ];

    for (var activity in activities) {
      await _dbService.insertActivity(activity);
    }

    print('활동 데이터 ${activities.length}개가 주입되었습니다.');
  }

  /// 테스트용 타이머 데이터 생성 및 주입
  Future<void> _insertTestTimers(int monthsOfHistory) async {
    DateTime now = DateTime.now();

    // 과거 몇 개월 전부터 타이머 데이터 생성
    for (int month = monthsOfHistory - 1; month >= 0; month--) {
      // 해당 월의 첫 날 계산 (Dart는 월 오버플로우를 자동 조정합니다)
      DateTime monthDate = DateTime(now.year, now.month - month, 1);
      DateTime firstMonday = monthDate.subtract(Duration(days: monthDate.weekday - 1));
      if (firstMonday.month != monthDate.month) {
        // 해당 월의 첫 날이 월요일이 아니면 다음 주 월요일로
        firstMonday = firstMonday.add(const Duration(days: 7));
      }

      // 해당 월의 각 주에 대해 타이머 생성
      DateTime currentMonday = firstMonday;
      while (currentMonday.month == monthDate.month) {
        String weekStart = _formatDate(currentMonday);

        Map<String, dynamic> timer = {
          'timer_id': _uuid.v4(),
          'current_session_id': null,
          'week_start': weekStart,
          'total_seconds': 360000, // 100시간 (초 단위)
          'timer_state': 'STOP',
          'created_at': _formatDateTime(currentMonday),
          'deleted_at': null,
          'last_started_at': null,
          'last_ended_at': null,
          'last_updated_at': _formatDateTime(currentMonday.add(const Duration(days: 6))),
          'is_deleted': 0,
          'timezone': now.timeZoneName,
        };

        await _dbService.createTimer(timer);

        // 다음 주 월요일로 이동
        currentMonday = currentMonday.add(const Duration(days: 7));
      }
    }

    print('$monthsOfHistory개월치 타이머 데이터가 주입되었습니다.');
  }

  /// 테스트용 세션 데이터 생성 및 주입
  Future<void> _insertTestSessions(int monthsOfHistory) async {
    // 활동 데이터 가져오기
    final activities = await _dbService.getActivities();
    if (activities.isEmpty) {
      print('활동 데이터가 없습니다. 세션 데이터를 생성할 수 없습니다.');
      return;
    }

    // 모든 타이머 가져오기
    final timers = await _dbService.getAllTimers();
    if (timers.isEmpty) {
      print('타이머 데이터가 없습니다. 세션 데이터를 생성할 수 없습니다.');
      return;
    }

    DateTime now = DateTime.now();
    int totalSessions = 0;

    // 과거부터 현재까지 각 주에 대해 세션 생성
    for (var timer in timers) {
      String weekStart = timer['week_start'];
      String timerId = timer['timer_id'];

      if (weekStart.isEmpty) continue;

      try {
        DateTime weekStartDate = DateTime.parse(weekStart);

        // 각 요일에 대해 세션 생성
        for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
          DateTime sessionDate = weekStartDate.add(Duration(days: dayOffset));

          // 미래 날짜는 건너뛰기
          if (sessionDate.isAfter(now)) continue;

          // 주말에는 세션 수 줄이기
          bool isWeekend = dayOffset >= 5;
          int maxSessionCount = isWeekend ? 2 : 4;
          int sessionCount = _random.nextInt(maxSessionCount) + (isWeekend ? 0 : 1);

          // 각 날짜에 여러 세션 생성
          for (int j = 0; j < sessionCount; j++) {
            // 동일한 활동이 연속으로 등장하지 않도록 랜덤화
            List<Map<String, dynamic>> shuffledActivities = List.from(activities)..shuffle(_random);
            final activity = shuffledActivities[j % shuffledActivities.length];

            // 시간대별 세션 분포 (아침, 오후, 저녁)
            List<int> timeSlots = [9, 13, 18];
            int baseHour = timeSlots[j % timeSlots.length];
            int hour = baseHour + _random.nextInt(3);
            int minute = _random.nextInt(60);

            DateTime startTime = DateTime(sessionDate.year, sessionDate.month, sessionDate.day, hour, minute);

            // 세션 기간 패턴 (짧은, 중간, 긴 세션)
            List<int> durationPatterns = [
              15 + _random.nextInt(15), // 15-30분 (짧은 세션)
              45 + _random.nextInt(30), // 45-75분 (중간 세션)
              90 + _random.nextInt(90) // 90-180분 (긴 세션)
            ];

            // 활동별로 다른 패턴 적용
            int patternIndex = (activity['activity_name'].hashCode + j) % durationPatterns.length;
            int durationMinutes = durationPatterns[patternIndex];

            // 주말 또는 오래된 데이터는 더 긴 세션 추가
            if (isWeekend || _random.nextInt(100) < 20) {
              durationMinutes += 30 + _random.nextInt(60);
            }

            int durationSeconds = durationMinutes * 60;
            DateTime endTime = startTime.add(Duration(seconds: durationSeconds));

            // 목표 기간 (대부분 실제 기간과 같고, 가끔 조정)
            int targetMode = _random.nextInt(10);
            int targetDuration;
            if (targetMode < 7) {
              targetDuration = durationSeconds;
            } else if (targetMode < 9) {
              targetDuration = (durationSeconds * 0.8).round();
            } else {
              targetDuration = durationSeconds + (15 + _random.nextInt(45)) * 60;
            }

            // 세션 생성
            String sessionId = _uuid.v4();
            Map<String, dynamic> session = {
              'session_id': sessionId,
              'timer_id': timerId,
              'activity_id': activity['activity_id'],
              'activity_name': activity['activity_name'],
              'activity_icon': activity['activity_icon'],
              'activity_color': activity['activity_color'],
              'mode': _random.nextInt(10) < 7 ? 'NORMAL' : 'FOCUS',
              'session_state': 'ENDED',
              'start_time': _formatDateTime(startTime),
              'end_time': _formatDateTime(endTime),
              'duration': durationSeconds,
              'target_duration': targetDuration,
              'original_duration': durationSeconds,
              'created_at': _formatDateTime(startTime),
              'deleted_at': null,
              'last_updated_at': _formatDateTime(endTime),
              'is_modified': _random.nextInt(10) < 2 ? 1 : 0,
              'is_deleted': 0,
              'is_ended': 1,
              'timezone': now.timeZoneName,
              'long_session_flag': durationSeconds >= 3600 ? 1 : 0,
            };

            await _dbService.insertSession(session);
            totalSessions++;

            // 긴 세션 중 짧은 휴식 세션 추가 (30% 확률)
            if (durationMinutes > 60 && _random.nextInt(10) < 3) {
              int breakPoint = _random.nextInt(durationSeconds ~/ 2) + (durationSeconds ~/ 4);
              DateTime breakStartTime = startTime.add(Duration(seconds: breakPoint));

              int breakDuration = (5 + _random.nextInt(10)) * 60;
              DateTime breakEndTime = breakStartTime.add(Duration(seconds: breakDuration));

              Map<String, dynamic> breakSession = {
                'session_id': _uuid.v4(),
                'timer_id': timerId,
                'activity_id': activities[0]['activity_id'],
                'activity_name': '휴식',
                'activity_icon': 'coffee',
                'activity_color': '#33A1FF',
                'mode': 'BREAK',
                'session_state': 'ENDED',
                'start_time': _formatDateTime(breakStartTime),
                'end_time': _formatDateTime(breakEndTime),
                'duration': breakDuration,
                'target_duration': breakDuration,
                'original_duration': breakDuration,
                'created_at': _formatDateTime(breakStartTime),
                'deleted_at': null,
                'last_updated_at': _formatDateTime(breakEndTime),
                'is_modified': 0,
                'is_deleted': 0,
                'is_ended': 1,
                'timezone': now.timeZoneName,
                'long_session_flag': 0,
              };

              await _dbService.insertSession(breakSession);
              totalSessions++;
            }
          }
        }
      } catch (e) {
        print('주 $weekStart에 대한 세션 생성 중 오류: $e');
        continue;
      }
    }

    print('총 세션 데이터 $totalSessions개가 주입되었습니다.');
  }

  /// 테스트용 할 일 데이터 생성 및 주입
  Future<void> _insertTestTodos() async {
    final activities = await _dbService.getActivities();
    if (activities.isEmpty) {
      print('활동 데이터가 없습니다. 할 일 데이터를 생성할 수 없습니다.');
      return;
    }

    List<String> todoNames = [
      '알고리즘 문제 풀기',
      '운동 30분',
      '책 2장 읽기',
      '영어 단어 외우기',
      '프로젝트 기획안 작성',
      '친구와 통화하기',
      '집안 청소하기',
      '수업 자료 정리',
      '블로그 글 작성',
      '디자인 포트폴리오 준비',
    ];

    List<String> priorities = ['HIGH', 'MEDIUM', 'LOW'];

    List<Map<String, dynamic>> todos = [];
    for (int i = 0; i < 10; i++) {
      final activity = activities[_random.nextInt(activities.length)];
      DateTime dueDate = DateTime.now().add(Duration(days: _random.nextInt(7) + 1));

      Map<String, dynamic> todo = {
        'todo_id': _uuid.v4(),
        'todo_name': todoNames[i],
        'todo_detail': '이것은 ${todoNames[i]}에 대한 상세 설명입니다.',
        'priority': priorities[_random.nextInt(priorities.length)],
        'activity_id': activity['activity_id'],
        'activity_name': activity['activity_name'],
        'activity_icon': activity['activity_icon'],
        'activity_color': activity['activity_color'],
        'created_at': _formatDateTime(DateTime.now()),
        'deleted_at': null,
        'last_updated_at': _formatDateTime(DateTime.now()),
        'due_date': _formatDate(dueDate),
        'position': i,
        'is_completed': _random.nextInt(10) < 3 ? 1 : 0,
        'is_deleted': 0,
      };

      todos.add(todo);
    }

    for (var todo in todos) {
      await _dbService.insertTodo(todo);
    }

    print('할 일 데이터 ${todos.length}개가 주입되었습니다.');
  }

  /// 활동 데이터 생성 헬퍼 메서드
  Map<String, dynamic> _createActivity(String name, String icon, String color, {bool isDefault = false}) {
    DateTime now = DateTime.now();
    return {
      'activity_id': _uuid.v4(),
      'activity_name': name,
      'activity_icon': icon,
      'activity_color': color,
      'created_at': _formatDateTime(now),
      'deleted_at': null,
      'last_updated_at': _formatDateTime(now),
      'is_favorite': _random.nextBool() ? 1 : 0,
      'is_default': isDefault ? 1 : 0,
      'is_deleted': 0,
    };
  }

  /// ISO 형식의 날짜 문자열 반환 (날짜만)
  String _formatDate(DateTime date) {
    return date.toIso8601String().split('T').first;
  }

  /// ISO 형식의 날짜+시간 문자열 반환
  String _formatDateTime(DateTime dateTime) {
    return dateTime.toUtc().toIso8601String();
  }
}

/// DatabaseService 확장 메서드들
extension TestDataMethods on DatabaseService {
  Future<List<Map<String, dynamic>>> getAllTimers() async {
    final db = await database;
    return await db.query('timers', where: 'is_deleted = 0');
  }

  Future<void> insertSession(Map<String, dynamic> session) async {
    final db = await database;
    await db.insert('sessions', session);
  }

  Future<void> insertActivity(Map<String, dynamic> activity) async {
    final db = await database;
    await db.insert('activities', activity);
  }

  Future<void> insertTodo(Map<String, dynamic> todo) async {
    final db = await database;
    await db.insert('todos', todo);
  }
}

/// 테스트 데이터 주입을 실행하는 예제 코드
Future<void> insertTestData(DatabaseService dbService) async {
  final testDataGenerator = TestDataGenerator(dbService);
  await testDataGenerator.generateAndInsertTestData();
}
