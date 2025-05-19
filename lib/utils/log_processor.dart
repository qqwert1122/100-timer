import 'dart:async';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:project1/utils/icon_utils.dart';

// 백그라운드에서 로그 데이터 그룹화 처리하는 함수
List<Map<String, dynamic>> groupLogsByDateIsolate(List<Map<String, dynamic>> logs) {
  // 사전 필터링으로 무효한 로그 제거
  if (logs.isEmpty) {
    return [];
  }
  final tempGroup = <String, List<Map<String, dynamic>>>{};
  // 날짜 파싱을 한 번만 수행하도록 최적화
  for (var log in logs) {
    if (log.containsKey('start_time') && log['start_time'] != null) {
      final startTime = log['start_time'] as String;

      final localDateTime = DateTime.parse(startTime).toLocal();
      final localDate = '${localDateTime.year}-'
          '${localDateTime.month.toString().padLeft(2, '0')}-'
          '${localDateTime.day.toString().padLeft(2, '0')}';

      tempGroup.putIfAbsent(localDate, () => []).add(log);
    }
  }

  // 정렬 최적화: 미리 캐시된 타임스탬프 사용
  final groupedList = tempGroup.entries.map((entry) {
    final logs = entry.value;

    // 시간 문자열 비교를 사용하여 날짜/시간 파싱 작업 감소
    logs.sort((a, b) => (b['start_time'] as String).compareTo(a['start_time'] as String));

    return {'date': entry.key, 'logs': logs};
  }).toList();

  // 날짜 문자열을 직접 비교하여 정렬 (ISO 형식이므로 가능함)
  groupedList.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));

  return groupedList;
}

// 백그라운드 작업을 위한 래퍼 클래스
class IsolateData {
  final List<Map<String, dynamic>> logs;

  IsolateData(this.logs);
}

// isolate에서 실행할 함수
Future<List<Map<String, dynamic>>> processLogsInBackground(IsolateData data) async {
  return groupLogsByDateIsolate(data.logs);
}

// 추가: compute 함수를 위한 래퍼 함수
List<Map<String, dynamic>> computeGroupLogs(List<Map<String, dynamic>> logs) {
  return groupLogsByDateIsolate(logs);
}

// 추가: Isolate를 직접 사용하는 유틸리티 함수
class IsolateMessage {
  final List<Map<String, dynamic>> logs;
  final SendPort sendPort;

  IsolateMessage(this.logs, this.sendPort);
}

Future<List<Map<String, dynamic>>> processLogsWithIsolate(List<Map<String, dynamic>> logs) async {
  final ReceivePort receivePort = ReceivePort();
  await Isolate.spawn(_isolateEntryPoint, IsolateMessage(logs, receivePort.sendPort));

  final List<Map<String, dynamic>> result = await receivePort.first;
  return result;
}

void _isolateEntryPoint(IsolateMessage message) {
  final result = groupLogsByDateIsolate(message.logs);
  message.sendPort.send(result);
}

// 로그 캐싱을 위한 간단한 유틸리티 클래스
class LogCache {
  static final Map<String, List<Map<String, dynamic>>> _cache = {};
  static const int maxCacheSize = 30;
  static const int maxCacheAgeMS = 10 * 60 * 1000; // 10분 캐시 수명
  static final Map<String, int> _lastAccessTime = {};

  // 캐시 정리를 위한 타이머
  static Timer? _cleanupTimer;

