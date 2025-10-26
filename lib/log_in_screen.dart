import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:senior_fall_detection/constants.dart';

class LogInScreen extends StatefulWidget {
  const LogInScreen({super.key});

  @override
  State<LogInScreen> createState() => _LogInScreenState();
}

class _LogInScreenState extends State<LogInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isloading = false;
  String? _error;


  Future<void> _submit() async {
    if(_formKey.currentState?.validate() ?? false){
      setState(() {
        _isloading = true;
        _error = null;
      });

      try {
        // Todo: Connect to firebase authentication and make new acc
        final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        Navigator.pushReplacementNamed(context, "/home");
      }
      catch(e){
        setState(() {
          _error = "Signup failed";
        });
      }
      finally {
        setState(() {
          _isloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
          child: Form(
              key: _formKey,
              child: Column(
                  children: [
                    Image.asset('assets/fall_detection_logo.png'),
                    Text(
                      "SafeStep",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        fontFamily: ""
                      )

                    ),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 12),
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                          color: card_color,
                          borderRadius: BorderRadius.circular(15)
                      ),
                      child: TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: "Email"),
                        validator: (value) => value == null || !value.contains("@") ? 'Enter a valid email' : null,
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 12),
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                          color: card_color,
                          borderRadius: BorderRadius.circular(15)
                      ),
                      child: TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(labelText: "Password"),
                        validator: (value) => value == null || value.length < 5 ? 'Enter a 5+ character password' : null,
                        obscureText: true,
                      ),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isloading ? null : _submit,
                        child: _isloading ? CircularProgressIndicator() : Text(
                            "Log In",
                          style: TextStyle(
                            color: primary_color,
                            fontSize: 20
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextButton(
                        onPressed: (){
                          Navigator.pushReplacementNamed(context, '/signup');
                        },
                        child: Text(
                          "Click Here to Create an Account",
                          style: TextStyle(
                            color: primary_color,
                            fontSize: 16
                          ),
                        )
                    ),
                    if(_error != null) ...[
                      Text(_error!),
                      SizedBox(height: 16)
                    ],
                  ]
              )
          )
      )
    );
  }
}
