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

import 'bluetooth.dart';

class HomeScreen extends StatefulWidget {

  final Bluetooth bluetoothManager;
  const HomeScreen({super.key, required this.bluetoothManager});

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
  Bluetooth get manager => widget.bluetoothManager;




  @override
  void initState()  {
    super.initState();
    checkConnection();
    getBatteryLevel();
    initBluetooth();
    manager.onDataReceived.listen((message) {
      if (message == "FALL DETECTED!") {
        setState(() {
        });
        _showFallAlert();
      }
    });
  }

  Future<void> initBluetooth() async {
    await manager.requestPermissions();

    // Wait until Bluetooth is ON before scanning
    BluetoothAdapterState state = await FlutterBluePlus.adapterState.first;
    if (state != BluetoothAdapterState.on) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Bluetooth Off'),
          content: const Text('Please enable Bluetooth and try again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

  }



  void _showFallAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    userHasFallen();
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
    DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection("Users").doc(uid).get();
    if (!snapshot.exists) return;
    await FirebaseFirestore.instance.collection("Users").doc(uid).update(
        {
          "totalAlerts": snapshot.get("totalAlerts") + 1

        }
    );
  }

  void scanPopup (var results){
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Device Connected'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              if (manager.scanResults.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('Available Devices:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ...manager.scanResults.map((result) => Card(
                  child: ListTile(
                    title: Text(result.device.platformName.isNotEmpty
                        ? result.device.platformName
                        : result.advertisementData.advName),
                    subtitle: Text(result.device.remoteId.toString()),
                    trailing: ElevatedButton(
                      onPressed: () async {
                        await manager.connectToDevice(result.device, () {
                          setState(() {});
                        });
                        setState(() {});
                      },
                      child: const Text('Connect'),
                    ),
                  ),
                )),
              ],

            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
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
                          manager.isConnected? "System Active": "System Offline",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20
                          ),
                      ),
                      CircleAvatar(
                        backgroundColor:
                        manager.isConnected? Colors.green.withOpacity(0.7): Colors.red.withOpacity(0.7),
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
                                color: manager.isConnected? Colors.lightGreen.withOpacity(0.4) : Colors.red.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(15)
                            ),
                            child: Text(
                              manager.isConnected? "Connected": "Disconnected",
                              style: TextStyle(
                                fontSize: 15,
                                color:
                                Colors.green[900]
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
            ),
            SizedBox(height: 20,),

            Text(
              manager.isConnected? "Connected" : "Not Connected",
              style: TextStyle(
                color: Colors.black,
                fontSize: 25,
                fontWeight: FontWeight.bold
              ),
            ),

            GestureDetector(
              onTap: manager.isConnected
                  ? null
                  : () async {
                await manager.startScan((results) {
                  setState(() {

                  });
                  scanPopup(results);
                });
              },
              child: CircleAvatar(
                backgroundColor: Colors.grey.withOpacity(0.3),
                radius: 80,
                child: Icon(
                    manager.isConnected? Icons.bluetooth:Icons.bluetooth_disabled,
                    color: Colors.black,
                    size: 80,
                ),
              ),
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

