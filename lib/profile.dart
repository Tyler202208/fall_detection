import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:senior_fall_detection/constants.dart';
import 'package:image_picker/image_picker.dart';

import 'bluetooth.dart';

class Profile extends StatefulWidget {

  final Bluetooth bluetoothManager;
  const Profile({super.key, required this.bluetoothManager});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {

  File? _imageFile;
  User? get user => FirebaseAuth.instance.currentUser;

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
    final action = await showModalBottomSheet <String> (
        context: context,
        builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.logout),
                  title: Text(
                    "Logout"
                  ),
                  onTap: () => Navigator.pop(context, 'Logout'),
                ),
                ListTile(
                  leading: Icon(
                    Icons.delete,
                    color: Colors.red
                  ),
                  title: Text(
                    "Delete Account",
                    style: TextStyle(
                      color: Colors.red
                    ),
                  ),
                  onTap: () => Navigator.pop(context, 'Delete Account'),
                )
              ]
            )
        )
    );
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




  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(
          leading: SizedBox(
            width: 15,
          ),
          title: Center(
              child: const
              Text(
                  'Profile',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold

                  )
              )
          ),
          backgroundColor: primary_color,

          actions: [
            IconButton(
                onPressed: logout_and_delete,
                icon: Icon(
                  Icons.settings,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                )
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
              var user_emergencyContacts;
              var user_profilePic;

              try{
                user_data = snapshot.data!.data() as Map<String, dynamic>;
                user_name = user_data["name"];
                user_age = user_data["age"];
                user_address = user_data["address"];
                user_emergencyContacts = user_data["emergency_contacts"];
                user_profilePic = user_data["profileImageUrl"];
              }
              catch (e){
                user_name = "";
                user_age = "";
                user_address = "";
                user_emergencyContacts = "";
                user_profilePic = "https://images.rawpixel.com/image_png_800/czNmcy1wcml2YXRlL3Jhd3BpeGVsX2ltYWdlcy93ZWJzaXRlX2NvbnRlbnQvbHIvdjkzNy1hZXctMTY1LnBuZw.png";
              }

              //TODO: Use fields in blueprint (my UI)

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    color: primary_color,
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            backgroundImage: NetworkImage(user_profilePic),
                            radius: 40,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          user_name,
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 25

                          ),

                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                                "Age $user_age",
                                style: textcard_color
                            ),
                            SizedBox(width: 10),
                            CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 2,
                            ),
                            SizedBox(width: 10),
                            Text(
                                "Fall Detection User",
                                style: textcard_color
                            )
                          ],
                        ),
                        SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Number_word(
                                number: user_emergencyContacts.length.toString(),
                                text: "Emergency",
                                optional_text: "Contacts"
                            ),
                            Number_word(
                                number: "24/7",
                                text: "Monitoring"
                            ),
                            Number_word(
                                number: "0",
                                text: "Falls",
                                optional_text: "Detected"
                            ),
                          ],
                        ),
                        SizedBox(height: 20),

                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 10, 0, 10),
                          child: Text(
                            "Personal Information",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey.withOpacity(0.3),
                      radius: 30,
                      child: Icon(
                        Icons.person,
                        size: 30,
                        color: Colors.blue,
                      ),
                    ),
                    title: Text('Name'),
                    subtitle: Text(user_name),
                  ),
                  ExpansionTile(
                    leading:  CircleAvatar(
                      backgroundColor: Colors.grey.withOpacity(0.3),
                      radius: 30,
                      child: Icon(
                        Icons.cake,
                        size: 30,
                        color: Colors.green,
                      ),
                    ),
                    title: Text('Age'),
                    subtitle: Text('$user_age years old'),
                  ),
                  ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey.withOpacity(0.3),
                      radius: 30,
                      child: Icon(
                        Icons.location_on,
                        size: 30,
                        color: Colors.purple,
                      ),
                    ),
                    title: Text('Address'),
                    subtitle: Text(user_address.toString()),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Text(
                        "Emergency Contacts",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold
                        ),
                    ),
                  ),
                  ...user_emergencyContacts.map(
                      (item) =>  Card(
                        color: card_color,
                        margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        child: ListTile(
                            title: Text(item["contact_name"]),
                            subtitle: Text(item["contact_number"]),

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

