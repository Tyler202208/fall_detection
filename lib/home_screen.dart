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

import 'ble_session.dart';
import 'bluetooth.dart';

class HomeScreen extends StatefulWidget {

  final BleSession bleSession;
  final Bluetooth bluetoothManager;

  const HomeScreen({super.key, required this.bleSession, required this.bluetoothManager});

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





  @override
  void initState()  {
    super.initState();
    checkConnection();
    getBatteryLevel();
    _requestPermissions();
  }

  @override
  void dispose() {
    characteristicSubscription?.cancel();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  Future<void> _startScan() async {
    if (isScanning) return;

    setState(() {
      isScanning = true;
      scanResults.clear();
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

      FlutterBluePlus.scanResults.listen((results) {
        setState(() {
          scanResults = results.where((result) =>
          result.device.platformName.isNotEmpty &&
              (result.device.platformName.contains('FallDetector') ||
                  result.advertisementData.advName.contains('FallDetector'))
          ).toList();
        });
      });

      await Future.delayed(const Duration(seconds: 10));
      await FlutterBluePlus.stopScan();
    } catch (e) {
      debugPrint('Error during scan: $e');
    }

    setState(() {
      isScanning = false;
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(timeout: const Duration(seconds: 10));

      setState(() {
        connectedDevice = device;
        isConnected = true;
      });

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
              characteristicSubscription = characteristic.lastValueStream.listen(widget.bleSession.onDataReceived);
              break;
            }
          }
          break;
        }
      }

      // Listen for disconnection
      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          setState(() {
            isConnected = false;
            connectedDevice = null;
            uartCharacteristic = null;
          });
          characteristicSubscription?.cancel();
        }
      });

    } catch (e) {
      debugPrint('Error connecting to device: $e');
    }
  }

  void _onDataReceived(List<int> data) {
    // Debug: Show raw data bytes
    print('Raw data bytes: $data');

    // Decode the message
    String message = utf8.decode(data).trim();

    // Debug: Show decoded message with length and character codes
    print('Decoded message: "$message" (length: ${message.length})');
    print('Character codes: ${message.codeUnits}');


    if (message == "FALL DETECTED!") {
      // Add to a visible log in the UI
      setState(() {
        fallAlerts.insert(0, 'Received: "$message" at ${DateTime.now().toString()}');
      });

      // Show alert dialog
      _showFallAlert();
    }
  }

  void _showFallAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _disconnect() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
    }
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
    DocumentSnapshot documentSnapshot =  await FirebaseFirestore.instance.collection("Users").doc(uid).get();

    if(!documentSnapshot.exists) {
      return;
    }
    var data = documentSnapshot.data() as Map<String, dynamic>?;



    await FirebaseFirestore.instance.collection("Users").doc(uid).update(
        {
          "alertsToday": totalAlerts,
          "totalAlerts": data?["alertsToday"] + 1 ?? 0
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
              "StrideGuard",
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
                                color: isConnected? Colors.lightGreen.withOpacity(0.4) : Colors.red.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(15)
                            ),
                            child: Text(
                              isConnected? "Connected": "Disconnected",
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










            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                          color: isConnected ? Colors.green : Colors.grey,
                          size: 30,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isConnected
                                ? 'Connected to ${connectedDevice?.platformName ?? "Unknown"}'
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
                            onPressed: isConnected ? null : _startScan,
                            child: Text(isScanning ? 'Scanning...' : 'Scan for Devices'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isConnected ? _disconnect : null,
                            child: const Text('Disconnect'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Scan Results
            if (scanResults.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('Available Devices:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...scanResults.map((result) => Card(
                child: ListTile(
                  title: Text(result.device.platformName.isNotEmpty
                      ? result.device.platformName
                      : result.advertisementData.advName),
                  subtitle: Text(result.device.remoteId.toString()),
                  trailing: ElevatedButton(
                    onPressed: () => _connectToDevice(result.device),
                    child: const Text('Connect'),
                  ),
                ),
              )),
            ],

            // Fall Alerts History
            const SizedBox(height: 20),
            const Text('Fall Alerts:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: fallAlerts.isEmpty
                  ? const Center(
                child: Text(
                  'No fall alerts yet.\nConnect to your fall detector to monitor for falls.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
                  : ListView.builder(
                itemCount: fallAlerts.length,
                itemBuilder: (context, index) {
                  return Card(
                    color: Colors.red[50],
                    child: ListTile(
                      leading: const Icon(Icons.warning, color: Colors.red),
                      title: const Text('Fall Detected'),
                      subtitle: Text(fallAlerts[index]),
                    ),
                  );
                },
              ),
            ),











































          ],
        ),
      ),

    );
  }
}

class data {
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

