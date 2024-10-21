import 'package:carousel_slider_plus/carousel_slider_plus.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:installment_app/userprofile.dart';
import 'adminside/adminpanel.dart';
import 'drawerfrontside.dart';
import 'Installmentpages/installment_orderlist.dart';
import 'itemselectpage.dart';
import 'itemslistpage.dart';
import 'loginpage.dart';


class FrontPage extends StatefulWidget {
  const FrontPage({super.key});

  @override
  _FrontPageState createState() => _FrontPageState();
}

class _FrontPageState extends State<FrontPage> {
  GlobalKey<ScaffoldState> _globalKey = GlobalKey<ScaffoldState>();
  final DatabaseReference _ratingRef = FirebaseDatabase.instance.ref("Feedback");
  final DatabaseReference _cartRef = FirebaseDatabase.instance.ref("cart");
  final DatabaseReference _sliderRef = FirebaseDatabase.instance.ref("slider images");
  final DatabaseReference _installmentOrdersRef = FirebaseDatabase.instance.ref("installmentOrders");
  final FirebaseAuth auth = FirebaseAuth.instance;
  final CarouselSliderController _slidercontroller = CarouselSliderController();
  final TextEditingController _controller = TextEditingController();
  Map<String, dynamic>? data;
  int _cartItemCount = 0;
  User? currentUser;
  List<String> sliderImages = [];
  bool _isLoading = true;
  bool? _isAdmin;
  String searchQuery = '';
  int _currentIndex = 0;
  List<Map<String, dynamic>> installmentOrders = [];
  List<String> categories = []; // Add more categories here
  List<String> Tech = [];
  bool _isDialogShowing = false;  // Track if a dialog is already shown
  int? _role;
  @override
  void dispose() {
    _controller.dispose();
    categories.clear();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    fetchData();
    fetchSliderImages();
    currentUser = FirebaseAuth.instance.currentUser;
    fetchCartItemCount();
    fetchUserRole();
    fetchUserdata();
  }

  Future<void> _onRefresh() async {
    currentUser = FirebaseAuth.instance.currentUser;
    await fetchCartItemCount();
    await fetchInstallmentOrders();
    await fetchSliderImages();
    await fetchUserRole();
    await fetchUserdata();
    await fetchData();

    // You can also fetch delivered orders if needed
  }


  Future<void> fetchUserdata() async {
    final currentUser = this.currentUser;
    if (currentUser != null) {
      try {
        final userRef = FirebaseDatabase.instance.ref("users/${currentUser.uid}");
        final snapshot = await userRef.child("role").get();

        if (snapshot.exists) {
          setState(() {
            _role = int.parse(snapshot.value.toString());
          });
        } else {
          // If the role is not found in the users node, check in the admin node
          final adminRef = FirebaseDatabase.instance.ref("admin/${currentUser.uid}");
          final adminSnapshot = await adminRef.child("role").get();

          if (adminSnapshot.exists) {
            setState(() {
              _role = int.parse(adminSnapshot.value.toString());
            });
          } else {
            // If the role is not found in the admin node, check in the riders node
            final riderRef = FirebaseDatabase.instance.ref("riders/${currentUser.uid}");
            final riderSnapshot = await riderRef.child("role").get();

            if (riderSnapshot.exists) {
              setState(() {
                _role = int.parse(riderSnapshot.value.toString());
              });
            } else {
              // Handle case where role is not found in any node
              print("User role not found in any node.");
            }
          }
        }
      } catch (e) {
        print('Error fetching user role: $e');
      }
    }
  }


  Future<double> fetchRating(String itemId) async {
    try {
      double addrating = 0;
      double? avgRating;
      final snapshot = await _ratingRef.orderByChild('itemId').equalTo(itemId).get();
      if (snapshot.exists) {
        final Map<String, dynamic> allData = {};
        final dataSnapshot = snapshot.value as Map;
        List<dynamic> itemList = [];
        itemList = dataSnapshot.values.toList();

        for (int i = 0; i < itemList.length; i++) {
          addrating += double.parse(itemList[i]['rating'].toString());
        }

        avgRating = (addrating / itemList.length);

        // print(avgRating);
        return avgRating;
      } else {
        return 0;
      }
    } catch (e) {
      // print('Error fetching data: $e');
      return 0;
    }
  }

