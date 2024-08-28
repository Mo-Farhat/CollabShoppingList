import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ListDetailScreen extends StatelessWidget {
  final String listId;
  final String listName;

  ListDetailScreen({required this.listId, required this.listName});

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get user => _auth.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(listName),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('lists').doc(listId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('List not found.'));
          }

          var listData = snapshot.data!.data() as Map<String, dynamic>;
          List items = listData['items'] ?? [];

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              var item = items[index];
              String buyer = item['boughtBy'] == user?.uid ? 'You' : 'Other';
              return ListTile(
                title: Text(item['name']),
                subtitle: Text('Bought by: $buyer\nCost: \$${item['cost'].toStringAsFixed(2)}'),
                trailing: Checkbox(
                  value: item['bought'],
                  onChanged: (value) {
                    _toggleItemBought(item, value!);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _toggleItemBought(Map<String, dynamic> item, bool isBought) async {
    try {
      await _firestore.collection('lists').doc(listId).update({
        'items': FieldValue.arrayRemove([item]),
      });

      item['bought'] = isBought;

      await _firestore.collection('lists').doc(listId).update({
        'items': FieldValue.arrayUnion([item]),
      });
    } catch (e) {
      print('Error updating item: $e');
    }
  }
}