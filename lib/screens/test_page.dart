import 'package:flutter/material.dart';

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  int _selectedIndex = 0;

  // 각 탭에 표시될 페이지 위젯
  static const List<Widget> _pages = <Widget>[
    Center(child: Text('타이머 페이지', style: TextStyle(fontSize: 24))),
    Center(child: Text('기록 페이지', style: TextStyle(fontSize: 24))),
    Center(child: Text('통계 페이지', style: TextStyle(fontSize: 24))),
    Center(child: Text('설정 페이지', style: TextStyle(fontSize: 24))),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('바텀 내비게이션 바 예제'),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: CustomAnimatedBottomBar(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemTapped,
        items: [
          BottomNavItem(
            icon: Icons.timer,
            title: '타이머',
          ),
          BottomNavItem(
            icon: Icons.history,
            title: '기록',
          ),
          BottomNavItem(
            icon: Icons.bar_chart,
            title: '통계',
          ),
          BottomNavItem(
            icon: Icons.settings,
            title: '설정',
          ),
        ],
      ),
    );
  }
}

// 애니메이션 바텀 네비게이션 바 클래스
class CustomAnimatedBottomBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final List<BottomNavItem> items;

  const CustomAnimatedBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          items.length,
          (index) => _buildNavItem(index),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    bool isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => onItemSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Icon(
                items[index].icon,
                color: isSelected ? Colors.blue : Colors.grey,
                size: isSelected ? 28 : 24,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                color: isSelected ? Colors.blue : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: isSelected ? 14.0 : 12.0,
              ),
              child: Text(
                items[index].title,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 내비게이션 아이템 모델
class BottomNavItem {
  final IconData icon;
  final String title;

  BottomNavItem({
    required this.icon,
    required this.title,
  });
}
