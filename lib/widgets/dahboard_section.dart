import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/responsive_size.dart';
import 'package:project1/utils/stats_provider.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class DashboardSection extends StatefulWidget {
  const DashboardSection({super.key});

  @override
  _DashboardSectionState createState() => _DashboardSectionState();
}

class _DashboardSectionState extends State<DashboardSection> {
  // 2. Future를 클래스 변수로 저장하여 한 번만 생성
  Future<List<int>>? _statsFuture;
  StatsProvider? statsProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      statsProvider = Provider.of<StatsProvider>(context, listen: false);
      // statsProvider의 변경을 감지하는 리스너 추가
      statsProvider!.addListener(_updateStats);
      _updateStats();
    });
  }

  void _updateStats() {
    // statsProvider의 값이 변경될 때마다 Future를 갱신
    setState(() {
      _statsFuture = Future.wait([
        statsProvider!.getTotalDurationForWeek(),
        statsProvider!.getTotalSecondsForWeek(),
      ]);
    });
  }

  @override
  void dispose() {
    statsProvider?.removeListener(_updateStats);
    super.dispose();
  }

  String _formatHour(int seconds) {
    final hours = seconds ~/ 3600;
    return '$hours';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background(context),
      ),
      child: Padding(
        padding: context.paddingSM,
        child: FutureBuilder<List<int>>(
          // 4. 저장된 Future 사용
          future: _statsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(
                children: [
                  Center(child: Text("활동 완료 시간", style: AppTextStyles.getTitle(context))),
                  SizedBox(height: context.hp(3)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: context.hp(1)),
                          Shimmer.fromColors(
                            baseColor: Colors.grey.shade300.withValues(alpha: 0.2),
                            highlightColor: Colors.grey.shade100.withValues(alpha: 0.2),
                            child: Container(
                              width: context.wp(50),
                              height: context.hp(7),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: AppColors.background(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Shimmer.fromColors(
                        baseColor: Colors.grey.shade300.withValues(alpha: 0.2),
                        highlightColor: Colors.grey.shade100,
                        child: Container(
                          width: context.wp(24),
                          height: context.wp(24),
                          decoration: BoxDecoration(
                            color: AppColors.background(context),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }

            if (snapshot.hasError) {
              return const Text('에러 발생');
            }

            final totalDuration = snapshot.data?[0] ?? 0;
            final totalSeconds = snapshot.data?[1] ?? 1;

            final formattedDuration = _formatHour(totalDuration);
            final tagetDuration = _formatHour(totalSeconds);

            double percent = (totalDuration / totalSeconds);
            String percentText = (percent * 100).toStringAsFixed(0);
            return Column(
              children: [
                Text("활동 완료 시간", style: AppTextStyles.getTitle(context)),
                SizedBox(height: context.hp(1)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      formattedDuration,
                      style: AppTextStyles.getTimeDisplay(context).copyWith(
                        fontFamily: 'chab',
                        color: Colors.redAccent,
                      ),
                    ),
                    SizedBox(width: context.wp(1)),
                    Container(
                      width: 1,
                      height: context.hp(2),
                      color: Colors.grey.shade400,
                      margin: EdgeInsets.symmetric(horizontal: context.wp(1)),
                    ),
                    SizedBox(width: context.wp(1)),
                    Text(
                      '${tagetDuration}h',
                      style: AppTextStyles.getTimeDisplay(context).copyWith(
                        fontFamily: 'chab',
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
