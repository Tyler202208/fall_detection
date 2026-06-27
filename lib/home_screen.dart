import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:battery_plus/battery_plus.dart';

import 'bluetooth.dart';
import 'constants.dart';

class HomeScreen extends StatefulWidget {
  final BluetoothManager bluetoothManager;

  const HomeScreen({super.key, required this.bluetoothManager});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  BluetoothManager get _ble => widget.bluetoothManager;

  late List<ConnectivityResult> connectivityResult;
  bool isMobileConnected = false;
  final Battery _battery = Battery();
  int getBattery = 0;
  int totalAlerts = -1;
  final uid = FirebaseAuth.instance.currentUser!.uid;

  List<String> _localFallAlerts = [];
  StreamSubscription<String>? _dataStreamSub;

  @override
  void initState() {
    super.initState();
    _ble.addListener(_onBleStateChanged);
    _dataStreamSub = _ble.dataStream.listen(_onDataMessage);
    checkConnection();
    _getBatteryLevel();
    _ble.requestPermissions();
    _localFallAlerts = List.of(_ble.fallAlerts);
  }

  @override
  void dispose() {
    _ble.removeListener(_onBleStateChanged);
    _dataStreamSub?.cancel();
    super.dispose();
  }

  void _onBleStateChanged() {
    if (!mounted) return;
    setState(() => _localFallAlerts = List.of(_ble.fallAlerts));
  }

  void _onDataMessage(String message) {
    if (!mounted) return;
    if (message == "FALL DETECTED!") _showFallAlert();
  }