  Future<void> fetchUserRole() async {
    final currentUser = this.currentUser;
    if (currentUser != null) {
      try {
        final userRef = FirebaseDatabase.instance.ref("users/${currentUser.uid}");
        final snapshot = await userRef.child("role").get();

        if (snapshot.exists) {
          final int role = int.parse(snapshot.value.toString());
          setState(() {
            _isAdmin = (role == 0); // Assuming 0 indicates admin
          });
        } else {
          final adminRef = FirebaseDatabase.instance.ref("admin/${currentUser.uid}");
          final adminSnapshot = await adminRef.child("role").get();

          if (adminSnapshot.exists) {
            final int role = int.parse(adminSnapshot.value.toString());
            setState(() {
              _isAdmin = (role == 0); // Assuming 0 indicates admin
            });
          } else {
            // print("User role not found in both nodes.");
          }
        }
      } catch (e) {
        // print('Error fetching user role: $e');
      }
    }
  }

  Future<Map<String, dynamic>> fetchData() async {
    final Map<String, dynamic> itemsMap = {};
    final DatabaseReference itemsRef = FirebaseDatabase.instance.ref('items');

    try {
      final snapshot = await itemsRef.get();
      if (snapshot.exists) {
        final items = snapshot.value as Map<dynamic, dynamic>;
        for (var itemId in items.keys) {
          final itemData = items[itemId] as Map<dynamic, dynamic>;
          Tech.add(itemData['category'].toString());
          final itemDataString = {
            'item_name': itemData['item_name']?.toString() ?? 'No Name',
            'category': itemData['category']?.toString() ?? 'No Category',
            'net_rate': itemData['net_rate']?.toString() ?? 'No Rate',
            'item_qty': itemData['item_qty']?.toString() ?? 'No Quantity',
            'unit': itemData['unit']?.toString() ?? 'No unit',
            'ptc_code': itemData['ptc_code']?.toString() ?? 'No Rate',
            'barcode': itemData['barcode']?.toString() ?? 'No Rate',
            'description': itemData['description']?.toString() ?? 'No description',
            'image': itemData['image']?.toString() ?? '',
            'adminId': itemData['adminId']?.toString() ?? '',
          };
          itemsMap[itemId] = itemDataString;
        }
        Tech = Tech.toSet().toList();
        categories = Tech.reversed.toList();



      }
    } catch (e) {
      // print('Error fetching data: $e');
    }

    return itemsMap;
  }

