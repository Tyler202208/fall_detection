import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// A singleton service that owns the entire BLE lifecycle.
///
/// Because it is a singleton it is created once and lives for the entire
/// app lifetime, so [onDataReceived] keeps firing even when the user
/// navigates between screens.
///
/// Usage
/// -----
/// 1. Obtain the instance:
///      final ble = BluetoothManager.instance;
///
/// 2. Pass it to every screen that needs it:
///      HomeScreen(bluetoothManager: ble)
///
/// 3. React to state changes by adding a listener:
///      ble.addListener(() => setState(() {}));
///      // remember to remove it in dispose():
///      ble.removeListener(myCallback);
///
/// 4. Receive data events by subscribing to the stream:
///      _sub = ble.dataStream.listen((message) { ... });
///
class BluetoothManager extends ChangeNotifier {
  // ── Singleton ────────────────────────────────────────────────────────────
  BluetoothManager._internal();
  static final BluetoothManager instance = BluetoothManager._internal();

  // ── Nordic UART UUIDs ────────────────────────────────────────────────────
  static const String _uartServiceUuid =
      "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
  static const String _uartRxCharacteristicUuid =
      "6e400003-b5a3-f393-e0a9-e50e24dcca9e";

  // ── Public state (read-only) ─────────────────────────────────────────────
  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isConnected => _isConnected;
  bool get isScanning => _isScanning;
  List<ScanResult> get scanResults => List.unmodifiable(_scanResults);
  List<String> get fallAlerts => List.unmodifiable(_fallAlerts);

  /// Stream of decoded string messages received over BLE.
  /// Screens can listen to this to react to incoming data in real time.
  Stream<String> get dataStream => _dataController.stream;

  // ── Private state ────────────────────────────────────────────────────────
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _uartCharacteristic;
  bool _isConnected = false;
  bool _isScanning = false;
  final List<ScanResult> _scanResults = [];
  final List<String> _fallAlerts = [];

  StreamSubscription<List<int>>? _characteristicSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;
  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;

  // Broadcast so multiple screens can listen simultaneously.
  final StreamController<String> _dataController =
  StreamController<String>.broadcast();

  // ── Permissions ──────────────────────────────────────────────────────────
  Future<void> requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  // ── Scanning ─────────────────────────────────────────────────────────────
  Future<void> startScan() async {
    if (_isScanning) return;

    _isScanning = true;
    _scanResults.clear();
    notifyListeners();

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

      _scanResultsSubscription =
          FlutterBluePlus.scanResults.listen((results) {
            _scanResults
              ..clear()
              ..addAll(
                results.where((r) =>
                r.device.platformName.isNotEmpty &&
                    (r.device.platformName.contains('FallDetector') ||
                        r.advertisementData.advName.contains('FallDetector'))),
              );
            notifyListeners();
          });

      await Future.delayed(const Duration(seconds: 10));
      await FlutterBluePlus.stopScan();
    } catch (e) {
      debugPrint('[BluetoothManager] Scan error: $e');
    } finally {
      await _scanResultsSubscription?.cancel();
      _scanResultsSubscription = null;
      _isScanning = false;
      notifyListeners();
    }
  }

  // ── Connection ────────────────────────────────────────────────────────────
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(timeout: const Duration(seconds: 10));

      _connectedDevice = device;
      _isConnected = true;
      notifyListeners();

      // Discover services and subscribe to UART notifications.
      final services = await device.discoverServices();
      for (final service in services) {
        if (service.uuid.toString().toLowerCase() ==
            _uartServiceUuid.toLowerCase()) {
          for (final characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toLowerCase() ==
                _uartRxCharacteristicUuid.toLowerCase()) {
              _uartCharacteristic = characteristic;
              await characteristic.setNotifyValue(true);

              // Cancel any stale subscription before creating a new one.
              await _characteristicSubscription?.cancel();
              _characteristicSubscription =
                  characteristic.lastValueStream.listen(_onDataReceived);

              debugPrint('[BluetoothManager] Subscribed to UART notifications.');
              break;
            }
          }
          break;
        }
      }

      // Watch for disconnection.
      await _connectionStateSubscription?.cancel();
      _connectionStateSubscription =
          device.connectionState.listen((state) async {
            if (state == BluetoothConnectionState.disconnected) {
              await _handleDisconnection();
            }
          });
    } catch (e) {
      debugPrint('[BluetoothManager] Connection error: $e');
      await _handleDisconnection();
    }
  }

  Future<void> disconnect() async {
    await _connectedDevice?.disconnect();
    await _handleDisconnection();
  }

  Future<void> _handleDisconnection() async {
    await _characteristicSubscription?.cancel();
    _characteristicSubscription = null;

    await _connectionStateSubscription?.cancel();
    _connectionStateSubscription = null;

    _connectedDevice = null;
    _uartCharacteristic = null;
    _isConnected = false;
    notifyListeners();
  }

  // ── Data reception (always active while connected) ────────────────────────
  void _onDataReceived(List<int> data) {
    debugPrint('[BluetoothManager] Raw bytes: $data');

    final message = utf8.decode(data).trim();
    debugPrint('[BluetoothManager] Decoded: "$message"');

    if (message.isEmpty) return;

    // Broadcast the raw message to all stream listeners (individual screens).
    _dataController.add(message);

    // Handle fall-detection logic centrally so it works regardless of
    // which screen is currently active.
    if (message == "INSTABILITY WARNING!") {
      _fallAlerts.insert(
        0,
        'Received: "$message" at ${DateTime.now()}',
      );
      notifyListeners();
    }
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────
  /// Call this only if you truly want to tear down the service (e.g. sign-out).
  Future<void> dispose() async {
    await _characteristicSubscription?.cancel();
    await _connectionStateSubscription?.cancel();
    await _scanResultsSubscription?.cancel();
    await _dataController.close();
    super.dispose();
  }
}
