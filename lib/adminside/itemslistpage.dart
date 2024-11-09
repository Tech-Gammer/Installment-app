import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:installment_app/adminside/adminpanel.dart';

import '../components.dart';
import 'additems.dart';

class ItemsPage extends StatefulWidget {
  @override
  _ItemsPageState createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  final DatabaseReference itemsRef = FirebaseDatabase.instance.ref("items");
  final FirebaseStorage storage = FirebaseStorage.instance;
  final ImagePicker picker = ImagePicker();
  List<String> categories = [];
  List<String> units = [];

  List<Map<dynamic, dynamic>> _items = [];
  String? selectedCategory;
  String? selectedUnit;

  TextEditingController categoryController = TextEditingController();
  File? _imageFile;
  XFile? pickfile;


  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchUnits();
  }

  Future<List<Map<String, dynamic>>> fetchItems() async {
    final snapshot = await itemsRef.get();

    if (snapshot.exists) {
      Map<dynamic, dynamic> items = snapshot.value as Map<dynamic, dynamic>;
      List<Map<String, dynamic>> itemList = items.values.map((item) {
        return Map<String, dynamic>.from(item);
      }).toList();
      return itemList;
    }
    else {
      return [];
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
          if (categories.isNotEmpty) selectedCategory = categories.first;
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
          if (units.isNotEmpty) selectedUnit = units.first;
        });
      } else {
        setState(() {
          units = [];
        });
      }
    } catch (e) {
      // print('Error fetching categories: $e');
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker imagePicker = ImagePicker();
    final image = await imagePicker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        if (kIsWeb) {
          // For web, store the picked file in `pickfile`
          pickfile = image;
        } else {
          // For mobile, store the picked file as `file`
          _imageFile = File(image.path);
        }
      });
    } else {
      // If no image is selected, show a SnackBar with a message
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("No Image Selected")));
    }
  }

  Future<String?> _uploadImage(XFile imageFile, String? existingImageUrl) async {
    try {
      String fileName;

      // Use the existing image file name if an existing URL is provided
      if (existingImageUrl != null) {
        Uri uri = Uri.parse(existingImageUrl);
        fileName = uri.pathSegments.last;
      } else {
        // Otherwise, create a new file name using the current timestamp
        fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      }

      // Reference to Firebase Storage
      Reference storageRef = storage.ref().child("Products/$fileName");

      UploadTask uploadTask;

      // Platform-specific file upload logic
      if (kIsWeb) {
        // For web, upload the file as bytes
        final byte = await pickfile!.readAsBytes();
        uploadTask = storageRef.putData(byte);
      } else {
        // For mobile, upload the file directly
        uploadTask = storageRef.putFile(imageFile as File);
      }

      // Wait for the upload to complete
      final snapshot = await uploadTask.whenComplete(() {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Image Uploaded")));
      });

      // Get and return the download URL of the uploaded image
      final imageUrl = await snapshot.ref.getDownloadURL();
      return imageUrl;
    } catch (e) {
      // Handle any errors during upload
      print("Error uploading image: $e");
      return null;
    }
  }


  void _showItemDetailsDialog(Map<String, dynamic> item) {
    final TextEditingController nameController = TextEditingController(text: item['item_name'] ?? '');
    final TextEditingController netController = TextEditingController(text: (item['net_rate'] ?? 0.0).toString());
    final TextEditingController descriptionController = TextEditingController(text: item['description'] ?? '');
    final TextEditingController purchaseController = TextEditingController(text: item['purchase_rate'] ?? '');
    final TextEditingController saleController = TextEditingController(text: item['sale_rate'] ?? '');
    final TextEditingController taxController = TextEditingController(text: item['tax'] ?? '');
    final TextEditingController barcodeController = TextEditingController(text: item['barcode'] ?? '');
    final TextEditingController ptcController = TextEditingController(text: item['ptc_code'] ?? '');
    final TextEditingController itemQtyController = TextEditingController(text: item['item_qty'] ?? '');

    // Use State variables for category and unit
    String currentCategory = item['category'] ?? categories.first;
    String currentUnit = item['unit'] ?? units.first;

    String? imageUrl = item['image'];

    double saleRate = double.tryParse(item['sale_rate'] ?? '0.0') ?? 0.0;
    double tax = double.tryParse(item['tax'] ?? '0.0') ?? 0.0;
    double netRate = saleRate * (1 + tax / 100);
    double taxAmount = 0.0;

    void _updateNetRate() {
      final saleRate = double.tryParse(saleController.text) ?? 0.0;
      final tax = double.tryParse(taxController.text) ?? 0.0;

      // Calculate net rate
      final netRate = saleRate * (1 + tax / 100);

      // Update net rate in the UI
      netController.text = netRate.toStringAsFixed(0);

      // Calculate tax amount (difference between net rate and sale rate)
      taxAmount = netRate - saleRate;
    }

    saleController.addListener(_updateNetRate);
    taxController.addListener(_updateNetRate);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Text("Item Details"),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 70,
                            backgroundImage: item['image'] != null ? NetworkImage(item['image']) : null,
                            backgroundColor: Colors.grey[200],
                            child: imageUrl == null ? const Icon(Icons.image, color: Colors.grey) : null,
                          ),
                          Positioned(
                            bottom: -5,
                            right: -5,
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt, color: Colors.blue, size: 30),
                              onPressed: _pickImage,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(nameController, "Item Name"),
                    TextField(
                      controller: TextEditingController(text: netRate.toStringAsFixed(0)),
                      decoration: const InputDecoration(
                        labelText: "Net Rate",
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey, width: 5),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      readOnly: true,
                    ),
                    _buildTextField(purchaseController, "Purchase Rate", keyboardType: TextInputType.number),
                    _buildTextField(saleController, "Sale Rate", keyboardType: TextInputType.number),
                    _buildTextField(taxController, "Tax", keyboardType: TextInputType.number),
                    _buildTextField(barcodeController, "Barcode", keyboardType: TextInputType.number),
                    _buildTextField(ptcController, "PCT CODE", keyboardType: TextInputType.number),
                    _buildTextField(itemQtyController, "Item Quantity", keyboardType: TextInputType.number),

                    // Dropdown for selecting category
                    DropdownButtonFormField<String>(
                      value: currentCategory,
                      decoration: const InputDecoration(
                        labelText: "Category",
                        border: OutlineInputBorder(),
                      ),
                      items: categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          currentCategory = value!;
                        });
                      },
                    ),

                    // Dropdown for selecting unit
                    DropdownButtonFormField<String>(
                      value: currentUnit,
                      decoration: const InputDecoration(
                        labelText: "Unit",
                        border: OutlineInputBorder(),
                      ),
                      items: units.map((unit) {
                        return DropdownMenuItem<String>(
                          value: unit,
                          child: Text(unit),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          currentUnit = value!;
                        });
                      },
                    ),

                    _buildTextField(descriptionController, "Description", maxLines: 3),
                  ],
                ),
              ),
              actions: [
                Center(
                  child: Container(
                    width: 200,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0A45E),
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    child: TextButton(
                      // onPressed: () async {
                      //   final itemId = item['itemId'] as String? ?? '';
                      //   final newPrice = double.tryParse(netController.text) ?? 0.0;
                      //   if (itemId.isNotEmpty) {
                      //     String? newImageUrl;
                      //     if (_imageFile != null) {
                      //       newImageUrl = await _uploadImage(_imageFile!, imageUrl);
                      //     } else {
                      //       newImageUrl = imageUrl; // Keep the old image URL if no new image is selected
                      //     }
                      //     await _updateItem(itemId, {
                      //       'item_name': nameController.text,
                      //       'net_rate': newPrice,
                      //       'category': currentCategory, // Updated category
                      //       'unit': currentUnit,         // Updated unit
                      //       'description': descriptionController.text,
                      //       'image': newImageUrl,
                      //       'sale_rate': saleController.text,
                      //       'purchase_rate': purchaseController.text,
                      //       'tax': taxController.text,
                      //       'barcode': barcodeController.text,
                      //       'ptc_code': ptcController.text,
                      //       'item_qty': itemQtyController.text,
                      //       'tax_amount': taxAmount.toStringAsFixed(0),
                      //     });
                      //
                      //     Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ItemsPage()));
                      //   } else {
                      //     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid item ID")));
                      //   }
                      // },
                      onPressed: () async {
                        final itemId = item['itemId'] as String? ?? '';
                        final saleRate = double.tryParse(saleController.text) ?? 0.0;
                        final purchaseRate = double.tryParse(purchaseController.text) ?? 0.0;
                        final tax = double.tryParse(taxController.text) ?? 0.0;

                        // Calculate net rate and ensure it is not less than sale rate
                        final netRate = saleRate * (1 + tax / 100);

                        if (itemId.isNotEmpty) {
                          if (saleRate < purchaseRate) {
                            // Show an error message if saleRate is less than purchaseRate
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Sale Rate cannot be less than Purchase Rate")),
                            );
                          } else {
                            String? newImageUrl;
                            if (_imageFile != null || pickfile!=null) {
                              newImageUrl = await _uploadImage(_imageFile!=null? _imageFile as XFile: pickfile as XFile, imageUrl);
                            } else {
                              newImageUrl = imageUrl; // Keep the old image URL if no new image is selected
                            }
                            await _updateItem(itemId, {
                              'item_name': nameController.text,
                              'net_rate': netRate, // Updated net rate
                              'category': currentCategory, // Updated category
                              'unit': currentUnit,         // Updated unit
                              'description': descriptionController.text,
                              'image': newImageUrl!=null? newImageUrl: 'url',
                              'sale_rate': saleController.text,
                              'purchase_rate': purchaseController.text,
                              'tax': taxController.text,
                              'barcode': barcodeController.text,
                              'ptc_code': ptcController.text,
                              'item_qty': itemQtyController.text,
                              'tax_amount': (netRate - saleRate).toStringAsFixed(0),
                            });

                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ItemsPage()));
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid item ID")));
                        }
                      },

                      child: const Text("Update Item", style: NewCustomTextStyles.newcustomTextStyle),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateItem(String itemId, Map<String, dynamic> updatedData) async {
    try {
      final itemRef = itemsRef.child(itemId);

      await itemRef.update(updatedData);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Item updated successfully")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error updating item")));
    }
  }

  Future<void> deleteItem(String itemId, String imageUrl) async {
    try {
      await itemsRef.child(itemId).remove();
      final storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
      await storageRef.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Item and image deleted successfully")),
      );
      setState(() {
        _items.removeWhere((item) => item['itemId'] == itemId);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting item: $e")),
      );
    }
  }

  Widget _buildTextField(TextEditingController controller, String labelText, {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
            labelText: labelText,
            border: const OutlineInputBorder(
                borderSide: BorderSide(
                    color: Colors.grey,
                    width: 5
                )
            )
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
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
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: fetchItems(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("No items found"));
            } else {
              final items = snapshot.data!;
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card(
                    elevation: 5,
                    shadowColor: Colors.blue,
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        radius: 30,
                        backgroundImage: item['image'] != null
                            ? NetworkImage(item['image'])
                            : null,
                        backgroundColor: Colors.grey[200],
                        child: item['image'] == null ? const Icon(Icons.image, color: Colors.grey) : null,
                      ),
                      title: Text("Name: ${item['item_name']}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Description: ${item['description']}"),
                          const SizedBox(height: 4),
                          Text("Rate: ${item['net_rate']}"),
                          const SizedBox(height: 4),
                          Text("Category: ${item['category']}"),
                          const SizedBox(height: 4),
                          Text("Quantity: ${item['item_qty']} ${item['unit']} "),
                        ],
                      ),
                      onTap: () => _showItemDetailsDialog(item),
                      trailing: IconButton(
                        onPressed: () async {
                          final confirm = await showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text("Confirm Deletion"),
                                content: const Text("Are you sure you want to delete this item?"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text("DELETE"),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text("CANCEL"),
                                  ),
                                ],
                              );
                            },
                          );
                          if (confirm) {
                            final itemId = item['itemId'] as String? ?? '';
                            if (itemId.isNotEmpty) {
                              await deleteItem(itemId, item['image']);
                              setState(() {}); // Refresh the list
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid item ID")));
                            }
                          }
                        },
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 25,
                        ),
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
        floatingActionButton:  FloatingActionButton(
            child: const Icon(Icons.add,color: Colors.white,),
            backgroundColor: const Color(0xFFE0A45E),
            onPressed: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>const AddItems()));
            }
        )
    );
  }
}
