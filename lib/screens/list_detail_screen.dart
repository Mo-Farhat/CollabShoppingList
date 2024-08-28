import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ListDetailScreen extends StatefulWidget {
  final String listId;
  final String listName;

  ListDetailScreen({required this.listId, required this.listName});

  @override
  _ListDetailScreenState createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TextEditingController _itemNameController;
  late TextEditingController _itemPriceController;

  @override
  void initState() {
    super.initState();
    _itemNameController = TextEditingController();
    _itemPriceController = TextEditingController();
    _initializeUserTotals();
  }

  User? get user => _auth.currentUser;

  Future<void> _initializeUserTotals() async {
    try {
      DocumentSnapshot listDoc = await _firestore.collection('lists').doc(widget.listId).get();

      if (!listDoc.exists) {
        // Handle the case where the list document doesn't exist
        return;
      }

      // Check if the userTotals field exists
      if (!(listDoc.data() as Map<String, dynamic>).containsKey('userTotals')) {
        // Initialize the userTotals field if it doesn't exist
        await _firestore.collection('lists').doc(widget.listId).update({
          'userTotals': {user?.uid: 0.0},
        });
      } else {
        // Ensure the current user's total is initialized
        Map<String, dynamic> userTotals = Map<String, dynamic>.from(listDoc['userTotals']);
        if (!userTotals.containsKey(user?.uid)) {
          userTotals[user!.uid] = 0.0;
          await _firestore.collection('lists').doc(widget.listId).update({
            'userTotals': userTotals,
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initialize user totals: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.listName),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showAddItemDialog(),
          ),
          IconButton(
            icon: Icon(Icons.info),
            onPressed: () => _showTotalSpentByOthers(),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('lists').doc(widget.listId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var list = snapshot.data!;
          var items = List<Map<String, dynamic>>.from(list['items'] ?? []);
          double userTotalAmountSpent = list['userTotals.${user?.uid}'] ?? 0.0;
          double combinedBudget = list['combinedBudget']?.toDouble() ?? 0.0;
          double totalAmountSpent = list['totalAmount']?.toDouble() ?? 0.0;
          double remainingBudget = combinedBudget - totalAmountSpent;
          double progress = combinedBudget > 0 ? totalAmountSpent / combinedBudget : 0.0;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    var item = items[index];
                    bool isBought = item['bought'] ?? false;

                    return CheckboxListTile(
                      title: Text(
                        '${item['name']} - \$${item['price'].toStringAsFixed(2)}',
                        style: TextStyle(
                          decoration: isBought ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      value: isBought,
                      onChanged: (bool? value) {
                        _updateItemStatus(index, value!);
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0), // Ensure progress is within bounds
                      backgroundColor: Colors.grey[300],
                      color: Colors.green,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Remaining Budget: \$${remainingBudget.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Total Spent by You: \$${userTotalAmountSpent.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddItemDialog() {
    _itemNameController.clear();
    _itemPriceController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _itemNameController,
                decoration: InputDecoration(labelText: 'Item Name'),
              ),
              TextField(
                controller: _itemPriceController,
                decoration: InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _addItem();
                Navigator.of(context).pop();
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

// list_detail_screen.dart

  Future<void> _addItem() async {
    var itemName = _itemNameController.text;
    var itemPrice = double.tryParse(_itemPriceController.text) ?? 0.0;

    if (itemName.isNotEmpty && user != null) {
      try {
        DocumentSnapshot listDoc = await _firestore.collection('lists').doc(widget.listId).get();
        List items = listDoc['items'] ?? [];
        double totalAmount = listDoc['totalAmount']?.toDouble() ?? 0.0;

        items.add({
          'name': itemName,
          'price': itemPrice,
          'bought': false,
        });

        totalAmount += itemPrice;

        await _firestore.collection('lists').doc(widget.listId).update({
          'items': items,
          'totalAmount': totalAmount,
        });

        await _updateBudget(itemPrice, isAdding: true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Item added successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add item: $e')),
        );
      }
    }
  }

  Future<void> _updateItemStatus(int index, bool bought) async {
    try {
      DocumentSnapshot listDoc = await _firestore.collection('lists').doc(widget.listId).get();
      List items = listDoc['items'] ?? [];

      double itemPrice = items[index]['price'];
      bool itemBought = items[index]['bought'] ?? false;

      items[index]['bought'] = bought;

      await _firestore.collection('lists').doc(widget.listId).update({
        'items': items,
      });

      if (bought && !itemBought) {
        await _updateBudget(itemPrice, isAdding: true);
      } else if (!bought && itemBought) {
        await _updateBudget(itemPrice, isAdding: false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update item: $e')),
      );
    }
  }

  Future<void> _updateBudget(double amount, {required bool isAdding}) async {
    if (user == null) return;

    try {
      DocumentReference budgetRef = _firestore.collection('budgets').doc(user!.uid);
      DocumentSnapshot budgetDoc = await budgetRef.get();

      if (budgetDoc.exists) {
        double currentSpent = (budgetDoc['amountSpent'] as num).toDouble();
        double newSpent = isAdding ? currentSpent + amount : currentSpent - amount;

        await budgetRef.update({
          'amountSpent': newSpent,
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update budget: $e')),
      );
    }
  }


  Future<void> _showTotalSpentByOthers() async {
    try {
      DocumentSnapshot listDoc = await _firestore.collection('lists').doc(widget.listId).get();
      Map<String, dynamic> userTotals = Map<String, dynamic>.from(listDoc['userTotals'] ?? {});

      double totalSpentByOthers = 0.0;
      userTotals.forEach((key, value) {
        if (key != user?.uid) {
          totalSpentByOthers += value.toDouble();
        }
      });

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Total Spent by Others'),
            content: Text('Total spent by others on this list: \$${totalSpentByOthers.toStringAsFixed(2)}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Close'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get total spent by others: $e')),
      );
    }
  }
}
