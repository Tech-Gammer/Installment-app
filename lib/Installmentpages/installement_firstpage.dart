// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../paymentfiles/firstpage.dart';
// import '../userprofile.dart';
//
// class InstallmentPage extends StatefulWidget {
//   late double totalBalance;
//
//   InstallmentPage(this.totalBalance);
//
//   @override
//   State<InstallmentPage> createState() => _InstallmentPageState();
// }
//
// class _InstallmentPageState extends State<InstallmentPage> {
//   final DatabaseReference _userRef = FirebaseDatabase.instance.ref("users");
//   final DatabaseReference _orderRef = FirebaseDatabase.instance.ref("installmentOrders");
//   final DatabaseReference _cartRef = FirebaseDatabase.instance.ref("cart");
//   final DatabaseReference _installmentOrdersRef = FirebaseDatabase.instance.ref("installmentOrders");
//   String selectedPaymentMethod = 'Installment'; // Default selected payment method
//
//   Map<String, dynamic>? cartItems;
//
//   User? currentUser = FirebaseAuth.instance.currentUser;
//   String? _role;
//   bool _isLoading = true;
//
//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _phoneController = TextEditingController();
//   final TextEditingController _cnicController = TextEditingController();
//   final TextEditingController _addressController = TextEditingController();
//   final TextEditingController _zipCodeController = TextEditingController();
//
//   final TextEditingController _downPaymentController = TextEditingController();
//
//   final TextEditingController _guarantor1NameController = TextEditingController();
//   final TextEditingController _guarantor1PhoneController = TextEditingController();
//   final TextEditingController _guarantor1AddressController = TextEditingController();
//   final TextEditingController _guarantor1CnicController = TextEditingController();
//
//   final TextEditingController _guarantor2NameController = TextEditingController();
//   final TextEditingController _guarantor2PhoneController = TextEditingController();
//   final TextEditingController _guarantor2AddressController = TextEditingController();
//   final TextEditingController _guarantor2CnicController = TextEditingController();
//   double minDownPayment = 0;
//   double installmentFee = 0;
//   double remainingAmount = 0;
//   double totalbalancewithinstallment= 0;
//   String selectedInstallmentPlan = '3 months';
//   double downPayment = 0;
//   String? _downPaymentError; // Variable to hold the error message
//   double installmentAmount = 0; // Variable to hold the amount per installment
//   List<Map<String, dynamic>> installmentOrders = [];
//
//
//
//   @override
//   void initState() {
//     super.initState();
//     fetchUserData();
//     installmentFee = widget.totalBalance * 0.3; // 30% installment fee
//     remainingAmount = (widget.totalBalance + installmentFee) - downPayment;
//     _calculateInstallmentAmount();
//   }
//
//   Future<void> fetchCartItems() async {
//     String? userId = currentUser?.uid;
//     final userCartRef = _cartRef.child(userId!); // Reference to the current user's cart
//     final snapshot = await userCartRef.once(); // Get all cart items for the user
//     // final userCartRef = _cartRef;
//     // final snapshot = await userCartRef.orderByChild('uid').equalTo(currentUser.uid).once();
//     if (snapshot.snapshot.value != null) {
//       setState(() {
//         cartItems = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
//       });
//     } else {
//       setState(() {
//         cartItems = {};
//       });
//     }
//   }
//
//   Future<void> fetchUserData() async {
//     if (currentUser != null) {
//       try {
//         // Check in the admin node first
//         final adminSnapshot = await FirebaseDatabase.instance.ref("admin").child(currentUser!.uid).once();
//         if (adminSnapshot.snapshot.value != null) {
//           final data = Map<String, dynamic>.from(adminSnapshot.snapshot.value as Map);
//           setState(() {
//             _nameController.text = data['name'] ?? '';
//             _emailController.text = data['email'] ?? '';
//             _phoneController.text = data['phone'] ?? '';
//             _cnicController.text = data['cnic'] ?? '';
//             // _passwordController.text = data['password'] ?? '';
//             _addressController.text = data['address'] ?? '';
//             _zipCodeController.text = data['zip_code'] ?? '';
//
//             _role = 'Admin';
//           });
//         } else {
//           // Check in the users node
//           final userSnapshot = await _userRef.child(currentUser!.uid).once();
//           if (userSnapshot.snapshot.value != null) {
//             final data = Map<String, dynamic>.from(userSnapshot.snapshot.value as Map);
//             setState(() {
//               _nameController.text = data['name'] ?? '';
//               _emailController.text = data['email'] ?? '';
//               _phoneController.text = data['phone'] ?? '';
//               _cnicController.text = data['cnic'] ?? '';
//               // _passwordController.text = data['password'] ?? '';
//               _addressController.text = data['address'] ?? '';
//               _zipCodeController.text = data['zip_code'] ?? '';
//               _role = 'Buyer';
//             });
//           }
//         }
//       } catch (e) {
//         // print('Error fetching user data: $e');
//       } finally {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }
//
//   Future<void> saveGuarantorDetails() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.setString('guarantor1_name', _guarantor1NameController.text);
//     await prefs.setString('guarantor1_phone', _guarantor1PhoneController.text);
//     await prefs.setString('guarantor1_cnic', _guarantor1CnicController.text);
//     await prefs.setString('guarantor1_address', _guarantor1AddressController.text);
//     await prefs.setString('guarantor2_name', _guarantor2NameController.text);
//     await prefs.setString('guarantor2_phone', _guarantor2PhoneController.text);
//     await prefs.setString('guarantor2_cnic', _guarantor2CnicController.text);
//     await prefs.setString('guarantor2_address', _guarantor2AddressController.text);
//   }
//
//   Future<void> fetchInstallmentOrders() async {
//     try {
//       final snapshot = await _installmentOrdersRef.once();
//       if (snapshot.snapshot.value != null) {
//         final allOrders = (snapshot.snapshot.value as Map<dynamic, dynamic>).values
//             .map((order) => Map<String, dynamic>.from(order as Map))
//             .toList();
//
//         setState(() {
//           installmentOrders = allOrders.where((order) {
//             final userId = order['userId'] as String?;
//             final adminId = order['adminId'] as String?;
//             return userId == currentUser?.uid || adminId == currentUser?.uid;
//           }).toList();
//
//           installmentOrders.sort((a, b) {
//             final timestampA = a['timestamp'] as String?;
//             final timestampB = b['timestamp'] as String?;
//
//             final dateTimeA = DateTime.tryParse(timestampA ?? '') ?? DateTime(1970);
//             final dateTimeB = DateTime.tryParse(timestampB ?? '') ?? DateTime(1970);
//             return dateTimeB.compareTo(dateTimeA); // Newest first
//           });
//
//           // Check for payment deadlines
//           for (var order in installmentOrders) {
//             final lastPaymentDateString = order['last_payment_date'] as String?;
//             if (lastPaymentDateString != null) {
//               final lastPaymentDate = DateTime.parse(lastPaymentDateString);
//               final difference = DateTime.now().difference(lastPaymentDate).inDays;
//
//               if (difference >= 30 && difference < 35) {
//                 // Show warning
//                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//                   content: Text("There are only ${35 - difference} days left to pay the installment."),
//                   duration: Duration(seconds: 3),
//                 ));
//               } else if (difference >= 35) {
//                 // Block new orders and show a red flag
//                 // (Implement your logic to block new orders here)
//                 AppBar(
//                   title: const Text('Pending Installments', style: TextStyle(color: Colors.red)),
//                   backgroundColor: Colors.yellow,
//                 );
//                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//                   content: Text("Pending installments! Please pay the amount."),
//                   duration: Duration(seconds: 3),
//                   backgroundColor: Colors.red,
//                 ));
//               }
//             }
//           }
//         });
//       }
//     } catch (e) {
//       print('Error fetching installment orders: $e');
//     }
//   }
//
//   Future<void> placeOrder() async {
//     if (installmentOrders.any((order) => DateTime.now().difference(DateTime.parse(order['last_payment_date'])).inDays >= 35)) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("You cannot place new orders due to pending installments.")));
//       return; // Exit the function to prevent order submission
//     }
//     if (_downPaymentError != null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please enter a valid down payment.')),
//       );
//       return; // Do not proceed if there is a validation error
//     }
//
//     // Check if down payment is valid
//     double downPayment = double.tryParse(_downPaymentController.text) ?? 0;
//     if (downPayment < minDownPayment) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Down payment must be at least 35% of the total balance.')),
//       );
//       return;
//     }
//
//     // Check if installment plan is selected
//     if (selectedInstallmentPlan.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select an installment plan.')),
//       );
//       return;
//     }
//
//     // Check if guarantors are added
//     if (_guarantor1NameController.text.isEmpty ||
//         _guarantor1PhoneController.text.isEmpty ||
//         _guarantor1CnicController.text.isEmpty ||
//         _guarantor1AddressController.text.isEmpty ||
//         _guarantor2NameController.text.isEmpty ||
//         _guarantor2PhoneController.text.isEmpty ||
//         _guarantor2CnicController.text.isEmpty ||
//         _guarantor2AddressController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please add details for both guarantors.')),
//       );
//       return;
//     }
//
//     // Fetch cart items from Firebase before placing the order
//     final userId = FirebaseAuth.instance.currentUser!.uid;
//     final cartSnapshot = await _cartRef.child(userId).get();
//     if (!cartSnapshot.exists) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Your cart is empty.')),
//       );
//       return;
//     }
//
//     final cartItems = cartSnapshot.value as Map<dynamic, dynamic>; // Retrieve the cart items
//
//
//     // Generate a new unique key for the order and use it as the orderId
//     DatabaseReference newOrderRef = _orderRef.push();
//     String newOrderId = newOrderRef.key.toString(); // This key will be the unique orderId
//
//     final orderData = {
//       'orderId': newOrderId, // Use the same key as orderId
//       'userId': currentUser?.uid,
//       'total_balance': widget.totalBalance,
//       'installment_fee': installmentFee,
//       'total_balance_with_installment': totalbalancewithinstallment,
//       'min_down_payment': minDownPayment,
//       'down_payment_done': downPayment,
//       'remaining_amount': remainingAmount,
//       'selected_installment_plan': selectedInstallmentPlan,
//       'installment_amount': installmentAmount,
//       'payment_status': 'Partially Paid', // Set payment status
//       'status': 'Pending',
//       'userId': currentUser?.uid,
//       'items': cartItems,
//       'orderDate': DateTime.now().toIso8601String(), // Add a timestamp for the order
//       'guarantors': {
//         'guarantor1': {
//           'name': _guarantor1NameController.text,
//           'phone': _guarantor1PhoneController.text,
//           'cnic': _guarantor1CnicController.text,
//           'address': _guarantor1AddressController.text,
//         },
//         'guarantor2': {
//           'name': _guarantor2NameController.text,
//           'phone': _guarantor2PhoneController.text,
//           'cnic': _guarantor2CnicController.text,
//           'address': _guarantor2AddressController.text,
//         },
//       },
//       'user_info': {
//         'userId': currentUser?.uid,
//         'name': _nameController.text,
//         'email': _emailController.text,
//         'phone': _phoneController.text,
//         'cnic': _cnicController.text,
//         'address': _addressController.text,
//         'zip_code': _zipCodeController.text,
//       },
//     };
//
//     try {
//       // Use the same reference to set the data
//       await newOrderRef.set(orderData);
//
//       // Remove cart items after placing the order
//       // await _cartRef.child(FirebaseAuth.instance.currentUser!.uid).remove();
//       await _cartRef.child(userId).remove();
//
//
//       // Navigate to Orders List Page
//       Navigator.pushReplacementNamed(context, '/installmentordersListPage');
//
//       // Show a success message
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Order placed successfully!')),
//       );
//     } catch (e) {
//       // Handle any errors during the order placement
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to place order: $e')),
//       );
//     }
//   }
//
//   @override
//   void dispose() {
//     // Dispose controllers when the widget is removed from the tree
//     _guarantor1NameController.dispose();
//     _guarantor1PhoneController.dispose();
//     _guarantor1AddressController.dispose();
//     _guarantor1CnicController.dispose();
//
//     _guarantor2NameController.dispose();
//     _guarantor2PhoneController.dispose();
//     _guarantor2AddressController.dispose();
//     _guarantor2CnicController.dispose();
//
//     super.dispose();
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//      minDownPayment = (widget.totalBalance + installmentFee) * 0.35;
//     totalbalancewithinstallment = widget.totalBalance + installmentFee;
//
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Installment Details",style: GoogleFonts.lora(color: Colors.white,fontSize: 25,fontWeight: FontWeight.bold,),),
//         centerTitle: true,
//         backgroundColor:const Color(0xFFe6b67e),
//         actions: [
//           IconButton(onPressed: (){
//             _addGuarantorFields(context);
//           }, icon: const Icon(Icons.add))
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           child: SingleChildScrollView(
//             child: Column(
//               children: [
//                 const Padding(
//                   padding: EdgeInsets.symmetric(vertical: 10),
//                   child: Text("Customer Info", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
//                 ),
//                 // Prefilled fields
//                 buildPrefilledTextField(_nameController, 'Name'),
//                 // buildPrefilledTextField(_emailController, 'Email'),
//                 buildPrefilledTextField(_phoneController, 'Phone'),
//                 buildPrefilledTextField(_cnicController, 'CNIC'),
//                 buildPrefilledTextField(_addressController, 'Address'),
//                 // buildPrefilledTextField(_zipCodeController, 'Zip Code'),
//                 const SizedBox(height: 20),
//                 const Text("Balance and Payment Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                   Table(
//                     border: TableBorder.all(),
//                     columnWidths: const {
//                       0: FlexColumnWidth(2),
//                       1: FlexColumnWidth(1),
//                     },
//                     children: [
//                       TableRow(
//                         children: [
//                           const TableCell(
//                             child: Padding(
//                               padding: EdgeInsets.all(8.0),
//                               child: Text('Sub Balance:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                             ),
//                           ),
//                           TableCell(
//                             child: Padding(
//                               padding: const EdgeInsets.all(8.0),
//                               child: Text('${widget.totalBalance.toStringAsFixed(0)} rs', style: const TextStyle(fontSize: 16)),
//                             ),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const TableCell(
//                             child: Padding(
//                               padding: EdgeInsets.all(8.0),
//                               child: Text('Installment Fee (30%):', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                             ),
//                           ),
//                           TableCell(
//                             child: Padding(
//                               padding: const EdgeInsets.all(8.0),
//                               child: Text('${installmentFee.toStringAsFixed(0)} rs', style: const TextStyle(fontSize: 16)),
//                             ),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const TableCell(
//                             child: Padding(
//                               padding: EdgeInsets.all(8.0),
//                               child: Text('Total Balance:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                             ),
//                           ),
//                           TableCell(
//                             child: Padding(
//                               padding: const EdgeInsets.all(8.0),
//                               child: Text('${totalbalancewithinstallment.toStringAsFixed(0)} rs', style: const TextStyle(fontSize: 16)),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 const SizedBox(height: 10),
//                 Text("You can add 35% minimum amount of the total amount: ${minDownPayment.toStringAsFixed(0)} rs"),
//                 const SizedBox(height: 10),
//                 TextFormField(
//                   controller: _downPaymentController,
//                   decoration: InputDecoration(
//                     labelText: 'Down Payment',
//                     border: const OutlineInputBorder(),
//                     errorText: _downPaymentError,
//                   ),
//                   keyboardType: TextInputType.number,
//                   onChanged: (value) {
//                     double downPayment = double.tryParse(value) ?? 0;
//
//                     // Calculate the minimum down payment (35% of total amount including installment fees)
//                     double minDownPayment = (widget.totalBalance + installmentFee) * 0.35;
//
//                     // Ensure the down payment is at least 35% of the total balance including the installment fee
//                     if (downPayment < minDownPayment) {
//                       setState(() {
//                         _downPaymentError = 'Down payment must be at least 35% of the total balance.';
//                       });
//                       return; // Do not proceed further if the validation fails
//                     } else {
//                       setState(() {
//                         _downPaymentError = null; // Clear error message
//                       });
//                     }
//
//                     // Optionally, ensure the down payment does not exceed the total amount with fees
//                     double maxDownPayment = widget.totalBalance + installmentFee;
//                     if (downPayment > maxDownPayment) {
//                       _downPaymentController.text = maxDownPayment.toStringAsFixed(2);
//                       downPayment = maxDownPayment;
//                     }
//
//                     // Calculate the remaining amount
//                     setState(() {
//                       remainingAmount = (widget.totalBalance + installmentFee) - downPayment;
//                       _calculateInstallmentAmount();
//
//                     });
//                   },
//                 ),
//
//                 const SizedBox(height: 10),
//                 Text('Remaining Amount: ${remainingAmount.toStringAsFixed(2)} rs', style: const TextStyle(fontSize: 18)),
//                 const SizedBox(height: 20),
//
//                 // Installment Plan Options
//                 const Text('Choose Installment Plan:', style: TextStyle(fontSize: 18)),
//                 buildInstallmentRadioButtons(),
//                 const SizedBox(height: 20),
//                 Text("Total Installment Amount is: ${installmentAmount.toStringAsFixed(0)}",
//                   style: const TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 ElevatedButton(
//                   // onPressed: placeOrder,
//                   onPressed: (){
//                     double downPayment = double.tryParse(_downPaymentController.text) ?? 0;
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => firstpage(
//                           downPayment,
//                           placeOrder: () async {
//                             await placeOrder(); // Ensure `placeOrder` is awaited
//                           },
//                         ),
//                       ),
//                     );
//
//                   },
//                   child: const Text('Place Order'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFFe6b67e), // Button color
//                     textStyle: const TextStyle(fontSize: 18),
//                   ),
//                 ),
//
//                 // Text("${installmentAmount.toStringAsFixed(0)}")
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget buildPrefilledTextField(TextEditingController controller, String label) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 10),
//       child: TextFormField(
//         controller: controller,
//         decoration: InputDecoration(
//           labelText: label,
//           enabled: false,
//           border: const OutlineInputBorder(),
//         ),
//       ),
//     );
//   }
//
//   Widget buildInstallmentRadioButtons() {
//     return Column(
//       children: [
//         buildRadioButton('3 months'),
//         buildRadioButton('6 months'),
//         buildRadioButton('8 months'),
//         buildRadioButton('10 months'),
//         buildRadioButton('12 months'),
//       ],
//     );
//   }
//
//   RadioListTile<String> buildRadioButton(String value) {
//     return RadioListTile<String>(
//       title: Text(value),
//       value: value,
//       groupValue: selectedInstallmentPlan,
//       onChanged: (String? newValue) {
//         setState(() {
//           selectedInstallmentPlan = newValue!;
//           _calculateInstallmentAmount(); // Recalculate installment amount when plan changes
//
//         });
//       },
//     );
//   }
//
//   void _addGuarantorFields(BuildContext context) {
//     final _formKey = GlobalKey<FormState>();
//
//
//
//     bool _isDuplicateGuarantorData() {
//       final name1 = _guarantor1NameController.text.trim();
//       final phone1 = _guarantor1PhoneController.text.trim();
//       final address1 = _guarantor1AddressController.text.trim();
//       final cnic1 = _guarantor1CnicController.text.trim();
//
//       final name2 = _guarantor2NameController.text.trim();
//       final phone2 = _guarantor2PhoneController.text.trim();
//       final address2 = _guarantor2AddressController.text.trim();
//       final cnic2 = _guarantor2CnicController.text.trim();
//
//       // Debug prints
//       print('Guarantor 1 - Name: $name1, Phone: $phone1, Address: $address1, CNIC: $cnic1');
//       print('Guarantor 2 - Name: $name2, Phone: $phone2, Address: $address2, CNIC: $cnic2');
//
//       // Check for duplicate CNICs
//       if (cnic1 == cnic2) {
//         print('Duplicate CNIC found');
//         return true;
//       }
//
//       // Check for other fields
//       if (name1 == name2 &&
//           phone1 == phone2 &&
//           address1 == address2) {
//         print('Duplicate details found (excluding CNIC)');
//         return true;
//       }
//
//       // Check for each field individually for more detailed duplication
//       if ((name1 == name2) ||
//           (phone1 == phone2) ||
//           (address1 == address2)) {
//         print('Some details are duplicated');
//         return true;
//       }
//
//       return false;
//     }
//
//
//     void _clearForm() {
//       _guarantor1NameController.clear();
//       _guarantor1PhoneController.clear();
//       _guarantor1AddressController.clear();
//       _guarantor1CnicController.clear();
//       _guarantor2NameController.clear();
//       _guarantor2PhoneController.clear();
//       _guarantor2AddressController.clear();
//       _guarantor2CnicController.clear();
//     }
//
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return SingleChildScrollView(
//           child: AlertDialog(
//             title: const Text('Add Guarantor'),
//             content: Form(
//               key: _formKey,
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   // Guarantor 1 Fields
//                   TextFormField(
//                     controller: _guarantor1NameController,
//                     textCapitalization: TextCapitalization.words,
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter your name';
//                       }
//                       return null;
//                     },
//                     decoration: const InputDecoration(
//                       labelText: 'Guarantor 1 Name',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   TextFormField(
//                     controller: _guarantor1PhoneController,
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter your phone number';
//                       }
//                       final regex = RegExp(r'^\+92[0-9]{10}$|^03[0-9]{9}$');
//                       if (!regex.hasMatch(value)) {
//                         return 'Please enter a valid Pakistani phone number';
//                       }
//                       return null;
//                     },
//                     decoration: const InputDecoration(
//                       labelText: 'Guarantor 1 Phone',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   TextFormField(
//                     controller: _guarantor1AddressController,
//                     textCapitalization: TextCapitalization.words,
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter your address';
//                       }
//                       return null;
//                     },
//                     decoration: const InputDecoration(
//                       labelText: 'Guarantor 1 Address',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   TextFormField(
//                     controller: _guarantor1CnicController,
//                     inputFormatters: [CnicFormatter()],
//                     validator: (value) {
//                       final cnicRegExp = RegExp(r'^\d{5}-\d{7}-\d{1}$');
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter your CNIC number';
//                       }
//                       if (!cnicRegExp.hasMatch(value)) {
//                         return 'Please enter a valid CNIC number in the format 12345-6789012-3';
//                       }
//                       return null;
//                     },
//                     decoration: const InputDecoration(
//                       labelText: 'Guarantor 1 CNIC',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//
//                   // Guarantor 2 Fields
//                   TextFormField(
//                     controller: _guarantor2NameController,
//                     textCapitalization: TextCapitalization.words,
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter your name';
//                       }
//                       return null;
//                     },
//                     decoration: const InputDecoration(
//                       labelText: 'Guarantor 2 Name',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   TextFormField(
//                     controller: _guarantor2PhoneController,
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter your phone number';
//                       }
//                       final regex = RegExp(r'^\+92[0-9]{10}$|^03[0-9]{9}$');
//                       if (!regex.hasMatch(value)) {
//                         return 'Please enter a valid Pakistani phone number';
//                       }
//                       return null;
//                     },
//                     decoration: const InputDecoration(
//                       labelText: 'Guarantor 2 Phone',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   TextFormField(
//                     controller: _guarantor2AddressController,
//                     textCapitalization: TextCapitalization.words,
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter your address';
//                       }
//                       return null;
//                     },
//                     decoration: const InputDecoration(
//                       labelText: 'Guarantor 2 Address',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   TextFormField(
//                     controller: _guarantor2CnicController,
//                     inputFormatters: [CnicFormatter()],
//                     validator: (value) {
//                       final cnicRegExp = RegExp(r'^\d{5}-\d{7}-\d{1}$');
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter your CNIC number';
//                       }
//                       if (!cnicRegExp.hasMatch(value)) {
//                         return 'Please enter a valid CNIC number in the format 12345-6789012-3';
//                       }
//                       return null;
//                     },
//                     decoration: const InputDecoration(
//                       labelText: 'Guarantor 2 CNIC',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   print('Form is valid');
//                   if (_formKey.currentState?.validate() ?? false) {
//                     if (_isDuplicateGuarantorData()) {
//                       print('Duplicate data detected');
//                       showDialog(
//                         context: context,
//                         builder: (BuildContext context) {
//                           return AlertDialog(
//                             title: const Text('Duplicate Data'),
//                             content: const Text('Guarantor details cannot be the same. Please enter different information for each guarantor.'),
//                             actions: [
//                               TextButton(
//                                 onPressed: () {
//                                   Navigator.of(context).pop();
//                                 },
//                                 child: const Text('OK'),
//                               ),
//                             ],
//                           );
//                         },
//                       );
//                     } else {
//                       saveGuarantorDetails(); // Save details
//                       Navigator.of(context).pop();
//                     }
//                   }
//                 },
//                 child: const Text('Save'),
//               ),
//               TextButton(
//                 onPressed: () {
//                   _clearForm(); // Clear the form
//                 },
//                 child: const Text('Clear'),
//               ),
//               TextButton(
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                 },
//                 child: const Text('Cancel'),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//
//   void _calculateInstallmentAmount() {
//     // Calculate the installment amount based on the selected plan
//     int months = _getMonthsFromPlan(selectedInstallmentPlan);
//     setState(() {
//       installmentAmount = remainingAmount / months;
//     });
//   }
//
//   int _getMonthsFromPlan(String plan) {
//     switch (plan) {
//       case '3 months':
//         return 3;
//       case '6 months':
//         return 6;
//       case '8 months':
//         return 8;
//       case '10 months':
//         return 10;
//       case '12 months':
//         return 12;
//       default:
//         return 1; // Default to 1 month if no valid plan is selected
//     }
//   }
//
//
// }