  static void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(minutes: 3), (_) {
      _cleanCache();
    });
  }

  static void _cleanCache() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final keysToRemove = <String>[];

    _lastAccessTime.forEach((key, timestamp) {
      if (now - timestamp > maxCacheAgeMS) {
        keysToRemove.add(key);
      }
    });

    for (final key in keysToRemove) {
      _cache.remove(key);
      _lastAccessTime.remove(key);
    }
  }

  static void store(String key, List<Map<String, dynamic>> data) {
    // LRU 캐시 구현
    if (_cache.length >= maxCacheSize) {
      String? oldestKey;
      int oldestTime = DateTime.now().millisecondsSinceEpoch;

      _lastAccessTime.forEach((k, time) {
        if (time < oldestTime) {
          oldestTime = time;
          oldestKey = k;
        }
      });

      if (oldestKey != null) {
        _cache.remove(oldestKey);
        _lastAccessTime.remove(oldestKey);
      }
    }

    _cache[key] = data;
    _lastAccessTime[key] = DateTime.now().millisecondsSinceEpoch;

    // 캐시 정리 타이머 시작
    if (_cleanupTimer == null || !_cleanupTimer!.isActive) {
      _startCleanupTimer();
    }
  }

  static List<Map<String, dynamic>>? retrieve(String key) {
    final data = _cache[key];
    if (data != null) {
      // 접근 시간 업데이트
      _lastAccessTime[key] = DateTime.now().millisecondsSinceEpoch;
    }
    return data;
  }

  static Future<void> clearAsync() async {
    return Future(() {
      _cache.clear();
      _lastAccessTime.clear();
    });
  }

  static void clear() {
    _cache.clear();
    _lastAccessTime.clear();
  }

  static bool containsKey(String key) {
    return _cache.containsKey(key);
  }

  static Future<void> removeByPatternAsync(String pattern) async {
    return Future(() {
      final keysToRemove = _cache.keys.where((key) => key.contains(pattern)).toList();
      for (final key in keysToRemove) {
        _cache.remove(key);
        _lastAccessTime.remove(key);
      }
    });
  }

  static void dispose() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _cache.clear();
    _lastAccessTime.clear();
  }

  static void updateLogInCache(String sessionId, Map<String, dynamic> updatedLog) {
    // 캐시의 모든 항목 확인
    LogCache._cache.forEach((key, value) {
      if (value is List<Map<String, dynamic>>) {
        bool cacheModified = false;

        for (var i = 0; i < value.length; i++) {
          final group = value[i];
          if (group.containsKey('logs')) {
            final logs = group['logs'] as List<Map<String, dynamic>>;
            final logIndex = logs.indexWhere((log) => log['session_id'] == sessionId);

            if (logIndex >= 0) {
              cacheModified = true;

              // 날짜 확인
              final oldDate = group['date'] as String;
              final newDateStr = updatedLog['start_time'].substring(0, 10);

              if (oldDate == newDateStr) {
                // 같은 날짜 그룹 내 업데이트
                logs[logIndex] = updatedLog;
              } else {
                // 날짜 변경됨 - 항목 이동 필요
                logs.removeAt(logIndex);

                // 기존 그룹이 비었으면 제거
                if (logs.isEmpty) {
                  value.removeAt(i);
                  i--; // 인덱스 조정
                  continue;
                }

                // 새 날짜 그룹 찾기
                int newGroupIndex = value.indexWhere((g) => g['date'] == newDateStr);

                if (newGroupIndex >= 0) {
                  // 기존 그룹에 추가
                  (value[newGroupIndex]['logs'] as List<Map<String, dynamic>>).add(updatedLog);
                  // 시간순 정렬
                  (value[newGroupIndex]['logs'] as List<Map<String, dynamic>>)
                      .sort((a, b) => (b['start_time'] as String).compareTo(a['start_time'] as String));
                } else {
                  // 새 그룹 생성
                  value.add({
                    'date': newDateStr,
                    'logs': [updatedLog]
                  });

                  // 날짜순 정렬
                  value.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
                }
              }
            }
          }
        }

        // 변경된 경우 타임스탬프 업데이트
        if (cacheModified && LogCache._lastAccessTime.containsKey(key)) {
          LogCache._lastAccessTime[key] = DateTime.now().millisecondsSinceEpoch;
        }
      }
    });
  }

// 캐시에서 항목 제거 메서드
  static void removeLogFromCache(String sessionId) {
    LogCache._cache.forEach((key, value) {
      if (value is List<Map<String, dynamic>>) {
        bool cacheModified = false;

        for (var i = 0; i < value.length; i++) {
          final group = value[i];
          if (group.containsKey('logs')) {
            final logs = group['logs'] as List<Map<String, dynamic>>;
            final originalLength = logs.length;

            logs.removeWhere((log) => log['session_id'] == sessionId);

            if (logs.length < originalLength) {
              cacheModified = true;

              // 그룹이 비어있으면 제거
              if (logs.isEmpty) {
                value.removeAt(i);
                i--; // 인덱스 조정
              }
            }
          }
        }

        // 변경된 경우 타임스탬프 업데이트
        if (cacheModified && LogCache._lastAccessTime.containsKey(key)) {
          LogCache._lastAccessTime[key] = DateTime.now().millisecondsSinceEpoch;
        }
      }
    });
  }
}

class IconCache {
  static final Map<String, Image> _cache = {};
  static const int MAX_CACHE_SIZE = 20;

  static Image getIcon(String iconName, double width, double height) {
    final String key = "$iconName-${width.toInt()}-${height.toInt()}";

    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    // 메모리 관리를 위해 특정 크기에 도달하면 캐시 비우기
    if (_cache.length >= MAX_CACHE_SIZE) {
      _cache.clear(); // 전체 캐시 초기화 (또는 LRU 알고리즘 적용)
    }

    final image = Image.asset(
      getIconImage(iconName),
      width: width,
      height: height,
      // 이미지 크기 최적화
      cacheWidth: (width * 1.5).toInt(), // 적절한 배율로 조정
      cacheHeight: (height * 1.5).toInt(),
      filterQuality: FilterQuality.medium, // 품질 설정 조정
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey.withOpacity(0.1),
          child: Icon(
            Icons.broken_image,
            size: width * 0.7, // 크기 최적화
            color: Colors.grey,
          ),
        );
      },
    );

    _cache[key] = image;
    return image;
  }

  static void preloadIcons(List<String> iconNames, double width, double height) {
    for (final name in iconNames) {
      getIcon(name, width, height);
    }
  }

  static void clear() {
    _cache.clear();
  }
}
