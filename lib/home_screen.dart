import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:battery_plus/battery_plus.dart';

import 'bluetooth.dart';
import 'constants.dart';

class HomeScreen extends StatefulWidget {
  /// Every screen receives the shared singleton so they all see the same
  /// connection state and the same live data stream.
  final BluetoothManager bluetoothManager;

  const HomeScreen({super.key, required this.bluetoothManager});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── Convenience getter ───────────────────────────────────────────────────
  BluetoothManager get _ble => widget.bluetoothManager;

  // ── Local state ──────────────────────────────────────────────────────────
  late List<ConnectivityResult> connectivityResult;
  bool isMobileConnected = false;
  final Battery _battery = Battery();
  int getBattery = 0;
  int totalAlerts = -1;
  final uid = FirebaseAuth.instance.currentUser!.uid;

  // Screen-local copy of fall alerts (mirrors the manager's list for display).
  List<String> _localFallAlerts = [];

  // Stream subscription for incoming BLE data messages.
  StreamSubscription<String>? _dataStreamSub;

  // ── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    // Re-render this screen whenever the BluetoothManager changes state
    // (connected, disconnected, scan results updated, etc.).
    _ble.addListener(_onBleStateChanged);

    // Listen to live data messages so this screen can show fall alerts
    // and (optionally) call _showFallAlert.
    _dataStreamSub = _ble.dataStream.listen(_onDataMessage);

    checkConnection();
    _getBatteryLevel();
    _ble.requestPermissions();

