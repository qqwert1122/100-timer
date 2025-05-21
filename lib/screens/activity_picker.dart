import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:project1/screens/add_activity_page.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/color_service.dart';
import 'package:project1/utils/database_service.dart';
import 'package:project1/utils/icon_utils.dart';
import 'package:project1/utils/logger_config.dart';
import 'package:project1/utils/prefs_service.dart';
import 'package:project1/utils/stats_provider.dart';
import 'package:project1/utils/responsive_size.dart';
import 'package:project1/utils/time.formatter.dart';
import 'package:project1/utils/timer_provider.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';

class ActivityPicker extends StatefulWidget {
  final String selectedActivity;
  final Function(String, String, String, String) onSelectActivity;

  const ActivityPicker({
    super.key,
    required this.selectedActivity,
    required this.onSelectActivity,
  });

  static final GlobalKey listKey3 = GlobalKey(debugLabel: 'activityPicker');

  @override
  _ActivityPickerState createState() => _ActivityPickerState();
}

class _ActivityPickerState extends State<ActivityPicker> with SingleTickerProviderStateMixin {
  late Future<List<Map<String, dynamic>>> _activityListFuture;
  late Future<List<Map<String, dynamic>>> _favoriteActivityListFuture;
  late final DatabaseService _dbService;
  late final StatsProvider _statsProvider;
  late final TimerProvider _timerProvider;

  // 탭/페이지 컨트롤러
  late TabController _tabController;
  late PageController _pageController;
  int _currentPageIndex = 0;

  // 활동 데이터 리스트
  List<Map<String, dynamic>> _allActivities = [];
  List<Map<String, dynamic>> _favoriteActivities = [];
  List<Map<String, dynamic>> _recentActivities = [];
  bool _isLoading = true;

  // 검색 관련 변수
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> filteredActivities = [];
  List<Map<String, dynamic>> rawActivities = [];
  late FocusNode _searchFocusNode;
  Timer? _debounce;

  // 편집 모드 (순서 변경 모드) 플래그
  bool isEditingOrder = false;

  // Onboarding flag
  bool _needShowOnboarding = false;

  // Onboarding GlobalKey
  final GlobalKey _addActivityKey = GlobalKey();
  final GlobalKey _searchKey = GlobalKey();
  final GlobalKey _listKey1 = GlobalKey();
  final GlobalKey _listKey2 = GlobalKey();
  final _listKey3 = ActivityPicker.listKey3;

  @override
  void initState() {
    super.initState();

    _statsProvider = Provider.of<StatsProvider>(context, listen: false);
    _dbService = Provider.of<DatabaseService>(context, listen: false);
    _timerProvider = Provider.of<TimerProvider>(context, listen: false);
    _tabController = TabController(length: 2, vsync: this);
    _pageController = PageController(initialPage: 0);

    // 탭 전환 시 페이지뷰 동기화
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _pageController.animateToPage(
          _tabController.index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });

    // 검색 focusNode 객체 생성 및 리스너 부착
    _searchFocusNode = FocusNode();
    _searchFocusNode.addListener(() {
      setState(() {});
    });

