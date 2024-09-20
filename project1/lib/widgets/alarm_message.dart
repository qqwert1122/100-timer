import 'package:flutter/material.dart';

class AlarmMessage extends StatefulWidget {
  const AlarmMessage({super.key});

  @override
  State<AlarmMessage> createState() => _AlarmMessageState();
}

class _AlarmMessageState extends State<AlarmMessage> {
  bool isSuspected = true;

  void closeMessage() {
    setState(() {
      isSuspected = !isSuspected;
    });
  }

  @override
  Widget build(BuildContext context) {
    return isSuspected
        ? Container(
            margin: const EdgeInsets.only(
              left: 32,
              right: 32,
            ),
            padding: const EdgeInsets.only(bottom: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      color: Colors.grey.shade500,
                      onPressed: () {
                        closeMessage();
                      },
                      icon: Icon(Icons.highlight_remove_rounded),
                    ),
                  ],
                ),
                const Text(
                  "혹시 휴식 누르는 걸 잊지 않으셨나요?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.black87,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Wiro'),
                ),
                const Text(
                  "기록을 올바르게 수정해주세요",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.black87,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Wiro'),
                ),
                const SizedBox(
                  height: 5,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: TextButton(
                    onPressed: () {},
                    style: ButtonStyle(
                      foregroundColor:
                          WidgetStateProperty.all(Colors.white), // 텍스트 색상
                      backgroundColor: WidgetStateProperty.all(
                          Colors.blueAccent.shade400), // 배경색
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12.0), // 둥근 모서리 반경
                        ),
                      ),
                    ),
                    child: const Text(
                      '     기록 수정하러 가기     ',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ))
        : Container();
  }
}
