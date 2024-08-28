import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'list_detail_screen.dart';
import 'dart:async';

class ListScreen extends StatefulWidget {
  final String? listId;

  ListScreen({this.listId});

  @override
  _ListScreenState createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get user => _auth.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Lists'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showCreateListDialog(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('lists')
            .where('sharedWith', arrayContains: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var lists = snapshot.data!.docs;
          if (lists.isEmpty) {
            return Center(child: Text('No lists available.'));
          }

          return ListView.builder(
            itemCount: lists.length,
            itemBuilder: (context, index) {
              var list = lists[index];
              return ListTile(
                title: Text(list['name']),
                onTap: () => _navigateToListDetail(list.id, list['name']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.sticky_note_2),
                      onPressed: () => _showNoteDialog(list.id),
                    ),
                    IconButton(
                      icon: Icon(Icons.more_vert),
                      onPressed: () => _showOptionsDialog(list.id, list['createdBy']),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _navigateToListDetail(String listId, String listName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListDetailScreen(
          listId: listId,
          listName: listName,
        ),
      ),
    );
  }

  void _showCreateListDialog() {
    TextEditingController _nameController = TextEditingController();
    TextEditingController _budgetController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Create New List'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'List Name'),
              ),
              TextField(
                controller: _budgetController,
                decoration: InputDecoration(labelText: 'Combined Budget'),
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
                _createList(_nameController.text, double.parse(_budgetController.text));
                Navigator.of(context).pop();
              },
              child: Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createList(String name, double budget) async {
    try {
      await _firestore.collection('lists').add({
        'name': name,
        'createdBy': user?.uid,
        'sharedWith': [user?.uid],
        'items': [],
        'note': '',
        'totalAmount': 0.0,
        'userTotals': {user?.uid: 0.0},
        'combinedBudget': budget, // Store the budget in Firestore
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('List created successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create list: $e')),
      );
    }
  }


  void _showOptionsDialog(String listId, String createdBy) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Share List'),
              onTap: () {
                Navigator.of(context).pop();
                _showShareDialog(listId);
              },
            ),
            ListTile(
              title: Text('View Shared People'),
              onTap: () {
                Navigator.of(context).pop();
                _showSharedPeopleDialog(listId);
              },
            ),
            if (user?.uid == createdBy)
              ListTile(
                title: Text('Delete List'),
                onTap: () {
                  Navigator.of(context).pop();
                  _deleteList(listId);
                },
              ),
          ],
        );
      },
    );
  }

  void _showShareDialog(String listId) {
    TextEditingController _emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Share List'),
          content: TextField(
            controller: _emailController,
            decoration: InputDecoration(labelText: 'Enter email to share with'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _shareList(listId, _emailController.text);
                Navigator.of(context).pop();
              },
              child: Text('Share'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _shareList(String listId, String email) async {
    try {
      var userDoc = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userDoc.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not found')),
        );
        return;
      }

      var sharedUserId = userDoc.docs.first.id;

      await _firestore.collection('lists').doc(listId).update({
        'sharedWith': FieldValue.arrayUnion([sharedUserId]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('List successfully shared')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share list: $e')),
      );
    }
  }

  void _showSharedPeopleDialog(String listId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Shared with'),
          content: FutureBuilder<List<String>>(
            future: _fetchSharedPeople(listId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              }

              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Text('This list is not shared with anyone.');
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: snapshot.data!.map((email) => Text(email)).toList(),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<List<String>> _fetchSharedPeople(String listId) async {
    try {
      DocumentSnapshot listDoc = await _firestore.collection('lists').doc(listId).get();

      if (!listDoc.exists) {
        return [];
      }

      List<String> sharedWith = List<String>.from(listDoc['sharedWith'] ?? []);

      List<String> emails = [];
      for (String uid in sharedWith) {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
        if (userDoc.exists) {
          emails.add(userDoc['email'] ?? 'No email');
        }
      }

      return emails;
    } catch (e) {
      return Future.error('Failed to fetch shared people: $e');
    }
  }

  Future<void> _deleteList(String listId) async {
    try {
      await _firestore.collection('lists').doc(listId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('List deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete list: $e')),
      );
    }
  }

  void _showNoteDialog(String listId) {
    showDialog(
      context: context,
      builder: (context) {
        return _NoteDialog(listId: listId);
      },
    );
  }
}

class _NoteDialog extends StatefulWidget {
  final String listId;

  _NoteDialog({required this.listId});

  @override
  _NoteDialogState createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TextEditingController _noteController;
  String _note = '';

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    _fetchNote();
  }

  Future<void> _fetchNote() async {
    try {
      DocumentSnapshot doc = await _firestore.collection('lists').doc(widget.listId).get();
      if (doc.exists) {
        setState(() {
          _note = doc['note'] ?? '';
          _noteController.text = _note;
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _saveNote() async {
    try {
      await _firestore.collection('lists').doc(widget.listId).update({
        'note': _noteController.text,
      });
      Navigator.of(context).pop();
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Notes'),
      content: TextField(
        controller: _noteController,
        maxLines: 5,
        decoration: InputDecoration(hintText: 'Enter your note here'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: _saveNote,
          child: Text('Save'),
        ),
      ],
    );
  }
}
