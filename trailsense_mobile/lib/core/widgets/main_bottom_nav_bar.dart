import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MainBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool notificacionesPendientes;

  const MainBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.notificacionesPendientes = false,
  });

  Widget _iconoConPunto(IconData icono, double size) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icono, size: size),
        if (notificacionesPendientes)
          Positioned(
            right: -1, top: -1,
            child: Container(
              width: 11.r, height: 11.r,
              decoration: BoxDecoration(color: const Color(0xFF1D4ED8), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
            ),
          ),
      ],
    );
  }

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
          icon: _iconoConPunto(Icons.notifications_none, iconSize),
          activeIcon: _iconoConPunto(Icons.notifications, iconSize),
          label: 'Notificaciones',
        ),
      ],
    );
  }
}