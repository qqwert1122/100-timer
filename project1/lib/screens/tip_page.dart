import 'package:flutter/material.dart';

class TipPage extends StatefulWidget {
  const TipPage({super.key});

  @override
  State<TipPage> createState() => _TipPageState();
}

class _TipPageState extends State<TipPage> {
  // 카테고리 리스트
  final List<String> categories = [
    '전체',
    '활동',
    '휴식',
    '통계',
    '설정',
  ];

  // 모든 팁을 담고 있는 리스트
  final List<Map<String, dynamic>> allTips = [
    {
      'category': '활동',
      'title': '주간 목표 설정하기',
      'content': '매주 월요일 00시에 주어지는 100시간을 효과적으로 활용하기 위해 목표를 명확히 설정하세요. 공부, 업무, 독서 등 각 활동별로 시간을 배분하여 계획을 세우면 효율적인 시간 관리가 가능합니다.'
    },
    {
      'category': '활동',
      'title': '우선순위 정하기',
      'content': '각 활동의 중요도와 긴급성을 평가하여 우선순위를 정하세요. 중요한 활동에 먼저 시간을 할애함으로써 주어진 시간을 보다 효과적으로 사용할 수 있습니다.'
    },
    {
      'category': '활동',
      'title': '활동 종류 다양화',
      'content': '공부, 업무, 독서 외에도 다양한 활동을 추가하여 주간 목표를 다각화하세요. 다양한 활동은 동기부여를 유지하고 전반적인 생산성을 향상시킵니다.',
    },
    {
      'category': '활동',
      'title': '활동 수정과 삭제 신중히',
      'content': '활동을 수정하거나 삭제할 때는 신중하게 결정하세요. 삭제된 활동은 기존 기록과 이어지지 않으므로, 필요 없는 활동만 삭제하도록 합니다.',
    },
    {
      'category': '활동',
      'title': '일일 목표 설정',
      'content': '주간 목표 외에도 매일 달성할 소규모 목표를 설정하여 꾸준히 활동을 이어가세요. 일일 목표는 주간 목표 달성을 위한 작은 단위의 마일스톤이 됩니다.'
    },
    {
      'category': '활동',
      'title': '자기 동기부여 유지',
      'content': '활동 기록을 꾸준히 유지하고, 자신의 성과를 시각적으로 확인하여 동기부여를 유지하세요. 성과를 기록하는 습관은 지속적인 자기계발에 큰 도움이 됩니다.'
    },
    {
      'category': '휴식',
      'title': '효과적인 휴식 시간 활용',
      'content': '휴식 시간 동안 간단한 스트레칭이나 짧은 산책을 통해 몸과 마음을 재충전하세요. 이는 장기적인 활동 지속에 도움이 됩니다.',
    },
    {
      'category': '휴식',
      'title': '휴식 시간 기록하기',
      'content': '휴식 시간을 기록하여 자신의 휴식 패턴을 파악하고, 필요에 따라 휴식 시간을 조정하세요. 균형 잡힌 활동과 휴식은 생산성을 높입니다.',
    },
    {
      'category': '통계',
      'title': '실시간 달성도 확인',
      'content': '30초마다 자동으로 갱신되는 이번주 달성도를 통해 남은 시간을 실시간으로 확인하세요. 이를 통해 목표 달성 여부를 지속적으로 모니터링할 수 있습니다.'
    },
    {
      'category': '통계',
      'title': '주간 목표 리뷰',
      'content': '매주 말에 자신의 활동 시간을 리뷰하고, 다음 주의 목표를 조정하세요. 주간 리뷰는 지속적인 자기계발에 중요한 역할을 합니다.',
    },
    {
      'category': '통계',
      'title': '활동 로그 추가 및 수정',
      'content': '활동을 생성하거나 수정할 때는 상세한 정보를 입력하여 기록을 정확하게 유지하세요. 정확한 로그는 추후 분석에 유용합니다.',
    },
    {
      'category': '통계',
      'title': '활동 로그 삭제 주의',
      'content': '활동 로그를 삭제할 경우, 기존 기록이 이어지지 않으므로 신중하게 삭제하세요. 삭제된 로그는 복구할 수 없으니 필요할 때만 삭제하도록 합니다.'
    },
    {
      'category': '통계',
      'title': '히트맵을 통한 활동 분석',
      'content': '히트맵 위젯을 활용하여 시간대별 활동 내역을 시각적으로 분석하세요. 활동 시간과 빈도를 한눈에 파악할 수 있어 효율적인 시간 관리가 가능합니다.'
    },
    {
      'category': '통계',
      'title': '활동 상세 정보 확인',
      'content': '히트맵의 각 시간대를 롱클릭하여 어떤 활동을 몇 분 했는지 툴팁을 통해 확인하세요. 이를 통해 자신의 활동 패턴을 더 깊이 이해할 수 있습니다.'
    },
    {
      'category': '통계',
      'title': '월별 활동 패턴 확인',
      'content': '잔디심기 기능을 통해 월별 캘린더를 이동하며 자신이 얼마나 꾸준히 활동했는지 확인하세요. 일별 활동 시간을 시각적으로 파악할 수 있어 동기부여에 도움이 됩니다.'
    },
    {
      'category': '통계',
      'title': '활동 일자별 상세 정보',
      'content': '각 날짜를 클릭하여 해당 날의 활동 시간을 메시지로 확인하세요. 이는 자신의 활동 습관을 분석하고 개선하는 데 유용합니다.',
    },
    {
      'category': '통계',
      'title': '잔디심기 목표 설정',
      'content': '월별로 설정한 목표를 달성하기 위해 잔디심기를 활용하세요. 목표 달성 시 시각적인 성취감을 통해 지속적인 활동을 유도할 수 있습니다.',
    },
  ];

  // 현재 선택된 카테고리
  String selectedCategory = '전체';

  // 필터링된 팁 리스트
  List<Map<String, dynamic>> filteredTips = [];

  @override
  void initState() {
    super.initState();
    _filterTips(); // 초기 팁 필터링
  }

  // 팁을 카테고리별로 필터링하는 함수
  void _filterTips() {
    setState(() {
      if (selectedCategory == '전체') {
        filteredTips = List.from(allTips);
      } else {
        filteredTips = allTips.where((tip) => tip['category'] == selectedCategory).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 다크 모드 여부 확인
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '팁',
          style: TextStyle(fontWeight: FontWeight.w400, fontSize: 18),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                SizedBox(
                  height: 40.0,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = category == selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: ChoiceChip(
                          label: Text(
                            category,
                            style: TextStyle(
                              fontSize: 12,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: Colors.red,
                          backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : isDarkMode
                                    ? Colors.white
                                    : Colors.black,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32.0),
                            side: BorderSide(color: Colors.transparent),
                          ),
                          onSelected: (bool selected) {
                            setState(() {
                              selectedCategory = category;
                              _filterTips();
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24.0),
                Expanded(
                  child: filteredTips.isNotEmpty
                      ? AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            return FadeTransition(opacity: animation, child: child);
                          },
                          child: ListView.builder(
                            key: ValueKey<String>(selectedCategory),
                            itemCount: filteredTips.length,
                            itemBuilder: (context, index) {
                              final tip = filteredTips[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(16.0),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    child: ListTile(
                                      title: Text(
                                        tip['title'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                        ),
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                                        child: Text(
                                          tip['content'],
                                          style: const TextStyle(
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : const Center(
                          child: Text('선택한 카테고리에 해당하는 팁이 없습니다.'),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
