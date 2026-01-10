import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:senior_fall_detection/constants.dart';
import 'package:fl_chart/fl_chart.dart';

import 'ble_session.dart';
import 'bluetooth.dart';

class ActivityMonitor extends StatefulWidget {

  final BleSession bleSession;
  const ActivityMonitor({super.key, required this.bleSession});




  @override
  State<ActivityMonitor> createState() => _ActivityMonitorState();
}



class _ActivityMonitorState extends State<ActivityMonitor> {

  List<Color> gradientColors = [
    Colors.cyan,
    Colors.blue
    ,
  ];


  @override
  void initState() {
    super.initState();
    widget.bleSession.addListener(_handleBleMessage);
  }

  void _handleBleMessage(String message) {
    setState(() {
      // update UI
    });
  }

  @override
  void dispose() {
    widget.bleSession.removeListener(_handleBleMessage);
    super.dispose();
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
    );
    String text = switch (value.toInt()) {
      0 => "0",
      2 => "1",
      4 => "2",
      6 => "3",
      8 => "4",
      10 => "5",
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

      1 => '1',
      3 => '3',
      5 => '5',
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
          return const FlLine(
            color: Color(0xff37434d),
            strokeWidth: 1,
          );
        },
        getDrawingHorizontalLine: (value) {
          return const FlLine(
            color: Color(0xff37434d),
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
        border: Border.all(color: const Color(0xff37434d)),
      ),
      minX: 0,
      maxX: 11,
      minY: 0,
      maxY: 6,
      lineBarsData: [
        LineChartBarData(
          spots: const [
            FlSpot(0, 3.44),
            FlSpot(2.6, 3.44),
            FlSpot(4.9, 3.44),
            FlSpot(6.8, 3.44),
            FlSpot(8, 3.44),
            FlSpot(9.5, 3.44),
            FlSpot(11, 3.44),
          ],
          isCurved: true,
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
    return Scaffold(
      appBar: AppBar(
        leading: SizedBox(
          width: 15,
        ),
        title: Center(
            child: const
            Text(
                'Activity Monitor',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold
                )
            )
        ),
        backgroundColor: primary_color,

        actions: [
          IconButton(
              onPressed: (){
                setState(() {
                });
              },
              icon: Icon(
                  Icons.refresh,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
              )
          ),

        ],

      ),
      body: Column(
          children: [
            Container(
              width: double.infinity,
              color: primary_color,
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.2),

                    radius: 40,

                    child: Icon(
                        Icons.auto_graph,
                        size: 35,
                        color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Real-Time Monitoring",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20

                    ),

                  ),
                  Text(
                    "Tracking movement and fall risk",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20
                    ),
                  ),
                  SizedBox(height: 20,)
                ],
              ),
            ),
            StreamBuilder <DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection("Users").doc(user!.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting){
                  return Center(
                      child: CircularProgressIndicator()
                  );
                }
                else if (snapshot.hasError){
                  return Center(child: Text("Failed to Connect to Firebase"));
                }

                final user_data;
                var user_fallRisk;

                try{
                  user_data = snapshot.data!.data() as Map<String, dynamic>;
                  user_fallRisk = user_data["alertsToday"];
                }
                catch (e){
                  user_fallRisk = "0";
                }

                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 30),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.grey[200],

                  ),

                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                              "Fall Risk Assessment",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold
                            ),

                          ),
                          Spacer(),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: Colors.lightGreen.withOpacity(0.2),
                            ),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              child: Text(
                                user_fallRisk <= 2? "Low Risk":
                                user_fallRisk <= 4? "Medium Risk":
                                "High Risk",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.red
                                ),
                              ),
                            ),
                          ),
                        ],

                        ),
                      SizedBox(height: 15),
                      Row(
                        children: [
                          Text(
                            "Current Risk Level"
                          ),
                          Spacer(),

                          CircleAvatar(
                            backgroundColor: Colors.green.withOpacity(0.9),
                            radius: 6,
                          ),
                          SizedBox(width: 7),
                          Text(
                            user_fallRisk <= 2? "Low":
                            user_fallRisk <= 4? "Medium":
                            "High",
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold
                            ),
                          )
                        ],
                      ),
                      SizedBox(height: 15),
                      LinearProgressIndicator(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.green,
                        value: user_fallRisk < 5 ? user_fallRisk * 0.2 : 1.0,
                        minHeight: 10,
                      ),
                      SizedBox(height: 15),
                      Text(
                        "Based on recent movement patterns, your fall risk is currently low. Continue with normal activities."
                      ),
                    ],
                  ),
                );
              }
            ),
            Text(
              textAlign: TextAlign.center,
              "Monitor Data",
              style: TextStyle(
                fontSize: 20,
              ),
            ),
            Stack(
              children: <Widget>[
                AspectRatio(
                  aspectRatio: 1.70,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      right: 18,
                      left: 12,
                      top: 24,
                      bottom: 12,
                    ),
                    child: LineChart(
                      avgData(),
                    ),
                  ),
                ),
              ],
            )

          ],
      )
      ,

    );
  }
}
