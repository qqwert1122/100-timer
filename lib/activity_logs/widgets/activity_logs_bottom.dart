import 'package:flutter/material.dart';
import 'package:project1/theme/app_text_style.dart';

class ActivityLogsBottom extends StatefulWidget {
  final bool isLoadingMore;
  final bool loadingError;
  final Future<void> Function() loadMoreData;
  final bool hasMoreData;

  const ActivityLogsBottom(
      {required this.isLoadingMore, required this.loadingError, required this.loadMoreData, required this.hasMoreData, super.key});

  @override
  State<ActivityLogsBottom> createState() => _ActivityLogsBottomState();
}

class _ActivityLogsBottomState extends State<ActivityLogsBottom> {
  @override
  Widget build(BuildContext context) {
    if (widget.isLoadingMore) {
      return const SizedBox();
    } else if (widget.loadingError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent),
              const SizedBox(height: 8),
              const Text('데이터 로드 중 오류 발생'),
              TextButton(
                onPressed: () => widget.loadMoreData,
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    } else if (!widget.hasMoreData) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            '마지막 기록입니다',
            style: AppTextStyles.getCaption(context),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
