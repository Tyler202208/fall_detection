import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  String _errorMessage = ""; //TODO: fix this
  int _page = 0;
  late final List <Widget> _screens = [_page1(), _page2(), _page3()];

  bool _validateControllers(){
    List <TextEditingController> _listControllers = [
      _ageController, 
      _addressController,
      _contactname,
      _contactnumber
    ];
    for(var controller in _listControllers){
      final text = controller.text.trim();
      if (text.isEmpty) {
        return false;
      }
    }
    return true;
  }
  
  Future<void> _verifyFields() async {
    if (_validateControllers()) {

      // Todo: Save data on firestore database
      final user = FirebaseAuth.instance.currentUser;

        await FirebaseFirestore.instance.collection("Users").doc(user?.uid).update(
            {
              // "name": _nameController.text.trim(),
              // "email": _emailController.text.trim(),
              // "createdAt": FieldValue.serverTimestamp()
              "age": _ageController.text.trim(),
              "address": _addressController.text.trim(),
              "emergency_contacts": [
                {
                  "contact_name": _contactname.text.trim(),
                  "contact_number": _contactnumber.text.trim()
                }
              ]
            }
        );
      Navigator.pushReplacementNamed(context, "/home");

    }
    else{
      setState(() {
        _errorMessage = "Please fill in all fields";
        print("verify fields");
      });
    }
  }

  void _onHorizontalDrag(DragEndDetails details) {
    if (details.primaryVelocity! < 0) {
      setState(() => _page = (_page + 1).clamp(0, _screens.length - 1));
    } else if (details.primaryVelocity! > 0) {
      setState(() => _page = (_page - 1).clamp(0, _screens.length - 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onHorizontalDragEnd: _onHorizontalDrag,
        child: _screens[_page],
      ),
    );
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
          SizedBox(height: 30),
          GestureDetector(
            onTap: _verifyFields,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: primary_color,
                  borderRadius: BorderRadius.circular(15)
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                      "Submit",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.bold

                      ),
                  ),
                ),
              ),

            ),
          ),
          SizedBox(height: 30),
          if (_errorMessage.isNotEmpty)...[
            Text(
              _errorMessage,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 30
              ),
            ),
          ],
          Spacer(
            flex: 3
          ),
          three_dots(dot3: true),
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

