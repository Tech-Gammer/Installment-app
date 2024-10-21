import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../components.dart';
import 'addcategory.dart';
import 'addunit.dart';
import 'itemslistpage.dart';


class AddItems extends StatefulWidget {
  const AddItems({super.key});

  @override
  State<AddItems> createState() => _AddItemsState();
}

class _AddItemsState extends State<AddItems> {
  String item_name = "";
  String description = "";
  String purchase_rate = "";
  String sale_rate = '';
  String category = "";
  String unit = "";
  String tax = "";
  double netRate = 0.0;
  String item_qty = "";
  String barcode = "";


  final dref = FirebaseDatabase.instance.ref("items");
  final storref = FirebaseStorage.instance;
  final dc = TextEditingController();
  final nc = TextEditingController();
  final src = TextEditingController();
  final prc = TextEditingController();
  final barc = TextEditingController();
  final ptcc = TextEditingController();
  final taxc = TextEditingController();
  final qtyc = TextEditingController();


  final catetoryController = TextEditingController();
  final unitController = TextEditingController();
  File? file;
  XFile? pickfile;
  bool isSaving = false;
  String? url;
  List<String> categories = [];
  List<String> units = [];

  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchUnits();

    // Add listeners to update net rate when sale rate or tax changes
    src.addListener(calculateNetRate);
    taxc.addListener(calculateNetRate);
  }

  void calculateNetRate() {
    // Parse the sale rate and tax percentage values
    final saleRate = double.tryParse(src.text) ?? 0.0;
    final taxPercentage = double.tryParse(taxc.text) ?? 0.0;

    // Calculate the net rate based on the parsed values
    setState(() {
      netRate = saleRate * (1 + taxPercentage / 100); // Update netRate
    });
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
      // print('Error fetching categories: $e');
    }
  }

  Future<void> getImage() async {
    final ImagePicker picker = ImagePicker();

    try {
      if (kIsWeb) {
        // Pick image for web
        final XFile? pickedFile = await picker.pickImage(
          source: ImageSource.gallery, // You can use ImageSource.camera if needed
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 80,
        );

        if (pickedFile != null) {
          setState(() {
            pickfile = pickedFile;
            file = null; // Clear mobile file reference
          });
        }
      } else {
        // Pick image for mobile (iOS/Android)
        final XFile? pickedFile = await picker.pickImage(
          source: ImageSource.gallery, // You can use ImageSource.camera if needed
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 80,
        );

        if (pickedFile != null) {
          setState(() {
            file = File(pickedFile.path);
            pickfile = null; // Clear web file reference
          });
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      // Optionally show an error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }


  Future<void> uploadImage() async {
    try {
      if (pickfile != null || file != null) {
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        Reference storageRef = storref.ref().child("Item Images/${DateTime.now().millisecondsSinceEpoch}.jpg");

        UploadTask uploadTask;

        if (kIsWeb && pickfile != null) {
          // Web upload (XFile)
          // For web, we need to convert the XFile to a Uint8List
          Uint8List imageData = await pickfile!.readAsBytes();
          uploadTask = storageRef.putData(imageData);
        } else if (file != null) {
          // Mobile upload (File)
          uploadTask = storageRef.putFile(file!);
        } else {
          return; // No file to upload
        }

        // Listen for the upload progress and completion
        TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
        url = await snapshot.ref.getDownloadURL(); // Get the uploaded file's download URL

        setState(() {
          print('Uploaded image URL: $url'); // Print or use the image URL as needed
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No image selected')),
        );
      }
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
    }
  }

  Future<void> save() async {

    String itemName = nc.text.trim();
    String barcode = barc.text.trim();

    print("Checking for duplicates with itemName: $itemName, barcode: $barcode");

    // Check for duplicates
    bool hasDuplicates = await checkForDuplicates(itemName, barcode);
    if (hasDuplicates) {
      print("Duplicate found"); // Check if this prints
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Item name or barcode already exists")),
      );
      setState(() {
        isSaving = false; // Reset saving state
      });
      return; // Exit if duplicates are found
    }

    // First, get the input values
    String itemId = dref.push().key.toString();
    String item_name = nc.text.trim();
    String description = dc.text.trim();
    String purchaseRate = prc.text.trim();
    String saleRate = src.text.trim();
     // String barcode = barc.text.trim();
    String ptcCode = ptcc.text.trim();
    String item_qty = qtyc.text.trim();
    String taxPercentage = taxc.text.trim();

    await uploadImage();
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error uploading image. Please try again.")),
      );
      setState(() {
        isSaving = false;
      });
      return;
    }
    print("Uploaded image URL: $url");


    String? aId = FirebaseAuth.instance.currentUser?.uid;
    // Convert rates to integer and handle any parsing errors
    int? purchaseRateInt;
    int? saleRateInt;

    try {
      purchaseRateInt = int.tryParse(purchaseRate);
      saleRateInt = int.tryParse(saleRate);

      if (purchaseRateInt == null || saleRateInt == null) {
        throw const FormatException("Invalid rate format");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid rate format")),
      );
      setState(() {
        isSaving = false;
      });
      return;
    }

    // Calculate the tax amount (18% of sale rate)
    double taxAmount = (saleRateInt * 18) / 100;

    // Add the 'unit' field to save the selected unit
    await dref.child(itemId).set({
      'item_name': item_name,
      'description': description,
      'purchase_rate': purchaseRateInt.toString(),
      'sale_rate': saleRateInt.toString(),
      'barcode': barcode,
      'ptc_code': ptcCode,
      'category': category,
      'item_qty': item_qty,
      'tax_amount': taxAmount.toStringAsFixed(0),
      'tax': taxPercentage, // Save tax percentage
      'net_rate': netRate.toStringAsFixed(0), // Save calculated net rate
      'image': url,
      'itemId': itemId,
      'adminId': aId,
      'unit': unit, // Saving selected unit
    }).then((value)  {
      print("Uploaded image URL: $url");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Data Saved Successfully")),
      );

      // Clear the form
      setState(() {
        nc.clear();
        dc.clear();
        prc.clear();
        src.clear();
        barc.clear();
        ptcc.clear();
        taxc.clear();
        qtyc.clear();  // Clear the quantity field after saving
        catetoryController.clear();
        unitController.clear();
        file = null;
        pickfile = null;
        item_name = "";
        description = "";
        purchase_rate = "";
        sale_rate = "";
        tax = "";
        netRate = 0.0; // Reset net rate
        isSaving = false;
        category = "";
        unit = "";  // Reset selected unit
        item_qty = "";  // Reset quantity
      });
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Something went wrong")),
      );
      setState(() {
        isSaving = false;
      });
    });
  }

  Future<bool> checkForDuplicates(String itemName, String barcode) async {
    try {
      print('I am in Duplicate Function');

      // Attempt to read the items node
      final  snapshot = await dref.get();

      // Debug the snapshot data
      print('Snapshot exists: ${snapshot.exists}');
      print('Snapshot value: ${snapshot.value}');

      // Check if the items node exists and is a Map
      if (snapshot.exists && snapshot.value is Map) {
        final Map<dynamic, dynamic> items = snapshot.value as Map<dynamic, dynamic>;
        List<dynamic> list = items.values.toList();

        print('Number of items retrieved: ${list.length}');

        // Iterate through items and check for duplicates
        for (var item in list) {
          // Add debugging to see the structure of each item
          print('Checking item: $item');

          // Ensure item_name and barcode exist and compare them case-insensitively
          if (item['item_name']?.toString().trim().toLowerCase() == itemName.trim().toLowerCase() ||
              item['barcode']?.toString() == barcode.toString()) {
            print('Duplicate found: $item');
            return true; // Duplicate found
          }
        }

        print('No duplicates found in the list.');
      } else {
        // If the items node doesn't exist or is not a Map, return false
        print("Items node does not exist or is not a map. No duplicates found.");
      }
    } catch (e) {
      print("Error reading items: $e");
    }

    return false; // No duplicates found
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar.customAppBar("Register Items",
          IconButton(onPressed: (){
            Navigator.push(context, MaterialPageRoute(builder: (context)=>ItemsPage()));

          }, icon: const Icon(Icons.arrow_back))
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 100,
                  backgroundImage: file != null
                      ? FileImage(file!)
                      : pickfile != null
                      ? NetworkImage(pickfile!.path) as ImageProvider
                      : null,
                  backgroundColor: Colors.grey[200],
                  child: file == null && pickfile == null
                      ? const Icon(Icons.image, color: Colors.grey, size: 100)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.grey, size: 30),
                    onPressed: getImage,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: nc,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                  filled: true,
                  labelText: "Name",
                  labelStyle: TextStyle(fontSize: 15),
                  hintText: "Enter Product Name",
                ),
                textCapitalization: TextCapitalization.words,

              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: dc,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                  filled: true,
                  labelText: "Description",
                  labelStyle: TextStyle(fontSize: 15),
                  hintText: "Enter your Description",
                ),
                textCapitalization: TextCapitalization.words,

              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: prc,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                        filled: true,
                        labelText: "Purchase Rate",
                        labelStyle: TextStyle(fontSize: 15),
                        hintText: "Enter your Purchase Rate",
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: src, // Make sure you initialize this controller
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                        filled: true,
                        labelText: "Sale Rate",
                        labelStyle: TextStyle(fontSize: 15),
                        hintText: "Enter your Sale Rate",
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: taxc,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                        filled: true,
                        labelText: "Tax (%)",
                        labelStyle: TextStyle(fontSize: 15),
                        hintText: "Enter tax percentage",
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      readOnly: true,
                      controller: TextEditingController(text: netRate.toStringAsFixed(0)), // Reflects the latest netRate
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                        filled: true,
                        labelText: "Net Rate",
                        labelStyle: TextStyle(fontSize: 15),
                      ),
                    )

                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: categories.isNotEmpty
                        ? DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                        filled: true,
                        labelText: "Category",
                        labelStyle: TextStyle(fontSize: 15),
                      ),
                      value: category.isEmpty ? null : category,
                      items: categories.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          category = newValue!;
                        });
                      },
                    )
                        : CustomLoader(),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AddCategory()));
                    },
                    icon: const Icon(Icons.add, size: 40),
                  ),

                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: qtyc, // Make sure you initialize this controller
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                          filled: true,
                          labelText: "Quantity",
                          labelStyle: TextStyle(fontSize: 15),
                          hintText: "Enter Available Quantity",
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: units.isNotEmpty
                        ? DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                        filled: true,
                        labelText: "Units",
                        labelStyle: TextStyle(fontSize: 15),
                      ),
                      value: unit.isEmpty ? null : unit,
                      items: units.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          unit = newValue!;
                        });
                      },
                    )
                        : CustomLoader(),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const Addunit()));
                    },
                    icon: const Icon(Icons.add, size: 40),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: barc,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                        filled: true,
                        labelText: "Barcode",
                        labelStyle: TextStyle(fontSize: 15),
                        hintText: "Enter  Barcode",
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: ptcc, // Make sure you initialize this controller
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                        filled: true,
                        labelText: "PCT Code",
                        labelStyle: TextStyle(fontSize: 15),
                        hintText: "Enter PCT code",
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: InkWell(
                onTap: isSaving
                    ? null
                    : () async {
                  setState(() {
                    isSaving = true;  // Start saving state
                  });

                  // Set the item details from text fields
                  item_name = nc.text.toString();
                  description = dc.text.toString();
                  purchase_rate = prc.text.toString();
                  sale_rate = src.text.toString();
                  item_qty = qtyc.text.toString();
                  tax = taxc.text.toString(); // Ensure tax is captured

                  if (item_name.isEmpty || description.isEmpty || purchase_rate.isEmpty || category.isEmpty || sale_rate.isEmpty || unit.isEmpty || item_qty.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill in all the fields")));
                    setState(() {
                      isSaving = false; // Reset saving state
                    });
                  } else {
                    await save();
                    setState(() {
                      isSaving = false; // Reset saving state after successful save
                    });
                  }
                },
                child: Container(
                  width: 200.0,
                  height: 50.0,
                  decoration: const BoxDecoration(color: Color(0xFFE0A45E), borderRadius: BorderRadius.all(Radius.circular(20))),
                  child: Center(
                    child: Text(
                      isSaving ? "Saving..." : "Save Data",
                      style: NewCustomTextStyles.newcustomTextStyle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomLoader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 80,
        height: 80,
        child: const Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
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