import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'Installmentpages/installement_firstpage.dart';
import 'cartitems.dart';
import 'components.dart';
import 'orderslist.dart';

class CheckoutPage extends StatefulWidget {
  @override
  _CheckoutPageState createState() => _CheckoutPageState ();
}

class _CheckoutPageState extends State<CheckoutPage> with SingleTickerProviderStateMixin{
  final DatabaseReference _userRef = FirebaseDatabase.instance.ref("users");
  final DatabaseReference _cartRef = FirebaseDatabase.instance.ref("cart");
  final DatabaseReference _adminRef = FirebaseDatabase.instance.ref("admin");
  final DatabaseReference _ordersRef = FirebaseDatabase.instance.ref("orders");
  final DatabaseReference _feedbackRef = FirebaseDatabase.instance.ref("Feedback");
  bool _isButtonDisabled = false; // Flag to disable the button after it's pressed
  Map<String, dynamic>? cartItems;
  Map<String, dynamic>? userDetails;
  String userRole = '';
  String selectedPaymentMethod = 'Cash'; // Default selected payment method
  double totalBalance = 0.0;
  late User currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser!;
    fetchUserDataAndCartItems();
  }

  Future<void> fetchUserDataAndCartItems() async {
        try {
          // Assuming the currentUser is already available
          final currentUser = FirebaseAuth.instance.currentUser!;
          final userId = currentUser.uid;

          // Fetching user role
          final adminSnapshot = await _adminRef.child(userId).once();
          final userSnapshot = await _userRef.child(userId).once();

          if (adminSnapshot.snapshot.exists) {
            userRole = 'Admin';
            userDetails = Map<String, dynamic>.from(adminSnapshot.snapshot.value as Map);
          } else if (userSnapshot.snapshot.exists) {
            userRole = 'User';
            userDetails = Map<String, dynamic>.from(userSnapshot.snapshot.value as Map);
          }

          // Fetching cart items
          final cartSnapshot = await _cartRef.child(userId).once();
          if (cartSnapshot.snapshot.exists) {
            cartItems = Map<String, dynamic>.from(cartSnapshot.snapshot.value as Map);

            // Calculate total balance
            cartItems!.forEach((key, item) {
              final sale_rate = double.tryParse(item['sale_rate'] as String? ?? '0') ?? 0;
              final quantity = item['quantity'] as int? ?? 0;
              totalBalance += sale_rate * quantity;
            });
          }

          setState(() {});
        } catch (e) {
          print('Error fetching user data or cart items: $e');
        }
      }

  void handlePaymentSelection(String method) {
    setState(() {
      selectedPaymentMethod = method;
    });
  }

  Future<String> placeOrder() async {
    String newOrderId = _ordersRef.push().key.toString();
    try {
      // Calculate the total balance (subtotal)
      double subtotal = totalBalance;

      // Create a new order
      final newOrder = {
        'orderId': newOrderId,
        'items': cartItems,
        'userId': FirebaseAuth.instance.currentUser!.uid,
        'subtotal': subtotal,
        'total': subtotal, // Since there are no delivery charges, total = subtotal
        'status': 'Pending',
        'payment_status': selectedPaymentMethod == 'Cash' ? 'Pending' : 'installment', // Set payment status
        'orderDate': DateTime.now().toIso8601String(),
      };

      // Add the new order to Firebase
      await _ordersRef.child(newOrderId).set(newOrder);

      // Optionally, clear the cart after placing the order
      await _cartRef.child(FirebaseAuth.instance.currentUser!.uid).remove();

      if (selectedPaymentMethod == 'Cash') {
        // Show feedback dialog after placing the order (if needed)
        await showFeedbackDialog(newOrderId);
      }

      return newOrderId;
    } catch (error) {
      throw Exception("Error placing order: $error");
    }
  }

  Future<void> showFeedbackDialog(String orderId) async {
    showDialog(
      context: context,
      builder: (context) {
        double rating = 0.0;
        TextEditingController feedbackController = TextEditingController();

        return AlertDialog(
          title: const Text('Rate your items'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RatingBar.builder(
                initialRating: 0,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (newRating) {
                  rating = newRating;
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: feedbackController,
                decoration: const InputDecoration(hintText: 'Leave your feedback'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => CustomerOrdersPage(comingFromCheckoutPage: true)),
                      (route) => false,
                );
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final feedback = feedbackController.text;
                await saveFeedback(orderId, rating, feedback,currentUser.uid);
                Navigator.of(context).pop();

                // Navigate to CustomerOrdersPage after feedback
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => CustomerOrdersPage(comingFromCheckoutPage: true)),
                      (route) => false,
                );
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Future<void> saveFeedback(String orderId, double rating, String feedback,String userId) async {
    if (cartItems != null) {
      cartItems!.forEach((key, item) async {
        final itemId = item['itemId'];
        final adminId = item['adminId'] as String? ?? 'unknownAdminId';
        final feedbackData = {
          'orderId': orderId,
          'itemId': itemId,
          'adminId': adminId,
          'rating': rating,
          'feedback': feedback,
          'timestamp': DateTime.now().toIso8601String(),
          'userId': userId
        };

        await _feedbackRef.push().set(feedbackData);
      });
    }
    else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No cart items found to provide feedback on.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar.customAppBar("Checkout",
          IconButton(onPressed: (){
            Navigator.push(context, MaterialPageRoute(builder: (context)=>CartPage()));

          }, icon: const Icon(Icons.arrow_back))
      ),
      body: cartItems != null && userDetails != null
          ? SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile Information:',
                style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ListTile(
                title: Text("Role: $userRole", style: GoogleFonts.lora(fontSize: 18)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Name: ${userDetails!['name']}", style: GoogleFonts.lora(fontSize: 16)),
                    Text("Phone: ${userDetails!['phone']}", style: GoogleFonts.lora(fontSize: 16)),
                    Text("CNIC: ${userDetails!['cnic']}", style: GoogleFonts.lora(fontSize: 16)),
                    Text("Address: ${userDetails!['address']}", style: GoogleFonts.lora(fontSize: 16)),
                    Text("Zip Code: ${userDetails!['zip_code']}", style: GoogleFonts.lora(fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Cart Items:',
                style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: cartItems!.length,
                itemBuilder: (context, index) {
                  final item = cartItems!.values.elementAt(index);
                  final name = item['name'] ?? 'No Name';
                  final imageUrl = item['imageUrl'] as String? ?? '';
                  final category = item['category'] as String? ?? 'No Category';
                  final description = item['description'] as String? ?? 'No description';
                  final quantity = item['quantity'] ?? 0;
                  final saleRate = item['sale_rate'] ?? '0';

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(imageUrl),
                      ),
                      title: Text("$name", style: GoogleFonts.lora(fontSize: 18)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Quantity: $quantity", style: GoogleFonts.lora(fontSize: 16)),
                          Text("Category: $category", style: GoogleFonts.lora(fontSize: 14)),
                          Text("Description: $description", style: GoogleFonts.lora(fontSize: 14)),
                          Text("Rate: Rs. $saleRate", style: GoogleFonts.lora(fontSize: 16)),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Text("Select Payment Method", style: GoogleFonts.lora(fontSize: 22, fontWeight: FontWeight.bold)),
              RadioListTile<String>(
                title: const Text('Cash on Delivery'),
                value: 'Cash',
                groupValue: selectedPaymentMethod,
                onChanged: (String? value) {
                  setState(() {
                    selectedPaymentMethod = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Installments'),
                value: 'installment',
                groupValue: selectedPaymentMethod,
                onChanged: (String? value) {
                  setState(() {
                    selectedPaymentMethod = value!;
                  });
                },
              ),


              const SizedBox(height: 20),
              Text("Total Balance: Rs. ${totalBalance.toStringAsFixed(2)}",
                  style: GoogleFonts.lora(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _isButtonDisabled
                      ? null // Disable the button if `_isButtonDisabled` is true
                      : () async {
                    setState(() {
                      _isButtonDisabled = true; // Disable the button to prevent multiple presses
                    });

                    try {
                      if (selectedPaymentMethod == 'installment') {
                        // Generate the order and pass `newOrderId` to `firstpage`
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (context) => InstallmentPage(
                        //        totalBalance, // Pass newOrderId here
                        //       // placeOrder: () async {
                        //       //   await placeOrder(); // Ensure `placeOrder` is awaited
                        //       // },
                        //     //     fetchUserDataAndCartItems: async{
                        //     //     await fetchUserDataAndCartItems();
                        //     // }
                        //
                        //     ),
                        //   ),
                        // );
                      } else {
                        await placeOrder(); // Ensure `placeOrder` is awaited
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error processing order: $e")));
                    } finally {
                      setState(() {
                        _isButtonDisabled = false; // Re-enable the button if an error occurs or action completes
                      });
                    }
                  },
                  child: const Text("Complete Checkout", style: NewCustomTextStyles.newcustomTextStyle),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFFe6b67e),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ),
            ],
          ),
        ),
      ): const Center(child: CircularProgressIndicator()),
    );
  }
}

