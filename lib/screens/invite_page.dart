import 'dart:math';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project1/widgets/achievement_card.dart';

class InvitePage extends StatefulWidget {
  const InvitePage({super.key});

  @override
  State<InvitePage> createState() => _InvitePageState();
}

class _InvitePageState extends State<InvitePage> {
  List<Map<String, dynamic>> benefitList = [
    {'title': '1명 초대하고', 'decription': '활동 개수 제한을 없애요'},
    {'title': '2명 초대하고', 'decription': '캐릭터를 내맘대로 선택해요'},
    {'title': '3명 초대하고', 'decription': '광고 없이 이용해요'},
  ];

  int _currentIndex = 0; // 현재 페이지 인덱스

  List<String> words = [
    "하늘",
    "바다",
    "산",
    "강",
    "나무",
    "꽃",
    "구름",
    "별",
    "달",
    "태양",
    "불꽃",
    "비",
    "눈",
    "바람",
    "초원",
    "숲",
    "정원",
    "새벽",
    "노을",
    "파도",
    "소나무",
    "강아지",
    "고양이",
    "토끼",
    "사자",
    "독수리",
    "비둘기",
    "거북",
    "도라지",
    "민들레",
    "나비",
    "햇살",
    "바위",
    "돌",
    "잔디",
    "해변",
    "계곡",
    "폭포",
    "호수",
    "분수",
    "연못",
    "나무늘보",
    "숲속",
    "잎",
    "가을",
    "봄",
    "여름",
    "겨울",
    "사막",
    "대양",
    "푸른",
    "하얀",
    "검은",
    "산들바람",
    "폭풍",
    "미풍",
    "여우",
    "늑대",
    "곰",
    "호랑이",
    "표범",
    "펭귄",
    "물개",
    "돌고래",
    "고래",
    "상어",
    "오징어",
    "해파리",
    "산호",
    "조개",
    "게",
    "새우",
    "소라",
    "바다거북",
    "참치",
    "연어",
    "매",
    "황새",
    "공작",
    "두루미",
    "청둥오리",
    "기러기",
    "원숭이",
    "침팬지",
    "오랑우탄",
    "고릴라",
    "낙타",
    "코끼리",
    "얼룩말",
    "하마",
    "코뿔소",
    "사슴",
    "말",
    "양",
    "염소",
    "닭",
    "오리",
    "거위",
    "까마귀",
    "두더지",
    "들판",
    "도랑",
    "강변",
    "늪",
    "모래",
    "흙",
    "여우비",
    "장미",
    "카네이션",
    "튤립",
    "해바라기",
    "백합",
    "진달래",
    "개나리",
    "철쭉",
    "장구벌레",
    "모기",
    "나비",
    "매미",
    "거미",
    "사마귀",
    "지네",
    "딱정벌레",
    "개구리",
    "두꺼비",
    "뱀",
    "도마뱀",
    "까치",
    "매화",
    "벚꽃",
    "이슬",
    "달팽이",
    "굴뚝",
    "강철",
    "은",
    "구리",
    "철",
    "옹기",
    "가마솥",
    "잔",
    "그릇",
    "종",
    "식기",
    "컵",
    "병",
    "나팔꽃",
    "금잔화",
    "안개꽃",
    "옥수수",
    "보리",
    "벼",
    "포도",
    "딸기",
    "사과",
    "배",
    "감",
    "수박",
    "참외",
    "바나나",
    "귤",
    "메론",
    "망고",
    "무화과",
    "밤",
    "잣",
    "도토리",
    "아카시아",
    "방울새",
    "찌르레기",
    "종달새",
    "산새",
    "노루",
    "멧돼지",
    "고라니",
    "물총새",
    "꾀꼬리",
    "물새",
    "큰까마귀",
    "솔개",
    "참새",
    "쥐",
    "고슴도치",
    "부엉이",
    "올빼미",
    "매",
    "참매",
    "개미",
    "벌",
    "나방",
    "부엉이",
    "고구마",
    "감자",
    "마늘",
    "양파",
    "당근",
    "무",
    "배추",
    "상추",
    "시금치",
    "토마토",
    "호박",
    "파프리카",
    "피망",
    "파슬리",
    "딜",
    "고추",
    "생강",
    "냉이",
    "치커리",
    "설탕",
    "소금",
    "간장",
    "된장",
    "고추장",
    "겨자",
    "마요네즈",
    "케첩",
    "초코",
    "빵",
    "케이크",
    "쿠키",
    "크래커",
    "사탕",
    "초콜릿",
    "피자",
    "스파게티",
    "라면",
    "우동",
    "짜장면",
    "짬뽕",
    "떡볶이",
    "순대",
    "빈대떡",
    "파전",
    "김치",
    "볶음밥",
    "김밥",
    "돈가스",
    "불고기",
    "고등어",
    "갈치",
    "생선회",
    "해물탕",
    "된장찌개",
    "김치찌개",
    "육개장",
    "감자탕",
    "순두부찌개",
    "칼국수",
    "수제비",
    "비빔밥",
    "콩나물국밥",
    "삼계탕",
    "보리차",
    "녹차",
    "홍차",
    "밀크티",
    "아이스크림",
    "와플",
    "커피",
    "라떼",
    "에스프레소",
    "카푸치노",
    "모카",
    "초콜릿",
    "딸기주스",
    "포도주스",
    "바닐라",
    "초코바",
    "요거트",
    "슬러시",
    "스무디",
    "비타민",
    "단백질",
    "운동",
    "수영",
    "축구",
    "농구",
    "배구",
    "테니스",
    "야구",
    "골프",
    "사이클링",
    "탁구",
    "복싱",
    "태권도",
    "유도",
    "스키",
    "스노보드",
    "카누",
    "하이킹",
    "캠핑",
    "낚시",
    "등산",
    "달리기",
    "걷기",
    "서핑",
    "요가",
    "필라테스",
    "피트니스",
    "웨이트",
    "헬스",
    "유산소",
    "근력",
    "자전거",
    "킥보드",
    "스케이트",
    "보드",
    "카약",
    "돛단배",
    "패러글라이딩",
    "카이트보드",
    "풍력",
    "태양열",
    "조력",
    "지열",
    "연탄",
    "석탄",
    "석유",
    "천연가스",
    "핵",
    "원자력",
    "수소",
    "물",
    "나노",
    "바이오",
    "인공지능",
    "로봇",
    "드론",
    "우주",
    "항공",
    "비행기",
    "우주선",
    "위성",
    "망원경",
    "현미경",
    "렌즈",
    "카메라",
    "컴퓨터",
    "프로세서",
    "칩",
    "배터리",
    "전기",
    "자동차",
    "버스",
    "기차",
    "지하철",
    "자전거",
    "도로",
    "고속도로",
    "건설",
    "굴착기",
    "크레인",
    "아스팔트",
    "콘크리트",
    "철근",
    "건물",
    "타워",
    "다리",
    "철도",
    "운하",
    "항구",
    "선박",
    "배",
    "보트",
    "등대",
    "빛",
    "색",
    "소리",
    "진동",
    "파동",
    "음향",
    "오디오",
    "비디오",
    "화상",
    "홀로그램",
    "3D",
    "가상현실",
    "증강현실",
    "디지털",
    "코딩",
    "알고리즘",
    "프로그래밍"
  ];