    _loadInitialData().then(
      (_) {
        _needShowOnboarding = !PrefsService().getOnboarding('activityPicker');
        if (_needShowOnboarding) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) {
              if (!mounted) return;
              _startShowcaseIfReady();
            },
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabController.dispose();
    _pageController.dispose();
    searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _startShowcaseIfReady() {
    // ① 현재 트리에 존재할 가능성이 있는 키만 추려서 배열 생성
    final keys = <GlobalKey>[
      if (_allActivities.length > 0) _listKey1,
      if (_allActivities.length > 1) _listKey2,
      if (_allActivities.length > 2) _listKey3,
      _searchKey,
      _addActivityKey,
    ];

    // ③ ShowCaseWidget 인스턴스 존재 여부 확인
    final showcaseState = ShowCaseWidget.of(context);

    // ④ 조건 만족 시 실행
    if (keys.any((k) => k.currentContext != null)) {
      showcaseState.startShowCase(keys);
    } else {}
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // DB에서 활동 목록 가져오기
      final rawAllActivities = await _statsProvider.getActivities();
      final rawFavoriteActivities = await _statsProvider.getFavoriteActivities();

      // 데이터의 깊은 복사본 생성 (불변 객체 방지)
      final allActivities = rawAllActivities.map((activity) => Map<String, dynamic>.from(activity)).toList();
      final favoriteActivities = rawFavoriteActivities.map((activity) => Map<String, dynamic>.from(activity)).toList();

      // 최근 활동 목록 생성 (last_used_at 기준 정렬)
      final recentActivities = allActivities.where((activity) => activity['last_used_at'] != null).toList()
        ..sort((a, b) => (b['last_used_at'] as String).compareTo(a['last_used_at'] as String));

      setState(() {
        _allActivities = allActivities;
        _favoriteActivities = favoriteActivities;
        _recentActivities = recentActivities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToAddActivityPage(BuildContext context) async {
    final newActivity = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddActivityPage()),
    );

    if (newActivity != null) {
      _loadInitialData();
    }
  }

  Future<void> _navigateToEditActivityPage(
      BuildContext context, String activityId, String activityName, String activityIcon, String activityColor) async {
    final updatedActivity = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddActivityPage(
          isEdit: true,
          activityId: activityId,
          activityName: activityName,
          activityIcon: activityIcon,
          activityColor: activityColor,
        ),
      ),
    );

    if (updatedActivity != null) {
      _loadInitialData();
      if (_timerProvider.currentActivityId == updatedActivity['id']) {
        logger.d('선택된 활동의 변경, setCurrentActivity 호출');
        _timerProvider.setCurrentActivity(
          updatedActivity['id'],
          updatedActivity['name'],
          updatedActivity['icon'],
          updatedActivity['color'],
        );
      }
    }
  }

  Future<void> _deleteActivity(BuildContext context, String activityId, String activityName) async {
    final shouldDelete = await _showDeleteConfirmationDialog(context, activityName);
    if (shouldDelete) {
      await _dbService.deleteActivity(activityId);

      setState(() {
        _allActivities.removeWhere((activity) => activity['activity_id'] == activityId);
        _favoriteActivities.removeWhere((activity) => activity['activity_id'] == activityId);
        _recentActivities.removeWhere((activity) => activity['activity_id'] == activityId);
      });

      if (widget.selectedActivity == activityName) {
        final defaultAcitivty = await _statsProvider.getDefaultActivity();
        widget.onSelectActivity(
          defaultAcitivty!['activity_id'],
          defaultAcitivty['activity_name'],
          defaultAcitivty['activity_icon'],
          defaultAcitivty['activity_color'],
        );
      }

      Fluttertoast.showToast(
        msg: "활동이 삭제되었습니다",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.redAccent.shade200,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    }
  }

  Future<bool> _showDeleteConfirmationDialog(BuildContext context, String activity) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: AppColors.background(context),
              title: Text('정말 삭제하시겠습니까?', style: AppTextStyles.getTitle(context).copyWith(color: Colors.redAccent)),
              content: Text(
                '활동을 삭제할 경우 같은 이름으로 재생성 할 수는 있으나 복구할 수 없습니다.',
                style: AppTextStyles.getBody(context),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('취소', style: AppTextStyles.getTitle(context).copyWith(color: Colors.grey)),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: Text('삭제', style: AppTextStyles.getTitle(context).copyWith(color: Colors.redAccent)),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _onPageChanged(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _currentPageIndex = index;
      _tabController.animateTo(index);
    });
  }

