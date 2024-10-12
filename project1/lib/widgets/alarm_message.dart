import 'package:flutter/material.dart';

class AlarmMessage extends StatefulWidget {
  final VoidCallback closeMessage;

  const AlarmMessage({required this.closeMessage, super.key});

  @override
  State<AlarmMessage> createState() => _AlarmMessageState();
}

class _AlarmMessageState extends State<AlarmMessage> {
  bool _isVisible = true;

  void _closeMessage() {
    setState(() {
      _isVisible = false; // 애니메이션 시작
    });

    // 애니메이션 시간이 끝난 후 부모의 closeMessage() 호출
    Future.delayed(const Duration(milliseconds: 100), () {
      widget.closeMessage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        width: 400,
        height: _isVisible ? 180 : 0,
        child: Container(
          margin: const EdgeInsets.only(
            left: 32,
            right: 32,
          ),
          padding: const EdgeInsets.only(bottom: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3), // 그림자 색상 (흰색)
                spreadRadius: 2, // 그림자가 퍼지는 정도
                blurRadius: 10, // 그림자 흐림 정도
                offset: const Offset(0, 5), // 그림자 위치 (x, y)
              ),
            ],
          ),
          child: _isVisible
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          color: Colors.grey.shade500,
                          onPressed: _closeMessage,
                          icon: const Icon(Icons.highlight_remove_rounded),
                        ),
                      ],
                    ),
                    const Text(
                      "혹시 휴식 누르는 걸 잊지 않으셨나요?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                    const Text(
                      "기록을 올바르게 수정해주세요",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {},
                          style: ButtonStyle(
                            foregroundColor: WidgetStateProperty.all(Colors.white), // 텍스트 색상
                            backgroundColor: WidgetStateProperty.all(Colors.blueAccent.shade400), // 배경색
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0), // 둥근 모서리 반경
                              ),
                            ),
                          ),
                          child: const Text(
                            '기록 수정하러 가기',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : const SizedBox(),
        ));
  }
}
