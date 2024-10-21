import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:installment_app/adminside/reportpage.dart';
import 'package:installment_app/adminside/showcategory.dart';
import 'package:installment_app/adminside/showslider.dart';
import 'package:installment_app/adminside/showunit.dart';
import 'package:installment_app/adminside/superadminpanel.dart';
import 'package:installment_app/adminside/takingOrderpage.dart';
import 'package:installment_app/clintfront.dart';
import '../loginpage.dart';
import 'itemslistpage.dart';
import 'notificatio_page.dart';
import 'ordermanagement.dart';


class Admin extends StatefulWidget {
  const Admin({super.key});

  @override
  State<Admin> createState() => _AdminState();
}

class _AdminState extends State<Admin> {
  GlobalKey<ScaffoldState> _globalKey = GlobalKey<ScaffoldState>();
  List<String> categories = [];
  List<String> units = [];
  List<String> items = [];
  List<String> sliderimages = [];
  List<Map<String, dynamic>> lowStockItems = [];
  int totalOrders = 0;
  int deliveredOrders = 0;
  String userRole = 'Loading...';
  String? adminNumber;
  late String adminId;


  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchUnits();
    fetchItems();
    fetchOrders();
    fetchUserRole();
    fetchSliderimages();
  }

  Future<void> _onRefresh() async {
    await fetchCategories();
    await fetchUnits();
    await fetchItems();
    await fetchOrders();
    await fetchUserRole();
    await fetchSliderimages();

    // You can also fetch delivered orders if needed
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()), // Navigate back to the Sign In page
            (Route<dynamic> route) => false, // Remove all previous routes
      );
    } catch (e) {
      // print("Error signing out: $e"); // Handle error if necessary
    }
  }

  Future<void> fetchCategories() async {
    try {
      final categoryRef = FirebaseDatabase.instance.ref("category");
      final snapshot = await categoryRef.once();

      if (snapshot.snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        List<String> fetchedCategories = data.values.map((value) => value['name'].toString()).toList();

        setState(() {
          categories = fetchedCategories;
        });
      } else {
        setState(() {
          categories = [];
        });
      }
    } catch (e) {
      // print('Error fetching categories: $e');
    }
  }

  Future<void> fetchUnits() async {
    try {
      final unitRef = FirebaseDatabase.instance.ref("unit");
      final snapshot = await unitRef.once();

      if (snapshot.snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        List<String> fetchedUnits = data.values.map((value) => value['name'].toString()).toList();

        setState(() {
          units = fetchedUnits;
        });
      } else {
        setState(() {
          units = [];
        });
      }
    } catch (e) {
      // print('Error fetching units: $e');
    }
  }

  Future<void> fetchSliderimages() async {
    try {
      final sliderimagesRef = FirebaseDatabase.instance.ref("slider images");
      final snapshot = await sliderimagesRef.once();

      if (snapshot.snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        List<String> fetchSliderimages = data.values.map((value) => value['image'].toString()).toList();

        setState(() {
          sliderimages = fetchSliderimages;
        });
      } else {
        setState(() {
          sliderimages = [];
        });
      }
    } catch (e) {
      // print('Error fetching units: $e');
    }
  }

  Future<void> fetchItems() async{
    final itemsRef = FirebaseDatabase.instance.ref("items");

    itemsRef.onValue.listen((event) {
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      List<String> fetchedItems = [];
      List<Map<String, dynamic>> fetchedLowStockItems = [];

      data.forEach((key, item) {
        final itemName = item['item_name'].toString();
        final quantity = int.tryParse(item['item_qty'].toString()) ?? 0;

        fetchedItems.add(itemName);

        // Check for low stock
        if (quantity < 10) {
          fetchedLowStockItems.add({
            'item_name': itemName,
            'item_qty': quantity,
          });
        }
      });

      setState(() {
        items = fetchedItems;
        lowStockItems = fetchedLowStockItems;
      });
    });
  }

  Future<void> fetchOrders() async {
    try {
      final installmentOrdersRef = FirebaseDatabase.instance.ref("Installment_Orders");

      // Fetch installment orders
      final installmentOrdersSnapshot = await installmentOrdersRef.once();
      int totalInstallmentOrders = 0;

      if (installmentOrdersSnapshot.snapshot.value != null) {
        final data = Map<String, dynamic>.from(installmentOrdersSnapshot.snapshot.value as Map);
        totalInstallmentOrders = data.length; // Count the total number of installment orders
        print("Total Installment Orders: $totalInstallmentOrders"); // Debug statement
      } else {
        print("No installment orders found."); // Debug statement
      }

      // Update the total orders count
      setState(() {
        totalOrders = totalInstallmentOrders; // Set total orders to the count of installment orders
      });

      print("Total Orders: $totalOrders"); // Debug statement
    } catch (e) {
      // Handle error
      print('Error fetching orders: $e');
    }
  }

  Future<void> fetchUserRole() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        setState(() {
          userRole = 'No User';
          adminNumber = 'Not Set';
        });
        return;
      }

      // Fetch the data from Firebase
      final userRef = FirebaseDatabase.instance.ref('admin/$userId');
      final snapshot = await userRef.get();

      // Ensure the snapshot exists and the value is not null
      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        final role = data['role'] ?? 'No Role';
        final fetchedAdminNumber = data['adminNumber']?.toString() ?? '0';  // Now adminNumber is String

        setState(() {
          userRole = role == '0' ? 'Admin' : 'User';
          adminNumber = fetchedAdminNumber;
        });
      } else {
        // If snapshot doesn't exist or is null
        setState(() {
          userRole = 'No Role';
          adminNumber = 'Not Set';
        });
      }
    } catch (e) {
      setState(() {
        userRole = 'Error';
        adminNumber = 'Error';
      });
      print('Error fetching user role: $e');
    }
  }




  Future<List<Map<String, dynamic>>> fetchDeliveredOrders() async {
    final List<Map<String, dynamic>> deliveredOrders = [];
    final DatabaseReference ordersRef = FirebaseDatabase.instance.ref('orders');

    try {
      final snapshot = await ordersRef.orderByChild('orderStatus').equalTo('delivered').get();
      if (snapshot.exists) {
        final orders = snapshot.value as Map<dynamic, dynamic>;
        for (var orderId in orders.keys) {
          final orderData = orders[orderId] as Map<dynamic, dynamic>;
          deliveredOrders.add(orderData.cast<String, dynamic>());
        }
      }
    } catch (e) {
      // print('Error fetching delivered orders: $e');
    }

    return deliveredOrders;
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    final int? adminNumberInt = int.tryParse(adminNumber ?? '');

    // Get the width of the screen
    double screenWidth = MediaQuery.of(context).size.width;

    // Define the number of columns based on screen width
    int crossAxisCount = screenWidth > 1200
        ? 6 // For larger screens like laptops
        : screenWidth > 800
        ? 4 // For tablet-sized screens
        : 3; // For smaller screens like phones

    return SafeArea(
      child: Scaffold(
        key: _globalKey,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: SizedBox(
              width: 100,
              height: 50,
              child: Image.asset('images/logomain.png')
          ),
          centerTitle: true,
        ),
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          child: Column(
            children: [
              Text("Role: $userRole"),
              Text("Admin Number: $adminNumber" ),
              Expanded(
                child: GridView.count(
                  crossAxisCount: crossAxisCount, // Responsive column count
                  children: [
                    DashboardCard(
                      title: "Categories",
                      icon: Icons.category,
                      count: categories.length.toString(),
                      onTap: () {
                         Navigator.push(context, MaterialPageRoute(builder: (context) => const ShowCategory()));
                      },
                    ),
                    DashboardCard(
                      title: "Units",
                      icon: Icons.ac_unit,
                      count: units.length.toString(),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ShowUnit()));
                      },
                    ),
                    DashboardCard(
                      title: "Orders",
                      icon: Icons.shopping_cart,
                      count: totalOrders.toString(),
                      onTap: () {
                         Navigator.push(context, MaterialPageRoute(builder: (context) => OrderManagementPage()));
                      },
                    ),
                    DashboardCard(
                      title: "Items",
                      icon: Icons.list,
                      count: items.length.toString(),
                      onTap: () {
                         Navigator.push(context, MaterialPageRoute(builder: (context) => ItemsPage()));
                      },
                    ),
                    DashboardCard(
                      title: "Reports",
                      icon: Icons.report,
                      count: deliveredOrders.toString(),
                      onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => ReportSummaryPage()),);
                      },
                    ),
                    DashboardCard(
                      title: "Slider",
                      icon: Icons.point_of_sale_outlined,
                      count: sliderimages.length.toString(),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const SliderImages()));

                      },
                    ),
                    DashboardCard(
                      title: "Low Stock",
                      icon: Icons.warning,
                      count: lowStockItems.length.toString(),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NotificationsPage(lowStockItems: lowStockItems),
                          ),
                        );
                      },
                    ),
                    InkWell(
                      onTap: (){
                        Navigator.push(context, MaterialPageRoute(builder: (context) =>  OrderTaking()));

                      },
                      child: Card(
                        margin: const EdgeInsets.all(10),
                        elevation: 5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(height: 8),
                            Center(child: Text("Installment\n-Orders", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),

                          ],
                        ),
                      ),
                    ),
                    InkWell(
                  onTap: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const FrontPage()));
                  },
                  child: Card(
                    margin: const EdgeInsets.all(10),
                    elevation: 5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.storefront, size: 30, color: Color(0xFFe6b67e)),
                        SizedBox(height: 8),
                        Text("Front Side", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),

                      ],
                    ),
                  ),
                ),
                    if (adminNumberInt == 1)
                    InkWell(
                      onTap: (){
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SuperAdminPanel(),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.all(10),
                        elevation: 5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(Icons.admin_panel_settings_outlined, size: 30, color: Color(0xFFe6b67e)),
                            SizedBox(height: 8),
                            Text("Super", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              FloatingActionButton(
                  child: const Icon(Icons.logout,color: Colors.white,),
                  backgroundColor: const Color(0xFFE0A45E),
                  onPressed: (){
                    _logout();
                  }

              )
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String count;
  final VoidCallback onTap;


  DashboardCard({
    required this.title,
    required this.icon,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.all(10),
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 30, color: const Color(0xFFe6b67e)),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),

    );
  }
}



