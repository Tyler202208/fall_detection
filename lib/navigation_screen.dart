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


  late final List <Widget> _pages;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    _pages = [
      HomeScreen(bluetoothManager: ble),
      ActivityMonitor(bluetoothManager: ble),
      Profile(
        // bleSession: bleSession,
      ),
    ];
  }

  void _onItemTapped(int index){
    setState(() {
      _selectedIndex = index;
    }

    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          showSelectedLabels: true,
          onTap: _onItemTapped,
          selectedItemColor: primary_color,
          items:[
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: "Monitor"),
            BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: "Profile"),
          ]
      ),

    );
  }
}


