import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SpendingAnalyticsScreen extends StatelessWidget {
  final String listId;

  SpendingAnalyticsScreen({required this.listId});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get user => _auth.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Spending Analytics'),
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
            return Center(child: Text('No data available.'));
          }

          var listData = snapshot.data!.data() as Map<String, dynamic>;
          double totalSpent = listData['totalAmount']?.toDouble() ?? 0.0;
          double combinedBudget = listData['combinedBudget']?.toDouble() ?? 0.0;
          Map<String, dynamic> userTotals = listData['userTotals'] ?? {};

          double userSpent = userTotals[user?.uid] != null ? (userTotals[user!.uid] as num).toDouble() : 0.0;
          double progress = combinedBudget > 0 ? totalSpent / combinedBudget : 0.0;
          double userProgress = combinedBudget > 0 ? userSpent / combinedBudget : 0.0;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Spending by You: \$${userSpent.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16.0),
                Text(
                  'Your Contribution to the Budget:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 16.0),
                LinearProgressIndicator(
                  value: userProgress.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[300],
                  color: userProgress > 1.0 ? Colors.red : Colors.green,
                ),
                SizedBox(height: 8.0),
                Text(
                  'Your Budget Utilization: ${(userProgress * 100).toStringAsFixed(2)}%',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8.0),
                Text(
                  'Remaining Budget: \$${(combinedBudget - totalSpent).toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16.0),
                Text(
                  'Overall Budget Utilization:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 16.0),
                LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[300],
                  color: progress > 1.0 ? Colors.red : Colors.green,
                ),
                SizedBox(height: 8.0),
                Text(
                  'Overall Budget Utilization: ${(progress * 100).toStringAsFixed(2)}%',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
