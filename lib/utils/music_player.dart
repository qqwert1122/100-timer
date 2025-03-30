import 'package:just_audio/just_audio.dart';

class MusicPlayer {
  static final MusicPlayer _instance = MusicPlayer._internal();
  late AudioPlayer _audioPlayer;
  String _currentMusic = '';

  // 싱글톤 패턴 구현
  factory MusicPlayer() {
    return _instance;
  }

  MusicPlayer._internal() {
    _audioPlayer = AudioPlayer();
  }

  // 현재 재생 중인 음악 가져오기
  String get currentMusic => _currentMusic;

  String getMusic(String musicName) {
    switch (musicName) {
      case '지저귀는 새':
        return 'assets/sounds/birds_singing.mp3';
      case '파도':
        return 'assets/sounds/waves.mp3';
      case '비 내리는 날':
        return 'assets/sounds/rain.mp3';
      case '도시':
        return 'assets/sounds/city.mp3';
      case '보리밭에 부는 바람':
        return 'assets/sounds/wheat_in_the_wind.mp3';
      default:
        return 'assets/sounds/waves.wav';
    }
  }

  // 음악 재생 함수
  Future<void> playMusic(String musicName) async {
    try {
      // 이미 선택된 음악이면 재생/일시정지 토글
      if (_currentMusic == musicName && _audioPlayer.playing) {
        await _audioPlayer.pause();
        return;
      }

      _currentMusic = musicName;

      // 음악 파일 경로 설정 (assets 폴더 내에 있다고 가정)
      final assetPath = getMusic(musicName);

      // 오디오 소스 설정
      await _audioPlayer.setAsset(assetPath);

      // 반복 재생 설정
      await _audioPlayer.setLoopMode(LoopMode.all);

      // 재생 시작
      await _audioPlayer.play();
    } catch (e) {
      print('음악 재생 오류: $e');
      // 에러 발생 시 기본 음악으로 대체하거나 오류 메시지 표시 등의 처리
    }
  }

  // 음악 정지 함수
  Future<void> stopMusic() async {
    await _audioPlayer.stop();
    _currentMusic = '';
  }

  // 일시정지 함수
  Future<void> pauseMusic() async {
    await _audioPlayer.pause();
  }

  // 볼륨 설정 함수 (0.0 ~ 1.0)
  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume);
  }

  // 리소스 해제
  void dispose() {
    _audioPlayer.dispose();
  }
}