  void _showFallAlert() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(card_radius)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: error_color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.warning_amber_rounded, color: error_color, size: 28),
            ),
            const SizedBox(width: 12),
            const Text("Fall detected"),
          ],
        ),
        content: const Text(
          'A fall was detected. Please get help or confirm you are okay.',
          style: TextStyle(fontSize: 16),
        ),
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text("OK", style: TextStyle(color: primary_color, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> checkConnection() async {
    connectivityResult = await Connectivity().checkConnectivity();
    if (!mounted) return;
    setState(() {
      isMobileConnected = connectivityResult.contains(ConnectivityResult.mobile);
    });
  }

  Future<void> _getBatteryLevel() async {
    final level = await _battery.batteryLevel;
    if (!mounted) return;
    setState(() => getBattery = level);
  }

  Future<void> userHasFallen() async {
    final doc = await FirebaseFirestore.instance.collection("Users").doc(uid).get();
    if (!doc.exists) return;
    final data = doc.data() as Map<String, dynamic>?;
    await FirebaseFirestore.instance.collection("Users").doc(uid).update({
      "alertsToday": totalAlerts,
      "totalAlerts": (data?["alertsToday"] ?? 0) + 1,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _ble.isConnected;
    final isScanning = _ble.isScanning;
    final scanResults = _ble.scanResults;

    return Scaffold(
      backgroundColor: surface_color,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            // Header
            Text(
              "StrideGuard",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: text_primary,
                fontFamily: "Inter",
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Smart monitoring for your safety",
              style: TextStyle(fontSize: 15, color: text_secondary),
            ),
            const SizedBox(height: 24),

            // Status card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primary_color, primary_dark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(card_radius),
                boxShadow: [
                  BoxShadow(
                    color: primary_color.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield_rounded, color: Colors.white, size: 28),
                      const SizedBox(width: 10),
                      Text(
                        isConnected ? "System active" : "System offline",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isConnected ? Colors.white : Colors.white54,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: isConnected ? Colors.greenAccent : Colors.redAccent,
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatChip(label: "24/7", sublabel: "Monitoring"),
                      Container(width: 1, height: 36, color: Colors.white24),
                      StreamBuilder(
                        stream: FirebaseFirestore.instance
                            .collection("Users")
                            .doc(uid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            );
                          }
                          if (snapshot.hasError) {
                            return const Text("—", style: TextStyle(color: Colors.white, fontSize: 20));
                          }
                          var alertsToday = 0;
                          try {
                            final data = snapshot.data!.data() as Map<String, dynamic>?;
                            alertsToday = data?["alertsToday"] ?? 0;
                            totalAlerts = alertsToday;
                          } catch (_) {}
                          return _StatChip(
                            label: "$alertsToday",
                            sublabel: "Alerts today",
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Sensor status
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: card_elevated,
                borderRadius: BorderRadius.circular(card_radius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "Sensor status",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: text_primary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isConnected
                              ? success_color.withValues(alpha: 0.15)
                              : error_color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isConnected ? "Connected" : "Disconnected",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isConnected ? success_color : error_color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SensorRowItem(
                    text: "Wi‑Fi",
                    icon: Icon(
                      isMobileConnected ? Icons.wifi_rounded : Icons.wifi_1_bar_rounded,
                      color: isMobileConnected ? primary_color : text_secondary,
                      size: 24,
                    ),
                    trailing: isMobileConnected ? "Strong" : "Weak",
                  ),
                  SensorRowItem(
                    text: "Battery",
                    icon: Icon(Icons.battery_charging_full_rounded, color: success_color, size: 24),
                    trailing: "$getBattery%",
                  ),
                  SensorRowItem(
                    text: "Signal",
                    icon: Icon(
                      isMobileConnected ? Icons.signal_cellular_alt_rounded : Icons.signal_cellular_alt_1_bar_rounded,
                      color: isMobileConnected ? primary_color : text_secondary,
                      size: 24,
                    ),
                    trailing: isMobileConnected ? "Strong" : "Weak",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // BLE control
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: card_elevated,
                borderRadius: BorderRadius.circular(card_radius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isConnected ? Icons.bluetooth_connected_rounded : Icons.bluetooth_disabled_rounded,
                        color: isConnected ? primary_color : text_secondary,
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isConnected
                              ? 'Connected to ${_ble.connectedDevice?.platformName ?? "device"}'
                              : 'Not connected',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: text_primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: isConnected ? null : _ble.startScan,
                          icon: isScanning
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.search_rounded, size: 20),
                          label: Text(isScanning ? "Scanning…" : "Scan"),
                          style: FilledButton.styleFrom(
                            backgroundColor: primary_color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(button_radius)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isConnected ? _ble.disconnect : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: text_primary,
                            side: BorderSide(color: isConnected ? error_color : Colors.grey.shade300),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(button_radius)),
                          ),
                          child: const Text("Disconnect"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (scanResults.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                "Available devices",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: text_primary,
                ),
              ),
              const SizedBox(height: 10),
              ...scanResults.map(
                (result) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: card_elevated,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Icon(Icons.bluetooth_rounded, color: primary_color),
                    title: Text(
                      result.device.platformName.isNotEmpty
                          ? result.device.platformName
                          : result.advertisementData.advName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      result.device.remoteId.toString(),
                      style: TextStyle(fontSize: 12, color: text_secondary),
                    ),
                    trailing: FilledButton(
                      onPressed: () => _ble.connectToDevice(result.device),
                      style: FilledButton.styleFrom(
                        backgroundColor: primary_color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(button_radius)),
                      ),
                      child: const Text("Connect"),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),
            Text(
              "Fall alerts",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: text_primary,
              ),
            ),
            const SizedBox(height: 10),
            _localFallAlerts.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: card_color,
                      borderRadius: BorderRadius.circular(card_radius),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.notifications_none_rounded, size: 40, color: text_secondary),
                        const SizedBox(height: 12),
                        Text(
                          "No fall alerts yet.\nConnect your fall detector to monitor for falls.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, color: text_secondary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _localFallAlerts.length,
                    itemBuilder: (ctx, i) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: error_color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: error_color.withValues(alpha: 0.2)),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.warning_amber_rounded, color: error_color, size: 24),
                        title: const Text("Instability detected", style: TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text(_localFallAlerts[i], style: TextStyle(color: text_secondary, fontSize: 13)),
                      ),
                    ),
                  ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String sublabel;

  const _StatChip({required this.label, required this.sublabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        Text(
          sublabel,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 12),
          Text(text, style: TextStyle(fontSize: 16, color: text_primary)),
          const Spacer(),
          Text(
            trailing,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: success_color),
          ),
        ],
      ),
    );
  }
}
