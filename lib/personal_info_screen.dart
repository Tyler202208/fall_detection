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
  String _errorMessage = "";
  int _page = 0;
  late final List<Widget> _screens = [_page1(), _page2(), _page3()];

  bool _validateControllers() {
    for (var controller in [_ageController, _addressController, _contactname, _contactnumber]) {
      if (controller.text.trim().isEmpty) return false;
    }
    return true;
  }

  Future<void> _verifyFields() async {
    if (_validateControllers()) {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection("Users").doc(user?.uid).update({
        "age": _ageController.text.trim(),
        "address": _addressController.text.trim(),
        "emergency_contacts": [
          {
            "contact_name": _contactname.text.trim(),
            "contact_number": _contactnumber.text.trim(),
          }
        ],
      });
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, "/home");
    } else {
      setState(() => _errorMessage = "Please fill in all fields.");
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
      backgroundColor: surface_color,
      body: SafeArea(
        child: GestureDetector(
          onHorizontalDragEnd: _onHorizontalDrag,
          child: _screens[_page],
        ),
      ),
    );
  }

  Widget _page1() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          Text(
            "Help us personalize your experience",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: text_primary,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(flex: 2),
          Text(
            "What is your age?",
            style: TextStyle(
              color: text_primary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: "Enter your age",
              prefixIcon: Icon(Icons.cake_rounded, size: 22),
            ),
          ),
          const SizedBox(height: 32),
          _PageDots(current: 0),
          const Spacer(flex: 1),
        ],
      ),
    );
  }

  Widget _page2() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          Text(
            "Help us personalize your experience",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: text_primary,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(flex: 2),
          Text(
            "What is your address?",
            style: TextStyle(
              color: text_primary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              hintText: "Street, city, state",
              prefixIcon: Icon(Icons.location_on_rounded, size: 22),
            ),
          ),
          const SizedBox(height: 32),
          _PageDots(current: 1),
          const Spacer(flex: 1),
        ],
      ),
    );
  }

  Widget _page3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          Text(
            "Provide your emergency contact",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: text_primary,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            "Contact name",
            style: TextStyle(
              color: text_secondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _contactname,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: "Full name",
              prefixIcon: Icon(Icons.person_rounded, size: 22),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Phone number",
            style: TextStyle(
              color: text_secondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _contactnumber,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              hintText: "Phone number",
              prefixIcon: Icon(Icons.phone_rounded, size: 22),
            ),
          ),
          if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: error_color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(input_radius),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: error_color, size: 20),
                  const SizedBox(width: 12),
                  Text(_errorMessage, style: TextStyle(color: error_color, fontSize: 14)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _verifyFields,
              style: FilledButton.styleFrom(
                backgroundColor: primary_color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(button_radius)),
              ),
              child: const Text("Continue"),
            ),
          ),
          const SizedBox(height: 24),
          _PageDots(current: 2),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  final int current;

  const _PageDots({required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? primary_color : text_secondary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
