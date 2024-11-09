import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../components.dart';
import 'additems.dart';
import 'adminpanel.dart'; // Import your AddItem page here

class ItemsPage extends StatefulWidget {
  @override
  _ItemsPageState createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  final DatabaseReference itemsRef = FirebaseDatabase.instance.ref().child('items');
  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  void _fetchItems() {
    itemsRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        setState(() {
          items = data.entries.map((e) {
            final item = Map<String, dynamic>.from(e.value as Map);
            item['key'] = e.key;
            return item;
          }).toList();
        });
      }
    });
  }

  void _deleteItem(String itemKey) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this item?'),
          actions: [
            TextButton(
              onPressed: () {
                // If user cancels, close the dialog
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Proceed with deletion
                itemsRef.child(itemKey).remove().then((_) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Item deleted successfully')));
                  Navigator.of(context).pop(); // Close the dialog
                }).catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete item: $error')));
                  Navigator.of(context).pop(); // Close the dialog
                });
              },
              child: Text('Delete'),
              style: TextButton.styleFrom(foregroundColor: Colors.red), // Make the delete button red
            ),
          ],
        );
      },
    );
  }


  void _updateItem(Map<String, dynamic> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddItems(
          item: item,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
              appBar: CustomAppBar.customAppBar("Items List",
            IconButton(onPressed: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>Admin()));

            }, icon: Icon(Icons.arrow_back))),
      body: items.isNotEmpty
          ? ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            leading: item['image'] != null
                ? Image.network(item['image'], width: 50, height: 50, fit: BoxFit.cover)
                : Icon(Icons.image, size: 50),
            title: Text(item['item_name'] ?? 'No Name'),
            subtitle: Text(item['description'] ?? 'No Description'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _updateItem(item),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteItem(item['key']),
                ),
              ],
            ),
          );
        },
      )
          : Center(child: Text('No items available')),
              floatingActionButton:  FloatingActionButton(
            child: const Icon(Icons.add,color: Colors.white,),
            backgroundColor: const Color(0xFFE0A45E),
            onPressed: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>AddItems()));
            }
        )
    );
  }
}
