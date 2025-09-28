import 'package:flutter/material.dart';
import 'package:senior_fall_detection/constants.dart';

class ActivityMonitor extends StatefulWidget {
  const ActivityMonitor({super.key});

  @override
  State<ActivityMonitor> createState() => _ActivityMonitorState();
}

class _ActivityMonitorState extends State<ActivityMonitor> {
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
              onPressed: (){},
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
            Container(
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
                            "Low Risk",
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
                        "Low",
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
                    value: 0.25,
                    minHeight: 10,
                  ),
                  SizedBox(height: 15),
                  Text(
                    "Based on recent movement patterns, your fall risk is currently low. Continue with normal activities."
                  ),
                ],
              ),
            )

          ],
        )

      ,

    );
  }
}
