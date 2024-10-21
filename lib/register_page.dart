import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:installment_app/userprofile.dart';

import 'loginpage.dart';
import 'models/datamodel.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final authentication = FirebaseAuth.instance;
  final DatabaseReference dref = FirebaseDatabase.instance.ref();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _cnicController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;



  void Registeruser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Check if the CNIC already exists in the database
        final cnic = _cnicController.text;
        final adminSnapshot = await dref.child('admin').orderByChild('cnic').equalTo(cnic).get();
        final userSnapshot = await dref.child('users').orderByChild('cnic').equalTo(cnic).get();

        if (adminSnapshot.exists || userSnapshot.exists) {
          // If CNIC exists, show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('This CNIC is already registered.')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // Register the user with Firebase Authentication
        final UserCredential userCredential = await authentication.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final userId = userCredential.user!.uid;
        final isAdmin = !(await dref.child('admin').once()).snapshot.exists;
        final role = isAdmin ? '0' : '1';

        if (isAdmin) {
          // Assign to the admin node and set adminNumber
          final adminNumberSnapshot = await dref.child('admin').get();
          final adminNumber = (adminNumberSnapshot.children.length + 1).toString();

          // Create an AdminModel instance
          final adminModel = AdminModel(
            userId,
            _nameController.text.trim(),
            _emailController.text.trim(),
            _phoneController.text.trim(),
            _passwordController.text.trim(),
            _cnicController.text.trim(),
            role,
            adminNumber,
          );

          // Save the admin data to Firebase
          await dref.child('admin').child(userId).set(adminModel.toMap());

        } else {
          // Assign to the users node and set userNumber
          final userNumberSnapshot = await dref.child('users').get();
          final userNumber = (userNumberSnapshot.children.length + 1).toString();

          // Create a UserModel instance
          final userModel = UserModel(
            userId,
            _nameController.text.trim(),
            _emailController.text.trim(),
            _phoneController.text.trim(),
            _passwordController.text.trim(),
            _cnicController.text.trim(),
            role,
            userNumber,
          );

          // Save the user data to Firebase
          await dref.child('users').child(userId).set(userModel.toMap());
        }

        // Navigate to user profile page after successful registration
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration successful!')),
        );

      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Registration failed.')),
        );
      } catch (e) {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth > 600 ? screenWidth * 0.2 : 16.0,
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
          key: _formKey,
          child: ListView(
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: Image.asset("images/logomain.png"),
              ),
              const SizedBox(height: 20),
              TextFormField(
                textCapitalization: TextCapitalization.words,
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Colors.grey,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  // Regex for validating Pakistani phone numbers
                  final regex = RegExp(r'^\+92[0-9]{10}$|^03[0-9]{9}$');
                  if (!regex.hasMatch(value)) {
                    return 'Please enter a valid Pakistani phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _cnicController,
                decoration: const InputDecoration(
                  labelText: 'CNIC',
                  border: OutlineInputBorder(),
                ),
                inputFormatters: [
                  CnicFormatter(), // Apply the custom formatter
                ],
                validator: (value) {
                  // Define a regular expression for CNIC validation
                  final RegExp cnicRegExp = RegExp(r'^\d{5}-\d{7}-\d{1}$');

                  // Check if the value is null or empty
                  if (value == null || value.isEmpty) {
                    return 'Please enter your CNIC number';
                  }

                  // Validate the CNIC format
                  if (!cnicRegExp.hasMatch(value)) {
                    return 'Please enter a valid CNIC number in the format 12345-6789012-3';
                  }

                  return null; // The CNIC is valid
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Colors.grey,
                      width: 2,
                    ),
                  ),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Password must be at least 6 characters long';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 5.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: InkWell(
                  onTap: () {
                    Registeruser();
                  },
                  child: Container(
                    width: screenWidth * 0.4,
                    height: screenHeight * 0.07,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [Colors.blue, Colors.green],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        "Register",
                        style: TextStyle(
                          fontSize: 25,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                child: const Text("Go to login Page if you already have an account"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


