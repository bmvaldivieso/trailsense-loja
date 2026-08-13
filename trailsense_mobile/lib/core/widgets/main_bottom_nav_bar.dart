import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MainBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const MainBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double iconSize = 28.r;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF3B82F6),
      unselectedItemColor: const Color(0xFF4C8DFF),
      showSelectedLabels: false,
      showUnselectedLabels: false,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined, size: iconSize),
          activeIcon: Icon(Icons.home, size: iconSize),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map_outlined, size: iconSize),
          activeIcon: Icon(Icons.map, size: iconSize),
          label: 'Senderos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.location_on_outlined, size: iconSize),
          activeIcon: Icon(Icons.location_on, size: iconSize),
          label: 'Recorrido',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.campaign_outlined, size: iconSize),
          activeIcon: Icon(Icons.campaign, size: iconSize),
          label: 'Reportes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications_none, size: iconSize),
          activeIcon: Icon(Icons.notifications, size: iconSize),
          label: 'Notificaciones',
        ),
      ],
    );
  }
}