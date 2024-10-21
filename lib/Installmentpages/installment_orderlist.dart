import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import '../clintfront.dart';
import '../components.dart';
import '../paymentfiles/firstpage.dart';

class InstallmentOrdersPage extends StatefulWidget {
  final bool comingFromInstallmentPage;

  InstallmentOrdersPage({required this.comingFromInstallmentPage});

  @override
  _InstallmentOrdersPageState createState() => _InstallmentOrdersPageState();
}

class _InstallmentOrdersPageState extends State<InstallmentOrdersPage> {
  final DatabaseReference _installmentOrdersRef = FirebaseDatabase.instance.ref("Installment_Orders");
  bool _isLoading = false; // Add this variable

  late User currentUser;
  List<Map<String, dynamic>> installmentOrders = [];

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser!;
    fetchInstallmentOrders();
  }


  void fetchInstallmentOrders() async {
    setState(() {
      _isLoading = true; // Start loading indicator
    });

    try {
      String? customerCnic;

      // Fetch the current user's CNIC from both `users` and `admin` nodes
      final DatabaseReference usersRef = FirebaseDatabase.instance.ref("users");
      final DatabaseReference adminRef = FirebaseDatabase.instance.ref("admin");

      // Query the 'users' node for the current user based on their FirebaseAuth UID
      final userSnapshot = await usersRef.child(currentUser.uid).get();
      if (userSnapshot.exists && userSnapshot.child("cnic").value != null) {
        customerCnic = userSnapshot.child("cnic").value.toString();
      }
        print(customerCnic);
      // If not found in `users`, query the 'admin' node
      if (customerCnic == null) {
        final adminSnapshot = await adminRef.child(currentUser.uid).get();
        if (adminSnapshot.exists && adminSnapshot.child("cnic").value != null) {
          customerCnic = adminSnapshot.child("cnic").value.toString();
        }
      }

      // If customer CNIC is still null, return as no data can be fetched
      if (customerCnic == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("CNIC not found for the current user.")));
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Fetch installment orders based on the customer CNIC from the "Installment_Orders" node
      final ordersSnapshot = await _installmentOrdersRef
          .orderByChild("customer_cnic")
          .equalTo(customerCnic)
          .get();

      if (ordersSnapshot.exists) {
        final ordersData = Map<String, dynamic>.from(ordersSnapshot.value as Map);
        final fetchedOrders = ordersData.entries.map((entry) {
          return {
            ...Map<String, dynamic>.from(entry.value as Map),
            'orderId': entry.key, // Adding orderId to the map
          };
        }).toList();

        setState(() {
          installmentOrders = fetchedOrders;
        });
      } else {
        setState(() {
          installmentOrders = [];
        });
      }
    } catch (e) {
      print("Error fetching installment orders: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to fetch installment orders.")));
    } finally {
      setState(() {
        _isLoading = false; // Stop loading indicator
      });
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.grey;
      case 'Processing':
        return Colors.amber;
      case 'Completed':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget buildInstallmentItemCard(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(8.0),
        leading: item['image'] != null
            ? Image.network(
          item['image'],
          width: 60,
          height: 60,
          fit: BoxFit.cover,
        )
            : Icon(Icons.image_not_supported, size: 60, color: Colors.brown[300]),
        title: Text("Name: ${item['item_name'] ?? 'N/A'}", style: GoogleFonts.lora(fontSize: 16, color: Colors.brown[800])),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Category: ${item['category'] ?? 'N/A'}", style: TextStyle(color: Colors.brown[600])),
            Text("Price: Rs. ${item['net_rate'] ?? '0'}", style: TextStyle(color: Colors.brown[600])),
            Text("Quantity: ${item['quantity'] ?? '0'}", style: TextStyle(color: Colors.brown[600])),
          ],
        ),
      ),
    );
  }

  void _showInstallmentOrderDetails(Map<String, dynamic> order) {
    final double installmentAmount = (order['installment_amount'] is int)
        ? (order['installment_amount'] as int).toDouble()
        : order['installment_amount'] ?? 0.0;

    final double totalBalance = (order['totalBalance'] is int)
        ? (order['totalBalance'] as int).toDouble()
        : order['totalBalance'] ?? 0.0;

    final double remainingAmount = (order['remainingAmount'] is int)
        ? (order['remainingAmount'] as int).toDouble()
        : order['remainingAmount'] ?? 0.0;

    // Calculate remaining installments
    final int remainingInstallments = (installmentAmount > 0)
        ? (remainingAmount / installmentAmount).ceil()
        : 0; // Prevent division by zero

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.brown[50],
          title: Text("Installment Order Details:", style: GoogleFonts.lora(fontSize: 22, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Total without Installment Charges: Rs. ${totalBalance.toStringAsFixed(0)}", style: GoogleFonts.lora(fontSize: 12)),
                Text("Installment Charges: Rs. ${order['installment_fee'] ?? 'N/A'}", style: GoogleFonts.lora(fontSize: 12)),
                Text("Total with Installment Charges: Rs. ${order['total_balance_with_installment']?.toStringAsFixed(0) ?? '0.00'}", style: GoogleFonts.lora(fontSize: 12)),
                Text("Advance Amount: Rs. ${order['downPayment'] ?? 'N/A'}", style: GoogleFonts.lora(fontSize: 16)),
                Text("Remaining Amount: Rs. ${remainingAmount.toStringAsFixed(0)}", style: GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.bold)),
                Text("Remaining Installments: $remainingInstallments", style: GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.bold)),
                Text("Installment Plan: ${order['installmentPlan'] ?? 'N/A'}", style: GoogleFonts.lora(fontSize: 16)),
                Text("Monthly Installment: Rs. ${installmentAmount.toStringAsFixed(0)}", style: GoogleFonts.lora(fontSize: 16)),
                Text("Date: ${order['Date & Time'] ?? 'N/A'}", style: GoogleFonts.lora(fontSize: 16)),
                Text("Status: ${order['status'] ?? 'Pending'}", style: GoogleFonts.lora(fontSize: 16)),
                const SizedBox(height: 10),
                Text("Order Items:", style: GoogleFonts.lora(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                // Check if 'items' is a List and build item cards accordingly
                if (order['items'] is List)
                  ...((order['items'] as List).map((item) => buildInstallmentItemCard(Map<String, dynamic>.from(item))).toList()),
                if (order['items'] is Map)
                  ...((order['items'] as Map).entries.map((entry) {
                    final item = entry.value;
                    return buildInstallmentItemCard(Map<String, dynamic>.from(item));
                  }).toList()),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Simply close the dialog
              },
              child: Text('Close', style: GoogleFonts.lora(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  void _payInstallment(Map<String, dynamic> order) async {
    // Ensure that you convert the installment amount and remaining amount to double
    final double installmentAmount = (order['installment_amount'] is int)
        ? (order['installment_amount'] as int).toDouble()
        : order['installment_amount'] ?? 0.0;

    final double remainingAmount = (order['remainingAmount'] is int)
        ? (order['remainingAmount'] as int).toDouble()
        : order['remainingAmount'] ?? 0.0;

    final int currentRemainingInstallments = (remainingAmount / installmentAmount).ceil();
    final String orderId = order['orderId'];

    if (remainingAmount <= 0) {
      // Handle case where no remaining amount
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No remaining amount to pay.")));
      return;
    }
    setState(() {
      _isLoading = true; // Start loading
    });

    // Logic to deduct the installment amount
    try {
      // Update the database
      await _installmentOrdersRef.child(orderId).update({
        'remainingAmount': remainingAmount - installmentAmount,
        'last_payment_date': DateTime.now().toIso8601String(),
        'remaining_installments': currentRemainingInstallments > 1 ? currentRemainingInstallments - 1 : 0, // Decrease the remaining installments
      });

      // Refresh the orders after payment
      fetchInstallmentOrders();

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Installment paid successfully!")));
    } catch (e) {
      print('Error paying installment: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to pay installment.")));
    }finally {
      setState(() {
        _isLoading = false; // Stop loading
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Installment Orders', style: NewCustomTextStyles.newcustomTextStyle),
        backgroundColor: const Color(0xFFe6b67e),
        centerTitle: true,
        automaticallyImplyLeading: !widget.comingFromInstallmentPage,
        leading: widget.comingFromInstallmentPage
            ? null
            : IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Go back to previous screen
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loading indicator
          : installmentOrders.isNotEmpty
          ? ListView.builder(
        itemCount: installmentOrders.length,
        itemBuilder: (context, index) {
          final order = installmentOrders[index];
          final orderId = order['orderId'] as String? ?? 'Unknown';
          final total = (order['remainingAmount'] is int) ? (order['remainingAmount'] as int).toDouble() : order['remainingAmount'] as double? ?? 0.0;
          final status = order['status'] as String? ?? 'Pending';
          final timestamp = order['Date & Time'] as String? ?? '';
          final double installmentAmount = (order['installment_amount'] is int)
              ? (order['installment_amount'] as int).toDouble()
              : order['installment_amount'] ?? 0.0;

          final double remainingAmount = (order['remainingAmount'] is int)
              ? (order['remainingAmount'] as int).toDouble()
              : order['remainingAmount'] ?? 0.0;

          // Calculate remaining installments
          final int remainingInstallments = (remainingAmount / installmentAmount).ceil();
          final String? lastPaymentDate = order['last_payment_date'] as String?;

          return Card(
            margin: const EdgeInsets.all(10.0),
            child: ListTile(
              title: Text("Installment Order", style: GoogleFonts.lora(fontSize: 22, fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("OrderId: $orderId", style: GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text("Amount: $total", style: GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('Status: $status', style: GoogleFonts.lora(fontSize: 16, color: getStatusColor(status))),
                  Text("Remaining Installments: $remainingInstallments", style: GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('Date: $timestamp', style: GoogleFonts.lora(fontSize: 16)),
                  if (lastPaymentDate != null)
                    Text('Last Payment Date: ${DateTime.parse(lastPaymentDate).toLocal().toString().split(' ')[0]}', style: GoogleFonts.lora(fontSize: 16)), // Format as needed
                  if (remainingInstallments == 0) // Show banner if all installments are paid
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      color: Colors.green[100],
                      child: Text("All installments have been paid!", style: GoogleFonts.lora(fontWeight: FontWeight.bold, color: Colors.green)),
                    ),
                ],
              ),
              trailing: remainingInstallments > 0 // Show payment button only if installments remain
                  ? IconButton(
                icon: const Icon(Icons.attach_money, color: Colors.green),
                onPressed: () {
                  _payInstallment(order);
                },
              )
                  : null,
              onTap: () {
                _showInstallmentOrderDetails(order);
              },
            ),
          );
        },
      )
          : const Center(child: Text("No Installment Orders Found")),
      floatingActionButton: widget.comingFromInstallmentPage
          ? FloatingActionButton(
        onPressed: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const FrontPage()),
                (Route<dynamic> route) => false,
          );
        },
        backgroundColor: const Color(0xFFe6b67e),
        child: const Icon(Icons.home_sharp, color: Colors.white),
        tooltip: 'Go to Front Page',
      )
          : null,
    );
  }

}
