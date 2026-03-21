import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:senior_fall_detection/constants.dart';
import 'package:fl_chart/fl_chart.dart';

import 'ble_session.dart';
import 'bluetooth.dart';

class ActivityMonitor extends StatefulWidget {

  final BluetoothManager bluetoothManager;
  const ActivityMonitor({super.key, required this.bluetoothManager});





  @override
  State<ActivityMonitor> createState() => _ActivityMonitorState();
}



class _ActivityMonitorState extends State<ActivityMonitor> {

  BluetoothManager get _ble => widget.bluetoothManager;

  // Screen-local copy of fall alerts (mirrors the manager's list for display).
  List<String> _localFallAlerts = [];

  // Stream subscription for incoming BLE data messages.
  StreamSubscription<String>? _dataStreamSub;

  List<Color> gradientColors = [
    primary_color,
    primary_dark,
  ];

  final uid = FirebaseAuth.instance.currentUser!.uid;

  List<FlSpot> graphValues =  [
    FlSpot(0, 0),
    FlSpot(1, 0),
    FlSpot(2, 0),
    FlSpot(3, 0),
    FlSpot(4, 0),
    FlSpot(5, 0),
    FlSpot(6, 0),
    FlSpot(7,0),
    FlSpot(8,0),
    FlSpot(9,0),
    FlSpot(10,0),



  ];


  @override
  void initState() {
    super.initState();
    _ble.addListener(_onBleStateChanged);

    _dataStreamSub = _ble.dataStream.listen(_onDataMessage);

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
    setState(() {
      // Sync fall alerts whenever the manager notifies.
      _localFallAlerts = List.of(_ble.fallAlerts);
    });
  }

  void _onDataMessage(String message) {
    if (!mounted) return;

    message = message.trim();

    if (message.contains("IW")) {
      print(message);

      // Extract the score number after "INSTABILITY WARNING!"
      final scoreStr = message.replaceFirst("IW", "").trim();
      final double? score = double.tryParse(scoreStr);

      if (score != null) {
        print("Score: $score");
        setState(() {
          addNewValue(score);
        });
      } else {
        print("Failed to parse score from: '$scoreStr'");
      }
    }
    if (message == "FALL DETECTED!"){
      _showFallAlert();
      userHasFallen();
      setState(() {});
    }
  }

  Future<void> userHasFallen() async {
    final doc = await FirebaseFirestore.instance
        .collection("Users")
        .doc(uid)
        .get();

    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>?;

    await FirebaseFirestore.instance.collection("Users").doc(uid).update({
      "alertsToday": (data?["alertsToday"] ?? 0) + 1,
    });
  }



  void addNewValue(double newValue) {
    if (graphValues.length >= 11) {
      graphValues.removeAt(0); // remove oldest
    }
    if (newValue >= 9){
      newValue = 9;
    }
    //move all the X index by 1
    for (int i = 0; i < graphValues.length - 1; i ++){
      FlSpot currFlSpot = graphValues[i];
      double x_index = currFlSpot.x;
      double y_index = currFlSpot.y;
      FlSpot newFlSpot = FlSpot(x_index - 1, y_index);
      graphValues[i] = newFlSpot;
    }
    FlSpot newAddition = FlSpot(10, newValue);
    graphValues.add(newAddition); // add newest
  }

