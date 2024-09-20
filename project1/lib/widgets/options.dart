import 'package:flutter/material.dart';

class Options extends StatefulWidget {
  const Options({super.key});

  @override
  State<Options> createState() => _OptionsState();
}

class _OptionsState extends State<Options> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // 첫 번째 옵션 버튼 (다크모드)
          Container(
            margin: const EdgeInsets.only(
              right: 10,
            ),
            width: 75,
            height: 75,
            decoration: BoxDecoration(
              color: Colors.blueAccent.shade200, // 배경 흰색
              borderRadius: BorderRadius.circular(16), // 네모난 테두리
            ),
            child: IconButton(
              icon: const Icon(
                Icons.dark_mode_rounded,
                color: Colors.white,
              ), // 검은색 아이콘
              iconSize: 36.0,
              onPressed: () {
                // 다크모드 버튼 동작
                print('다크모드 버튼 클릭됨');
              },
            ),
          ),
          // 두 번째 옵션 버튼 (서버와 싱크)
          Container(
            margin: const EdgeInsets.only(
              right: 10,
            ),
            width: 75,
            height: 75,
            decoration: BoxDecoration(
              color: Colors.blueAccent.shade200, // 배경 흰색
              borderRadius: BorderRadius.circular(16), // 네모난 테두리
            ),
            child: IconButton(
              icon: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
              ), // 검은색 아이콘
              iconSize: 36.0,
              onPressed: () {
                // 다크모드 버튼 동작
                print('서버와 싱크');
              },
            ),
          ),
        ],
      ),
    );
  }
}
