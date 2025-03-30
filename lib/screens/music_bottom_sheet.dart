import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/responsive_size.dart';

class MusicBottomSheet extends StatefulWidget {
  final String initialMusic;
  final Function(String) onMusicSelected;
  final VoidCallback onStopMusic;

  const MusicBottomSheet({
    Key? key,
    required this.initialMusic,
    required this.onMusicSelected,
    required this.onStopMusic,
  }) : super(key: key);

  @override
  State<MusicBottomSheet> createState() => _MusicBottomSheetState();
}

class _MusicBottomSheetState extends State<MusicBottomSheet> {
  late String currentMusic;

  // 음악 목록
  final List<String> musicList = ['지저귀는 새', '파도', '비 내리는 날', '도시', '보리밭에 부는 바람'];

  @override
  void initState() {
    super.initState();
    currentMusic = widget.initialMusic;
  }

  void selectMusic(String music) {
    setState(() {
      if (currentMusic == music) {
        stopMusic();
      } else {
        currentMusic = music;
        widget.onMusicSelected(music);
      }
    });
  }

  void stopMusic() {
    setState(() {
      currentMusic = '';
    });
    widget.onStopMusic();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.hp(70),
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(color: AppColors.background(context), borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.center,
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: context.wp(20),
              height: context.hp(1),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary(context),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          SizedBox(height: context.hp(5)),
          Text(
            '배경음악 선택',
            style: AppTextStyles.getTitle(context),
          ),
          SizedBox(height: context.hp(2)),
          Expanded(
            child: ListView.builder(
              itemCount: musicList.length,
              itemBuilder: (context, index) {
                final music = musicList[index];
                final isSelected = music == currentMusic;

                return ListTile(
                  title: Text(
                    music,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.redAccent : AppColors.textPrimary(context),
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.pause_circle_filled_rounded, color: Colors.redAccent)
                      : Icon(Icons.play_circle_fill_rounded, color: AppColors.textSecondary(context)),
                  onTap: () {
                    selectMusic(music);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 음악 목록을 외부에서 접근할 수 있는 getter 메서드
  List<String> getMusicList() {
    return musicList;
  }
}

// 바텀시트를 표시하는 함수
void showMusicBottomSheet({
  required BuildContext context,
  required String currentMusic,
  required Function(String) onMusicSelected,
  required VoidCallback onStopMusic,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return MusicBottomSheet(
        initialMusic: currentMusic,
        onMusicSelected: onMusicSelected,
        onStopMusic: onStopMusic,
      );
    },
  );
}
