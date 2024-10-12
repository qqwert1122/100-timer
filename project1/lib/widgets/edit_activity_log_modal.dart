import 'dart:ffi';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class EditActivityLogModal extends StatefulWidget {
  const EditActivityLogModal({super.key});

  @override
  State<EditActivityLogModal> createState() => _EditActivityLogModalState();
}

class _EditActivityLogModalState extends State<EditActivityLogModal> {
  final List<Map<String, dynamic>> items = [
    {'icon': Icons.play_circle_fill_rounded, 'text': '활동 시간', 'time': '2시간 42분'},
    {'icon': Icons.pause_circle_filled_rounded, 'text': '휴식 시간', 'time': '16분'},
    // 필요한 만큼 추가
  ];
  int selectedValue = 0; // 선택된 숫자 초기값
  final List<int> values = List.generate(25, (index) => index * 5); // 0부터 120까지의 숫자 목록 생성

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setModalState) {
        return Container(
          height: 400, // 모달창 높이 설정
          width: MediaQuery.of(context).size.width, // 모달창 가로 길이를 화면 크기로 설정
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '활동 기록 수정',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: Icon(
                        items[index]['icon'],
                        size: 38,
                        color: Colors.grey,
                      ),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            '${items[index]['text']}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.grey),
                          ),
                          const SizedBox(width: 30),
                          Text(
                            '${items[index]['time']}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
                          ),
                        ],
                      ),
                      onTap: () {
                        // 항목 클릭 시 동작
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  '기록보다',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
              // 위아래 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  GestureDetector(
                      onTap: () => _showPicker(context), // 숫자 선택 피커 표시
                      child: Row(
                        children: [
                          Text(
                            '$selectedValue 분', // 현재 선택된 값 표시
                            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 36,
                          ),
                        ],
                      )),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setModalState(() {}); // 필요한 경우 상태 업데이트
                        Navigator.pop(context); // 모달창 닫기
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '더 휴식했어요',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setModalState(() {}); // 필요한 경우 상태 업데이트
                        Navigator.pop(context); // 모달창 닫기
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '활동했어요',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  void _showPicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 200,
          color: Colors.white,
          child: Column(
            children: [
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(initialItem: selectedValue ~/ 5), // 초기 선택값 설정
                  itemExtent: 40, // 각 항목의 높이
                  onSelectedItemChanged: (int index) {
                    setState(() {
                      selectedValue = values[index]; // 선택된 값 업데이트
                    });
                  },
                  children: List<Widget>.generate(values.length, (int index) {
                    return Center(
                      child: Text(
                        '${values[index]} 분', // 숫자 표시
                        style: const TextStyle(fontSize: 24, color: Colors.black),
                      ),
                    );
                  }),
                ),
              ),
              CupertinoButton(
                child: const Text(
                  '확인',
                  style: TextStyle(color: Colors.black),
                ),
                onPressed: () {
                  Navigator.pop(context); // 피커 닫기
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
