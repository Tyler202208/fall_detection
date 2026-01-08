import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:senior_fall_detection/constants.dart';

import 'ble_session.dart';
import 'bluetooth.dart';

class ActivityMonitor extends StatefulWidget {

  final BleSession bleSession;
  const ActivityMonitor({super.key, required this.bleSession});




  @override
  State<ActivityMonitor> createState() => _ActivityMonitorState();
}



class _ActivityMonitorState extends State<ActivityMonitor> {


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
            )

          ],
        )

      ,

    );
  }
}
