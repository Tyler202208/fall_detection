import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:senior_fall_detection/constants.dart';
import 'package:image_picker/image_picker.dart';

import 'bluetooth.dart';

class Profile extends StatefulWidget {

  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {

  File? _imageFile;
  User? get user => FirebaseAuth.instance.currentUser;
  bool ifEditing = false;
  late TextEditingController updateNameController = TextEditingController();
  late TextEditingController updateAgeController = TextEditingController();
  late TextEditingController updateAddressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isloading = false;
  String? _error;

  Future<String> _promptForPassword() async{
    String password = "";
    final _passwordController = TextEditingController();
    await showDialog(
        context: context, 
        builder: (context){
          final controller = TextEditingController();
          return AlertDialog(
            title: Text("Please Type Your Password"),
            content: TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            actions: [
              TextButton(
                  onPressed: (){
                    password = _passwordController.text;
                    Navigator.of(context).pop();
                  },
                  child: Text("Confirm")
              ),
              TextButton(
                  onPressed: (){
                    Navigator.of(context).pop();
                  },
                  child: Text("Cancel")
              )

            ]
          );
        }
    );
    return password;
  }
  
  Future<void> logout_and_delete() async {
    final action = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          decoration: BoxDecoration(
            color: card_elevated,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: text_secondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Icon(Icons.logout_rounded, color: primary_color),
                  title: const Text("Log out"),
                  onTap: () => Navigator.pop(context, 'Logout'),
                ),
                ListTile(
                  leading: Icon(Icons.delete_outline_rounded, color: error_color),
                  title: Text("Delete account", style: TextStyle(color: error_color, fontWeight: FontWeight.w500)),
                  onTap: () => Navigator.pop(context, 'Delete Account'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ));
    if (action == "Logout"){
      await FirebaseAuth.instance.signOut();
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
    else if (action == 'Delete Account'){
      try{
        final user = FirebaseAuth.instance.currentUser;
        final credential = EmailAuthProvider.credential(
          email: user!.email!,
          password: await _promptForPassword()
        );
        await user?.reauthenticateWithCredential(credential);
        await user?.delete();
        await FirebaseFirestore.instance.collection("Users").doc(user.uid).delete();
        Navigator.pushReplacementNamed(context, "/login");
      }
      catch (e){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Account Deletion Failed"))
        );
      }
    }
}

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    String? profileImageUrl;
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
    // Upload new image if selected
    if (_imageFile != null) {
      profileImageUrl = await _uploadProfileImage();
      if (profileImageUrl == null) {
        throw Exception('Failed to upload image');
      }
    }
    // Update user profile in Firestore
    final updateData = {
      'profileImageUrl': profileImageUrl ?? '',
    };

// Only update image URL if we have a new one
    if (profileImageUrl != null) {
      updateData['profileImageUrl'] = profileImageUrl;
    }

    await FirebaseFirestore.instance.collection('Users').doc(user!.uid).update(updateData);
  }

