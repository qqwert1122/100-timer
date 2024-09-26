import 'package:flutter/material.dart';
import 'package:project1/utils/database_service.dart';
import 'package:project1/utils/icon_utils.dart'; // 아이콘 유틸리티

class ActivityLogPage extends StatefulWidget {
  @override
  _ActivityLogPageState createState() => _ActivityLogPageState();
}

class _ActivityLogPageState extends State<ActivityLogPage> {
  final DatabaseService _dbService = DatabaseService(); // DB 서비스 인스턴스

  Future<List<Map<String, dynamic>>> _getActivityLogs() async {
    // DB에서 모든 액티비티 로그 데이터를 가져옴
    return await _dbService.getAllActivityLogs(); // 이 메소드는 DB에서 모든 로그를 가져와야 함
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('활동 기록'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getActivityLogs(), // DB에서 로그 데이터를 가져옴
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator()); // 로딩 중일 때 로딩 표시
          }
          if (snapshot.hasError) {
            return const Center(child: Text('데이터를 불러오는 중 오류가 발생했습니다.'));
          }

          final logs = snapshot.data ?? [];

          if (logs.isEmpty) {
            return const Center(child: Text('로그가 없습니다.')); // 로그가 없을 때 표시
          }

          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              final iconName = log['activity_icon'];
              final iconData = getIconData(iconName); // 아이콘 유틸리티에서 아이콘 매핑

              final startTime = DateTime.parse(log['start_time']);
              final endTime = log['end_time'] != null
                  ? DateTime.parse(log['end_time'])
                  : null;

              final activityName = log['activity_name']; // 액티비티 이름

              return ListTile(
                leading: Icon(iconData),
                title: Text(
                  activityName,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '시작 시간: ${startTime.toLocal()}\n종료 시간: ${endTime?.toLocal() ?? '진행 중'}',
                ),
              );
            },
          );
        },
      ),
    );
  }
}
