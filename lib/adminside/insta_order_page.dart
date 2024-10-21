// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../components.dart';
// import 'package:flutter/services.dart';
//
// class Ordersoninstallment extends StatefulWidget {
//   const Ordersoninstallment({super.key});
//
//   @override
//   State<Ordersoninstallment> createState() => _OrdersoninstallmentState();
// }
//
// class _OrdersoninstallmentState extends State<Ordersoninstallment> {
//   final DatabaseReference _itemRef = FirebaseDatabase.instance.ref().child('items');
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final DatabaseReference _orderRef = FirebaseDatabase.instance.ref().child('Installment_Orders');
//   final DatabaseReference _guarantorRef = FirebaseDatabase.instance.ref().child('guarantor');
//   List<Map<String, dynamic>> _basket = [];
//   double minDownPayment = 0;
//   double installmentFee = 0;
//   double remainingAmount = 0;
//   double totalbalancewithinstallment= 0;
//   String selectedInstallmentPlan = '3 months';
//   double downPayment = 0;
//   String? _downPaymentError; // Variable to hold the error message
//   double installmentAmount = 0; // Variable to hold the amount per installment
//   List<Map<String, dynamic>> installmentOrders = [];
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
//   Map<String, dynamic>? _selectedItem;
//   TextEditingController _searchController = TextEditingController();
//   TextEditingController _quantityController = TextEditingController();
//
//    double totalBalanceWithInstallment = 0.0; // Declare totalBalanceWithInstallment
//    double _calculatedTotal = 0.0;
//    late double totalBalancewithoutinsta ;
//     double installmentPercentage = 0.0; // Default to 30%
//   final TextEditingController _percentageController = TextEditingController();
//
//   final _formKey = GlobalKey<FormState>();
//
//   String? _validateField(String? value, String fieldName) {
//     if (value == null || value.isEmpty) {
//       return '$fieldName cannot be empty';
//     }
//     return null; // Return null if there is no error
//   }
//
//   String? _validateEmail(String? value) {
//     if (value == null || value.isEmpty) {
//       return 'Email cannot be empty';
//     }
//     // Basic email validation pattern
//     String emailPattern = r'^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$';
//     RegExp regExp = RegExp(emailPattern);
//     if (!regExp.hasMatch(value)) {
//       return 'Enter a valid email address';
//     }
//     return null; // Return null if email is valid
//   }
//
//   String? _validatePhone(String? value) {
//     if (value == null || value.isEmpty) {
//       return 'Phone number cannot be empty';
//     }
//
//     // Pattern for phone numbers starting with 03 (local format) or +92 (international format)
//     String phonePattern = r'^(03[0-9]{9}|(\+92)[0-9]{10})$';
//     RegExp regExp = RegExp(phonePattern);
//
//     if (!regExp.hasMatch(value)) {
//       return 'Enter a valid phone number (03XXXXXXXXX or +92XXXXXXXXXX)';
//     }
//     return null; // Return null if phone number is valid
//   }
//
//   String? _validateCNIC(String? value) {
//
//     final cnicRegExp = RegExp(r'^\d{5}-\d{7}-\d{1}$');
//     if (value == null || value.isEmpty) {
//       return 'Please enter your CNIC number';
//     }
//     if (!cnicRegExp.hasMatch(value)) {
//       return 'Please enter a valid CNIC number in the format 12345-6789012-3';
//     }
//     return null;
//   }
//
//   Widget buildUserTextField(TextEditingController controller, String label, String? Function(String?) validator, {bool isCnicField = false}) {
//     return Padding(
//       padding: const EdgeInsets.all(10),
//       child: TextFormField(
//         controller: controller,
//         decoration: InputDecoration(
//           labelText: label,
//           border: const OutlineInputBorder(),
//         ),
//         inputFormatters: isCnicField ? [CnicFormatter()] : [], // Use CnicFormatter for CNIC field
//
//         validator: validator, // Add validation logic here
//       ),
//     );
//   }
//
//   void _calculateTotalWithInstallment() {
//     setState(() {
//       double installmentPercentage = double.tryParse(_percentageController.text) ?? 0; // Defaults to 0 if invalid
//       double totalBalance = _calculatedTotal; // Use the calculated total as the base amount
//       double installmentFee = totalBalance * (installmentPercentage / 100); // Calculate installment fee
//       totalbalancewithinstallment = totalBalance + installmentFee; // Total with installment fee
//     });
//   }
//
//   Widget buildCnicTextField() {
//     return buildUserTextField(
//       _cnicController,  // Your CNIC controller
//       'CNIC',
//       _validateCNIC,  // CNIC validation function
//       isCnicField: true, // Pass true to enable CNIC formatter
//     );
//   }
//
//
//   @override
//   void initState() {
//     super.initState();
//     _calculateInstallmentAmount();
//     _percentageController.text = installmentPercentage.toString();
//   }
//   @override
//   void dispose() {
//     _searchController.dispose();
//     _quantityController.dispose();
//     _percentageController.dispose();
//
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//
//     final screenWidth = MediaQuery.of(context).size.width;
//     final bool isLargeScreen = screenWidth > 600;
//     double totalBalance = _calculatedTotal;
//     double installmentFee = (totalBalance * (installmentPercentage / 100)); // Calculate installment fee dynamically
//     totalbalancewithinstallment = totalBalance + installmentFee;
//     minDownPayment = (totalBalance + installmentFee) * 0.35;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Installment Details",style: GoogleFonts.lora(color: Colors.white,fontSize: 25,fontWeight: FontWeight.bold,),),
//         centerTitle: true,
//         backgroundColor:const Color(0xFFe6b67e),
//         automaticallyImplyLeading: false,
//         leading: IconButton(onPressed: (){
//           Navigator.pop(context);
//         }, icon: const Icon(Icons.arrow_back)),
//         actions: [
//           IconButton(onPressed: (){
//             _addGuarantorFields(context);
//           }, icon: const Icon(Icons.add)),
//         ],
//       ),
//       body: SingleChildScrollView(
//         child: Form(
//           key: _formKey,
//           child: Column(
//             children: [
//               const Padding(
//                 padding: EdgeInsets.symmetric(vertical: 10),
//                 child: Text("Customer Info", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
//               ),
//               buildUserTextField(_cnicController, 'CNIC', _validateCNIC, isCnicField: true),
//               buildUserTextField(_nameController, 'Name', (value) => _validateField(value, 'Name')),
//               buildUserTextField(_emailController, 'Email', _validateEmail),
//               buildUserTextField(_phoneController, 'Phone', _validatePhone), // Phone validation
//               // buildUserTextField(_cnicController, 'CNIC', _validateCNIC), // CNIC validation
//               buildUserTextField(_addressController, 'Address', (value) => _validateField(value, 'Address')),
//               buildUserTextField(_zipCodeController, 'Zip Code', (value) => _validateField(value, 'Zip Code')),
//
//               const Text("Items Info", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
//               _buildSearchField(isLargeScreen),
//
//               if (_selectedItem != null)
//                 _buildItemDetails(isLargeScreen), // Show item details when an item is selected
//
//               const Padding(
//                 padding: EdgeInsets.symmetric(vertical: 10),
//                 child: Center(
//                   child: Text("Basket Items", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
//                 ),
//               ),
//
//               _buildBasketList(),
//
//               Text(
//                 'Total Balance: \Pkr ${_calculateTotalBalance().toStringAsFixed(0)}', // Display total balance
//                 style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//               ),
//
//               Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: TextField(
//                   controller: _percentageController,
//                   keyboardType: TextInputType.number,
//                   decoration: const InputDecoration(
//                     labelText: 'Enter Installment Percentage (%)',
//                     border: OutlineInputBorder(),
//                   ),
//                   onChanged: (value) {
//                     setState(() {
//                       installmentPercentage = double.tryParse(value) ?? 30; // Default to 30% if invalid
//                       _calculateTotalWithInstallment();
//                     });
//                   },
//                 ),
//               ),
//
//               const SizedBox(height: 10),
//
//               Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: Table(
//                   border: TableBorder.all(),
//                   columnWidths: const {
//                     0: FlexColumnWidth(2),
//                     1: FlexColumnWidth(1),
//                   },
//                   children: [
//                     TableRow(
//                       children: [
//                         const TableCell(
//                           child: Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Sub Balance:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                           ),
//                         ),
//                         TableCell(
//                           child: Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text('${_calculatedTotal} rs', style: const TextStyle(fontSize: 16)),
//                           ),
//                         ),
//                       ],
//                     ),
//                     TableRow(
//                       children: [
//                         const TableCell(
//                           child: Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Installment Fee (30%):', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                           ),
//                         ),
//                         TableCell(
//                           child: Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text('${installmentFee} rs', style: const TextStyle(fontSize: 16)),
//                           ),
//                         ),
//                       ],
//                     ),
//                     TableRow(
//                       children: [
//                         const TableCell(
//                           child: Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Total Balance:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                           ),
//                         ),
//                         TableCell(
//                           child: Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text('${totalbalancewithinstallment.toStringAsFixed(0)} rs', style: const TextStyle(fontSize: 16)),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 10),
//               Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: Text("You can add any down payment amount."),
//               ),
//               const SizedBox(height: 10),
//               Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: TextFormField(
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
//                     // Optionally, ensure the down payment does not exceed the total amount with fees
//                     double maxDownPayment = totalBalance + installmentFee;
//                     if (downPayment > maxDownPayment) {
//                       _downPaymentController.text = maxDownPayment.toStringAsFixed(2);
//                       downPayment = maxDownPayment;
//                     }
//
//                     // Calculate the remaining amount
//                     setState(() {
//                       remainingAmount = (totalBalance + installmentFee) - downPayment;
//                       _calculateInstallmentAmount();
//                     });
//                   },
//                 ),
//               ),
//
//               const SizedBox(height: 10),
//               Text('Remaining Amount: ${remainingAmount.toStringAsFixed(2)} rs', style: const TextStyle(fontSize: 18)),
//               const SizedBox(height: 20),
//               // Installment Plan Options
//               const Text('Choose Installment Plan:', style: TextStyle(fontSize: 18)),
//               buildInstallmentRadioButtons(),
//               const SizedBox(height: 20),
//               Text("Total Installment Amount is: ${installmentAmount.toStringAsFixed(0)}",
//                 style: const TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold
//                 ),
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton (
//                 // onPressed: (){
//                 //   placeOrder();
//                 // },
//                 onPressed: () async {
//                  if(_formKey.currentState?.validate() == true){
//                    String cnic = _cnicController.text.trim();
//
//                    int? remainingInstallments = await _getRemainingInstallments(cnic);
//
//                    if (remainingInstallments != null) {
//                      if (remainingInstallments == 0) {
//                        placeOrder(); // Allow the order to be placed
//                      } else {
//                        ScaffoldMessenger.of(context).showSnackBar(
//                            SnackBar(content: Text("User has remaining installments: $remainingInstallments. Cannot place a new order."))
//                        );
//                      }
//                    } else {
//                      // If user does not exist, allow the new order to be placed
//                      placeOrder();
//                    }
//                  }
//                 },
//
//                 child: const Text('Place Order'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFFe6b67e), // Button color
//                   textStyle: const TextStyle(fontSize: 18),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
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
//   void _searchItem(String barcodeOrItemName) async {
//     final DataSnapshot snapshot = await _itemRef.get();
//
//     if (snapshot.exists) {
//       final itemsData = Map<String, dynamic>.from(snapshot.value as Map);
//
//       final lowercaseQuery = barcodeOrItemName.toLowerCase();
//
//
//       final item = itemsData.values.firstWhere(
//             (item) =>
//         (
//             item['barcode'].toString().toLowerCase().contains(lowercaseQuery)||
//                 item['item_name'].toString().toLowerCase().contains(lowercaseQuery)
//         ),
//         orElse: () => null,
//       );
//
//       setState(() {
//         _selectedItem = item != null ? Map<String, dynamic>.from(item) : null;
//         _calculatedTotal = 0.0; // Reset total when new item is selected
//       });
//     }
//   }
//
//   void _calculateTotal(String value) {
//     final quantity = int.tryParse(value) ?? 0;
//     final net_rate = double.tryParse(_selectedItem!['net_rate'].toString()) ?? 0.0;
//     final tax = double.tryParse(_selectedItem!['tax'].toString()) ?? 0.0;
//     final total = (net_rate * quantity) + ((tax / 100) * (net_rate * quantity));
//
//     setState(() {
//       _calculatedTotal = total;
//     });
//   }
//
//   Widget _buildItemDetails(bool isLargeScreen) {
//     // Ensure _selectedItem is not null
//     if (_selectedItem == null) {
//       return const Text('No item selected.'); // Handle null case
//     }
//     return Padding(
//       padding: EdgeInsets.symmetric(vertical: isLargeScreen ? 16.0 : 8.0),
//       child: Card(
//         elevation: 4.0,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
//         child: Padding(
//           padding: EdgeInsets.all(isLargeScreen ? 16.0 : 12.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               ListTile(
//                 title:   Text('Item Name: ${_selectedItem!['item_name']}', style: _itemDetailStyle(isLargeScreen)),
//                 subtitle: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                 Text('Rate: ${_selectedItem!['net_rate']}', style: _itemDetailStyle(isLargeScreen)),
//                 Text('Tax (%): ${_selectedItem!['tax']}', style: _itemDetailStyle(isLargeScreen)),
//                 Text('Available Qty: ${_selectedItem!['item_qty']}', style: _itemDetailStyle(isLargeScreen)),
//                   ],
//                 ),
//                 trailing: _selectedItem!['image'] != null && _selectedItem!['image'].isNotEmpty
//                     ? Image.network(
//                   _selectedItem!['image'],
//                   height: 50, // Set the height of the image
//                   width: 50, // Set the width of the image
//                   fit: BoxFit.cover, // Maintain aspect ratio
//                 )
//                     : const Icon(Icons.image_not_supported),
//               ),
//               SizedBox(height: isLargeScreen ? 16.0 : 8.0),
//               _buildQuantityField(isLargeScreen),
//               SizedBox(height: isLargeScreen ? 16.0 : 8.0),
//               Text('Total: \Pkr ${_calculatedTotal.toStringAsFixed(0)}', style: _itemDetailStyle(isLargeScreen)),
//               SizedBox(height: isLargeScreen ? 16.0 : 8.0),
//
//               Center(
//                 child: SizedBox(
//                   width: 200,
//                   child: ElevatedButton(
//                     onPressed: _addToBasket,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFFe6b67e),
//                       padding: const EdgeInsets.all(10),
//                     ),
//                     child: const Text('Add to Basket', style: NewCustomTextStyles.newcustomTextStyle),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Future<void> _addToBasket() async {
//     if (_selectedItem != null) {
//       final quantity = int.tryParse(_quantityController.text) ?? 0;
//       if (quantity <= 0) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Please enter a valid quantity')),
//         );
//         return;
//       }
//
//       // Parse availableQty as an integer
//       final availableQty = int.tryParse(_selectedItem!['item_qty'].toString()) ?? 0;
//       if (availableQty < quantity) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Not enough items in stock')),
//         );
//         return;
//       }
//
//       // Parse sale_rate and tax as double
//       final net_rate = double.tryParse(_selectedItem!['net_rate'].toString()) ?? 0.0;
//
//       final total = (net_rate * quantity);
//
//       // Create a new item map to add to the basket
//       final newItem = {
//         ..._selectedItem!,
//         'quantity': quantity,
//         'total': total,
//         'image': _selectedItem!['image'], // Include imageUrl
//
//       };
//
//       // print(newItem);
//       // Add the new item to the basket list
//       setState(() {
//         _basket.add(newItem); // Add the item to the local basket
//         _selectedItem = null; // Reset the selected item
//         _quantityController.clear(); // Clear the quantity input field
//       });
//       print(_basket);
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Item added to basket!')),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('No item selected')),
//       );
//     }
//   }
//
//   Widget _buildBasketList() {
//     return ListView.builder(
//       shrinkWrap: true,
//       itemCount: _basket.length,
//       itemBuilder: (context, index) {
//         final item = _basket[index];
//         return ListTile(
//           leading: item['image'] != null && item['image'].isNotEmpty
//               ? Image.network(
//             item['image'],
//             height: 50, // Set the height of the image
//             width: 50, // Set the width of the image
//             fit: BoxFit.cover, // Maintain aspect ratio
//           )
//               : const Icon(Icons.image_not_supported),
//           title: Text(item['item_name']),
//           subtitle: Column(
//             mainAxisAlignment: MainAxisAlignment.start,
//             children: [
//               Text('Subtotal: Pkr ${item['total'].toStringAsFixed(0)}'),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.start,
//                 children: [
//                   Text('Quantity: ${item['quantity']}'),const SizedBox(width: 10,),
//                   Text('Rate: ${item['net_rate']}'),
//                 ],
//               ),
//             ],
//           ),
//           trailing: IconButton(
//               onPressed: () => _removeFromBasket(index), // Call the remove method with the index
//
//               icon: const Icon(Icons.delete)),
//         );
//       },
//     );
//   }
//
//   Widget _buildQuantityField(bool isLargeScreen) {
//     return TextFormField(
//       controller: _quantityController,
//       decoration: InputDecoration(
//         labelText: 'Enter Quantity',
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(8.0),
//         ),
//         contentPadding: EdgeInsets.all(isLargeScreen ? 20.0 : 16.0),
//       ),
//       keyboardType: TextInputType.number,
//       onChanged: _calculateTotal,
//     );
//   }
//
//   TextStyle _itemDetailStyle(bool isLargeScreen) {
//     return TextStyle(
//       fontSize: isLargeScreen ? 18.0 : 16.0,
//       fontWeight: FontWeight.w500,
//     );
//   }
//
//   Widget _buildSearchField(bool isLargeScreen) {
//     return Padding(
//       padding: const EdgeInsets.all(8.0),
//       child: TextFormField(
//         controller: _searchController,
//         decoration: InputDecoration(
//           labelText: 'Search by Barcode/Item Name',
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(8.0),
//           ),
//           prefixIcon: const Icon(Icons.search),
//           contentPadding: EdgeInsets.all(isLargeScreen ? 20.0 : 16.0),
//         ),
//         onChanged: _searchItem,
//       ),
//     );
//   }
//
//   void _removeFromBasket(int index) {
//     setState(() {
//       _basket.removeAt(index); // Remove the item at the specified index
//     });
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Item removed from basket!")),
//     );
//   }
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
//   double _calculateTotalBalance() {
//     double totalBalancewithoutinst = 0.0;
//
//     for (var item in _basket) {
//       totalBalancewithoutinst += item['total']; // Sum up the total of each item
//     }
//
//     setState(() {
//       installmentFee = totalBalancewithoutinst*0.30;
//       _calculatedTotal = totalBalancewithoutinst;
//     });
//     return totalBalancewithoutinst;
//   }
//
//   Future<void> placeOrder() async {
//     // Check if any installments are pending
//     if (installmentOrders.any((order) => DateTime.now().difference(DateTime.parse(order['last_payment_date'])).inDays >= 35)) {
//       ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("You cannot place new orders due to pending installments."))
//       );
//       return; // Exit the function to prevent order submission
//     }
//
//     // Validate down payment
//     double downPayment = double.tryParse(_downPaymentController.text) ?? 0;
//     if (downPayment <= 0) {
//       ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('A down payment is required to place an order.'))
//       );
//       return;
//     }
//
//     // Check if installment plan is selected
//     if (selectedInstallmentPlan.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Please select an installment plan.'))
//       );
//       return;
//     }
//
//     // Validate guarantors
//     if (_guarantor1NameController.text.isEmpty ||
//         _guarantor1PhoneController.text.isEmpty ||
//         _guarantor1CnicController.text.isEmpty ||
//         _guarantor1AddressController.text.isEmpty ||
//         _guarantor2NameController.text.isEmpty ||
//         _guarantor2PhoneController.text.isEmpty ||
//         _guarantor2CnicController.text.isEmpty ||
//         _guarantor2AddressController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Please add details for both guarantors.'))
//       );
//       return;
//     }
//
//     // Validate user details
//     if (_nameController.text.isEmpty ||
//         _emailController.text.isEmpty ||
//         _phoneController.text.isEmpty ||
//         _cnicController.text.isEmpty ||
//         _addressController.text.isEmpty ||
//         _zipCodeController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Please fill in all the user details.'))
//       );
//       return;
//     }
//
//
//     // Validate phone number (03XXXXXXXXX or +92XXXXXXXXXX)
//     String phonePattern = r'^(03[0-9]{9}|(\+92)[0-9]{10})$';
//     RegExp phoneRegExp = RegExp(phonePattern);
//     if (!phoneRegExp.hasMatch(_phoneController.text)) {
//       ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Please enter a valid phone number (03XXXXXXXXX or +92XXXXXXXXXX).'))
//       );
//       return;
//     }
//
//
//
//     // Use local basket items instead of fetching from Firebase
//     if (_basket.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Your basket is empty.'))
//       );
//       return;
//     }
//
//     // Generate a new unique key for the order and use it as the orderId
//     DatabaseReference newOrderRef = _orderRef.push();
//     String newOrderId = newOrderRef.key.toString(); // This key will be the unique orderId
//
//     // Calculate remaining amount, installment fee, etc.
//     final totalBalance = _calculateitemTotalBalance(); // Implement this method to sum up basket totals
//     final installmentFee = totalBalance * 0.35; // Calculate 35% of the total balance
//     final remainingAmount = totalBalance - downPayment; // Calculate remaining amount
//     final installmentAmount = remainingAmount / selectedInstallmentPlan.length; // Example calculation
//     final int currentRemainingInstallments = selectedInstallmentPlan.length;
//
//     final orderData = {
//       'orderId': newOrderId, // Use the same key as orderId
//       'userId': FirebaseAuth.instance.currentUser?.uid,
//       'total_balance': totalBalance,
//       'installment_fee': installmentFee,
//       'total_balance_with_installment': totalBalance + installmentFee,
//       'min_down_payment': minDownPayment,
//       'down_payment_done': downPayment, //1
//       'remaining_amount': remainingAmount,//2
//       'selected_installment_plan': selectedInstallmentPlan,//3
//       'remaining_installments': currentRemainingInstallments,//4
//       'installment_amount': installmentAmount,//5
//       'payment_status': 'Partially Paid',//6 // Set payment status
//       'status': 'Pending',
//       'items': _basket.map((item) => {
//         'item_name': item['item_name'],
//         'quantity': item['quantity'],
//         'net_rate': item['net_rate'],
//         'total': item['total'],
//         'image': item['image'],
//         'category': item['category'],
//       }).toList(), // Convert the local basket to the required format
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
//         'userId': FirebaseAuth.instance.currentUser?.uid,
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
//       // Clear the basket after placing the order
//       _basket.clear(); // Clear local basket
//       setState(() {}); // Update UI
//
//       // Navigate to Orders List Page
//       Navigator.pushReplacementNamed(context, '/admin');
//
//       // Show a success message
//       ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Order placed successfully!'))
//       );
//     } catch (e) {
//       // Handle any errors during the order placement
//       ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to place order: $e'))
//       );
//     }
//   }
//
//
// // Helper function to calculate the remaining amount after the down payment
//   double calculateRemainingAmount(double downPayment) {
//     double totalBalance = _calculateitemTotalBalance(); // Custom function to calculate total balance from items
//     return totalBalance - downPayment;
//   }
//
// // Helper function to calculate the per-installment amount
//   double calculateInstallmentAmount() {
//     double remainingAmount = calculateRemainingAmount(double.tryParse(_downPaymentController.text) ?? 0);
//     return remainingAmount / selectedInstallmentPlan.length; // Assuming selectedInstallmentPlan has the number of installments
//   }
//
// // Function to clear form fields after successful order
//   void _clearForm() {
//     _nameController.clear();
//     _emailController.clear();
//     _phoneController.clear();
//     _cnicController.clear();
//     _addressController.clear();
//     _zipCodeController.clear();
//     _downPaymentController.clear();
//     _guarantor1NameController.clear();
//     _guarantor1PhoneController.clear();
//     _guarantor1CnicController.clear();
//     _guarantor1AddressController.clear();
//     _guarantor2NameController.clear();
//     _guarantor2PhoneController.clear();
//     _guarantor2CnicController.clear();
//     _guarantor2AddressController.clear();
//   }
//
//   double _calculateitemTotalBalance() {
//     double total = 0.0;
//     for (var item in _basket) {
//       total += item['total']; // Assuming each item has a 'total' field
//     }
//     return total;
//   }
//
//   Future<int?> _getRemainingInstallments(String cnic) async {
//     final databaseReference = FirebaseDatabase.instance.ref();
//
//     // Use 'once' to fetch the data as a DatabaseEvent
//     DatabaseEvent event = await databaseReference.child('Installment_orders').once();
//
//     // Access the DataSnapshot from the DatabaseEvent
//     DataSnapshot snapshot = event.snapshot;
//
//     if (snapshot.exists) {
//       Map<dynamic, dynamic> orders = snapshot.value as Map<dynamic, dynamic>; // Cast the value to a Map
//       for (var order in orders.values) {
//         if (order['cnic'] == cnic) {
//           return order['remaining_installments']; // Return the remaining installments if found
//         }
//       }
//     }
//     return null; // User does not exist
//   }
//
// }
// class CnicFormatter extends TextInputFormatter {
//   @override
//   TextEditingValue formatEditUpdate(
//       TextEditingValue oldValue, TextEditingValue newValue) {
//     String newText = newValue.text;
//
//     // Remove any existing hyphens
//     newText = newText.replaceAll('-', '');
//
//     // Apply the formatting as the user types
//     StringBuffer buffer = StringBuffer();
//     if (newText.length > 5) {
//       buffer.write(newText.substring(0, 5) + '-'); // First 5 digits
//     } else {
//       buffer.write(newText); // If less than 5 digits, return the input so far
//     }
//     if (newText.length > 5 && newText.length <= 12) {
//       buffer.write(newText.substring(5, newText.length)); // Next set of digits
//     } else if (newText.length > 12) {
//       buffer.write(newText.substring(5, 12) + '-'); // Second block of digits with hyphen
//       buffer.write(newText.substring(12)); // Last digit
//     }
//
//     // Ensure the cursor stays in the right position
//     return TextEditingValue(
//       text: buffer.toString(),
//       selection: TextSelection.collapsed(offset: buffer.length),
//     );
//   }
// }
//