  // 즐겨찾기 상태 토글
  Future<void> _toggleFavorite(Map<String, dynamic> activity) async {
    final activityId = activity['activity_id'];
    final newFavoriteValue = activity['is_favorite'] == 1 ? 0 : 1;

    // DB 업데이트
    await _dbService.updateActivity(
      activityId: activityId,
      newIsFavorite: newFavoriteValue,
    );

    // 메모리 내 목록 업데이트
    setState(() {
      // 전체 활동 목록에서 즐겨찾기 상태 업데이트
      final index = _allActivities.indexWhere((a) => a['activity_id'] == activityId);
      if (index != -1) {
        _allActivities[index]['is_favorite'] = newFavoriteValue;
      }

      // 최근 활동 목록에서도 업데이트
      final recentIndex = _recentActivities.indexWhere((a) => a['activity_id'] == activityId);
      if (recentIndex != -1) {
        _recentActivities[recentIndex]['is_favorite'] = newFavoriteValue;
      }

      // 즐겨찾기 목록 업데이트
      if (newFavoriteValue == 1) {
        // 즐겨찾기에 추가
        if (!_favoriteActivities.any((a) => a['activity_id'] == activityId)) {
          _favoriteActivities.add(_allActivities[index]);
        }
      } else {
        // 즐겨찾기에서 제거
        _favoriteActivities.removeWhere((a) => a['activity_id'] == activityId);
      }
    });

    Fluttertoast.showToast(
      msg: newFavoriteValue == 1 ? "즐겨찾기에 추가되었습니다" : "즐겨찾기에서 제거되었습니다",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.blueAccent,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  // 활동 검색
  void _onActivitySearch(String query) {
    final result = _allActivities.where((activity) {
      final name = activity['activity_name'] as String;
      return name.toLowerCase().contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredActivities = result;
      isSearching = query.trim().isNotEmpty && result.isNotEmpty;
    });
  }

  // 활동 순서 변경 (즐겨찾기)
  Future<void> _reorderFavoriteActivities(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;

    setState(() {
      // UI상의 리스트 순서 재배열
      final item = _favoriteActivities.removeAt(oldIndex);
      _favoriteActivities.insert(newIndex, item);
    });

    // 즐겨찾기 리스트의 순서(인덱스)를 DB에 업데이트
    for (int i = 0; i < _favoriteActivities.length; i++) {
      // 각 즐겨찾기 활동의 새로운 순서를 updateActivityOrder() 함수에 전달
      await _dbService.updateActivityOrder(
        activityId: _favoriteActivities[i]['activity_id'],
        newFavoriteOrder: i, // 즐겨찾기 순서 업데이트
        newSortOrder: _favoriteActivities[i]['sort_order'],
      );
    }
  }

  // 활동 순서 변경 (전체)
  Future<void> _reorderAllActivities(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;

    setState(() {
      final item = _allActivities.removeAt(oldIndex);
      _allActivities.insert(newIndex, item);
    });

    for (int i = 0; i < _allActivities.length; i++) {
      await _dbService.updateActivityOrder(
        activityId: _allActivities[i]['activity_id'],
        newSortOrder: i,
      );
    }
  }

  /// 슬라이더와 ListTile을 조합한 활동 항목 위젯.
  Widget _buildActivityTile(
    Map<String, dynamic> activity, {
    bool isRecentList = true,
  }) {
    final iconName = activity['activity_icon'];
    final iconData = getIconImage(iconName);
    Widget tile = Slidable(
      key: ValueKey(activity['activity_id']),
      closeOnScroll: true,
      enabled: activity['is_default'] != 1, // 기본 활동이면 슬라이드 비활성화
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          // 즐겨찾기 토글
          SlidableAction(
            onPressed: (context) async {
              HapticFeedback.lightImpact();
              await _toggleFavorite(activity);
            },
            backgroundColor: Colors.yellow,
            foregroundColor: Colors.black,
            icon: activity['is_favorite'] != 1 ? Icons.star_border_rounded : Icons.star_rounded,
            flex: 1,
            autoClose: true,
          ),
          // 순서 변경 액션 - 클릭 시 드래그 가능하다는 메시지 노출
          if (!isRecentList)
            SlidableAction(
              onPressed: (context) {
                HapticFeedback.lightImpact();
                setState(() {
                  isEditingOrder = !isEditingOrder;
                });
                Fluttertoast.showToast(
                  msg: "드래그하여 위치 변경하세요",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                );
              },
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              icon: Icons.swap_vert_rounded,
              flex: 1,
              autoClose: true,
            ),
        ],
      ),
      endActionPane: activity['is_default'] != 1
          ? ActionPane(
              motion: const DrawerMotion(),
              children: [
                SlidableAction(
                  onPressed: (context) {
                    _navigateToEditActivityPage(
                      context,
                      activity['activity_id'],
                      activity['activity_name'],
                      activity['activity_icon'],
                      activity['activity_color'],
                    );
                  },
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  icon: Icons.edit,
                  flex: 1,
                  autoClose: true,
                ),
                SlidableAction(
                  onPressed: (context) {
                    _deleteActivity(context, activity['activity_id'], activity['activity_name']);
                  },
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  icon: Icons.delete,
                  flex: 1,
                ),
              ],
            )
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: activity['activity_name'] == widget.selectedActivity ? Colors.red[50] : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 0),
          child: ListTile(
            leading: Image.asset(
              iconData,
              width: context.xl,
              height: context.xl,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: context.xl,
                  height: context.xl,
                  color: Colors.grey.withValues(alpha: 0.2),
                  child: const Icon(
                    Icons.broken_image,
                    size: 40,
                    color: Colors.grey,
                  ),
                );
              },
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    isRecentList && activity['activity_name'].length >= 10
                        ? '${activity['activity_name'].substring(0, 10)}...'
                        : activity['activity_name'],
                    style: AppTextStyles.getBody(context).copyWith(
                      fontWeight: FontWeight.w900,
                      color: activity['activity_name'] == widget.selectedActivity ? Colors.redAccent.shade200 : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.symmetric(vertical: 2.0),
                  decoration: BoxDecoration(
                    color: ColorService.hexToColor(activity['activity_color']),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            // 편집 모드일 때만 순서 변경 아이콘 표시
            trailing: isEditingOrder
                ? const Icon(Icons.swap_vert_rounded)
                : isRecentList && activity['last_used_at'] != null
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: context.md,
                            color: AppColors.textSecondary(context),
                          ),
                          SizedBox(width: context.wp(1)),
                          Text(
                            getTimeAgo(
                              activity['last_used_at'],
                            ),
                            style: AppTextStyles.getCaption(context).copyWith(
                              color: AppColors.textSecondary(context),
                            ),
                          ),
                        ],
                      )
                    : null,

