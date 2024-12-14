import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:project1/utils/database_service.dart';
import 'package:provider/provider.dart';
import 'package:scroll_to_index/scroll_to_index.dart'; // 스크롤 이동을 위해 추가

class ContentSection extends StatefulWidget {
  const ContentSection({super.key});

  @override
  State<ContentSection> createState() => _ContentSectionState();
}

class _ContentSectionState extends State<ContentSection> with TickerProviderStateMixin {
  late final DatabaseService _dbService; // 주입받을 DatabaseService
  List<Map<String, dynamic>> contents = [];
  final AutoScrollController _scrollController = AutoScrollController(); // 스크롤 컨트롤러

  @override
  void initState() {
    super.initState();
    _dbService = Provider.of<DatabaseService>(context, listen: false); // DatabaseService 주입
    _fetchContents();
  }

  // 로컬 데이터베이스에서 콘텐츠를 가져오는 함수
  Future<void> _fetchContents() async {
    final allContents = await _dbService.getContents();
    final uncompletedContents = allContents.where((content) => content['is_completed'] == 0).toList();

    // 우선순위 및 비우선순위로 분류
    final priorityContents = uncompletedContents.where((content) => content['priority'] == 1).toList();
    final nonPriorityContents = uncompletedContents.where((content) => content['priority'] == 0).toList();

    // 우선순위 콘텐츠 최대 7개, 비우선순위 콘텐츠 최대 3개 선택
    List<Map<String, dynamic>> selectedContents = [];
    selectedContents.addAll(priorityContents.take(7));
    if (selectedContents.length < 10) {
      selectedContents.addAll(nonPriorityContents.take(10 - selectedContents.length));
    }

    setState(() {
      contents = selectedContents;
    });
  }

  // 콘텐츠 완료 처리 함수
  Future<void> _completeContent(String contentId) async {
    await _dbService.markContentAsCompleted(contentId);
    await _fetchContents();
  }

  // 콘텐츠 새로고침 함수
  Future<void> _refreshContents() async {
    await _fetchContents();
    // 스크롤을 맨 왼쪽으로 이동
    _scrollController.scrollToIndex(0, preferPosition: AutoScrollPosition.begin);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목과 아이콘
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.0),
          child: Text(
            '콘텐츠',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: contents.length + 2, // 앞에 배너 하나, 뒤에 새로고침 버튼 하나 추가
            itemBuilder: (context, index) {
              if (index == 0) {
                // 맨 앞의 배너 컨테이너
                return Container(
                  width: 150,
                  margin: const EdgeInsets.only(left: 16, right: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      const Positioned(
                        left: 16,
                        top: 16,
                        child: Text(
                          '콘텐츠',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Positioned(
                        right: -15,
                        bottom: 0,
                        child: Image.asset(
                          'assets/images/sticker_tip_4.png',
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                );
              } else if (index == contents.length + 1) {
                // 맨 뒤의 새로고침 컨테이너
                return GestureDetector(
                  onTap: _refreshContents,
                  child: Container(
                    width: 150,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '새로고침',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Icon(
                          Icons.replay_rounded,
                          size: 28,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                final content = contents[index - 1]; // 인덱스 보정
                return _buildContentCard(content, isDarkMode);
              }
            },
          ),
        ),
      ],
    );
  }

  // 콘텐츠 카드 빌드 함수
  Widget _buildContentCard(Map<String, dynamic> content, bool isDarkMode) {
    bool isCompleted = false; // 완료 상태를 추적
    ValueNotifier<bool> isVisible = ValueNotifier(true); // 카드 표시 여부를 제어

    return ValueListenableBuilder<bool>(
      valueListenable: isVisible,
      builder: (context, visible, child) {
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: visible ? 1 : 0,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 300),
            offset: visible ? Offset.zero : const Offset(0, 1),
            child: visible
                ? Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            content['title'],
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black87,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            content['content'],
                            style: TextStyle(
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {
                                if (!isCompleted) {
                                  isCompleted = true;
                                  setState(() {}); // 애니메이션 갱신

                                  // 애니메이션이 끝난 후 카드 제거
                                  Future.delayed(const Duration(milliseconds: 500), () {
                                    isVisible.value = false;
                                  }).then((_) {
                                    // 일정 시간 후 실제 데이터베이스에서 완료 처리
                                    Future.delayed(const Duration(milliseconds: 300), () {
                                      _completeContent(content['id'] as String);
                                    });
                                  });
                                }
                              },
                              child: isCompleted
                                  ? Lottie.asset(
                                      'assets/animations/check_3.json',
                                      width: 50,
                                      height: 50,
                                      repeat: false,
                                    )
                                  : Icon(
                                      Icons.check_circle_outline,
                                      color: isDarkMode ? Colors.white : Colors.black54,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(), // 표시되지 않을 경우 빈 위젯 반환
          ),
        );
      },
    );
  }
}
