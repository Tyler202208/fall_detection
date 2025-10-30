import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:convert';


class Bluetooth {

  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? uartCharacteristic;
  StreamSubscription<List<int>>? characteristicSubscription;
  bool isScanning = false;
  bool isConnected = false;
  List<ScanResult> scanResults = [];
  List<String> fallAlerts = [];

  // Nordic UART Service UUID
  static const String uartServiceUuid = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
  static const String uartRxCharacteristicUuid = "6e400003-b5a3-f393-e0a9-e50e24dcca9e";

  // Stream controller for received data
  final StreamController<String> _dataStreamController = StreamController.broadcast();
  Stream<String> get onDataReceived => _dataStreamController.stream;

  void dispose() {
    characteristicSubscription?.cancel();
    _dataStreamController.close();
  }

  Future<void> requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  Future<void> startScan(Function(List<ScanResult>) onResultsUpdated) async {
    if (isScanning) return;
    isScanning = true;
    scanResults.clear();

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

      FlutterBluePlus.scanResults.listen((results) {
          scanResults = results.where((result) =>
          result.device.platformName.isNotEmpty &&
              (result.device.platformName.contains('FallDetector') ||
                  result.advertisementData.advName.contains('FallDetector'))
          ).toList();

          onResultsUpdated(scanResults);
      });

      await Future.delayed(const Duration(seconds: 10));
      await FlutterBluePlus.stopScan();
    } catch (e) {
      debugPrint('Error during scan: $e');
    }

      isScanning = false;

  }

  Future<void> connectToDevice(BluetoothDevice device, VoidCallback onDisconnect ) async {
    try {
      await device.connect(timeout: const Duration(seconds: 10));
      connectedDevice = device;
      isConnected = true;

      // Discover services
      List<BluetoothService> services = await device.discoverServices();

      // Find UART service
      for (BluetoothService service in services) {
        if (service.uuid.toString().toLowerCase() == uartServiceUuid.toLowerCase()) {
          // Find RX characteristic
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toLowerCase() == uartRxCharacteristicUuid.toLowerCase()) {
              uartCharacteristic = characteristic;

              // Subscribe to notifications
              await characteristic.setNotifyValue(true);
              characteristicSubscription = characteristic.lastValueStream.listen(_handleIncomingData);
              break;
            }
          }
          break;
        }
      }

      // Listen for disconnection
      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
            isConnected = false;
            connectedDevice = null;
            uartCharacteristic = null;
            characteristicSubscription?.cancel();
            onDisconnect();
        }
      });

    } catch (e) {
      debugPrint('Error connecting to device: $e');
    }
  }

  void _handleIncomingData(List<int> data) {
    try {
      String message = utf8.decode(data).trim();
      debugPrint('Received message: $message');
      _dataStreamController.add(message);
    } catch (e) {
      debugPrint('Error decoding data: $e');
    }
  }

  Future<void> disconnect() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
    }
  }
}