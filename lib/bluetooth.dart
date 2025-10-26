import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class Bluetooth {

  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? uartCharacteristic;
  StreamSubscription<List<int>>? characteristicSubscription;
  bool isScanning = false;
  bool isConnected = false;
  List<ScanResult> scanResults = [];
  List<String> fallAlerts = [];

  Bluetooth(){
    Re
  }

}