import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:project1/daily_report/screens/ratio_card_11.dart';
import 'package:project1/daily_report/screens/ratio_card_45.dart';
import 'package:project1/daily_report/screens/ratio_card_916.dart';
import 'package:project1/daily_report/utils/daily_stats_utils.dart';
import 'package:project1/daily_report/widgets/data_insufficient_widget.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/logger_config.dart';
import 'package:project1/utils/responsive_size.dart';

import 'package:project1/utils/screenshot_service.dart';

class DailyReportPage extends StatefulWidget {
  const DailyReportPage({super.key});

  @override
  State<DailyReportPage> createState() => _DailyReportPageState();
}

class _DailyReportPageState extends State<DailyReportPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Animation<double>? _widthAnimation;
  Animation<double>? _heightAnimation;

  // 스크린샷을 위한 GlobalKey
  final GlobalKey _dailyReportRepaintBoundaryKey = GlobalKey();

  // 현재 선택된 사이즈 타입
  String _selectedSize = '4:5';

  // 각 사이즈별 비율 정의
  final Map<String, double> _aspectRatios = {
    '4:5': 4 / 5,
    '1:1': 1 / 1,
    '9:16': 9 / 16,
  };

  bool isDataInsufficient = false;
  int totalSeconds = 0;
  Map<String, Map<String, dynamic>> activityTimes = {};
  List<Map<String, dynamic>> activities = [];
  List<Map<String, dynamic>> hourlyData = [];
  List<int> sevenDayTimes = [];
  DateTime selectedDate = DateTime.now();
  Map<String, dynamic> comparisonData = {};
  int currentStreak = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadDailyStats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_widthAnimation == null) {
      _setupAnimations('4:5');
    }
  }

  void _setupAnimations(String sizeType) {
    final maxWidth = context.wp(90);
    final aspectRatio = _aspectRatios[sizeType] ?? 1.0;

    double targetWidth, targetHeight;

    if (sizeType == '9:16') {
      // 세로형은 높이 기준으로 계산
      targetHeight = maxWidth * 1.4;
      targetWidth = targetHeight * aspectRatio;
    } else {
      // 4:5, 1:1은 너비 기준으로 계산
      targetWidth = maxWidth;
      targetHeight = targetWidth / aspectRatio;
    }

    _widthAnimation = Tween<double>(
      begin: _widthAnimation?.value ?? targetWidth,
      end: targetWidth,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _heightAnimation = Tween<double>(
      begin: _heightAnimation?.value ?? targetHeight,
      end: targetHeight,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  void _changeSize(String sizeType) {
    if (_selectedSize == sizeType) return;

    setState(() {
      _selectedSize = sizeType;
    });
    _setupAnimations(sizeType);
    _animationController.reset();
    _animationController.forward();
    HapticFeedback.lightImpact();
  }

  void _changeDate(int days) {
    final newDate = selectedDate.add(Duration(days: days));
    final today = DateTime.now();

    if (newDate.isAfter(today)) {
      return;
    }

    setState(() {
      selectedDate = newDate;
    });
    logger.d(selectedDate);
    _loadDailyStats();
    HapticFeedback.lightImpact();
  }

  void _loadDailyStats() async {
    final result = await DailyStatsUtils.getDailyStats(selectedDate);
    final total = await DailyStatsUtils.getTotalActivityTime(selectedDate);
    final tempActivityTimes = await DailyStatsUtils.getActivityTimes(selectedDate);
    final tempActivities = tempActivityTimes.values.toList();
    final sevenDays = <int>[];
    final tempHourlyData = await DailyStatsUtils.getHourlyActivityChart(selectedDate);
    final tempComparison = await DailyStatsUtils.compareWithYesterday(selectedDate);
    final streak = await DailyStatsUtils.calculateCurrentStreak(selectedDate);

    for (int i = 6; i >= 0; i--) {
      final dayDate = selectedDate.subtract(Duration(days: i));
      final dayTotal = await DailyStatsUtils.getTotalActivityTime(dayDate);
      sevenDays.add(dayTotal);
    }

    setState(() {
      isDataInsufficient = result.isDataInsufficient;
      totalSeconds = total;
      activityTimes = tempActivityTimes;
      activities = tempActivities;
      hourlyData = tempHourlyData;
      sevenDayTimes = sevenDays;
      comparisonData = tempComparison;
      currentStreak = streak;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenshotService = ScreenshotService();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '데일리 리포트',
          style: AppTextStyles.getTitle(context),
        ),
        backgroundColor: AppColors.backgroundSecondary(context),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary(context),
        ),
        child: Column(
          children: [
            // 메인 컨텐츠 영역
            Expanded(
              child: Center(
                child: RepaintBoundary(
                  key: _dailyReportRepaintBoundaryKey,
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      // 애니메이션이 아직 초기화되지 않은 경우 기본값 사용
                      if (_widthAnimation == null || _heightAnimation == null) {
                        return Container(
                          width: 200,
                          height: 250,
                          decoration: BoxDecoration(
                            color: AppColors.background(context),
                          ),
                        );
                      }

                      switch (_selectedSize) {
                        case '4:5':
                          return RatioCard45(
                            width: _widthAnimation!.value,
                            height: _heightAnimation!.value,
                            selectedDate: selectedDate,
                            isDataInsufficient: isDataInsufficient,
                            totalSeconds: totalSeconds,
                            activityTimes: activityTimes,
                            activities: activities,
                            sevenDayTimes: sevenDayTimes,
                            hourlyData: hourlyData,
                            comparisonData: comparisonData,
                            currentSteak: currentStreak,
                          );
                        case '1:1':
                          return RatioCard11(
                            width: _widthAnimation!.value,
                            height: _heightAnimation!.value,
                            selectedDate: selectedDate,
                            isDataInsufficient: isDataInsufficient,
                            totalSeconds: totalSeconds,
                            activityTimes: activityTimes,
                            activities: activities,
                            sevenDayTimes: sevenDayTimes,
                            hourlyData: hourlyData,
                            comparisonData: comparisonData,
                            currentSteak: currentStreak,
                          );
                        case '9:16':
                          return RatioCard916(
                            width: _widthAnimation!.value,
                            height: _heightAnimation!.value,
                            selectedDate: selectedDate,
                            isDataInsufficient: isDataInsufficient,
                            totalSeconds: totalSeconds,
                            activityTimes: activityTimes,
                            activities: activities,
                            sevenDayTimes: sevenDayTimes,
                            hourlyData: hourlyData,
                            comparisonData: comparisonData,
                            currentSteak: currentStreak,
                          );
                        default:
                          return CircularProgressIndicator(
                            color: Colors.grey,
                          );
                      }
                    },
                  ),
                ),
              ),
            ),

            _buildActionButton(screenshotService),

            // 하단 버튼 영역
            Container(
              margin: context.paddingSM,
              decoration: BoxDecoration(
                color: AppColors.background(context),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSizeButton('4:5', '인스타'),
                  _buildSizeButton('1:1', '정사각형'),
                  _buildSizeButton('9:16', '스토리'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(ScreenshotService screenshotService) {
    return Container(
      width: double.infinity,
      margin: context.paddingHorizSM,
      child: Row(
        children: [
          _buildDateButton(LucideIcons.chevronLeft, () => _changeDate(-1)),
          SizedBox(width: context.wp(2)),
          _buildDateButton(LucideIcons.chevronRight, () => _changeDate(1)),
          SizedBox(width: context.wp(2)),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await screenshotService.captureAndSave(
                  boundaryKey: _dailyReportRepaintBoundaryKey,
                  fileName: 'timer100_daily_report_${DateTime.now().millisecondsSinceEpoch}',
                );

                // 결과 표시
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result.message)),
                );
              },
              icon: const Icon(LucideIcons.download),
              label: Text(
                '스크린샷 저장',
                style: AppTextStyles.getBody(context).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: Colors.black.withValues(alpha: 0.1),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: AppColors.background(context),
      borderRadius: BorderRadius.circular(12),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon),
        ),
      ),
    );
  }

  Widget _buildSizeButton(String sizeType, String description) {
    final isSelected = _selectedSize == sizeType;

    return GestureDetector(
      onTap: () => _changeSize(sizeType),
      child: AnimatedContainer(
        width: context.wp(20),
        duration: const Duration(milliseconds: 200),
        padding: context.paddingXS,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              sizeType,
              style: AppTextStyles.getBody(context).copyWith(
                color: isSelected ? Colors.blueAccent : AppColors.textSecondary(context),
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              description,
              textAlign: TextAlign.center,
              style: AppTextStyles.getCaption(context).copyWith(
                color: isSelected ? Colors.blueAccent : AppColors.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
