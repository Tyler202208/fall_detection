import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:senior_fall_detection/activity_monitor.dart';
import 'package:senior_fall_detection/constants.dart';
import 'package:senior_fall_detection/fall_alert.dart';
import 'package:senior_fall_detection/home_screen.dart';
import 'package:senior_fall_detection/profile.dart';

import 'ble_session.dart';
import 'bluetooth.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final ble = BluetoothManager.instance;
  final BleSession bleSession = BleSession();
  StreamSubscription<List<int>>? characteristicSubscription;

  late final List<Widget> _pages;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(bluetoothManager: ble),
      ActivityMonitor(bluetoothManager: ble),
      const Profile(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: card_elevated,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: "Home",
                  isSelected: _selectedIndex == 0,
                  onTap: () => _onItemTapped(0),
                ),
                _NavItem(
                  icon: Icons.show_chart_rounded,
                  label: "Monitor",
                  isSelected: _selectedIndex == 1,
                  onTap: () => _onItemTapped(1),
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: "Profile",
                  isSelected: _selectedIndex == 2,
                  onTap: () => _onItemTapped(2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primary_color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 26,
              color: isSelected ? primary_color : text_secondary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? primary_color : text_secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
