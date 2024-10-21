import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components.dart';
import '../userprofile.dart';

class OrderTaking extends StatefulWidget {
  const OrderTaking({super.key});

  @override
  State<OrderTaking> createState() => _OrderTakingState();
}

class _OrderTakingState extends State<OrderTaking> {
  final DatabaseReference _itemRef = FirebaseDatabase.instance.ref().child('items');
  final DatabaseReference _orderRef = FirebaseDatabase.instance.ref().child('Installment_Orders');
  final DatabaseReference _guarantorRef = FirebaseDatabase.instance.ref().child('guarantor');
  final DatabaseReference _customerRef = FirebaseDatabase.instance.ref().child('customer');
  double totalbalancewithinstallment= 0;
  // double installmentFee = 0;
  double _calculatedTotal = 0.0;
  double totalBalanceWithInstallment = 0.0;
  double installmentPercentage = 0;
  String? _downPaymentError;
  double remainingAmount = 0;
  String selectedInstallmentPlan = '3 months';
  double installmentAmount = 0;


  final _formKey = GlobalKey<FormState>();
  TextEditingController _searchController = TextEditingController();
  final TextEditingController _percentageController = TextEditingController();
  TextEditingController _quantityController = TextEditingController();
  final TextEditingController _downPaymentController = TextEditingController();

  Map<String, dynamic>? _selectedItem;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _cnicController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  // Controllers for the guarantor dialog form
  final _guarantor1NameController = TextEditingController();
  final _guarantor1AddressController = TextEditingController();
  final _guarantor1CnicController = TextEditingController();
  final _guarantor1PhoneController = TextEditingController();

