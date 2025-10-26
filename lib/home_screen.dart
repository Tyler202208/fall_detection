import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:senior_fall_detection/constants.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  late List<ConnectivityResult> connectivityResult;
  late var isMobileConnected = false;
  var battery = Battery();
  int getBattery = 0;
  bool isDeviceConnected = false;
  int totalAlerts = -1;
  final uid = FirebaseAuth.instance.currentUser!.uid;




  @override
  void initState()  {
    super.initState();
    checkConnection();
    getBatteryLevel();
  }
  Future<void> checkConnection() async {
    connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile)) {

      setState(() {
        isMobileConnected = true;
      });
    }
  }

  Future<void> getBatteryLevel() async {
    getBattery = await battery.batteryLevel;
    print(getBattery);
  }


  //TODO: Assume you've added to total alerts
  Future <void> userHasFallen() async {
    await FirebaseFirestore.instance.collection("Users").doc(uid).update(
        {
          "alertsToday": totalAlerts,
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Text(
              "Fall Detection",
              style: TextStyle(
                fontSize: 50
              )
            ),
            Text(
              "Smart monitoring for your safety",
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey

              )
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
                          isDeviceConnected? "System Active": "System Offline",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20
                          ),
                      ),
                      CircleAvatar(
                        backgroundColor:
                        isDeviceConnected? Colors.green.withOpacity(0.7): Colors.red.withOpacity(0.7),
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

            Container(
              margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              padding: EdgeInsets.all(15),

                decoration: BoxDecoration(
                  color: card_color,
                  borderRadius: BorderRadius.circular(15)

                ),
                child: Column(
                  children: [
                    Row(
                        children: [
                          Text(
                            "Sensor Status",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 30

                            )
                          ),
                          Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                                color: Colors.lightGreen.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(15)
                            ),
                            child: Text(
                              "Connected",
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.green[900]
                              ),
                            ),
                          )
                        ]
                    ),
                    SensorRowItem(
                        text: 'Wifi Connection',
                        icon: isMobileConnected?
                          Icon(
                            Icons.wifi,
                            color: primary_color,
                            size: 30,
                          ):
                          Icon(
                            Icons.wifi_1_bar,
                            color: Colors.red,
                            size: 30
                          ) ,
                        trailing: isMobileConnected?
                            "Strong":
                            "Weak"
                    ),
                    SensorRowItem(
                        text: "Battery Level",
                        icon: Icon(
                          Icons.battery_3_bar,
                          color: Colors.green,
                          size: 30,
                        ),
                        trailing: getBattery.toString()
                    ),
                    SensorRowItem(
                        text: 'Signal Strength',
                        icon: isMobileConnected?
                        Icon(
                          Icons.signal_cellular_alt,
                          color: primary_color,
                          size: 30,
                        ):
                        Icon(
                            Icons.signal_cellular_alt_1_bar,
                            color: Colors.red,
                            size: 30
                        ) ,
                        trailing: isMobileConnected?
                        "Strong":
                        "Weak"
                    )

                  ],
                )
            )

          ],
        ),
      ),

    );
  }
}

class SensorRowItem extends StatelessWidget {
  final String text;
  final Icon icon;
  final String trailing;
  const SensorRowItem({super.key, required this.text, required this.icon, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          icon,
          SizedBox(width:10),
          Text(
            text,
            style: TextStyle(
                fontSize: 20
            ),
          ),
          Spacer(),
          Text(
            trailing,
            style: TextStyle(
                fontSize: 20,
                color: Colors.green
            ),

          )

        ],
      ),
    );
  }
}

