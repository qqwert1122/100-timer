import 'package:flutter/material.dart';

class AlarmPage extends StatefulWidget {
  const AlarmPage({super.key});

  @override
  State<AlarmPage> createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '알림',
          style: TextStyle(fontWeight: FontWeight.w400, fontSize: 18),
        ),
      ),
      body: const Center(
        child: Text('Notices Page Content'),
      ),
    );
  }
}