  Future<String?> _uploadProfileImage() async {
    if (_imageFile == null || user == null) return null;

    try {
      final storageRef = FirebaseStorage.instance.ref().child(
        'profile_images/${user!.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      await storageRef.putFile(_imageFile!);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future <void> updateProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isloading = true;
        _error = null;
      });
      try{
        final user = FirebaseAuth.instance.currentUser;
        await FirebaseFirestore.instance.collection("Users").doc(user?.uid).update(
            {
              "name": updateNameController.text.trim(),
              "age": updateAgeController.text.trim(),
              "address": updateAddressController.text.trim()


            }
        );
        setState(() {
          ifEditing = false;
        });
      }
      catch(e){
        setState(() {
          _error = "Update failed";
        });
      }
      finally{
        setState(() {
          _isloading = false;
        });
      }

    }
  }




  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      backgroundColor: surface_color,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: logout_and_delete,
            icon: const Icon(Icons.more_vert_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: StreamBuilder <DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection("Users").doc(uid).snapshots(),
            builder: (context, snapshot){
              if (snapshot.connectionState == ConnectionState.waiting){
                return Center(
                    child: CircularProgressIndicator()
                );
              }
              else if (snapshot.hasError){
                return Center(child: Text("Failed to Connect to Firebase"));
              }

              // TODO: Connected to firebase, and get all field values

              final user_data;
              var user_name;
              var user_age;
              var user_address;
              List <Map<String, dynamic>> user_emergencyContacts;
              var user_profilePic;
              var user_fallsDetected;

              try{
                user_data = snapshot.data!.data() as Map<String, dynamic>;
                user_name = user_data["name"];
                updateNameController.text = user_name;
                user_age = user_data["age"];
                updateAgeController.text = user_age;
                user_address = user_data["address"];
                updateAddressController.text = user_address;
                try {
                  user_emergencyContacts = user_data["emergency_contacts"];
                }
                catch(e){
                  user_emergencyContacts = [];
                }
                print(user_emergencyContacts);
                user_profilePic = user_data["profileImageUrl"];
                print(user_profilePic);
                user_fallsDetected = user_data["alertsToday"];
              }
              catch (e){
                user_name = "";
                user_age = "";
                user_address = "";
                user_emergencyContacts = [];
                user_profilePic = "https://images.rawpixel.com/image_png_800/czNmcy1wcml2YXRlL3Jhd3BpeGVsX2ltYWdlcy93ZWJzaXRlX2NvbnRlbnQvbHIvdjkzNy1hZXctMTY1LnBuZw.png";
                user_fallsDetected = "";
              }

              //TODO: Use fields in blueprint (my UI)

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primary_color, primary_dark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                      boxShadow: [
                        BoxShadow(
                          color: primary_color.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                                backgroundImage: NetworkImage(user_profilePic),
                                radius: 44,
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: primary_dark,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          user_name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Age $user_age", style: textcard_color),
                            const SizedBox(width: 8),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: Colors.white54,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text("StrideGuard user", style: textcard_color),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (ifEditing)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlinedButton(
                                onPressed: () => setState(() => ifEditing = false),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white70),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(button_radius)),
                                ),
                                child: const Text("Cancel"),
                              ),
                              const SizedBox(width: 12),
                              FilledButton(
                                onPressed: updateProfile,
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: primary_color,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(button_radius)),
                                ),
                                child: const Text("Save"),
                              ),
                            ],
                          )
                        else
                          TextButton.icon(
                            onPressed: () => setState(() => ifEditing = true),
                            icon: const Icon(Icons.edit_rounded, size: 18, color: Colors.white),
                            label: const Text("Edit profile", style: TextStyle(color: Colors.white)),
                          ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Number_word(
                                number: user_emergencyContacts.length.toString(),
                                text: "Emergency",
                                optional_text: "Contacts"),
                            Number_word(number: "24/7", text: "Monitoring"),
                            Number_word(
                                number: user_fallsDetected.toString(),
                                text: "Falls",
                                optional_text: "Detected"),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                    child: Text(
                      "Personal information",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: text_primary,
                      ),
                    ),
                  ),
                  if (ifEditing)
                    Form(
                      key: _formKey,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: card_elevated,
                          borderRadius: BorderRadius.circular(card_radius),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: updateNameController,
                              decoration: const InputDecoration(labelText: "Name"),
                              validator: (value) => value == null || value.isEmpty ? 'Enter your name' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: updateAgeController,
                              decoration: const InputDecoration(labelText: "Age"),
                              validator: (value) => value == null || value.isEmpty ? 'Enter your age' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: updateAddressController,
                              decoration: const InputDecoration(labelText: "Address"),
                              validator: (value) => value == null ? 'Enter your address' : null,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: card_elevated,
                        borderRadius: BorderRadius.circular(card_radius),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primary_color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.person_rounded, color: primary_color, size: 22),
                            ),
                            title: Text('Name', style: TextStyle(fontSize: 13, color: text_secondary)),
                            subtitle: Text(user_name, style: const TextStyle(fontWeight: FontWeight.w500)),
                          ),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: success_color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.cake_rounded, color: success_color, size: 22),
                            ),
                            title: Text('Age', style: TextStyle(fontSize: 13, color: text_secondary)),
                            subtitle: Text('$user_age years', style: const TextStyle(fontWeight: FontWeight.w500)),
                          ),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primary_dark.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.location_on_rounded, color: primary_dark, size: 22),
                            ),
                            title: Text('Address', style: TextStyle(fontSize: 13, color: text_secondary)),
                            subtitle: Text(user_address.toString(), style: const TextStyle(fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                    child: Text(
                      "Emergency contacts",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: text_primary,
                      ),
                    ),
                  ),
                  ...user_emergencyContacts.map(
                    (item) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      decoration: BoxDecoration(
                        color: card_elevated,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: Icon(Icons.contact_phone_rounded, color: primary_color),
                        title: Text(item["contact_name"], style: const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text(item["contact_number"], style: TextStyle(color: text_secondary, fontSize: 14)),
                      ),
                    ),
                  ).toList()


                ],
              );

            }
        ),
      )
    );
  }
}

class Number_word extends StatelessWidget {

  final String number;
  final String text;
  final String? optional_text;
  const Number_word({super.key, required this.number, required this.text, this.optional_text});

  @override
  Widget build(BuildContext context) {
    return  Column(
      children: [
        Text(
          number,
          style: textcard_color_bigger_bolder,
        ),
        Text(
          text,
          style: textcard_color,
        ),
        if (optional_text != null)...[
          Text(
            optional_text!,
            style: textcard_color,
          ),
        ]

      ],
    );
  }
}