  void _showFallAlert() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            const Text('Fall detected'),
          ],
        ),
        content: const Text('A fall has been detected by the sensor.'),
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

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
    );
    String text = switch (value.toInt()) {
      0 => '0',
      1 => '1',
      2 => '2',
      3 => '3',
      4 => '4',
      5 => '5',
      6 => '6',
      7 => '7',
      8 => '8',
      9 => '9',
      10 => '10',
      _ => '',
    };
    return SideTitleWidget(
      meta: meta,
      child: Text(text, style: style),
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 15,
    );
    String text = switch (value.toInt()) {


      0 => '0',
      1 => '1',
      2 => '2',
      3 => '3',
      4 => '4',
      5 => '5',
      6 => '6',
      7 => '7',
      8 => '8',
      9 => '9',
      _ => '',
    };

    return Text(text, style: style, textAlign: TextAlign.left);
  }

  LineChartData avgData() {
    return LineChartData(
      lineTouchData: const LineTouchData(enabled: false),
      gridData: FlGridData(
        show: true,
        drawHorizontalLine: true,
        verticalInterval: 1,
        horizontalInterval: 1,
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: text_secondary.withValues(alpha: 0.25),
            strokeWidth: 1,
          );
        },
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: text_secondary.withValues(alpha: 0.25),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          axisNameWidget: Text(
              "Time Passed(s)"
            ),

          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: bottomTitleWidgets,
            interval: 1,
          ),
        ),
        leftTitles: AxisTitles(
          axisNameWidget: Padding(
            padding: const EdgeInsets.only(right:8.0),
            child: Text(
              "Instability Score"
            ),
          ),
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: leftTitleWidgets,
            reservedSize: 30,
            interval: 1,
          ),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: text_secondary.withValues(alpha: 0.2)),
      ),
      minX: 0,
      maxX: 10,
      minY: 0,
      maxY: 9,
      lineBarsData: [
        LineChartBarData(
          spots: graphValues,
          isCurved: true,
          preventCurveOverShooting: true,
          preventCurveOvershootingThreshold: 0,
          gradient: LinearGradient(
            colors: [
              ColorTween(begin: gradientColors[0], end: gradientColors[1])
                  .lerp(0.2)!,
              ColorTween(begin: gradientColors[0], end: gradientColors[1])
                  .lerp(0.2)!,
            ],
          ),
          barWidth: 5,
          isStrokeCapRound: true,
          dotData: const FlDotData(
            show: false,
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                ColorTween(begin: gradientColors[0], end: gradientColors[1])
                    .lerp(0.2)!
                    .withValues(alpha: 0.1),
                ColorTween(begin: gradientColors[0], end: gradientColors[1])
                    .lerp(0.2)!
                    .withValues(alpha: 0.1),
              ],
            ),
          ),
        ),
      ],
    );
  }

  User? get user => FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final isConnected = _ble.isConnected;

    return Scaffold(
      backgroundColor: surface_color,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: primary_color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.show_chart_rounded, color: primary_color, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Activity monitor",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: text_primary,
                              ),
                            ),
                            Text(
                              "Real-time movement & fall risk",
                              style: TextStyle(fontSize: 14, color: text_secondary),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isConnected ? success_color : error_color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection("Users").doc(user!.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(child: Text("Failed to load data", style: TextStyle(color: text_secondary))),
                    ),
                  );
                }
                var user_fallRisk = 0;
                try {
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  user_fallRisk = data?["alertsToday"] ?? 0;
                } catch (_) {}

                final riskLabel = user_fallRisk <= 2 ? "Low" : user_fallRisk <= 4 ? "Medium" : "High";
                final riskColor = user_fallRisk <= 2 ? success_color : user_fallRisk <= 4 ? warning_color : error_color;

                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
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
                                "Fall risk",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: text_primary,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: riskColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  riskLabel,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: riskColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: user_fallRisk < 5 ? user_fallRisk * 0.2 : 1.0,
                              minHeight: 8,
                              backgroundColor: card_color,
                              valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            user_fallRisk <= 2
                                ? "Your fall risk is currently low. Continue with normal activities."
                                : user_fallRisk <= 4
                                    ? "Medium risk. Please move with caution."
                                    : "High risk. Please stop and get help if needed.",
                            style: TextStyle(fontSize: 14, color: text_secondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Instability over time",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: text_primary,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(card_radius),
                  child: AspectRatio(
                    aspectRatio: 1.70,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16, left: 8, top: 16, bottom: 8),
                      child: LineChart(avgData()),
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}
