import 'package:project1/models/achievement.dart';

List<Achievement> getAchievements() {
  return [
    Achievement(
      '첫걸음',
      '첫 10시간을 달성했어요',
      true,
      'https://via.placeholder.com/150?text=Study',
    ),
    Achievement(
      '절반의 성공',
      '50시간을 달성했어요',
      true,
      'https://via.placeholder.com/150?text=Burning',
    ),
    Achievement(
      '풀타임 버닝',
      '100시간을 모두 달성했어요',
      false,
      'https://via.placeholder.com/150?text=Running',
    ),
    Achievement(
      '지치지 않는 열정',
      '연속 2주간 100시간을 달성했어요',
      true,
      'https://via.placeholder.com/150?text=Books',
    ),
    Achievement(
      '버닝 마스터',
      '연속 4주간 100시간을 달성했어요',
      false,
      'https://via.placeholder.com/150?text=Language',
    ),
    Achievement(
      '집중의 달인',
      '하루에 5시간 이상 연속으로 타이머를 사용했어요',
      true,
      'https://via.placeholder.com/150?text=Exercise',
    ),
    Achievement(
      '자기관리의 달인',
      '연속 7일 동안 타이머를 사용했어요',
      true,
      'https://via.placeholder.com/150?text=Meditation',
    ),
    Achievement(
      '지속의 힘',
      '연속 30일 동안 하루도 빠짐없이 타이머를 사용했어요',
      false,
      'https://via.placeholder.com/150?text=Time+Management',
    ),
    Achievement(
      '초집중 모드',
      '하루 10시간 이상 타이머를 사용했어요',
      false,
      'https://via.placeholder.com/150?text=Time+Management',
    ),
    Achievement(
      '살아있나요?',
      '쉬지않고 48시간 동안 타이머를 사용했어요',
      false,
      'https://via.placeholder.com/150?text=Time+Management',
    ),
  ];
}
