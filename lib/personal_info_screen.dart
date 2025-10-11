import 'package:flutter/material.dart';
import 'package:senior_fall_detection/constants.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _ageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primary_color,
      appBar: AppBar(),
      body: Column(
        children: [
          Text(
            "Help us personalize your experience",
            style: TextStyle(
              color: Colors.white,
              fontSize: 30
            ),
          ),
          Text(
            "What is your age?",
            style: TextStyle(
                color: Colors.white,
                fontSize: 30
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 12),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
                color: card_color,
                borderRadius: BorderRadius.circular(15)
            ),
            child: TextFormField(
              controller: _ageController,
              validator: (value) => value == null || value is num ? 'Enter a valid age' : null,
            ),
          )


        ],
      ),

    );
  }
}
