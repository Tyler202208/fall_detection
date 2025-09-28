import 'package:flutter/material.dart';

class FallAlert extends StatefulWidget {
  const FallAlert({super.key});

  @override
  State<FallAlert> createState() => _FallAlertState();
}

class _FallAlertState extends State<FallAlert> {
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
                'Fall Alert',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold

                )
            )
        ),
        backgroundColor: Colors.red,

        actions: [
          IconButton(
              onPressed: (){},
              icon: Icon(
                Icons.phone,
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
              color: Colors.red,
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.2),

                    radius: 40,

                    child: Icon(
                      Icons.warning_amber,
                      size: 35,
                      color: Colors.white.withOpacity(0.65),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Fall Detected!",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20

                    ),

                  ),
                  Text(
                    "Emergency response activated",
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
                color: Colors.yellow.withOpacity(0.35),
                border: Border.all(
                  color: Colors.orange,
                  width: 2
                )

              ),

              child: Column(
                children: [
                  Text(
                    "Auto-Call in Progress",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red
                    ),

                  ),
                  SizedBox(height: 5),
                  Text(
                    "00:15",
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.red
                    ),
                  ),
                  Center(
                    child: Text(
                      "Emergency services will be called automatically",
                      style: TextStyle(
                          color: Colors.red,
                          fontSize: 15
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 30),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.red,
              ),

              child: Column(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.2),

                    radius: 40,

                    child: Icon(
                      Icons.phone,
                      size: 35,
                      color: Colors.white.withOpacity(0.65),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Call Emergency Services",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20

                    ),

                  ),
                  Text(
                    "Immediate response needed",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                      onPressed: (){},
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                                Icons.phone,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                            ),
                            Text(
                              "Call 911 Now",
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 17
                              ),
                            )
                          ],
                        ),
                      )
                  )
                ],
              ),
            ),


          ],
        )
    );
  }
}
