import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'adminpanel.dart';
import 'ordersmanagement/requestforcancel.dart';
import 'ordersmanagement/requestforreturn.dart';


class OrderManagementPage extends StatefulWidget {
  @override
  _OrderManagementPageState createState() => _OrderManagementPageState();
}

class _OrderManagementPageState extends State<OrderManagementPage> {
  final DatabaseReference _ordersRef = FirebaseDatabase.instance.ref("orders");
  final DatabaseReference _installmentOrdersRef = FirebaseDatabase.instance.ref("Installment_Orders");

  List<Map<String, dynamic>> standardOrders = [];
  List<Map<String, dynamic>> installmentOrders = [];
  int _currentIndex = 1;

  String _selectedStatus = 'All';
  String _selectedRequestFilter = 'All';
  final List<String> statusOptions = ['All', 'Pending', 'Processing','Completed'];
  final List<String> requestFilterOptions = ['All', 'With Request', 'Without Request'];

  @override
  void initState() {
    super.initState();
    fetchInstallmentOrders();
    fetchOverdueOrders(); // Fetch overdue orders

  }

  Future<void> fetchInstallmentOrders() async {
    try {
      final snapshot = await _installmentOrdersRef.once();
      List<Map<String, dynamic>> fetchedOrders = [];

      if (snapshot.snapshot.value != null) {
        final Map installmentOrdersMap = snapshot.snapshot.value as Map;
        fetchedOrders = installmentOrdersMap.entries.map((entry) => Map<String, dynamic>.from(entry.value)).toList();
      }

      setState(() {
        installmentOrders = fetchedOrders;
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> updateInstallmentOrderStatus(String orderId, String status) async {
    try {
      await _installmentOrdersRef.child(orderId).update({'status': status});
      fetchInstallmentOrders(); // Refresh the installment order list
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Installment order status updated!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error updating installment order status: $e")));
    }
  }

  Future<void> cancelOrder(String orderId, {bool isInstallment = false}) async {
    try {
      DatabaseReference ref = isInstallment ? _installmentOrdersRef.child(orderId) : _ordersRef.child(orderId);
      await ref.update({
        'status': 'Cancelled',
        'cancelledBy': 'Admin', // or 'Buyer' depending on the context
      });

      if (isInstallment) {
        fetchInstallmentOrders(); // Refresh the installment order list
      } else {
        const Text('no orders found');
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order canceled!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error canceling order: $e")));
    }
  }

  void _showInstallmentOrderDetails(Map<String, dynamic> order) async {
    final userDetails = order['user_info'];

    final double installmentAmount = (order['installment_amount'] is int)
        ? (order['installment_amount'] as int).toDouble()
        : order['installment_amount'] ?? 0.0;

    final double totalBalance = (order['totalBalance'] is int)
        ? (order['totalBalance'] as int).toDouble()
        : order['totalBalance'] ?? 0.0;

    final double remainingAmount = (order['remainingAmount'] is int)
        ? (order['remainingAmount'] as int).toDouble()
        : order['remainingAmount'] ?? 0.0;

    // Check if installmentAmount is valid to avoid division by zero
    if (installmentAmount <= 0) {
      // Handle the error appropriately, e.g., set remainingInstallments to 0 or show a message
      print("Error: Installment amount is zero or negative.");
      return; // Exit the method early or set a default value
    }

    // Calculate remaining installments
    // final int remainingInstallments = (remainingAmount / installmentAmount).ceil();
    // if (remainingInstallments.isNaN || remainingInstallments.isInfinite) {
    //   // Handle this situation appropriately
    //   print("Error: Remaining installments calculation resulted in an invalid number.");
    //   return;
    // }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.brown[50],
          title: Text(
            "Order ID: ${order['orderId']}",
            style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown[800]),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (userDetails != null) ...[
                  Text("Name: ${userDetails['name'] ?? 'N/A'}", style: GoogleFonts.lora(fontSize: 16)),
                  Text("Address: ${userDetails['address'] ?? 'N/A'}", style: GoogleFonts.lora(fontSize: 16)),
                  Text("Phone No: ${userDetails['phone'] ?? 'N/A'}", style: GoogleFonts.lora(fontSize: 16)),
                  Text("Zip Code: ${userDetails['zip_code'] ?? 'N/A'}", style: GoogleFonts.lora(fontSize: 16)),
                  const SizedBox(height: 10),
                ],
                Text("Total without Installment Charges: Rs. ${totalBalance.toStringAsFixed(0) ?? '0.00'}", style: GoogleFonts.lora(fontSize: 12)),
                Text("Installment Charges: Rs. ${order['installment_fee']?.toStringAsFixed(0) ?? 'N/A'}", style: GoogleFonts.lora(fontSize: 12)),
                Text("Total with Installment Charges: Rs. ${order['total_balance_with_installment']?.toStringAsFixed(0) ?? '0.00'}", style: GoogleFonts.lora(fontSize: 12)),
                Text("Advance Amount: Rs. ${order['downPayment'] ?? 'N/A'}", style: GoogleFonts.lora(fontSize: 16)),
                Text("Remaining Amount: Rs. ${remainingAmount.toStringAsFixed(0) ?? 'N/A'}", style: GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.bold)),
                Text("Remaining Installments: ${order['remaining_installments'] ?? 'N/A'}", style: GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.bold)),
                Text("Installment Plan: ${order['installmentPlan'] ?? 'N/A'}", style: GoogleFonts.lora(fontSize: 16)),
                Text("Monthly Installment: Rs. ${order['installment_amount']?.toStringAsFixed(0) ?? 'N/A'}", style: GoogleFonts.lora(fontSize: 16)),
                Text("Date: ${order['Date & Time'] ?? 'N/A'}", style: GoogleFonts.lora(fontSize: 16)),
                Text("Status: ${order['status'] ?? 'Pending'}", style: GoogleFonts.lora(fontSize: 16)),
                if (order.containsKey('cancellationRequest') && order['cancellationRequest'] != null)
                  Text("Cancellation Request Status: ${order['cancellationRequest']['status'] ?? 'Pending'}", style: GoogleFonts.lora(fontSize: 16, color: Colors.red)),
                const SizedBox(height: 10),
                Text("Order Items:", style: GoogleFonts.lora(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                if (order['items'] is List) ..._buildItemList(order['items'] as List),
                if (order['items'] is Map) ..._buildItemMap(order['items'] as Map),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.brown,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              ),
              child: Text('Close', style: GoogleFonts.lora(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildItemList(List<dynamic> items) {
    return items.map((item) {
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
          title: Text(item['item_name'] ?? 'N/A', style: GoogleFonts.lora(fontSize: 16, color: Colors.brown[800])),
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
    }).toList();
  }

  List<Widget> _buildItemMap(Map<dynamic, dynamic> items) {
    return items.entries.map((entry) {
      final item = entry.value;
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
          title: Text(item['name'] ?? 'N/A', style: GoogleFonts.lora(fontSize: 16, color: Colors.brown[800])),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Category: ${item['category'] ?? 'N/A'}", style: TextStyle(color: Colors.brown[600])),
              Text("Price: Rs. ${item['sale_rate'] ?? '0'}", style: TextStyle(color: Colors.brown[600])),
              Text("Quantity: ${item['quantity'] ?? '0'}", style: TextStyle(color: Colors.brown[600])),
            ],
          ),
        ),
      );
    }).toList();
  }

  Future<void> fetchOverdueOrders() async {
    try {
      final snapshot = await _installmentOrdersRef.once();
      List<Map<String, dynamic>> fetchedOrders = [];

      if (snapshot.snapshot.value != null) {
        final Map installmentOrdersMap = snapshot.snapshot.value as Map;
        for (var entry in installmentOrdersMap.entries) {
          final order = Map<String, dynamic>.from(entry.value);
          // Parse the last payment date
          DateTime lastPaymentDate = DateTime.parse(order['last_payment_date']);
          // Check if it's more than or equal to 4 hours
          if (DateTime.now().difference(lastPaymentDate).inDays >= 30) {
            fetchedOrders.add(order);
          }
        }
      }

      setState(() {
        standardOrders = fetchedOrders; // Store overdue orders in standardOrders
      });
    } catch (e) {
      // Handle error
      print("Error fetching overdue orders: $e"); // Optional: Log the error
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Management"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const Admin()));
          },
        ),
      ),
      body: _currentIndex == 0 ? buildOverdueOrdersList() : buildInstallmentOrdersList(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.list), label: "Pending Installment Orders"),
          const BottomNavigationBarItem(icon: Icon(Icons.credit_card), label: "Installment Orders"),
        ],
      ),
    );
  }


  Widget buildOverdueOrdersList() {
    return Expanded(
      child: standardOrders.isNotEmpty
          ? ListView.builder(
        itemCount: standardOrders.length,
        itemBuilder: (context, index) {
          final order = standardOrders[index];
          return buildInstallmentOrderCard(order); // Reuse the same card method
        },
      )
          : const Center(child: CircularProgressIndicator()),
    );
  }


  Widget buildInstallmentOrdersList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedStatus,
                  items: statusOptions.map((String status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status, style: TextStyle(color: getStatusColor(status))),
                    );
                  }).toList(),
                  onChanged: (String? newStatus) {
                    if (newStatus != null) {
                      setState(() {
                        _selectedStatus = newStatus;
                        fetchInstallmentOrders(); // Fetch orders based on selected status
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedRequestFilter,
                  items: requestFilterOptions.map((String filter) {
                    return DropdownMenuItem<String>(
                      value: filter,
                      child: Text(filter, style: const TextStyle(color: Colors.black)),
                    );
                  }).toList(),
                  onChanged: (String? newFilter) {
                    if (newFilter != null) {
                      setState(() {
                        _selectedRequestFilter = newFilter;
                        fetchInstallmentOrders();
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: installmentOrders.isNotEmpty
              ? ListView.builder(
            itemCount: installmentOrders.length,
            itemBuilder: (context, index) {
              final order = installmentOrders[index];
              return buildInstallmentOrderCard(order);
            },
          )
              : const Center(child: CircularProgressIndicator()),
        ),      ],
    );
  }


  Widget buildInstallmentOrderCard(Map<String, dynamic> order) {

    final hasCancellationRequest = order.containsKey('cancellationRequest') && order['cancellationRequest'] != null;
    final hasReturnRequest = order.containsKey('returnRequest') && order['returnRequest'] != null;
    final cancellationRequestStatus = hasCancellationRequest ? order['cancellationRequest']['status'] : null;

    return Stack(
      children: [
        Banner(
          message: order['status'] == 'Cancelled'
              ? 'Cancelled'
              : cancellationRequestStatus == 'Rejected'
              ? 'Request Rejected'
              : order['status'] == 'In Transit'
              ? 'In Transit'
              : order['status'] == 'Picked Up'
              ? 'Picked UP'
              : order['status'] == 'Completed'
              ? 'Completed'
              : order['status'] == 'Returned'
              ? 'Returned'
              : '',
          color: order['status'] == 'Cancelled'
              ? Colors.red
              : cancellationRequestStatus == 'Rejected'
              ? Colors.yellow
              : order['status'] == 'In Transit'
              ? Colors.orange
              : order['status'] == 'Picked Up'
              ? Colors.blue
              : order['status'] == 'Completed'
              ? Colors.green
              : order['status'] == 'Returned'
              ? Colors.red
              : Colors.transparent,
          location: BannerLocation.topEnd,
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              onTap: () {
                _showInstallmentOrderDetails(order);
              },
              title: Text(
                "Order ID: ${order['orderId']}",
                style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("User ID: ${order['userId']}", style: GoogleFonts.lora(fontSize: 14)),
                  Text("Total: Rs. ${order['total_balance_with_installment']}", style: GoogleFonts.lora(fontSize: 14)),
                  Text("Timestamp: ${order['Date & Time']}", style: GoogleFonts.lora(fontSize: 14)),
                  Text("Payment Status: ${order['payment_status']}", style: GoogleFonts.lora(fontSize: 18, color: Colors.green)),
                  if(order['status'] == 'Completed')
                    Text("Completed", style: GoogleFonts.lora(fontSize: 18, color: Colors.green)
                    ),
                  if (['Pending', 'Processing'].contains(order['status']))
                    Row(
                      children: [
                        Text("Status: ", style: GoogleFonts.lora(fontSize: 14)),
                        DropdownButton<String>(
                          value: statusOptions.contains(order['status']) ? order['status'] : statusOptions.first,
                          items: statusOptions.map((String status) {
                            return DropdownMenuItem<String>(
                              value: status,
                              child: Text(
                                status,
                                style: TextStyle(color: getStatusColor(status)),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newStatus) {
                            if (newStatus != null) {
                              updateInstallmentOrderStatus(order['orderId'], newStatus);
                            }
                          },
                        ),
                      ],
                    ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.cancel, color: Colors.red),
                onPressed: order['status'] != 'Cancelled' && order['status'] != 'Completed'
                    ? () => cancelOrder(order['orderId'])
                    : null,
              ),
            ),
          ),
        ),
        if (hasCancellationRequest)
          Positioned(
            bottom: 16,
            right: 16,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CancellationRequestsPage(orderId: order['orderId']),
                  ),
                );
              },
              child: const Text("Cancel Request Page", style: TextStyle(color: Colors.red)),
            ),
          ),
        if (hasReturnRequest)
          Positioned(
            bottom: 16,
            right: 20,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReturnRequestsPage(orderId: order['orderId']),
                  ),
                );
              },
              child: const Text("Return Request Page", style: TextStyle(color: Colors.red)),
            ),
          ),
      ],
    );
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.grey;
      case 'Processing':
        return Colors.amber;
      case 'Shipped':
        return Colors.purple;
      case 'Picked Up':
        return Colors.blue; // Color for Picked Up
      case 'In Transit':
        return Colors.orange; // Color for In Transit
      case 'Completed':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey; // Default color for unknown status
    }
  }


}