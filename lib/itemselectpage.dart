  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:firebase_database/firebase_database.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter_rating_bar/flutter_rating_bar.dart';
  import 'package:google_fonts/google_fonts.dart';

  import 'cartitems.dart';
  import 'clintfront.dart';
import 'components.dart';
import 'loginpage.dart';
import 'models/cartmodel.dart';

  class ItemSelectPage extends StatefulWidget {
    final String itemId;
    final String adminId;
    final String item_name;
    final String imageUrl;
    final String category;
    final String item_qty;
    final String net_rate;
    final String barcode;
    final String ptc_code;
    final String unit;
    final String description;

    const ItemSelectPage({
      Key? key,
      required this.imageUrl,
      required this.category,
      required this.net_rate,
      required this.item_qty,
      required this.unit,
      required this.ptc_code,
      required this.barcode,
      required this.description,
      required this.itemId,
      required this.adminId,
      required this.item_name,
    }) : super(key: key);

    @override
    _ItemSelectPageState createState() => _ItemSelectPageState();
  }

  class _ItemSelectPageState extends State<ItemSelectPage> {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final DatabaseReference cartRef = FirebaseDatabase.instance.ref("cart");
    final DatabaseReference _ratingRef = FirebaseDatabase.instance.ref("Feedback");
    final DatabaseReference _adminRef = FirebaseDatabase.instance.ref("admin");
    final DatabaseReference _usersRef = FirebaseDatabase.instance.ref("users");
    final DatabaseReference _ridersRef = FirebaseDatabase.instance.ref("riders");
    bool _isAddingToCart = false;
    List<dynamic> feedback = [];
    Map<String, dynamic> userData = {};
    int quantity = 0;
    int _cartItemCount = 0;
    int currentQty = 0;



    @override
    void initState() {
      super.initState();
      currentQty = int.parse(widget.item_qty); // Initialize currentQty with item_qty
    }

    Future<double> fetchRating(String itemId) async {
      try {
        double addrating = 0;
        final snapshot = await _ratingRef.orderByChild('itemId').equalTo(itemId).get();
        if (snapshot.exists) {
          final dataSnapshot = snapshot.value as Map<dynamic, dynamic>;
          feedback.clear(); // Clear the previous feedback before adding new

          dataSnapshot.forEach((key, value) {
            addrating += double.parse(value['rating'].toString());
            feedback.add({
              'userId': value['userId'],
              'rating': value['rating'],
              'feedback': value['feedback'],
              'timestamp': value['timestamp']
            });
          });

          return addrating / dataSnapshot.length;
        } else {
          return 0;
        }
      } catch (e) {
        print('Error fetching feedback: $e');
        return 0;
      }
    }

    Future<void> loadUserDetails() async {
      Map<String, dynamic> fetchedUserData = {};
      if (feedback.isNotEmpty) {
        for (var node in feedback) {
          final userId = node['userId'];

          // Fetch from 'admin' node
          final adminSnapshot = await _adminRef.child(userId).get();
          if (adminSnapshot.exists) {
            final adminData = adminSnapshot.value;
            if (adminData is Map<Object?, Object?>) {
              fetchedUserData[userId] = Map<String, dynamic>.from(adminData);
              continue;
            }
          }

          // Fetch from 'users' node
          final userSnapshot = await _usersRef.child(userId).get();
          if (userSnapshot.exists) {
            final userDataMap = userSnapshot.value;
            if (userDataMap is Map<Object?, Object?>) {
              fetchedUserData[userId] = Map<String, dynamic>.from(userDataMap);
              continue;
            }
          }
        }

        setState(() {
          userData = fetchedUserData;
        });
      }
    }

    Future<void> showFeedbackDialog(String itemId) async {
      showDialog(
        context: context,
        builder: (context) {
          double rating = 0.0;
          TextEditingController feedbackController = TextEditingController();

          return AlertDialog(
            title: const Text('Rate this Item'),
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
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final feedback = feedbackController.text;
                  await saveFeedback(itemId, rating, feedback);
                  Navigator.pop(context);
                },
                child: const Text('Submit'),
              ),
            ],
          );
        },
      );
    }

    Future<void> saveFeedback(String itemId, double rating, String userFeedback) async {
      final feedbackData = {
        'itemId': itemId,
        'rating': rating,
        'feedback': userFeedback,
        'timestamp': DateTime.now().toIso8601String(),
        'userId': currentUser!.uid
      };

      await _ratingRef.push().set(feedbackData);

      setState(() {
        // Trigger UI refresh after submitting feedback
        feedback.add(feedbackData); // Now this refers to the class-level feedback list
      });
    }


    @override
    Widget build(BuildContext context) {
      double rating = 3.0; // Default rating

      return Scaffold(
        appBar: AppBar(
          title: Text(widget.item_name, style: GoogleFonts.lora(
            fontSize: 25,
            color: Colors.white,
            fontWeight: FontWeight.bold,)),
          backgroundColor:const Color(0xFFe6b67e),
          centerTitle: true,
          automaticallyImplyLeading: false,
          leading: IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const FrontPage()));
            },
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      image: DecorationImage(image: NetworkImage(widget.imageUrl),
                      fit: BoxFit.fitHeight,
                      ),

                    ),
                  ),
                  Text(widget.item_name,style: GoogleFonts.lora(
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                    ),
                  ),const SizedBox(height: 10),
                  Text("Rs: ${widget.net_rate}",style: GoogleFonts.lora(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    ),
                  ),const SizedBox(height: 10),
                  Text("${widget.category} Item",style: GoogleFonts.lora(
                    fontSize: 25,
                  ),
                  ),const SizedBox(height: 10),
                  Text(widget.description,style: GoogleFonts.lora(
                    fontSize: 20,
                  ),
                  ),const SizedBox(height: 10),

                  Text("Available Quantity: $currentQty ${widget.unit}", style: GoogleFonts.lora(
                    fontSize: 20,
                  )
                  ), const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      if (currentUser == null) {
                        // User is not logged in
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Login Required'),
                              content: const Text('You must be logged in to rate this item.'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          },
                        );
                      } else {
                        // User is logged in, show feedback dialog
                        showFeedbackDialog(widget.itemId);
                      }
                    },
                    child: const Text('Rate Item'),
                  ),
                  FutureBuilder<double>(
                    future: fetchRating(widget.itemId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.active) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else {
                        rating = snapshot.data ?? 0.0;
                        if(feedback.isNotEmpty){
                          loadUserDetails();
                        }
                        return Column(
                          children: [
                            Text("Rating Stars",style: GoogleFonts.lora(fontSize: 30,fontWeight: FontWeight.bold,color:const Color(0xFFE0A45E) )),
                            Card(
                              shape: BeveledRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                side: const BorderSide(
                                  color: Color(0xFFE0A45E),
                                  width: 1.0,
                                ),
                              ),
                              elevation: 10,
                              child: ListTile(

                                title: Center(
                                  child: RatingBar.builder(
                                    ignoreGestures: true,
                                    initialRating: rating,
                                    minRating: 1,
                                    direction: Axis.horizontal,
                                    allowHalfRating: true,
                                    itemCount: 5,
                                    itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                                    itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                                    onRatingUpdate: (rating) {},
                                  ),
                                ),
                              ),
                            ),
                            Text("Feed Back",style: GoogleFonts.lora(fontSize: 30,fontWeight: FontWeight.bold,color:const Color(0xFFE0A45E) )),
                            if (feedback.isNotEmpty)
                              Column(
                                children: feedback.map((feedbackItem) {
                                  final userId = feedbackItem['userId'];
                                  final user = userData[userId];
                                  return Card(
                                    shape: BeveledRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                      side: const BorderSide(
                                        color: Color(0xFFE0A45E),
                                        width: 2.0,
                                      ),
                                    ),
                                    elevation: 10,
                                    child: ListTile(
                                      title: Text("Feedback: ${feedbackItem['feedback'] ?? 'No feedback'}",style: const TextStyle(fontSize: 20),),
                                      subtitle: user != null
                                          ? Text(
                                        "User: ${user['name'] ?? 'Unknown User'}\nRating: ${feedbackItem['rating'] != null ? feedbackItem['rating'] : 'No Rating'}\nDate & Time: ${feedbackItem['timestamp']}",
                                        style: const TextStyle(fontSize: 15),
                                      )
                                          : Text(
                                        "Rating: ${feedbackItem['rating'] != null ? feedbackItem['rating'].toStringAsFixed(1) : 'No Rating'}\nDate & Time: ${feedbackItem['timestamp']}",
                                      ),


                                    ),
                                  );
                                }).toList(),
                              ),
                          ],
                        );
                      }
                    },
                  ),


              ],
              ),
            ),
          ),
        ),
      );
    }
  }
