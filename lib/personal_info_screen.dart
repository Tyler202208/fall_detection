import 'package:flutter/material.dart';
import 'package:senior_fall_detection/constants.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactname = TextEditingController();
  final _contactnumber = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return _page3();
  }


  Widget _page1(){
    return Scaffold(
      backgroundColor: primary_color,
      appBar: AppBar(
        backgroundColor: primary_color,

      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              textAlign: TextAlign.center,
              "Help us personalize your experience",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 30
              ),
            ),
          ),
          Spacer(
            flex: 7,
          ),
          Text(
            "What is your age?",
            style: TextStyle(
                color: Colors.white,
                fontSize: 30
            ),
          ),
          SizedBox(height: 20),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 12),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
                color: card_color,
                borderRadius: BorderRadius.circular(15)
            ),
            child: TextFormField(
              controller: _ageController,
              validator: (value) => value != null || value is num ?  null : 'Enter a valid age',
            ),
          ),
          SizedBox(height: 20),
          three_dots(dot1: true),
          Spacer(
            flex: 1,
          )




        ],
      ),

    );
  }

  Widget _page2(){
    return Scaffold(
      backgroundColor: primary_color,
      appBar: AppBar(
        backgroundColor: primary_color,

      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              textAlign: TextAlign.center,
              "Help us personalize your experience",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 30
              ),
            ),
          ),
          Spacer(
            flex: 7,
          ),
          Text(
            "What is your address?",
            style: TextStyle(
                color: Colors.white,
                fontSize: 30
            ),
          ),
          SizedBox(height: 20),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 12),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
                color: card_color,
                borderRadius: BorderRadius.circular(15)
            ),
            child: TextFormField(
              controller: _addressController,
              validator: (value) => value != null ? null : 'Enter a valid age',
            ),
          ),
          SizedBox(height: 20),
          three_dots(dot2: true),
          Spacer(
            flex: 1,
          )




        ],
      ),

    );
  }

  Widget _page3(){
    return Scaffold(
      backgroundColor: primary_color,
      appBar: AppBar(
        backgroundColor: primary_color,

      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              textAlign: TextAlign.center,
              "Provide your emergency contacts",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 30
              ),
            ),
          ),
          SizedBox(height: 20),

          Text(
            "Contact Full Name",
            style: TextStyle(
                color: Colors.white,
                fontSize: 30
            ),
          ),
          SizedBox(height: 20),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 12),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
                color: card_color,
                borderRadius: BorderRadius.circular(15)
            ),
            child: TextFormField(
              controller: _contactname,
              validator: (value) => value != null ? null : 'Enter a valid name',
            ),
          ),
          SizedBox(height: 20),
          Text(
            "Contact Phone Number",
            style: TextStyle(
                color: Colors.white,
                fontSize: 30
            ),
          ),
          SizedBox(height: 20),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 12),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
                color: card_color,
                borderRadius: BorderRadius.circular(15)
            ),
            child: TextFormField(
              controller: _contactnumber,
              validator: (value) => value != null  ? null : 'Enter a valid number',
            ),
          ),
          SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),

          ),
          three_dots(dot2: true),
          Spacer(
            flex: 1,
          )




        ],
      ),

    );
  }
}

class three_dots extends StatelessWidget {
  bool dot1;
  bool dot2;
  bool dot3;
  three_dots({super.key, this.dot1 = false, this.dot2 = false, this.dot3 = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(
            height: 25,
            width: 25,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dot1?
                    Colors.white:
                    Colors.white.withOpacity(0.2)
            ),
          ),
          Container(
            height: 25,
            width: 25,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dot2?
                Colors.white:
                Colors.white.withOpacity(0.2)
            ),
          ),
          Container(
            height: 25,
            width: 25,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dot3?
                Colors.white:
                Colors.white.withOpacity(0.2)
            ),
          )
        ],
      ),
    );
  }
}

