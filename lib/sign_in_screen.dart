import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPassword = TextEditingController();
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
        final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
        );

        // Todo: Save data on firestore database
        final user = credential.user;
        if(user != null && _nameController.text.trim().isNotEmpty){
          await FirebaseFirestore.instance.collection("Users").doc(user.uid).set(
            {
              "name": _nameController.text.trim(),
              "email": _emailController.text.trim(),
              "createdAt": FieldValue.serverTimestamp()
            }
          );
        }
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
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Name"),
                validator: (value) => value == null || value.isEmpty ? 'Enter a valid name' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (value) => value == null || !value.contains("@") ? 'Enter a valid email' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                validator: (value) => value == null || value.length < 5 ? 'Enter a 5+ character password' : null,
                obscureText: true,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _confirmPassword,
                decoration: const InputDecoration(labelText: "Confirm Password"),
                validator: (value) => value == null || value != _passwordController.text ? 'Password do not match' : null,
                obscureText: true,
              ),
              if(_error != null) ...[
                Text(_error!),
                SizedBox(height: 16)
              ],
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: _isloading ? null : _submit,
                    child: _isloading ? CircularProgressIndicator() : Text("Sign up"),
                ),
              ),
            ],
          ),
        ),
      )
    );
  }
}
