import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  final List<Map<String, dynamic>> lowStockItems;

  const NotificationsPage({Key? key, required this.lowStockItems}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Low Stock Notifications'),
      ),
      body: lowStockItems.isEmpty
          ? const Center(child: Text('No low stock notifications.'))
          : ListView.builder(
        itemCount: lowStockItems.length,
        itemBuilder: (context, index) {
          final item = lowStockItems[index];
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              elevation: 5,
              child: ListTile(
                title: Text(item['item_name']),
                subtitle: Text('Available quantity: ${item['item_qty']}'),
                trailing: const Icon(Icons.warning, color: Colors.red),
              ),
            ),
          );
        },
      ),
    );
  }
}