    // Sync initial fall-alert list from the manager.
    _localFallAlerts = List.of(_ble.fallAlerts);
  }

  @override
  void dispose() {
    _ble.removeListener(_onBleStateChanged);
    _dataStreamSub?.cancel();
    super.dispose();
  }

  // ── BLE callbacks ─────────────────────────────────────────────────────────
  void _onBleStateChanged() {
    if (!mounted) return;
    setState(() {
      // Sync fall alerts whenever the manager notifies.
      _localFallAlerts = List.of(_ble.fallAlerts);
    });
  }

  void _onDataMessage(String message) {
    if (!mounted) return;
    if (message == "INSTABILITY WARNING!") {
      _showFallAlert();
    }
  }

  // ── UI helpers ────────────────────────────────────────────────────────────
  void _showFallAlert() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 30),
            SizedBox(width: 10),
            Text('FALL DETECTED!'),
          ],
        ),
        content: const Text('A fall has been detected by the sensor.'),
        backgroundColor: Colors.red[50],
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ── Connectivity / battery ────────────────────────────────────────────────
  Future<void> checkConnection() async {
    connectivityResult = await Connectivity().checkConnectivity();
    if (!mounted) return;
    setState(() {
      isMobileConnected =
          connectivityResult.contains(ConnectivityResult.mobile);
    });
  }

  Future<void> _getBatteryLevel() async {
    final level = await _battery.batteryLevel;
    if (!mounted) return;
    setState(() => getBattery = level);
  }

  // ── Firebase ──────────────────────────────────────────────────────────────
  Future<void> userHasFallen() async {
    final doc = await FirebaseFirestore.instance
        .collection("Users")
        .doc(uid)
        .get();

    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>?;

    await FirebaseFirestore.instance.collection("Users").doc(uid).update({
      "alertsToday": totalAlerts,
      "totalAlerts": (data?["alertsToday"] ?? 0) + 1,
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isConnected = _ble.isConnected;
    final isScanning = _ble.isScanning;
    final scanResults = _ble.scanResults;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            // ── Header ──────────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Center(
                child: Text(
                  "StrideGuard",
                  style: TextStyle(fontSize: 50),
                ),
              ),
            ),
            const Center(
              child: Text(
                "Smart monitoring for your safety",
                style: TextStyle(fontSize: 20, color: Colors.grey),
              ),
            ),

            Container(
                margin: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 30),
                decoration: BoxDecoration(
                    color: primary_color,
                    borderRadius: BorderRadius.circular(15)
                ),
                child: Column(
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Icon(
                              Icons.shield,
                              color: Colors.white,
                              size: 30,
                            ),

                            Text(
                              isConnected? "System Active": "System Offline",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20
                              ),
                            ),
                            CircleAvatar(
                              backgroundColor:
                              isConnected? Colors.green.withOpacity(0.7): Colors.red.withOpacity(0.7),
                              radius: 10,
                            )
                          ]
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Text(
                                "24/7",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20
                                ),
                              ),
                              Text(
                                "Monitoring",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              StreamBuilder(
                                  stream: FirebaseFirestore.instance.collection("Users").doc(uid).snapshots(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Center(
                                          child: CircularProgressIndicator()
                                      );
                                    }
                                    else if (snapshot.hasError) {
                                      return Center(child: Text(
                                          "Failed to Connect to Firebase"));
                                    }
                                    final user_data;
                                    var alertsToday;

                                    try{
                                      user_data = snapshot.data!.data() as Map<String, dynamic>;
                                      alertsToday = user_data["alertsToday"];
                                      totalAlerts = alertsToday;

                                    }
                                    catch (e){
                                      alertsToday = 0;
                                    }
                                    return Text(
                                      "$alertsToday",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20
                                      ),
                                    );
                                  }
                              ),
                              Text(
                                "Alerts Today",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20
                                ),
                              )
                            ],
                          ),



                        ],
                      ),




                    ]


                )
            ),

            // ── Sensor Status Card ───────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: card_color,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text(
                        "Sensor Status",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 30,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isConnected
                              ? Colors.lightGreen.withOpacity(0.4)
                              : Colors.red.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          isConnected ? "Connected" : "Disconnected",
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.green[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SensorRowItem(
                    text: 'Wifi Connection',
                    icon: Icon(
                      isMobileConnected ? Icons.wifi : Icons.wifi_1_bar,
                      color: isMobileConnected ? primary_color : Colors.red,
                      size: 30,
                    ),
                    trailing: isMobileConnected ? "Strong" : "Weak",
                  ),
                  SensorRowItem(
                    text: "Battery Level",
                    icon: const Icon(
                      Icons.battery_3_bar,
                      color: Colors.green,
                      size: 30,
                    ),
                    trailing: "$getBattery%",
                  ),
                  SensorRowItem(
                    text: 'Signal Strength',
                    icon: Icon(
                      isMobileConnected
                          ? Icons.signal_cellular_alt
                          : Icons.signal_cellular_alt_1_bar,
                      color: isMobileConnected ? primary_color : Colors.red,
                      size: 30,
                    ),
                    trailing: isMobileConnected ? "Strong" : "Weak",
                  ),
                ],
              ),
            ),

            // ── BLE Control Card ─────────────────────────────────────────
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          isConnected
                              ? Icons.bluetooth_connected
                              : Icons.bluetooth_disabled,
                          color: isConnected ? Colors.green : Colors.grey,
                          size: 30,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isConnected
                                ? 'Connected to ${_ble.connectedDevice?.platformName ?? "Unknown"}'
                                : 'Not connected',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                            isConnected ? null : _ble.startScan,
                            child: Text(
                                isScanning ? 'Scanning...' : 'Scan for Devices'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isConnected ? _ble.disconnect : null,
                            child: const Text('Disconnect'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Scan Results ─────────────────────────────────────────────
            if (scanResults.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Available Devices:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              ...scanResults.map(
                    (result) => Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 4),
                  child: ListTile(
                    title: Text(
                      result.device.platformName.isNotEmpty
                          ? result.device.platformName
                          : result.advertisementData.advName,
                    ),
                    subtitle: Text(result.device.remoteId.toString()),
                    trailing: ElevatedButton(
                      onPressed: () => _ble.connectToDevice(result.device),
                      child: const Text('Connect'),
                    ),
                  ),
                ),
              ),
            ],

            // ── Fall Alerts History ───────────────────────────────────────
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Fall Alerts:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            _localFallAlerts.isEmpty
                ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No fall alerts yet.\n'
                      'Connect to your fall detector to monitor for falls.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            )
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _localFallAlerts.length,
              itemBuilder: (ctx, i) => Card(
                color: Colors.red[50],
                margin: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 4),
                child: ListTile(
                  leading:
                  const Icon(Icons.warning, color: Colors.red),
                  title: const Text('Fall Detected'),
                  subtitle: Text(_localFallAlerts[i]),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ── Reusable widget ──────────────────────────────────────────────────────────
class SensorRowItem extends StatelessWidget {
  final String text;
  final Icon icon;
  final String trailing;

  const SensorRowItem({
    super.key,
    required this.text,
    required this.icon,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 20)),
          const Spacer(),
          Text(
            trailing,
            style: const TextStyle(fontSize: 20, color: Colors.green),
          ),
        ],
      ),
    );
  }
}
