import 'package:flutter/material.dart';

class AddActivityPage extends StatelessWidget {
  const AddActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '활동 추가',
          style: TextStyle(fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded), // 원하는 아이콘으로 변경
          onPressed: () {
            Navigator.pop(context); // 뒤로가기
          },
        ),
      ),
      body: Center(
        child: const Text(
          '여기에 활동 추가를 구현하세요.',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