  // 기존 조합을 저장하는 Set
  Set<String> existingCombinations = {};

  // 고유 조합 생성 함수
  List<String> generateUniqueCombination(String userId) {
    final random = Random();
    List<String> combination;
    String combinationKey;

    while (true) {
      // 3개의 단어를 랜덤하게 선택
      combination = [];
      for (int i = 0; i < 3; i++) {
        combination.add(words[random.nextInt(words.length)]);
      }

      // 단어들을 정렬하여 동일한 조합 체크
      List<String> sortedCombination = List.from(combination)..sort();

      // 정렬된 단어들을 하나의 문자열로 결합하여 키 생성
      combinationKey = sortedCombination.join('-');

      // 중복 검증
      if (!existingCombinations.contains(combinationKey)) {
        // 중복되지 않는 경우 Set에 추가 후 반환
        existingCombinations.add(combinationKey);
        return combination; // 원래의 순서 유지된 combination 반환
      }
    }
  }

  // 위쪽에 변수 선언
  final TextEditingController _wordController1 = TextEditingController();
  final TextEditingController _wordController2 = TextEditingController();
  final TextEditingController _wordController3 = TextEditingController();

// dispose 메서드에서 컨트롤러 해제
  @override
  void dispose() {
    _wordController1.dispose();
    _wordController2.dispose();
    _wordController3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

    List<String> userCodes = generateUniqueCombination('userId');

    return Scaffold(
      appBar: AppBar(
        title: const Text('친구 초대', style: TextStyle(fontWeight: FontWeight.w400, fontSize: 18)),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          // scrollDirection을 vertical로 변경
          scrollDirection: Axis.vertical,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 제목 부분
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '친구초대하고\n선물 받기 🎁',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              // 캐러셀 슬라이더
              CarouselSlider.builder(
                itemCount: benefitList.length,
                itemBuilder: (BuildContext context, int itemIndex, int pageViewIndex) {
                  double angle = 0.0;

                  // 현재 인덱스에 따라 기울기 각도 설정
                  double getAngle(int itemIndex, int currentIndex, int totalCount) {
                    // 이전, 현재, 다음 인덱스를 순환 계산하여 설정
                    int previousIndex = (currentIndex - 1 + totalCount) % totalCount;
                    int nextIndex = (currentIndex + 1) % totalCount;

                    if (itemIndex == previousIndex) {
                      return -0.1; // 왼쪽으로 기울기
                    } else if (itemIndex == currentIndex) {
                      return 0.0; // 똑바로
                    } else if (itemIndex == nextIndex) {
                      return 0.1; // 오른쪽으로 기울기
                    } else {
                      return 0.0; // 나머지는 기울기 없음
                    }
                  }

                  angle = getAngle(itemIndex, _currentIndex, benefitList.length);

                  return Transform.rotate(
                    angle: angle,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Container(
                          width: 300,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.lightBlue,
                                Colors.indigo,
                              ],
                              stops: const [0.0, 1.0],
                            ),
                            color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  benefitList[itemIndex]['title'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  benefitList[itemIndex]['decription'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                options: CarouselOptions(
                  height: 200,
                  autoPlay: true,
                  enlargeCenterPage: true,
                  onPageChanged: (index, reason) {
                    setState(() {
                      _currentIndex = index; // 현재 인덱스 업데이트
                    });
                  },
                ),
              ),
              const SizedBox(
                height: 60,
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '나의 코드',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    const Text(
                      '나를 초대한 친구에게 나의 코드 3개를 전달해요',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    Row(
                      children: userCodes.map((word) {
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(right: 8.0),
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 6,
                                  offset: const Offset(2, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              word,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(
                      height: 30,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Container(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            String codeToCopy = userCodes.join(' ');
                            Clipboard.setData(ClipboardData(text: codeToCopy));

                            // 사용자에게 복사 완료 메시지 표시
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('클립보드에 복사되었습니다'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          style: ButtonStyle(
                            foregroundColor: WidgetStateProperty.all(Colors.white), // 텍스트 색상
                            backgroundColor: WidgetStateProperty.all(Colors.blueAccent), // 배경색
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0), // 둥근 모서리 반경
                              ),
                            ),
                          ),
                          child: const Text(
                            '코드 복사',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 60,
                    ),
                    const Text(
                      '내가 데려온 친구의 코드',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    const Text(
                      '친구에게 코드를 전달받아 순서 상관없이 입력하세요',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _wordController1,
                            decoration: InputDecoration(
                              hintText: '첫번째 코드',
                              hintStyle: TextStyle(color: Colors.grey[300], fontSize: 14),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide(color: isDarkMode ? Colors.grey : Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide(color: Colors.blueAccent),
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12.0),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: TextField(
                            controller: _wordController2,
                            decoration: InputDecoration(
                              hintText: '두번째 코드',
                              hintStyle: TextStyle(color: Colors.grey[300], fontSize: 14),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide(color: isDarkMode ? Colors.grey : Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide(color: Colors.blueAccent),
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12.0),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: TextField(
                            controller: _wordController3,
                            decoration: InputDecoration(
                              hintText: '세번째 코드',
                              hintStyle: TextStyle(color: Colors.grey[300], fontSize: 14),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide(color: isDarkMode ? Colors.grey : Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide(color: Colors.blueAccent),
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12.0),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Container(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            String codeToCopy = userCodes.join(' ');
                            Clipboard.setData(ClipboardData(text: codeToCopy));

                            // 사용자에게 복사 완료 메시지 표시
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('클립보드에 복사되었습니다'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          style: ButtonStyle(
                            foregroundColor: WidgetStateProperty.all(Colors.white), // 텍스트 색상
                            backgroundColor: WidgetStateProperty.all(Colors.blueAccent), // 배경색
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0), // 둥근 모서리 반경
                              ),
                            ),
                          ),
                          child: const Text(
                            '등록',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 100,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
