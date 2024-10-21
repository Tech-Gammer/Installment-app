import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'components.dart';
import 'itemselectpage.dart';

class totalitemspage extends StatefulWidget {
  String category;

  totalitemspage(this.category);

  @override
  State<totalitemspage> createState() => _totalitemspageState();
}

class _totalitemspageState extends State<totalitemspage> {
  String searchQuery = '';
  List<dynamic> CategoryData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final DatabaseReference itemsRef = FirebaseDatabase.instance.ref('items');

    try {
      final snapshot = await itemsRef.get();
      if (snapshot.exists) {
        final items = snapshot.value as Map<dynamic, dynamic>;
        List<dynamic> itemsd = [];
        itemsd = items.values.toList();
        for (var i = 0; i < itemsd.length; i++) {
          if (itemsd[i]['category'].toString() == widget.category) {
            CategoryData.add(itemsd[i]);
          }
        }
      }
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        isLoading = false; // Data is loaded
      });
    }
  }

  Widget buildCategorySection() {
    final screenWidth = MediaQuery.of(context).size.width;

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Number of items per row
        childAspectRatio:
            0.75, // Adjust this to control the aspect ratio of the items
        crossAxisSpacing: 8.0, // Space between columns
        mainAxisSpacing: 8.0, // Space between rows
      ),
      shrinkWrap: true, // Make sure GridView doesn't take infinite height
      physics: NeverScrollableScrollPhysics(), // Disable inner scrolling
      itemCount: CategoryData.length,
      itemBuilder: (context, index) {
        final imageUrl = CategoryData[index]['image'];
        final category = CategoryData[index]['category'];
        final item_name = CategoryData[index]['item_name'] as String? ?? 'No Name';
        final net_rate = CategoryData[index]['net_rate']?.toString() ?? 'No net_rate';
        final item_qty = CategoryData[index]['item_qty']?.toString() ?? 'No item_qty';
        final unit = CategoryData[index]['unit']?.toString() ?? 'No unit';
        final ptc_code = CategoryData[index]['ptc_code']?.toString() ?? 'No ptc_code';
        final barcode = CategoryData[index]['barcode']?.toString() ?? 'No barcode';
        final description = CategoryData[index]['description']?.toString() ?? 'No description';
        final adminId = CategoryData[index]['adminId']?.toString() ?? 'No adminId';


        // final itemId = CategoryData[index]['itemId']; // Use barcode or any unique field
        final itemId = CategoryData[index]['itemId'] ?? 'unknownItemId';  // Handle potential missing fields

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ItemSelectPage(
                      imageUrl: imageUrl,
                      category: category,
                      net_rate: net_rate,
                      item_qty: item_qty,
                      unit: unit,
                      ptc_code: ptc_code,
                      barcode: barcode,
                      description: description,
                      itemId: itemId,
                      adminId: adminId,
                      item_name: item_name
                  )
              ),
            );
          },
          child: Card(
            elevation: 5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: screenWidth * 0.35, // diameter
                  height: screenWidth * 0.35, // diameter
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
                  CategoryData[index]['item_name'].toString(),
                  style: GoogleFonts.lora(
                    textStyle: TextStyle(
                      fontSize: screenWidth * 0.045,
                      color: Colors.brown,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                ),
                Text("Rs ${CategoryData[index]['net_rate']}"),
                Text(
                  "Quantity ${CategoryData[index]['item_qty']} ${CategoryData[index]['unit']}",
                  style: GoogleFonts.lora(
                    textStyle: TextStyle(
                      fontSize: screenWidth * 0.035,
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar.customAppBar(
          widget.category,
          IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back))),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(children: [buildCategorySection()]),
            ),
    );
  }
}
