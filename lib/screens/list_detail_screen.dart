import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ListDetailScreen extends StatefulWidget {
  final String listId;
  final String listName;

  ListDetailScreen({required this.listId, required this.listName});

  @override
  _ListDetailScreenState createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.listName),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('lists')
                  .doc(widget.listId)
                  .collection('items')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var items = snapshot.data!.docs;
                if (items.isEmpty) {
                  return Center(child: Text('No items in this list.'));
                }

                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    var item = items[index];
                    return ListTile(
                      title: Text(
                        '${item['name']} (Qty: ${item['quantity']})',
                        style: TextStyle(
                          decoration: item['bought']
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      leading: Checkbox(
                        value: item['bought'],
                        onChanged: (bool? value) {
                          _toggleItemBought(item.id, value!);
                        },
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _deleteItem(item.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _itemController,
                    decoration: InputDecoration(labelText: 'Add item'),
                  ),
                ),
                SizedBox(width: 10),
                Container(
                  width: 80,
                  child: TextField(
                    controller: _quantityController,
                    decoration: InputDecoration(labelText: 'Qty'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _addItem,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addItem() async {
    if (_itemController.text.isEmpty || _quantityController.text.isEmpty) {
      return;
    }

    try {
      await _firestore
          .collection('lists')
          .doc(widget.listId)
          .collection('items')
          .add({
        'name': _itemController.text,
        'quantity': _quantityController.text,
        'bought': false,
      });
      _itemController.clear();
      _quantityController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add item: $e')),
      );
    }
  }

  Future<void> _toggleItemBought(String itemId, bool bought) async {
    try {
      await _firestore
          .collection('lists')
          .doc(widget.listId)
          .collection('items')
          .doc(itemId)
          .update({
        'bought': bought,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update item: $e')),
      );
    }
  }

  Future<void> _deleteItem(String itemId) async {
    try {
      await _firestore
          .collection('lists')
          .doc(widget.listId)
          .collection('items')
          .doc(itemId)
          .delete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete item: $e')),
      );
    }
  }
}