            onTap: () {
              HapticFeedback.lightImpact();
              widget.onSelectActivity(
                activity['activity_id'],
                activity['activity_name'],
                activity['activity_icon'],
                activity['activity_color'],
              );
            },
          ),
        ),
      ),
    );

    return tile;
  }

  /// ReorderableListView에서 사용하기 위한 래퍼 위젯 (key 포함)
  Widget _buildReorderableTile({
    required Key key,
    required Map<String, dynamic> activity,
    required bool isRecentList,
  }) {
    return Container(
        key: key,
        child: _buildActivityTile(
          activity,
          isRecentList: isRecentList,
        ));
  }

  /// "전체 활동" 탭 – CustomScrollView 내에 검색 영역, 섹션 헤더 및 ReorderableListView 구성
  Widget _buildAllTab() {
    if (_isLoading) {
      return Center(
          child: CircularProgressIndicator(
        color: AppColors.backgroundSecondary(context),
      ));
    }

    // 검색 시 전체(즐겨찾기+일반) 활동으로 필터링
    return CustomScrollView(
      slivers: [
        // 검색 모드일 경우 검색 결과를 SliverList로 노출
        if (isSearching)
          filteredActivities.isNotEmpty
              ? SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final activity = filteredActivities[index];
                      return _buildActivityTile(activity);
                    },
                    childCount: filteredActivities.length,
                  ),
                )
              : const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: SizedBox(),
                  ),
                )
        else ...[
          // 즐겨찾기 섹션 헤더
          if (_favoriteActivities.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 8.0,
                  left: 8.0,
                  right: 8.0,
                  bottom: 2.0,
                ),
                child: Text("즐겨찾기",
                    style: AppTextStyles.getBody(context).copyWith(
                      fontWeight: FontWeight.w900,
                    )),
              ),
            ),
          // 즐겨찾기 활동 ReorderableListView (내부 스크롤 비활성화, proxyDecorator 적용)
          if (_favoriteActivities.isNotEmpty)
            SliverToBoxAdapter(
              child: ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                proxyDecorator: (child, index, animation) {
                  return Material(
                    color: AppColors.backgroundSecondary(context),
                    borderRadius: BorderRadius.circular(16),
                    elevation: 2,
                    child: child,
                  );
                },
                onReorder: _reorderFavoriteActivities,
                children: List.generate(
                  _favoriteActivities.length,
                  (index) {
                    final activity = _favoriteActivities[index];

                    Widget tile = _buildReorderableTile(
                      key: ValueKey(activity['activity_id']),
                      activity: activity,
                      isRecentList: false,
                    );

                    return tile;
                  },
                ),
              ),
            ),
          // 전체 활동 섹션 헤더
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(
                top: 16.0,
                left: 8.0,
                right: 8.0,
                bottom: 2.0,
              ),
              child: Text(
                "전체 활동",
                style: AppTextStyles.getBody(context).copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          // 일반 활동 ReorderableListView (내부 스크롤 비활성화, proxyDecorator 적용)
          SliverToBoxAdapter(
            child: ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              proxyDecorator: (child, index, animation) {
                return Material(
                  color: AppColors.backgroundSecondary(context),
                  borderRadius: BorderRadius.circular(16),
                  elevation: 2,
                  child: child,
                );
              },
              onReorder: _reorderAllActivities,
              children: List.generate(
                _allActivities.length,
                (index) {
                  final activity = _allActivities[index];

                  Widget tile = _buildReorderableTile(
                    key: ValueKey(activity['activity_id']),
                    activity: activity,
                    isRecentList: false,
                  );

                  if (index == 0) {
                    tile = Showcase(
                      key: _listKey1,
                      description: '활동을 선택하세요',
                      targetBorderRadius: BorderRadius.circular(16),
                      targetShapeBorder: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      overlayOpacity: 0.5,
                      child: tile,
                    );
                  }

                  if (index == 1) {
                    tile = Showcase(
                      key: _listKey2,
                      description: '좌우로 드래그해서 즐겨찾기/삭제',
                      targetBorderRadius: BorderRadius.circular(16),
                      targetShapeBorder: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      overlayOpacity: 0.5,
                      child: tile,
                    );
                  }

                  if (index == 2) {
                    tile = Showcase(
                      key: _listKey3,
                      description: '길게 눌러 순서를 편집하세요',
                      targetBorderRadius: BorderRadius.circular(16),
                      targetShapeBorder: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      overlayOpacity: 0.5,
                      child: tile,
                    );
                  }

                  return tile;
                },
              ),
            ),
          ),
          // '활동 추가' 버튼
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: ListTile(
              leading: const Icon(Icons.add, color: Colors.blue),
              title: Text('활동 추가', style: AppTextStyles.getBody(context).copyWith(fontWeight: FontWeight.w900)),
              onTap: () {
                _navigateToAddActivityPage(context);
              },
            ),
          ),
        ],
      ],
    );
  }

  /// "최근 활동" 탭 – last_used_at 내림차순 ListView로 노출 (startActionPane 없이)
  Widget _buildRecentTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_recentActivities.isEmpty) {
      return Center(child: Text('데이터가 없습니다.', style: AppTextStyles.getBody(context)));
    }

    return ListView.builder(
      itemCount: _recentActivities.length,
      itemBuilder: (context, index) {
        final activity = _recentActivities[index];
        // 최근 탭에서는 startActionPane 제거
        return _buildActivityTile(
          activity,
          isRecentList: true,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.hp(90),
      padding: context.paddingSM,
      decoration: BoxDecoration(
        color: AppColors.background(context),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          // 상단 드래그바
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: context.paddingXS,
              width: context.wp(20),
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.textPrimary(context),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          // "활동 선택하기" 제목과 오른쪽에 "추가", "편집" 버튼 (편집 시 순서 변경 아이콘 표시)
          Padding(
            padding: context.paddingSM,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('활동', style: AppTextStyles.getTitle(context)),
                Row(
                  children: [
                    Showcase(
                      key: _addActivityKey,
                      description: '활동을 새로 만들어보세요',
                      targetBorderRadius: BorderRadius.circular(16),
                      overlayOpacity: 0.5,
                      child: ElevatedButton(
                        onPressed: () {
                          _navigateToAddActivityPage(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: context.paddingXS,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.add_rounded, color: Colors.white),
                            SizedBox(width: context.wp(1)),
                            Text(
                              '추가',
                              style: AppTextStyles.getCaption(context).copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: context.wp(2)),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isEditingOrder = !isEditingOrder;
                        });
                        if (isEditingOrder) {
                          Fluttertoast.showToast(
                            msg: "드래그하여 위치 변경하세요",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isEditingOrder ? Colors.indigoAccent : AppColors.backgroundSecondary(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: context.paddingXS,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.swap_vert_rounded,
                            color: isEditingOrder ? Colors.white : AppColors.textPrimary(context),
                          ),
                          SizedBox(width: context.wp(1)),
                          Text(
                            '순서편집',
                            style: AppTextStyles.getCaption(context).copyWith(
                              color: isEditingOrder ? Colors.white : AppColors.textPrimary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppColors.textPrimary(context),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelPadding: const EdgeInsets.symmetric(horizontal: 16.0),
            labelColor: AppColors.background(context),
            labelStyle: AppTextStyles.getBody(context).copyWith(
              fontWeight: FontWeight.w900,
            ),
            unselectedLabelStyle: AppTextStyles.getBody(context).copyWith(
              fontWeight: FontWeight.w900,
            ),
            unselectedLabelColor: AppColors.textPrimary(context),
            tabs: const [
              Tab(text: '전체 활동'),
              Tab(text: '최근 활동'),
            ],
          ),
          SizedBox(height: context.hp(1)),
          // 상단 검색 영역: 검색 버튼 또는 텍스트필드 전환
          _currentPageIndex == 0
              ? Showcase(
                  key: _searchKey,
                  description: '활동을 검색해서 찾아보세요',
                  targetBorderRadius: BorderRadius.circular(16),
                  targetPadding: const EdgeInsets.all(1.0),
                  targetShapeBorder: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  overlayOpacity: 0.5,
                  child: TextField(
                    controller: searchController,
                    textInputAction: TextInputAction.search,
                    onChanged: (query) {
                      // 기존에 실행 중인 디바운스 타이머가 있으면 취소
                      if (_debounce?.isActive ?? false) _debounce!.cancel();
                      _debounce = Timer(const Duration(milliseconds: 300), () {
                        // 300ms 후에 검색어가 있는지 확인 후 검색 실행
                        if (query.trim().isNotEmpty) {
                          _onActivitySearch(query);
                          setState(() {
                            isSearching = true;
                          });
                        } else {
                          setState(() {
                            filteredActivities = [];
                            isSearching = false;
                          });
                        }
                        print('Debounced search executed: $query');
                      });
                    },
                    onSubmitted: (query) {
                      // 사용자가 엔터를 누르면 즉시 디바운스 취소 후 검색 실행
                      if (_debounce?.isActive ?? false) _debounce!.cancel();
                      if (query.trim().isNotEmpty) {
                        _onActivitySearch(query);
                        setState(() {
                          isSearching = true;
                        });
                      } else {
                        setState(() {
                          filteredActivities = [];
                          isSearching = false;
                        });
                      }
                      print('onSubmitted: $query');
                    },
                    decoration: InputDecoration(
                      hintText: "활동 이름을 검색하세요",
                      hintStyle: AppTextStyles.getBody(context).copyWith(color: AppColors.textSecondary(context)),
                      border: InputBorder.none,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide.none, // 테두리 없음
                        borderRadius: BorderRadius.circular(8), // 원하는 둥근 정도로 조정 가능
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide.none, // 포커스 상태에서도 테두리 없음
                        borderRadius: BorderRadius.circular(8), // 원하는 둥근 정도로 조정 가능
                      ),
                      filled: true,
                      fillColor: AppColors.backgroundSecondary(context),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: context.xs,
                        horizontal: context.sm,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _searchFocusNode.hasFocus || searchController.text.isNotEmpty ? Icons.clear : Icons.search_rounded,
                        ),
                        onPressed: () {
                          // 검색 종료 시 초기화
                          setState(() {
                            isSearching = false;
                            searchController.clear();
                            filteredActivities = [];
                          });
                          FocusScope.of(context).unfocus(); // 키보드 숨기기
                        },
                      ),
                    ),
                  ),
                )
              : Container(),
          SizedBox(height: context.hp(2)),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const AlwaysScrollableScrollPhysics(),
              onPageChanged: _onPageChanged,
              children: [
                _buildAllTab(),
                _buildRecentTab(),
              ],
            ),
          ),
          SizedBox(height: context.hp(1)),
        ],
      ),
    );
  }
}
