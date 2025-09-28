import 'package:flutter/material.dart';
import 'package:senior_fall_detection/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
                          "System Active",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20
                          ),
                      ),
                      CircleAvatar(
                        backgroundColor: Colors.green.withOpacity(0.7),
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
                          Text(
                            "0",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20
                            ),
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
                        icon: Icon(
                          Icons.wifi,
                          color: primary_color,
                          size: 30,
                        ),
                        trailing: "Strong"
                    ),
                    SensorRowItem(
                        text: "Battery Level",
                        icon: Icon(
                          Icons.battery_3_bar,
                          color: Colors.green,
                          size: 30,
                        ),
                        trailing: "85%"
                    ),
                    SensorRowItem(
                        text: "Signal Strength",
                        icon: Icon(
                          Icons.signal_cellular_alt,
                          color: primary_color,
                          size: 30,
                        ),
                        trailing: "Excellent"
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
