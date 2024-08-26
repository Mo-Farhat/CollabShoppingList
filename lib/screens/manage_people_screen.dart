import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManagePeopleScreen extends StatefulWidget {
  final String listId;

  ManagePeopleScreen({required this.listId});

  @override
  _ManagePeopleScreenState createState() => _ManagePeopleScreenState();
}

class _ManagePeopleScreenState extends State<ManagePeopleScreen> {
  final TextEditingController _shareController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage People'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('lists').doc(widget.listId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var list = snapshot.data!;
          var sharedWith = List<String>.from(list['sharedWith'] ?? []);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _shareController,
                        decoration: InputDecoration(
                          labelText: 'Add User ID',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        String newUserId = _shareController.text.trim();
                        if (newUserId.isNotEmpty && !sharedWith.contains(newUserId)) {
                          FirebaseFirestore.instance.collection('lists').doc(widget.listId).update({
                            'sharedWith': FieldValue.arrayUnion([newUserId]),
                          }).then((_) {
                            _shareController.clear();
                          }).catchError((error) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to add user: $error')),
                            );
                          });
                        }
                      },
                      child: Text('Add'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: sharedWith.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(sharedWith[index]),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          FirebaseFirestore.instance.collection('lists').doc(widget.listId).update({
                            'sharedWith': FieldValue.arrayRemove([sharedWith[index]]),
                          }).catchError((error) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to remove user: $error')),
                            );
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
