import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'spending_analytics_screen.dart';

class BudgetOverviewScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get user => _auth.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Budget Overview'),
        actions: [
          IconButton(
            icon: Icon(Icons.analytics),
            onPressed: () {
              // Assuming you have a specific listId for analytics
              // If not, you might need to select a list first
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('lists').where('sharedWith', arrayContains: user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No lists found.'));
          }

          var lists = snapshot.data!.docs;

          return ListView.builder(
            itemCount: lists.length,
            itemBuilder: (context, index) {
              var listData = lists[index].data() as Map<String, dynamic>;
              double budget = listData['combinedBudget']?.toDouble() ?? 0.0;
              double totalSpent = listData['totalAmount']?.toDouble() ?? 0.0;
              double remainingBudget = budget - totalSpent;
              double progress = budget > 0 ? totalSpent / budget : 0.0;

              return ListTile(
                title: Text(listData['name']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: Colors.grey[300],
                      color: remainingBudget < 0 ? Colors.red : Colors.green,
                    ),
                    Text('Total Budget: \$${budget.toStringAsFixed(2)}'),
                    Text('Total Spent: \$${totalSpent.toStringAsFixed(2)}'),
                    Text('Remaining Budget: \$${remainingBudget.toStringAsFixed(2)}'),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SpendingAnalyticsScreen(listId: lists[index].id),
                    ),
                  );
                },
                trailing: remainingBudget < 0
                    ? Icon(Icons.warning, color: Colors.red)
                    : Icon(Icons.check_circle, color: Colors.green),
              );
            },
          );
        },
      ),
    );
  }
}
