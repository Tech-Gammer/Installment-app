//
// Future<void> save() async {
//   setState(() {
//     isSaving = true; // Start saving state
//   });
//
//   try {
//     // Check for duplicates before proceeding (with indexed fields)
//     final nameSnapshot = await dref.orderByChild('item_name').equalTo(nc.text.trim()).once();
//     final barcodeSnapshot = await dref.orderByChild('barcode').equalTo(barc.text.trim()).once();
//
//     // If duplicate item_name exists
//     if (nameSnapshot.snapshot.exists) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Item with this name already exists")),
//       );
//       return;
//     }
//
//     // If duplicate barcode exists
//     if (barcodeSnapshot.snapshot.exists) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Item with this barcode already exists")),
//       );
//       return;
//     }
//
//     // Proceed to upload image
//     await uploadImage();
//     if (url == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Error uploading image. Please try again.")),
//       );
//       return;
//     }
//
//     String itemId = dref.push().key.toString();
//     String item_name = nc.text.trim();
//     String description = dc.text.trim();
//     String purchaseRate = prc.text.trim();
//     String saleRate = src.text.trim();
//     String barcode = barc.text.trim();
//     String ptcCode = ptcc.text.trim();
//     String item_qty = qtyc.text.trim();
//
//     String taxPercentage = taxc.text.trim();
//     String? aId = FirebaseAuth.instance.currentUser?.uid;
//
//     // Convert rates to integer and handle any parsing errors
//     int? purchaseRateInt = int.tryParse(purchaseRate);
//     int? saleRateInt = int.tryParse(saleRate);
//
//     if (purchaseRateInt == null || saleRateInt == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Invalid rate format")),
//       );
//       return;
//     }
//
//     // Calculate the tax amount (18% of sale rate)
//     double taxAmount = (saleRateInt * 18) / 100;
//
//     // Save item details to the database
//     await dref.child(itemId).set({
//       'item_name': item_name,
//       'description': description,
//       'purchase_rate': purchaseRateInt.toString(),
//       'sale_rate': saleRateInt.toString(),
//       'barcode': barcode,
//       'ptc_code': ptcCode,
//       'category': category,
//       'item_qty': item_qty,
//       'tax_amount': taxAmount.toStringAsFixed(0),
//       'tax': taxPercentage,
//       'net_rate': netRate.toStringAsFixed(0),
//       'image': url,
//       'itemId': itemId,
//       'adminId': aId,
//       'unit': unit,
//     });
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Data Saved Successfully")),
//     );
//
//     // Clear the form
//     _clearForm();
//
//   } catch (e) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Something went wrong")),
//     );
//   } finally {
//     setState(() {
//       isSaving = false; // Always reset saving state at the end
//     });
//   }
// }
//
// void _clearForm() {
//   setState(() {
//     nc.clear();
//     dc.clear();
//     prc.clear();
//     src.clear();
//     barc.clear();
//     ptcc.clear();
//     taxc.clear();
//     qtyc.clear();
//     catetoryController.clear();
//     unitController.clear();
//     file = null;
//     pickfile = null;
//     item_name = "";
//     description = "";
//     purchase_rate = "";
//     sale_rate = "";
//     tax = "";
//     netRate = 0.0;
//     category = "";
//     unit = "";
//     item_qty = "";
//   });
// }


// for (var item in items.values) {
// if (item.containsKey('item_name') && item.containsKey('barcode')) {
// if (item['item_name'] == itemName || item['barcode'] == barcode) {
// return true; // Duplicate found
// }
// }
// }