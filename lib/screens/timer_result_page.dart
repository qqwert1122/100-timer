import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lottie/lottie.dart';
import 'package:project1/screens/main_page.dart';
import 'package:project1/screens/timer_page.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/color_service.dart';
import 'package:project1/utils/database_service.dart';
import 'package:project1/utils/icon_utils.dart';
import 'package:project1/utils/music_player.dart';
import 'package:project1/utils/notification_service.dart';
import 'package:project1/utils/stats_provider.dart';
import 'package:project1/utils/timer_provider.dart';
import 'package:provider/provider.dart';
import 'package:project1/utils/responsive_size.dart';
import 'package:shimmer/shimmer.dart';

// StatelessWidget에서 StatefulWidget으로 변경
class TimerResultPage extends StatefulWidget {
  final Map<String, dynamic> timerData;
  final int sessionDuration;
  final bool isSessionTargetExceeded;

  const TimerResultPage({
    super.key,
    required this.timerData,
    required this.sessionDuration,
    required this.isSessionTargetExceeded,
  });

  @override
  State<TimerResultPage> createState() => _TimerResultPageState();
}

// State 클래스에 TickerProviderStateMixin 추가
class _TimerResultPageState extends State<TimerResultPage> with TickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  late final TimerProvider timerProvider;
  late final StatsProvider statsProvider;
  late final DatabaseService dbService;

  // 애니메이션 컨트롤러 선언
  late AnimationController _trophyController;
  late AnimationController _checkController;
  late AnimationController _congratulationsController;

  // musicPlayer
  final musicPlayer = MusicPlayer();

  // admob 광고
  BannerAd? _bannerAd1;
  bool _isAdLoaded1 = false;

  @override
  void initState() {
    super.initState();

    timerProvider = Provider.of<TimerProvider>(context, listen: false);
    statsProvider = Provider.of<StatsProvider>(context, listen: false);
    dbService = Provider.of<DatabaseService>(context, listen: false);

    // 음악 종료
    musicPlayer.stopMusic();

    // 트로피 애니메이션 컨트롤러 초기화
    _trophyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // 체크 애니메이션 컨트롤러 초기화
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // 축하 애니메이션 컨트롤러 초기화
    _congratulationsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // 애니메이션 시작
    if (widget.isSessionTargetExceeded) {
      _trophyController.forward();
    } else {
      _checkController.forward();
    }
    _congratulationsController.repeat();

    // admob 광고 초기화
    _bannerAd1 = BannerAd(
      // 이 광고 단위 ID는 Google에서 제공하는 테스트용 ID입니다.
      adUnitId: 'ca-app-pub-9503898094962699/9890914412',
      size: AdSize.fullBanner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          setState(() {
            _isAdLoaded1 = true;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
          print('BannerAd failed to load: $error');
        },
      ),
    );
    _bannerAd1!.load();
  }

  @override
  void dispose() {
    // 컨트롤러 해제
    _trophyController.dispose();
    _checkController.dispose();
    _congratulationsController.dispose();
    super.dispose();
  }

  String formatDuration(int seconds) {
    final Duration duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final remainingSeconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours시간 $minutes분';
    } else if (minutes > 0) {
      return '$minutes분 $remainingSeconds초';
    } else {
      return '$remainingSeconds초';
    }
  }

  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('정말 삭제하시겠습니까?', style: AppTextStyles.getTitle(context).copyWith(color: Colors.redAccent)),
              content: Text(
                '활동 기록을 삭제할 경우 통계에 반영되지 않으며 복구할 수 없습니다.',
                style: AppTextStyles.getBody(context),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('취소', style: AppTextStyles.getTitle(context).copyWith(color: Colors.grey)),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: Text('삭제', style: AppTextStyles.getTitle(context).copyWith(color: Colors.redAccent)),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Column(
              children: [
                SizedBox(height: context.hp(5)),
                _isAdLoaded1
                    ? Container(
                        width: _bannerAd1!.size.width.toDouble(),
                        height: _bannerAd1!.size.height.toDouble(),
                        child: AdWidget(ad: _bannerAd1!),
                      )
                    : SizedBox.shrink(),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            right: -context.wp(2.5),
                            top: -context.hp(1.5),
                            child: Transform.rotate(
                              angle: 0.05,
                              child: _buildCard(context, Colors.blue.shade100, 0.5),
                            ),
                          ),
                          Positioned(
                            left: -context.wp(2.5),
                            top: -context.hp(1.5),
                            child: Transform.rotate(
                              angle: -0.05,
                              child: _buildCard(context, Colors.deepPurple.shade100, 0.5),
                            ),
                          ),
                          _buildMainCard(context),
                        ],
                      ),
                      SizedBox(height: context.hp(15)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: context.spacing_sm,
                right: context.spacing_sm,
                bottom: context.spacing_sm,
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: context.hp(7),
                    child: ElevatedButton(
                      onPressed: () {
                        // 타이머 데이터 갱신 로직 추가
                        statsProvider.updateCurrentSessions();
                        // 남은 시간 갱신 및 상태 업데이트
                        timerProvider.refreshRemainingSeconds().then((_) {
                          // 갱신이 완료된 후 페이지 이동
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MainPage(),
                            ),
                          );
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(context.wp(3)),
                        ),
                      ),
                      child: Text(
                        '확인',
                        style: TextStyle(
                          fontSize: context.md,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: context.hp(1)),
                  SizedBox(
                    width: double.infinity,
                    height: context.hp(7),
                    child: ElevatedButton(
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        final shouldDelete = await _showDeleteConfirmationDialog(context);
                        if (!shouldDelete) return;

                        await dbService.deleteSession(widget.timerData['current_session_id']).then((_) {
                          // 갱신이 완료된 후 페이지 이동
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TimerPage(timerData: widget.timerData),
                            ),
                          );
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.backgroundTertiary(context),
                        foregroundColor: AppColors.textPrimary(context),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(context.wp(3)),
                        ),
                      ),
                      child: Text(
                        '활동 삭제하기',
                        style: TextStyle(
                          fontSize: context.md,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, Color color, double opacity) {
    return Container(
      width: context.wp(90),
      height: context.hp(50),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.wp(5)),
        color: color.withOpacity(opacity),
      ),
    );
  }

  Widget _buildMainCard(BuildContext context) {
    final timerProvider = Provider.of<TimerProvider>(context);
    final activityColor = ColorService.hexToColor(timerProvider.currentActivityColor);

    String formatTargetDuration() {
      return formatDuration(timerProvider.currentSessionTargetDuration!);
    }

    return Container(
      width: context.wp(90),
      height: context.hp(50),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.wp(5)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            activityColor.withOpacity(0.9),
            activityColor.withOpacity(0.7),
            activityColor.withOpacity(0.5),
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: activityColor.withOpacity(0.4),
            spreadRadius: context.wp(1),
            blurRadius: context.wp(4),
            offset: Offset(0, context.hp(0.5)),
          ),
        ],
      ),
      padding: context.paddingLG,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                getIconImage(timerProvider.currentActivityIcon),
                width: context.xxxl,
                height: context.xxxl,
              ),
              SizedBox(height: context.hp(2)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Builder(
                        builder: (context) {
                          final activityName = timerProvider.currentActivityName;
                          final displayText = activityName.length > 6 ? '${activityName.substring(0, 6)}...' : activityName;

                          return Text(
                            displayText,
                            style: AppTextStyles.getHeadline(context).copyWith(
                              color: ColorService.getTextColorForBackground(activityColor),
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Neo',
                            ),
                          );
                        },
                      ),
                      SizedBox(width: context.wp(2)),
                      Builder(
                        builder: (context) {
                          final activityName = timerProvider.currentActivityName;
                          final displayText = activityName.length > 6 ? '활동 완료' : '활동을 완료했습니다 !';

                          return Text(
                            displayText,
                            style: AppTextStyles.getTitle(context).copyWith(
                              fontWeight: FontWeight.w900,
                              color: ColorService.getTextColorForBackground(activityColor),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: context.hp(4)),
              Align(
                alignment: Alignment.center,
                child: Shimmer.fromColors(
                  baseColor: ColorService.getTextColorForBackground(activityColor),
                  highlightColor: Colors.grey.shade100.withOpacity(0.2),
                  child: Text(
                    formatDuration(widget.sessionDuration),
                    style: AppTextStyles.getHeadline(context).copyWith(
                      color: ColorService.getTextColorForBackground(activityColor),
                      fontFamily: 'Neo',
                      fontSize: context.xxl,
                    ),
                  ),
                ),
              ),
              SizedBox(height: context.hp(2)),
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    widget.isSessionTargetExceeded
                        ? Lottie.asset(
                            'assets/images/trophy.json',
                            repeat: true,
                            width: context.wp(30),
                            height: context.wp(30),
                            fit: BoxFit.contain,
                            controller: _trophyController,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.error,
                                color: Colors.red,
                                size: 24,
                              );
                            },
                          )
                        : Lottie.asset(
                            'assets/images/check_3.json',
                            repeat: true,
                            width: context.wp(20),
                            height: context.wp(20),
                            fit: BoxFit.contain,
                            controller: _checkController,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.error,
                                color: Colors.red,
                                size: 24,
                              );
                            },
                          ),
                  ],
                ),
              ),
            ],
          ),
          Lottie.asset(
            'assets/images/congraturations.json',
            repeat: true,
            width: context.wp(100),
            height: context.wp(100),
            fit: BoxFit.contain,
            controller: _congratulationsController,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.error,
                color: Colors.red,
                size: 24,
              );
            },
          ),
        ],
      ),
    );
  }
}
