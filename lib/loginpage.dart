// import 'package:flutter/material.dart';
//
// import 'clintfront.dart';
//
// class LoginPage extends StatefulWidget {
//   const LoginPage({super.key});
//
//   @override
//   State<LoginPage> createState() => _LoginPageState();
// }
//
// class _LoginPageState extends State<LoginPage> {
//   final _formKey = GlobalKey<FormState>();
//
//   // Controllers for form fields
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//
//   bool _isLoading = false;
//
//   Future<void> _loginUser() async {
//     if (_formKey.currentState!.validate()) {
//       setState(() {
//         _isLoading = true;
//       });
//
//       try {
//         String email = _emailController.text.trim();
//         String password = _passwordController.text.trim();
//
//         // Example of login process (replace with actual Firebase or authentication logic)
//         await Future.delayed(const Duration(seconds: 2));
//
//         setState(() {
//           _isLoading = false;
//         });
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Login successful!')),
//         );
//         Navigator.pushAndRemoveUntil(
//           context,
//           MaterialPageRoute(builder: (context) => const FrontPage()),
//               (Route<dynamic> route) => false, // This removes all previous routes
//         );
//
//       } catch (e) {
//         setState(() {
//           _isLoading = false;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(e.toString())),
//         );
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // Screen size to handle responsiveness
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
//
//     return Scaffold(
//       body: Padding(
//         padding: EdgeInsets.symmetric(
//           horizontal: screenWidth > 600 ? screenWidth * 0.2 : 16.0,
//         ),
//         child: _isLoading
//             ? const Center(child: CircularProgressIndicator())
//             : Form(
//           key: _formKey,
//           child: ListView(
//             children: [
//               const SizedBox(height: 50),
//               SizedBox(
//                 width: 150,
//                 height: 150,
//                 child: Image.asset("images/logomain.png"),
//               ),
//               const SizedBox(height: 50),
//               TextFormField(
//                 controller: _emailController,
//                 decoration: InputDecoration(
//                   labelText: 'Email',
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8),
//                     borderSide: const BorderSide(
//                       color: Colors.grey,
//                       width: 2,
//                     ),
//                   ),
//                 ),
//                 keyboardType: TextInputType.emailAddress,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter your email';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 20),
//               TextFormField(
//                 controller: _passwordController,
//                 decoration: InputDecoration(
//                   labelText: 'Password',
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8),
//                     borderSide: const BorderSide(
//                       color: Colors.grey,
//                       width: 2,
//                     ),
//                   ),
//                 ),
//                 obscureText: true,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter your password';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 30),
//               InkWell(
//                 onTap: _loginUser,
//                 child: Container(
//                   height: 50,
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(12),
//                     gradient: const LinearGradient(
//                       colors: [Colors.blue, Colors.green],
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                   ),
//                   child: const Center(
//                     child: Text(
//                       'Login',
//                       style: TextStyle(
//                         fontSize: 18,
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Text("Don't have an account? "),
//                   TextButton(
//                     onPressed: () {
//                       // Navigate to the registration page
//                       // Navigator.pushNamed(context, '/register');
//                       Navigator.pushNamed(context, '/register');
//
//                     },
//                     child: const Text('Sign up'),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:installment_app/register_page.dart';
import 'adminside/adminpanel.dart';
import 'clintfront.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth authentication = FirebaseAuth.instance;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final DatabaseReference userRef = FirebaseDatabase.instance.ref("users");
  bool isLoggingIn = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void loginUser() async {
    if (formKey.currentState?.validate() ?? false) {
      setState(() {
        isLoggingIn = true;
      });

      try {
        // Sign in with Firebase Auth
        UserCredential userCredential = await authentication.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        // Get the user ID
        String uid = userCredential.user?.uid ?? '';

        // References to the admins and users nodes
        DatabaseReference adminRef = FirebaseDatabase.instance.ref("admin/$uid");
        DatabaseReference userRef = FirebaseDatabase.instance.ref("users/$uid");

        // Check if user is in the admins node
        DataSnapshot adminSnapshot = await adminRef.get();

        if (adminSnapshot.exists) {
          // User is in the admin node
          Map<dynamic, dynamic> adminData = adminSnapshot.value as Map<dynamic, dynamic>;
          String role = adminData['role'] ?? '';

          if (role == '0') { // Admin role
            _showRolePrompt(
              "Admin Access",
              "You are logged in as an Admin. Would you like to go to the Admin side or the Home page?",
              const Admin(),
              "Admin Side",
              const FrontPage(),
              "Home Page",
            );
          } else {
            // Role not found or incorrect for admin
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid role for admin.')),
            );
          }
        } else {
          // Check if user is in the users node
          DataSnapshot userSnapshot = await userRef.get();

          if (userSnapshot.exists) {
            // User is in the users node
            Map<dynamic, dynamic> userData = userSnapshot.value as Map<dynamic, dynamic>;
            String role = userData['role'] ?? '';

            if (role == '1') { // Buyer role
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const FrontPage()),
              );
            } else {
              // Role not found or incorrect for user
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invalid role for user.')),
              );
            }
          } else {
            // Handle case where user data doesn't exist in any node
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User data not found.')),
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        // Handle authentication errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
      } finally {
        setState(() {
          isLoggingIn = false;
        });
      }
    }
  }

  void _showRolePrompt(
      String title,
      String content,
      Widget page1,
      String page1Text,
      Widget page2,
      String page2Text,
      ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => page1));
                  },
                  child: Text(page1Text, style: GoogleFonts.lora(color: Colors.black)),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => page2));
                  },
                  child: Text(page2Text, style: GoogleFonts.lora(color: Colors.black)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: screenWidth * 0.5,
                  height: screenWidth * 0.5,
                  child: Image.asset("images/logomain.png"),
                ),
                SizedBox(height: screenHeight * 0.05),
                Container(
                  width: screenWidth * 0.8,
                  height: screenHeight * 0.6,
                  child: Form(
                    key: formKey,
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                          child: TextFormField(
                            controller: emailController,
                            decoration: InputDecoration(
                              hintText: "Enter your E-mail Address",
                              label: Text("E-mail"),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              return null;
                            },
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                          child: TextFormField(
                            controller: passwordController,
                            decoration: InputDecoration(
                              hintText: "Enter Your Password",
                              labelText: "Password",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off),
                                onPressed: () {
                                  setState(() {
                                    obscurePassword = !obscurePassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: obscurePassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.05),
                        InkWell(
                          onTap: isLoggingIn ? null : loginUser,
                          child: Container(
                            width: screenWidth * 0.5,
                            height: screenHeight * 0.07,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: const LinearGradient(
                                colors: [Colors.blue, Colors.green],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),

                            ),
                            child: Center(
                              child: Text(
                                isLoggingIn ? "Logging in..." : "Login",
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("If not a registered member, click on"),
                            TextButton(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) {
                                  return RegisterPage();
                                }));
                              },
                              child: const Text("Register"),
                            ),
                          ],
                        ),
                        TextButton(onPressed: (){
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const FrontPage()),
                                (Route<dynamic> route) => false, // This removes all previous routes
                          );
                        }, child: Text("Go To Home Page"))
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