  Future<void> fetchSliderImages() async {
    try {
      final snapshot = await _sliderRef.get();
      if (snapshot.exists) {
        final images = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          sliderImages = images.values.map((value) => value['image'] as String).toList();
        });
      }
    } catch (e) {
      // print('Error fetching slider images: $e');
    } finally {
      _checkIfLoadingComplete();
    }
  }

  Future<void> fetchCartItemCount() async {
    if (currentUser != null) {
      try {
        String userId = currentUser!.uid;
        final userCartRef = _cartRef.child(userId); // Reference to the current user's cart
        final snapshot = await userCartRef.once(); // Get all cart items for the user

        if (snapshot.snapshot.exists) {
          final cartItems = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
          setState(() {
            _cartItemCount = cartItems.length; // Number of items in the cart
          });
        } else {
          setState(() {
            _cartItemCount = 0; // No items in the cart
          });
        }
      } catch (e) {
        // print('Error fetching cart item count: $e');
      }
    }
  }

  void _checkIfLoadingComplete() {
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
      });
    });
  }

  Future<void> signOut() async {
    await auth.signOut().then((value) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    });
  }

  void _filterItems(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
    });
  }

  Future<void> fetchInstallmentOrders() async {
    try {
      final snapshot = await _installmentOrdersRef.once();
      if (snapshot.snapshot.value != null) {
        final allOrders = (snapshot.snapshot.value as Map<dynamic, dynamic>).values
            .map((order) => Map<String, dynamic>.from(order as Map))
            .toList();

        setState(() {
          installmentOrders = allOrders.where((order) {
            final userId = order['userId'] as String?;
            final adminId = order['adminId'] as String?;
            return userId == currentUser?.uid || adminId == currentUser?.uid;
          }).toList();

          installmentOrders.sort((a, b) {
            final timestampA = a['timestamp'] as String?;
            final timestampB = b['timestamp'] as String?;

            final dateTimeA = DateTime.tryParse(timestampA ?? '') ?? DateTime(1970);
            final dateTimeB = DateTime.tryParse(timestampB ?? '') ?? DateTime(1970);
            return dateTimeB.compareTo(dateTimeA); // Newest first
          });

          // Check for payment deadlines
          for (var order in installmentOrders) {
            final lastPaymentDateString = order['last_payment_date'] as String?;
            if (lastPaymentDateString != null) {
              final lastPaymentDate = DateTime.parse(lastPaymentDateString);
              final difference = DateTime.now().difference(lastPaymentDate).inDays;

              if (difference >= 30 && difference < 35) {
                // Show warning
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text("There are only ${35 - difference} days left to pay the installment."),
                  duration: const Duration(seconds: 3),
                ));
              } else if (difference >= 35) {
                // Block new orders and show a red flag
                // (Implement your logic to block new orders here)
                AppBar(
                  title: const Text('Pending Installments', style: TextStyle(color: Colors.red)),
                  backgroundColor: Colors.yellow,
                );
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Pending installments! Please pay the amount."),
                  duration: Duration(seconds: 3),
                  backgroundColor: Colors.red,
                ));
              }
            }
          }
        });
      }
    } catch (e) {
      // print('Error fetching installment orders: $e');
    }
  }

  Widget buildCategorySection(String category) {
    // Return an empty container if the category is null or empty
    if (category.isEmpty || category.toLowerCase() == 'null') {
      return SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: screenWidth * 0.02,
        horizontal: screenWidth * 0.02,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$category:',
                style: GoogleFonts.lora(
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => totalitemspage(category),
                    ),
                  );
                },
                child: const Text(
                  "Shop More",
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
          FutureBuilder<Map<String, dynamic>>(
            future: fetchData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.active) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error fetching data: ${snapshot.error}'));
              } else if (snapshot.hasData) {
                final Map<String, dynamic> itemsMap = snapshot.data!;
                final filteredItems = itemsMap.entries.where((entry) {
                  final item = entry.value;
                  final itemNameMatches = item['item_name'].toString().toLowerCase().contains(searchQuery.toLowerCase());
                  final categoryMatches = item['category'].toString().toLowerCase().contains(searchQuery.toLowerCase());
                  return (itemNameMatches || categoryMatches) && (item['category'] == category);
                }).toList();

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = constraints.maxWidth;

                    // Define breakpoints for responsiveness
                    int crossAxisCount;
                    double childAspectRatio;
                    double imageSize;
                    double fontSize;
                    double quantityFontSize;

                    if (screenWidth >= 1200) {
                      // For large screens like laptops or desktops
                      crossAxisCount = 6;
                      childAspectRatio = 0.71;
                      imageSize = screenWidth * 0.09;  // Large screen image size
                      fontSize = screenWidth * 0.02;
                      quantityFontSize = screenWidth * 0.015;
                    } else if (screenWidth >= 1100) {
                      crossAxisCount = 5;
                      childAspectRatio = 0.75;
                      imageSize = screenWidth * 0.09;
                      fontSize = screenWidth * 0.019;
                      quantityFontSize = screenWidth * 0.014;
                    } else if (screenWidth >= 800) {
                      crossAxisCount = 4;
                      childAspectRatio = 0.75;
                      imageSize = screenWidth * 0.12;  // Medium screen image size
                      fontSize = screenWidth * 0.018;
                      quantityFontSize = screenWidth * 0.013;
                    } else if (screenWidth >= 600) {
                      crossAxisCount = 3;
                      childAspectRatio = 0.8;
                      imageSize = screenWidth * 0.15;  // Smaller screen image size
                      fontSize = screenWidth * 0.017;
                      quantityFontSize = screenWidth * 0.012;
                    } else {
                      // For mobile screens
                      crossAxisCount = 2;
                      childAspectRatio = 0.8;
                      imageSize = screenWidth * 0.3;  // Mobile screen image size
                      fontSize = screenWidth * 0.05;
                      quantityFontSize = screenWidth * 0.035;
                    }

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.all(screenWidth * 0.02),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: screenWidth * 0.02,
                        mainAxisSpacing: screenWidth * 0.02,
                        childAspectRatio: childAspectRatio,
                      ),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index].value;
                        final imageUrl = item['image'] as String?;
                        final item_name = item['item_name'] as String? ?? 'No Name';
                        final itemId = filteredItems[index].key;

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ItemSelectPage(
                                  item_name: item_name,
                                  imageUrl: imageUrl!,
                                  category: category,
                                  item_qty: item['item_qty'],
                                  net_rate: item['net_rate'],
                                  description: item['description'],
                                  itemId: itemId,
                                  unit: item['unit'],
                                  adminId: item['adminId'],
                                  barcode: item['barcode'],
                                  ptc_code: item['ptc_code'],
                                ),
                              ),
                            );
                          },
                          child: Card(
                            elevation: 5,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: imageSize,
                                  height: imageSize,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: NetworkImage(imageUrl ?? ''),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  item_name,
                                  style: GoogleFonts.lora(
                                    textStyle: TextStyle(
                                      fontSize: fontSize,
                                      color: Colors.brown,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                ),
                                Text("Rs ${item['net_rate']}"),
                                Text(
                                  "Quantity ${item['item_qty']} ${item['unit']}",
                                  style: GoogleFonts.lora(
                                    textStyle: TextStyle(
                                      fontSize: quantityFontSize,
                                      color: Colors.brown,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
        ],
      ),
    );
  }

  void _getLastPaymentDate(BuildContext context) async {
    final DatabaseReference databaseRef = FirebaseDatabase.instance.ref();

    try {
      // Fetching the list of all orders under Installment_Orders
      final DatabaseEvent event = await databaseRef.child('Installment_Orders').once();
      final DataSnapshot snapshot = event.snapshot;

      if (snapshot.value != null) {
        // Iterate over each child node (each order)
        Map<String, dynamic> orders = Map<String, dynamic>.from(snapshot.value as Map);
        for (var entry in orders.entries) {
          String orderId = entry.key;
          Map<String, dynamic> orderData = Map<String, dynamic>.from(entry.value);

          // Check if `last_payment_date` exists for this order
          if (orderData.containsKey('last_payment_date')) {
            String lastPaymentDateStr = orderData['last_payment_date'].toString();
            DateTime lastPaymentDate = DateTime.parse(lastPaymentDateStr);

            DateTime currentDate = DateTime.now();
            // Check if more than 30 days have passed since the last payment
            if (currentDate.difference(lastPaymentDate).inDays > 30) { // Change inDays for 30-day check
              // Check if no other dialog is already showing
              if (!_isDialogShowing) {
                _isDialogShowing = true;  // Set the flag to true when showing the dialog
                _showPaymentAlert(context);
              }
            }
          }
        }
      }
    } catch (e) {
      print("Error fetching last payment date: $e");
    }
  }

  void _showPaymentAlert(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // User cannot dismiss by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Payment Alert'),
          content: const Text(
              'It has been more than 30 days since your last payment. Please make a payment to avoid penalties.'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.pop(context);  // Close the dialog
                _isDialogShowing = false;  // Reset the flag when dialog is closed
              },
            ),
          ],
        );
      },
    );
  }


  @override

  Widget build(BuildContext context) {

    final isSearching = searchQuery.isNotEmpty;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

// Ensure the method is called after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getLastPaymentDate(context);  // Call after frame build
    });

    return SafeArea(
      child: Scaffold(
        key: _globalKey,
         // drawer: const Drawerfrontside(),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: currentUser != null && _role == 0
              ? IconButton(
            onPressed: () {
              // Handle the button press for admin role
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Admin())
              );
            },
            icon: Icon(Icons.admin_panel_settings),
          ) : null,
          title: SizedBox(
            width: screenWidth * 0.15, // Adjusted width based on screen size
            height: screenHeight * 0.1, // Adjusted height based on screen size
            child: Image.asset("images/logomain.png"),
          ),
          centerTitle: true,
          actions: [
            PopupMenuButton(
              icon: currentUser == null
                  ? const Icon(Icons.login)
                  : const Icon(Icons.person_rounded),
              itemBuilder: (BuildContext context) {
                return [
                  if (currentUser != null)
                    PopupMenuItem(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfile()));
                      },
                      child: const Row(
                        children: [
                          Icon(Icons.person),
                          Text("       Profile"),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    onTap: () {
                      if (currentUser == null) {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
                      } else {
                        signOut();
                      }
                    },
                    child: Row(
                      children: [
                        Icon(currentUser == null ? Icons.login : Icons.logout),
                        Text(currentUser == null ? "       Log In" : "       Log Out"),
                      ],
                    ),
                  ),
                  if (currentUser != null)
                    PopupMenuItem(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => InstallmentOrdersPage(
                                  comingFromInstallmentPage: false,
                                )));
                      },
                      child: const Row(
                        children: [
                          Icon(Icons.shopping_cart),
                          Text("       Installment Orders"),
                        ],
                      ),
                    ),
                ];
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          child: _isLoading
              ? CustomLoader()
              : SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 6),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.025), // Responsive padding
                  child: SizedBox(
                    height: screenHeight * 0.06, // Responsive height
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () {
                            _filterItems(_controller.text);
                          },
                        ),
                        hintText: 'Search',
                        filled: true,
                        fillColor: const Color(0xFFe6b67e).withOpacity(0.2),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFe6b67e)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFe6b67e)),
                        ),
                      ),
                      onChanged: _filterItems,
                    ),
                  ),
                ),

                Visibility(
                  visible: !isSearching,
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Stack(
                        children: [
                          InkWell(
                            onTap: () {
                              // print(_currentIndex);
                            },
                            child: CarouselSlider(
                              items: sliderImages
                                  .map((imageUrl) => Image.network(
                                imageUrl,
                                // fit: BoxFit.fitHeight,
                                fit: BoxFit.contain, // Change from BoxFit.fitHeight to BoxFit.contain
                                  width: double.infinity,

                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.image_not_supported, size: 300);
                                },
                              ))
                                  .toList(),
                              controller: _slidercontroller,
                              options: CarouselOptions(
                                scrollPhysics: const BouncingScrollPhysics(),
                                autoPlay: true,

                                aspectRatio: 3.5,
                                viewportFraction: 1,
                                onPageChanged: (index, reason) {
                                  setState(() {
                                    _currentIndex = index;
                                  });
                                },
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: sliderImages.asMap().entries.map((entry) {
                                return GestureDetector(
                                  onTap: () => _slidercontroller.animateToPage(entry.key),
                                  child: Container(
                                    width: _currentIndex == entry.key ? screenWidth * 0.045 : screenWidth * 0.018, // Responsive width
                                    height: screenHeight * 0.01, // Responsive height
                                    margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.008), // Responsive margin
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: _currentIndex == entry.key ? Colors.brown : Colors.grey,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "We Provide",
                        style: GoogleFonts.berkshireSwash(
                          fontSize: screenWidth * 0.04, // Responsive font size
                          color: Colors.brown,
                        ),
                      ),
                      Text(
                        "New & Used Items",
                        style: GoogleFonts.berkshireSwash(
                          fontSize: screenWidth * 0.04, // Responsive font size
                          color: Colors.brown,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: EdgeInsets.all(screenWidth * 0.02), // Responsive padding
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildCategoryIcon(Icons.computer, "Electronics", "sweets"),
                                SizedBox(width: screenWidth * 0.04), // Responsive spacing
                                _buildCategoryIcon(Icons.bed, "Furniture", "Furniture"),
                                SizedBox(width: screenWidth * 0.04),
                                _buildCategoryIcon(Icons.laptop, "House Hold", "House Hold"),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Available Items",
                        style: GoogleFonts.berkshireSwash(
                          fontSize: screenWidth * 0.04, // Responsive font size
                          color: Colors.brown,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
                Column(
                  children: categories.map(buildCategorySection).toList(),
                ),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildCategoryIcon(IconData icon, String label, String category) {
    return GestureDetector(
      onTap: () {
        // Navigator.push(context, MaterialPageRoute(builder: (context) => const ItemListPage(uid: 'uid')));
      },
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFe6b67e),
            radius: 30,
            child: Icon(icon, size: 30, color: Colors.brown),
          ),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            "UMAIR   TRADERS",
            style: GoogleFonts.lora(
              textStyle: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 100,
            child: Image.asset('images/logomain.png'), // Replace with your logo asset
          ),
          const SizedBox(height: 10),
          Text(
            "There are all types of electronic good and furniture goods present",
            textAlign: TextAlign.center,
            style: GoogleFonts.lora(
              textStyle: const TextStyle(fontSize: 16, color: Colors.brown),
            ),
          ),
          const SizedBox(height: 10),
          // _buildSocialMediaLinks(),
        ],
      ),
    );
  }
}

class CustomLoader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 110,  // Adjust size as needed
        height: 110, // Adjust size as needed
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Logo image positioned above the loader
            Positioned(
              top: 0,
              child: Image.asset(
                'images/logomain.png', // Replace with your logo asset path
                width: 70,  // Adjust size as needed
                height: 70, // Adjust size as needed
              ),
            ),
            // Loader positioned below the logo
            const Positioned(
              bottom: 0,
              child: CircularProgressIndicator(
                strokeWidth: 8.0,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
              ),
            ),
          ],
        ),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}