  final _guarantor2NameController = TextEditingController();
  final _guarantor2AddressController = TextEditingController();
  final _guarantor2CnicController = TextEditingController();
  final _guarantor2PhoneController = TextEditingController();
  List<Map<String, String>> _guarantors = [];
  Map<String, String>? _userDetails;
  List<Map<String, dynamic>> _basket = [];




  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    // Email regex validation
    String pattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
    RegExp regex = RegExp(pattern);
    if (!regex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }
  String? _validateCNIC(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your CNIC';
    }
    String pattern = r'^\d{5}-\d{7}-\d{1}$';
    RegExp regex = RegExp(pattern);
    if (!regex.hasMatch(value)) {
      return 'Please enter a valid CNIC (XXXXX-XXXXXXX-X)';
    }
    return null;
  }
  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }

    // Regular expression to match both formats:
    // 1. Local format: 03XX-XXXXXXX or 03XXXXXXXXX
    // 2. International format: +92XXXXXXXXXX
    String pattern = r'^(03[0-9]{2}-?[0-9]{7}|(\+92[0-9]{10}))$';
    RegExp regex = RegExp(pattern);

    // Trim the value to remove leading/trailing spaces
    String trimmedValue = value.trim();

    if (!regex.hasMatch(trimmedValue)) {
      return 'Please enter a valid Pakistani phone number (03XX-XXXXXXX or +92XXXXXXXXXX)';
    }
    return null;
  }
  // Future<void> _addToBasket() async {
  //   if (_selectedItem != null) {
  //     final quantity = int.tryParse(_quantityController.text) ?? 0;
  //     if (quantity <= 0) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Please enter a valid quantity')),
  //       );
  //       return;
  //     }
  //
  //     // Parse availableQty as an integer
  //     final availableQty = int.tryParse(_selectedItem!['item_qty'].toString()) ?? 0;
  //     if (availableQty < quantity) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Not enough items in stock')),
  //       );
  //       return;
  //     }
  //
  //     // Parse sale_rate and tax as double
  //     final net_rate = double.tryParse(_selectedItem!['net_rate'].toString()) ?? 0.0;
  //
  //     final total = (net_rate * quantity);
  //
  //     // Create a new item map to add to the basket
  //     final newItem = {
  //       ..._selectedItem!,
  //       'quantity': quantity,
  //       'total': total,
  //       'image': _selectedItem!['image'], // Include imageUrl
  //
  //     };
  //
  //     // print(newItem);
  //     // Add the new item to the basket list
  //     setState(() {
  //       _basket.add(newItem); // Add the item to the local basket
  //       _selectedItem = null; // Reset the selected item
  //       _quantityController.clear(); // Clear the quantity input field
  //     });
  //     print(_basket);
  //     // Update the available quantity in the database
  //     final updatedQty = availableQty - quantity;
  //
  //     try {
  //       // Assuming your items are stored in a node called "items" and each item has a unique ID
  //       final itemRef = FirebaseDatabase.instance.ref("items/${_selectedItem!['id']}");
  //       await itemRef.update({'item_qty': updatedQty});
  //
  //       print("Item quantity updated in database: $updatedQty");
  //
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Item added to basket!')),
  //       );
  //     } catch (e) {
  //       // Handle error in updating the database
  //       print('Error updating item quantity: $e');
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Error updating item quantity')),
  //       );
  //     }
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('No item selected')),
  //     );
  //   }
  // }
  Future<void> _addToBasket() async {
    if (_selectedItem != null) {
      final quantity = int.tryParse(_quantityController.text) ?? 0;
      if (quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid quantity')),
        );
        return;
      }

      // Parse availableQty as an integer
      final availableQty = int.tryParse(_selectedItem!['item_qty'].toString()) ?? 0;
      if (availableQty < quantity) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not enough items in stock')),
        );
        return;
      }

      // Parse sale_rate and tax as double
      final net_rate = double.tryParse(_selectedItem!['net_rate'].toString()) ?? 0.0;

      final total = (net_rate * quantity);

      // Create a new item map to add to the basket
      final newItem = {
        ..._selectedItem!,
        'quantity': quantity,
        'total': total,
        'image': _selectedItem!['image'], // Include imageUrl
      };

      // Store item ID before resetting _selectedItem
      final itemId = _selectedItem!['itemId']; // Get the ID before resetting

      // Add the new item to the basket list
      setState(() {
        _basket.add(newItem); // Add the item to the local basket
        _selectedItem = null; // Reset the selected item
        _quantityController.clear(); // Clear the quantity input field
      });

      // Update the available quantity in the database
      final updatedQty = availableQty - quantity;

      try {
        // Update the item quantity in the database
        final itemRef = FirebaseDatabase.instance.ref("items/$itemId");
        await itemRef.update({'item_qty': updatedQty});

        print("Item quantity updated in database: $updatedQty");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item added to basket!')),
        );
      } catch (e) {
        // Handle error in updating the database
        print('Error updating item quantity: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating item quantity')),
        );
      }

      print(_basket);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No item selected')),
      );
    }
  }

  Future<void> _saveDetails() async {
    // Get user details
    _userDetails = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'cnic': _cnicController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
    };

    // Get guarantors
    _guarantors = [
      {
        'name': _guarantor1NameController.text.trim(),
        'phone': _guarantor1PhoneController.text.trim(),
        'cnic': _guarantor1CnicController.text.trim(),
        'address': _guarantor1AddressController.text.trim(),
      },
      {
        'name': _guarantor2NameController.text.trim(),
        'phone': _guarantor2PhoneController.text.trim(),
        'cnic': _guarantor2CnicController.text.trim(),
        'address': _guarantor2AddressController.text.trim(),
      },
    ];

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User and guarantors added successfully!')),
    );

    // Clear form after saving
    // _clearForm();
    // Navigator.of(context).pop(); // Close the dialog
    setState(() {}); // Update the UI
  }
  Future<void> _saveGuarantors() async {
    // Get the input values
    String guarantor1Name = _guarantor1NameController.text.trim();
    String guarantor1Phone = _guarantor1PhoneController.text.trim();
    String guarantor1Cnic = _guarantor1CnicController.text.trim();
    String guarantor1Address = _guarantor1AddressController.text.trim();

    String guarantor2Name = _guarantor2NameController.text.trim();
    String guarantor2Phone = _guarantor2PhoneController.text.trim();
    String guarantor2Cnic = _guarantor2CnicController.text.trim();
    String guarantor2Address = _guarantor2AddressController.text.trim();

    // Check for duplicate entries
    if (_hasDuplicates(guarantor1Name, guarantor1Phone, guarantor1Cnic, guarantor1Address,
        guarantor2Name, guarantor2Phone, guarantor2Cnic, guarantor2Address)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Duplicate input detected. Please ensure all fields are unique.')),
      );
      return; // Exit the method if duplicates are found, keeping the dialog open
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('guarantor1_name', guarantor1Name);
    await prefs.setString('guarantor1_phone', guarantor1Phone);
    await prefs.setString('guarantor1_cnic', guarantor1Cnic);
    await prefs.setString('guarantor1_address', guarantor1Address);
    await prefs.setString('guarantor2_name', guarantor2Name);
    await prefs.setString('guarantor2_phone', guarantor2Phone);
    await prefs.setString('guarantor2_cnic', guarantor2Cnic);
    await prefs.setString('guarantor2_address', guarantor2Address);

    // Successfully saved, close the dialog
    Navigator.of(context).pop();
  }
  bool _hasDuplicates(String name1, String phone1, String cnic1, String address1,
      String name2, String phone2, String cnic2, String address2) {
    return (name1 == name2 ||
        phone1 == phone2 ||
        cnic1 == cnic2 ||
        address1 == address2 ||
        name1 == phone2 || name1 == cnic2 || name1 == address2 ||
        phone1 == name2 || phone1 == cnic2 || phone1 == address2 ||
        cnic1 == name2 || cnic1 == phone2 || cnic1 == address2 ||
        address1 == name2 || address1 == phone2 || address1 == cnic2);
  }
  void _showGuarantorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Add Guarantors"),
          content: SingleChildScrollView(
            child: Form(
              key: GlobalKey<FormState>(),
              child: Column(
                children: [
                  // Guarantor 1 Fields
                  const Text("Guarantor 1"),
                  TextFormField(
                    controller: _guarantor1NameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter guarantor name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _guarantor1AddressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _guarantor1CnicController,
                    decoration: const InputDecoration(
                      labelText: 'CNIC',
                      border: OutlineInputBorder(),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      CnicFormatter(),
                    ],
                    validator: _validateCNIC,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _guarantor1PhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validatePhoneNumber,
                  ),
                  const SizedBox(height: 16),

                  // Guarantor 2 Fields
                  const Text("Guarantor 2"),
                  TextFormField(
                    controller: _guarantor2NameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter guarantor name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _guarantor2AddressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _guarantor2CnicController,
                    decoration: const InputDecoration(
                      labelText: 'CNIC',
                      border: OutlineInputBorder(),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      CnicFormatter(),
                    ],
                    validator: _validateCNIC,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _guarantor2PhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validatePhoneNumber,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Check if guarantor 1 and 2 are filled
                if (_guarantor1NameController.text.isNotEmpty &&
                    _guarantor2NameController.text.isNotEmpty) {
                  // Save guarantors to SharedPreferences
                  await _saveGuarantors();
                  await _saveDetails();


                  // Show success message only if save was successful
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Guarantors added successfully!')),
                  );
                  // The dialog will close only after successful save
                } else {
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields for both guarantors.')),
                  );
                }
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () {
                _clearForm(); // Clear the form
              },
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }
  void _showUserDetailsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Add User Details"),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cnicController,
                    decoration: const InputDecoration(
                      labelText: 'CNIC',
                      border: OutlineInputBorder(),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      CnicFormatter(),
                    ],
                    validator: _validateCNIC,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validatePhoneNumber,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your address';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            // TextButton(
            //   onPressed: () async {
            //     if (_formKey.currentState!.validate()) {
            //       String cnic = _cnicController.text.trim();
            //
            //       bool cnicExists = await _isCnicAlreadyPresent(cnic);
            //
            //      if(cnicExists){
            //        // _showUserExistsWarningDialog(cnic);
            //
            //
            //      }else{
            //        // Trim the text from controllers
            //        _nameController.text.trim();
            //        _emailController.text.trim();
            //        _cnicController.text.trim();
            //        _phoneController.text.trim();
            //        _addressController.text.trim();
            //        await _saveDetails();
            //        ScaffoldMessenger.of(context).showSnackBar(
            //          const SnackBar(content: Text('User details submitted successfully!')),
            //        );
            //
            //        // Close the dialog
            //        Navigator.of(context).pop();
            //      }
            //     }
            //   },
            //   child: const Text('Submit'),
            // ),

            TextButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  String cnic = _cnicController.text.trim();

                  bool cnicExists = await _isCnicAlreadyPresent(cnic);

                  if (cnicExists) {
                    // Fetch previous orders for this CNIC
                    var previousOrders = await _fetchPreviousOrders(cnic);

                    // Navigate to the UserDetailsPage
                    Navigator.of(context).pop(); // Close the dialog first
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => UserDetailsPage(
                          cnic: cnic,
                          previousOrders: previousOrders,
                          onSave: _saveDetails, // Pass the save function

                        ),
                      ),
                    );
                  } else {
                    // Handle new user submission
                    await _saveDetails();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User details submitted successfully!')),
                    );

                    // Close the dialog
                    Navigator.of(context).pop();
                  }
                }
              },
              child: const Text('Submit'),
            ),

          ],
        );
      },
    );
  }
  Future<List<Map<String, dynamic>>> _fetchPreviousOrders(String cnic) async {
    DatabaseEvent customerEvent = await FirebaseDatabase.instance
        .ref()
        .child('Installment_Orders')
        .orderByChild('customer_cnic')
        .equalTo(cnic)
        .once();

    var previousOrders = <Map<String, dynamic>>[];
    print("Querying for CNIC: $cnic");

    if (customerEvent.snapshot.value != null) {
      Map<dynamic, dynamic> ordersMap = customerEvent.snapshot.value as Map<dynamic, dynamic>;
      previousOrders = ordersMap.values.map((order) => Map<String, dynamic>.from(order)).toList();
    } else {
      print("No orders found for CNIC: $cnic");
    }

    return previousOrders;
  }
  void _searchItem(String barcodeOrItemName) async {
    final DataSnapshot snapshot = await _itemRef.get();

    if (snapshot.exists) {
      final itemsData = Map<String, dynamic>.from(snapshot.value as Map);

      final lowercaseQuery = barcodeOrItemName.toLowerCase();


      final item = itemsData.values.firstWhere(
            (item) =>
        (
            item['barcode'].toString().toLowerCase().contains(lowercaseQuery)||
                item['item_name'].toString().toLowerCase().contains(lowercaseQuery)
        ),
        orElse: () => null,
      );

      setState(() {
        _selectedItem = item != null ? Map<String, dynamic>.from(item) : null;
        _calculatedTotal = 0.0; // Reset total when new item is selected
      });
    }
  }
  Widget _buildSearchField(bool isLargeScreen) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: 'Search by Barcode/Item Name',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          prefixIcon: const Icon(Icons.search),
          contentPadding: EdgeInsets.all(isLargeScreen ? 20.0 : 16.0),
        ),
        onChanged: _searchItem,
      ),
    );
  }
  void _calculateTotalWithInstallment() {
    setState(() {
      double installmentPercentage = double.tryParse(_percentageController.text) ?? 0; // Defaults to 0 if invalid
      double totalBalance = _calculatedTotal; // Use the calculated total as the base amount
      double installmentFee = totalBalance * (installmentPercentage / 100); // Calculate installment fee
      totalbalancewithinstallment = totalBalance + installmentFee; // Total with installment fee
    });
  }
  void _calculateTotal(String value) {
    final quantity = int.tryParse(value) ?? 0;
    final net_rate = double.tryParse(_selectedItem!['net_rate'].toString()) ?? 0.0;
    final total = (net_rate * quantity) ;

    setState(() {
      _calculatedTotal = total;
    });
  }
  Widget _buildQuantityField(bool isLargeScreen) {
    return TextFormField(
      controller: _quantityController,
      decoration: InputDecoration(
        labelText: 'Enter Quantity',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        contentPadding: EdgeInsets.all(isLargeScreen ? 20.0 : 16.0),
      ),
      keyboardType: TextInputType.number,
      onChanged: _calculateTotal,
    );
  }
  TextStyle _itemDetailStyle(bool isLargeScreen) {
    return TextStyle(
      fontSize: isLargeScreen ? 18.0 : 16.0,
      fontWeight: FontWeight.w500,
    );
  }
  Widget _buildItemDetails(bool isLargeScreen) {
    // Ensure _selectedItem is not null
    if (_selectedItem == null) {
      return const Text('No item selected.'); // Handle null case
    }
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isLargeScreen ? 16.0 : 8.0),
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: Padding(
          padding: EdgeInsets.all(isLargeScreen ? 16.0 : 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title:   Text('Item Name: ${_selectedItem!['item_name']}', style: _itemDetailStyle(isLargeScreen)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rate: ${_selectedItem!['net_rate']}', style: _itemDetailStyle(isLargeScreen)),
                    Text('Tax (%): ${_selectedItem!['tax']}', style: _itemDetailStyle(isLargeScreen)),
                    Text('Available Qty: ${_selectedItem!['item_qty']}', style: _itemDetailStyle(isLargeScreen)),
                  ],
                ),
                trailing: _selectedItem!['image'] != null && _selectedItem!['image'].isNotEmpty
                    ? Image.network(
                  _selectedItem!['image'],
                  height: 50, // Set the height of the image
                  width: 50, // Set the width of the image
                  fit: BoxFit.cover, // Maintain aspect ratio
                )
                    : const Icon(Icons.image_not_supported),
              ),
              SizedBox(height: isLargeScreen ? 16.0 : 8.0),
              _buildQuantityField(isLargeScreen),
              SizedBox(height: isLargeScreen ? 16.0 : 8.0),
              Text('Total: \Pkr ${_calculatedTotal.toStringAsFixed(0)}', style: _itemDetailStyle(isLargeScreen)),
              SizedBox(height: isLargeScreen ? 16.0 : 8.0),

              Center(
                child: SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: _addToBasket,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFe6b67e),
                      padding: const EdgeInsets.all(10),
                    ),
                    child: const Text('Add to Basket', style: NewCustomTextStyles.newcustomTextStyle),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // void _removeFromBasket(int index) {
  //   setState(() {
  //     _basket.removeAt(index); // Remove the item at the specified index
  //   });
  //
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(content: Text("Item removed from basket!")),
  //   );
  // }

  void _removeFromBasket(int index) async {
    // Get the item to be removed to access its details
    final itemToRemove = _basket[index];

    setState(() {
      _basket.removeAt(index); // Remove the item at the specified index
    });

    // Retrieve the quantity of the item being removed
    final quantityToRestore = itemToRemove['quantity'];

    // Update the item_qty in the database
    try {
      // Assuming your items are stored in a node called "items" and each item has a unique ID
      final itemRef = FirebaseDatabase.instance.ref("items/${itemToRemove['itemId']}");

      // Fetch the current quantity using once()
      DatabaseEvent event = await itemRef.once(); // Get the DatabaseEvent

      // Access the snapshot from the event
      final snapshot = event.snapshot;

      if (snapshot.exists) {
        // Get the current available quantity
        final currentQty = int.tryParse(snapshot.child('item_qty').value.toString()) ?? 0;

        // Calculate the new quantity
        final newQty = currentQty + quantityToRestore;

        // Update the quantity in the database
        await itemRef.update({'item_qty': newQty});
        print("Item quantity updated in database: $newQty");
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Item removed from basket!")),
      );
    } catch (e) {
      // Handle error in updating the database
      print('Error updating item quantity: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating item quantity')),
      );
    }
  }

  Widget _buildBasketList() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _basket.length,
      itemBuilder: (context, index) {
        final item = _basket[index];
        return ListTile(
          leading: item['image'] != null && item['image'].isNotEmpty
              ? Image.network(
            item['image'],
            height: 50, // Set the height of the image
            width: 50, // Set the width of the image
            fit: BoxFit.cover, // Maintain aspect ratio
          )
              : const Icon(Icons.image_not_supported),
          title: Text(item['item_name']),
          subtitle: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text('Subtotal: Pkr ${item['total'].toStringAsFixed(0)}'),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text('Quantity: ${item['quantity']}'),const SizedBox(width: 10,),
                  Text('Rate: ${item['net_rate']}'),
                ],
              ),
            ],
          ),
          trailing: IconButton(
              onPressed: () => _removeFromBasket(index), // Call the remove method with the index

              icon: const Icon(Icons.delete)),
        );
      },
    );
  }
  double _calculateTotalBalance() {
    double totalBalancewithoutinst = 0.0;

    for (var item in _basket) {
      totalBalancewithoutinst += item['total']; // Sum up the total of each item
    }

    setState(() {
      // installmentFee = totalBalancewithoutinst*0.30;
      _calculatedTotal = totalBalancewithoutinst;
    });
    return totalBalancewithoutinst;
  }
  int _getMonthsFromPlan(String plan) {
    switch (plan) {
      case '3 months':
        return 3;
      case '6 months':
        return 6;
      case '8 months':
        return 8;
      case '10 months':
        return 10;
      case '12 months':
        return 12;
      default:
        return 1; // Default to 1 month if no valid plan is selected
    }
  }
  RadioListTile<String> buildRadioButton(String value) {
    return RadioListTile<String>(
      title: Text(value),
      value: value,
      groupValue: selectedInstallmentPlan,
      onChanged: (String? newValue) {
        setState(() {
          selectedInstallmentPlan = newValue!;
          _calculateInstallmentAmount(); // Recalculate installment amount when plan changes

        });
      },
    );
  }
  Widget buildInstallmentRadioButtons() {
    return Column(
      children: [
        buildRadioButton('3 months'),
        buildRadioButton('6 months'),
        buildRadioButton('8 months'),
        buildRadioButton('10 months'),
        buildRadioButton('12 months'),
      ],
    );
  }
  void _calculateInstallmentAmount() {
    // Calculate the installment amount based on the selected plan
    int months = _getMonthsFromPlan(selectedInstallmentPlan);
    setState(() {
      installmentAmount = remainingAmount / months;
    });
  }
  Future<bool> _isCnicAlreadyPresent(String cnic) async {
    bool isCustomerPresent = false;
    bool isGuarantorPresent = false;

    // Query the customer node
    DatabaseEvent customerEvent = await FirebaseDatabase.instance
        .ref()
        .child('customer')
        .orderByChild('cnic')
        .equalTo(cnic)
        .once();  // Use `once()` which returns a `DatabaseEvent`

    if (customerEvent.snapshot.value != null) {
      isCustomerPresent = true;
    }

    // Query the guarantor node
    DatabaseEvent guarantorEvent = await FirebaseDatabase.instance
        .ref()
        .child('guarantor')
        .orderByChild('cnic')
        .equalTo(cnic)
        .once();  // Use `once()` which returns a `DatabaseEvent`

    if (guarantorEvent.snapshot.value != null) {
      isGuarantorPresent = true;
    }

    return isCustomerPresent || isGuarantorPresent;
  }


  void placeOrder() async {

    // Collecting data from the form
    String name = _userDetails?['name'] ?? '';
    String email = _userDetails?['email'] ?? '';
    String phone = _userDetails?['phone'] ?? '';
    String cnic = _cnicController.text.trim(); // Assuming you have a CNIC input field
    double downPayment = double.tryParse(_downPaymentController.text) ?? 0.0;
    final int currentRemainingInstallments = selectedInstallmentPlan.length;
    double totalBalance = _calculatedTotal;
    double installmentFee = (totalBalance * (installmentPercentage / 100)); // Calculate installment fee dynamically
    // Generate a unique order ID
    String orderId = _orderRef.push().key ?? 'unknown_order_id'; // Create an order ID using Firebase push

    // Assuming you have a method to get the current user's ID (userId)
    String userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown_user_id'; // Get current user's ID

    // Collecting guarantor details
    List<Map<String, dynamic>> guarantors = _guarantors.map((guarantor) {
      return {
        'name': guarantor['name'],
        'phone': guarantor['phone'],
        'cnic': guarantor['cnic'],
        'address': guarantor['address'],
      };
    }).toList();

    // Collecting basket items with the provided mapping structure
    List<Map<String, dynamic>> basketItems = _basket.map((item) {
      return {
        'item_name': item['item_name'],
        'quantity': item['quantity'],
        'net_rate': item['net_rate'],
        'total': item['total'],
        'image': item['image'],
        'category': item['category'],
      };
    }).toList();

    // Creating order data
    Map<String, dynamic> orderData = {
      'customer': {
        'name': name,
        'email': email,
        'phone': phone,
        'cnic': cnic,
      },
      'guarantors': guarantors,
      'items': basketItems, // Add basket items here
      'totalBalance': _calculateTotalBalance(),
      'installmentPercentage': installmentPercentage,
      'downPayment': downPayment,
      'remainingAmount': remainingAmount,
      'installmentPlan': selectedInstallmentPlan, // Assuming this variable exists
      'remaining_installments': currentRemainingInstallments,
      'installment_amount': installmentAmount,
      'payment_status': 'Partially Paid', // Set payment status
      'installment_fee': installmentFee,
      'total_balance_with_installment': totalBalance + installmentFee,
      'orderId': orderId, // Add orderId
      'userId': userId,   // Add userId
      'customer_cnic': cnic, // Add user's CNIC
      'guarantor_cnic': guarantors.map((g) => g['cnic']).toList(), // Add guarantors' CNICs
      'Date & Time' : DateTime.now().toIso8601String(),
      'status': 'Pending',
      'last_payment_date': DateTime.now().toIso8601String(),
    };

    // Save order to Firebase
    try {
      await _orderRef.child(orderId).set(orderData);

      // Optionally, save to customer and guarantor references
      await _customerRef.child(cnic).set({
        'name': name,
        'phone': phone,
        'email': email,
        'cnic': cnic,
        // Add other relevant fields here
      });

      for (var guarantor in guarantors) {
        await _guarantorRef.child(guarantor['cnic']).set(guarantor);
      }
// Clear the basket after placing the order
      _basket.clear(); // Clear local basket
      setState(() {}); // Update UI

      // Navigate to Orders List Page
      Navigator.pushReplacementNamed(context, '/admin');

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order placed successfully!")),
      );
    } catch (e) {
      // Handle any errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to place order: $e")),
      );
    }
  }



  @override

  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isLargeScreen = screenWidth > 600;
    double totalBalance = _calculatedTotal;
    double installmentFee = (totalBalance * (installmentPercentage / 100)); // Calculate installment fee dynamically


    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Taking"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _showGuarantorDialog,
            icon: const Icon(Icons.add),
          ),
          IconButton(
            onPressed: _showUserDetailsDialog, // Show the dialog on button press
            icon: const Icon(Icons.person),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text("User Details:", style: TextStyle(fontSize: 20)),
              ],
            ),
            if (_userDetails != null)
              ListTile(
                title: Text(_userDetails!['name'] ?? ''),
                subtitle: Text(
                  'Email: ${_userDetails!['email']}\nPhone: ${_userDetails!['phone']}\nCNIC: ${_userDetails!['cnic']}',
                ),
              ),
            const SizedBox(height: 20),
            const Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text("Guarantors", style: TextStyle(fontSize: 20)),
              ],
            ),
            ..._guarantors.map((guarantor) {
              return ListTile(
                title: Text(guarantor['name'] ?? ''),
                subtitle: Text(
                  'Phone: ${guarantor['phone']}\nCNIC: ${guarantor['cnic']}\nAddress: ${guarantor['address']}',
                ),
              );
            }).toList(),
            const SizedBox(height: 20),
            const Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  "Items Info",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            _buildSearchField(isLargeScreen),

            if (_selectedItem != null)
              _buildItemDetails(isLargeScreen),

            const Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text("Basket Items", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
            _buildBasketList(),

            Text(
              'Total Balance: \Pkr ${_calculateTotalBalance().toStringAsFixed(0)}', // Display total balance
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _percentageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Enter Installment Percentage (%)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    installmentPercentage = double.tryParse(value) ?? 0;
                    _calculateTotalWithInstallment();
                  });
                },
              ),
            ),
            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Table(
                border: TableBorder.all(),
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(1),
                },
                children: [
                  TableRow(
                    children: [
                      const TableCell(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Sub Balance:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('${_calculatedTotal} rs', style: const TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      const TableCell(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Installment Fee %:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('${installmentFee} rs', style: const TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      const TableCell(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Total Balance:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      TableCell(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('${totalbalancewithinstallment.toStringAsFixed(0)} rs', style: const TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("You can add any down payment amount."),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                controller: _downPaymentController,
                decoration: InputDecoration(
                  labelText: 'Down Payment',
                  border: const OutlineInputBorder(),
                  errorText: _downPaymentError,
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  double downPayment = double.tryParse(value) ?? 0;

                  // Optionally, ensure the down payment does not exceed the total amount with fees
                  double maxDownPayment = totalBalance + installmentFee;
                  if (downPayment > maxDownPayment) {
                    _downPaymentController.text = maxDownPayment.toStringAsFixed(2);
                    downPayment = maxDownPayment;
                  }

                  // Calculate the remaining amount
                  setState(() {
                    remainingAmount = (totalBalance + installmentFee) - downPayment;
                    _calculateInstallmentAmount();
                  });
                },
              ),
            ),

            const SizedBox(height: 10),
            Text('Remaining Amount: ${remainingAmount.toStringAsFixed(2)} rs', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),

            const Text('Choose Installment Plan:', style: TextStyle(fontSize: 18)),
            buildInstallmentRadioButtons(),
            const SizedBox(height: 20),

            Text("Total Installment Amount is: ${installmentAmount.toStringAsFixed(0)}",
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton (
              onPressed: (){
                placeOrder();
              },
              // onPressed: () async {
              //   if(_formKey.currentState?.validate() == true){
              //     String cnic = _cnicController.text.trim();
              //
              //     int? remainingInstallments = await _getRemainingInstallments(cnic);
              //
              //     if (remainingInstallments != null) {
              //       if (remainingInstallments == 0) {
              //          placeOrder(); // Allow the order to be placed
              //       } else {
              //         ScaffoldMessenger.of(context).showSnackBar(
              //             SnackBar(content: Text("User has remaining installments: $remainingInstallments. Cannot place a new order."))
              //         );
              //       }
              //     } else {
              //       // If user does not exist, allow the new order to be placed
              //        placeOrder();
              //     }
              //   }
              // },

              child: const Text('Place Order'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFe6b67e), // Button color
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),

          ],
        ),
      ),
    );
  }


  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // Dispose controllers
    _nameController.dispose();
    _emailController.dispose();
    _cnicController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _guarantor1NameController.dispose();
    _guarantor1AddressController.dispose();
    _guarantor1CnicController.dispose();
    _guarantor1PhoneController.dispose();
    _guarantor2NameController.dispose();
    _guarantor2AddressController.dispose();
    _guarantor2CnicController.dispose();
    _guarantor2PhoneController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _guarantor1NameController.clear();
    _guarantor1PhoneController.clear();
    _guarantor1AddressController.clear();
    _guarantor1CnicController.clear();
    _guarantor2NameController.clear();
    _guarantor2PhoneController.clear();
    _guarantor2AddressController.clear();
    _guarantor2CnicController.clear();
  }
}


class UserDetailsPage extends StatelessWidget {
  final String cnic;
  final List<Map<String, dynamic>> previousOrders;
  final Function() onSave; // Callback for saving details

  const UserDetailsPage({
    Key? key,
    required this.cnic,
    required this.previousOrders,
    required this.onSave, // Accepting the onSave function

  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "This user is already present in the database. Below are the previous order details:",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            previousOrders.isNotEmpty
                ? Expanded(
              child: ListView.builder(
                itemCount: previousOrders.length,
                itemBuilder: (context, index) {
                  var order = previousOrders[index];
                  var items = order['items'] ?? [];
                  var orderId = order['orderId'] ?? 'N/A';
                  var orderDateTime = order['Date & Time'] ?? 'N/A';
                  var remainingInstallment = order['remaining_installments'] ?? 'N/A';

                  return ExpansionTile(
                    title: Text('Order ID: $orderId'),
                    subtitle: Column(
                      crossAxisAlignment:CrossAxisAlignment.start,
                      children: [
                        Text('Order Date & Time: $orderDateTime'),
                        Text("Remaining Installments: $remainingInstallment"),
                      ],
                    ),
                    children: [
                      items.isNotEmpty
                          ? Column(
                        children: items.map<Widget>((item) {
                          return ListTile(
                            title: Text('Item: ${item['item_name']}'),
                            subtitle: Text('Quantity: ${item['quantity']}, Price: ${item['net_rate']}'),
                          );
                        }).toList(),
                      )
                          : const Text('No items found for this order.'),
                    ],
                  );
                },
              ),
            )
                : const Text('No previous orders found.'),
            const SizedBox(height: 16), // Add some spacing before the button
            ElevatedButton(
              onPressed: onSave, // Call the onSave function when pressed
              child: const Text('Save Details'),
            ),
          ],
        ),
      ),
    );
  }
}
