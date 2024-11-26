import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, 'loginScreen');
    } catch (e) {
      print("Logout error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Found Items'),
            Tab(text: 'Lost Items'),
            Tab(text: 'Users'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          CollectionCRUDScreen(collectionName: 'found_items'),
          CollectionCRUDScreen(collectionName: 'lost_items'),
          UserManagementScreen(),
        ],
      ),
    );
  }
}

class CollectionCRUDScreen extends StatefulWidget {
  final String collectionName;

  const CollectionCRUDScreen({super.key, required this.collectionName});

  @override
  _CollectionCRUDScreenState createState() => _CollectionCRUDScreenState();
}

class _CollectionCRUDScreenState extends State<CollectionCRUDScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _dateTimeController = TextEditingController();
  final TextEditingController _itemTypeController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController();

  bool showName = true;
  bool showPhone = true;
  String? selectedItemId;

  Future<void> _addItem() async {
    await FirebaseFirestore.instance.collection(widget.collectionName).add({
      'description': _descriptionController.text,
      'location': _locationController.text,
      'color': _colorController.text,
      'date_time': _dateTimeController.text,
      'item_type': _itemTypeController.text,
      'image_url': _imageUrlController.text,
      'user_id': _userIdController.text,
      'show_name': showName,
      'show_phone': showPhone,
      'created_at': Timestamp.now(),
    });

    _clearFields();
  }

  Future<void> _updateItem() async {
    if (selectedItemId == null) return;

    await FirebaseFirestore.instance
        .collection(widget.collectionName)
        .doc(selectedItemId)
        .update({
      'description': _descriptionController.text,
      'location': _locationController.text,
      'color': _colorController.text,
      'date_time': _dateTimeController.text,
      'item_type': _itemTypeController.text,
      'image_url': _imageUrlController.text,
      'user_id': _userIdController.text,
      'show_name': showName,
      'show_phone': showPhone,
    });

    _clearFields();
  }

  Future<void> _deleteItem(String id) async {
    await FirebaseFirestore.instance
        .collection(widget.collectionName)
        .doc(id)
        .delete();
  }

  void _clearFields() {
    _descriptionController.clear();
    _locationController.clear();
    _colorController.clear();
    _dateTimeController.clear();
    _itemTypeController.clear();
    _imageUrlController.clear();
    _userIdController.clear();
    setState(() {
      selectedItemId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              TextField(
                controller: _colorController,
                decoration: const InputDecoration(labelText: 'Color'),
              ),
              TextField(
                controller: _dateTimeController,
                decoration: const InputDecoration(labelText: 'Date/Time'),
              ),
              TextField(
                controller: _itemTypeController,
                decoration: const InputDecoration(labelText: 'Item Type'),
              ),
              TextField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: 'Image URL'),
              ),
              TextField(
                controller: _userIdController,
                decoration: const InputDecoration(labelText: 'User ID'),
              ),
              Row(
                children: [
                  const Text("Show Name"),
                  Switch(
                    value: showName,
                    onChanged: (value) {
                      setState(() {
                        showName = value;
                      });
                    },
                  ),
                  const Text("Show Phone"),
                  Switch(
                    value: showPhone,
                    onChanged: (value) {
                      setState(() {
                        showPhone = value;
                      });
                    },
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: selectedItemId == null ? _addItem : _updateItem,
                child:
                    Text(selectedItemId == null ? 'Add Item' : 'Save Changes'),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(widget.collectionName)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final items = snapshot.data!.docs;
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final id = item.id;
                  final description = item['description'];
                  final location = item['location'];
                  final color = item['color'];
                  final dateTime = item['date_time'];
                  final itemType = item['item_type'];
                  final imageUrl = item['image_url'];
                  final userId = item['user_id'];

                  return ListTile(
                    title: Text(description),
                    subtitle: Text(location),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            setState(() {
                              selectedItemId = id;
                            });
                            _descriptionController.text = description;
                            _locationController.text = location;
                            _colorController.text = color;
                            _dateTimeController.text = dateTime;
                            _itemTypeController.text = itemType;
                            _imageUrlController.text = imageUrl;
                            _userIdController.text = userId;
                            showName = item['show_name'];
                            showPhone = item['show_phone'];
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteItem(id),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  bool isActive = true;
  String? selectedUserId;

  Future<void> _addUser() async {
    await FirebaseFirestore.instance.collection('users').add({
      'email': _emailController.text,
      'fullName': _fullNameController.text,
      'role_id': 2,
      'isActive': isActive,
      'created_at': Timestamp.now(),
    });

    _clearFields();
  }

  Future<void> _updateUser() async {
    if (selectedUserId == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(selectedUserId)
        .update({
      'fullName': _fullNameController.text,
      'isActive': isActive,
    });

    _clearFields();
  }

  Future<void> _updateUserStatus(String id, bool status) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(id)
        .update({'isActive': status});
  }

  Future<void> _deleteUser(String userId) async {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    final currentUser = auth.currentUser;

    try {
      await firestore.collection('users').doc(userId).delete();

      QuerySnapshot lostItems = await firestore
          .collection('lost_items')
          .where('user_id', isEqualTo: userId)
          .get();

      for (var doc in lostItems.docs) {
        await doc.reference.delete();
      }

      QuerySnapshot foundItems = await firestore
          .collection('found_items')
          .where('user_id', isEqualTo: userId)
          .get();

      for (var doc in foundItems.docs) {
        await doc.reference.delete();
      }

      QuerySnapshot chats = await firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .get();

      for (var chatDoc in chats.docs) {
        await chatDoc.reference.delete();
      }

      if (currentUser != null && currentUser.uid == userId) {
        await currentUser.delete();
        print('User and all related data deleted successfully.');
      } else {
        print(
            'User data deleted from Firestore, but no authenticated session found for this user ID to delete from Authentication.');
      }
    } catch (e) {
      print('Error deleting user and related data: $e');
    }
  }

  void _clearFields() {
    _emailController.clear();
    _fullNameController.clear();
    setState(() {
      selectedUserId = null;
      isActive = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              Row(
                children: [
                  const Text("Account Active"),
                  Switch(
                    value: isActive,
                    onChanged: (value) {
                      setState(() {
                        isActive = value;
                      });
                    },
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: selectedUserId == null ? _addUser : _updateUser,
                child:
                    Text(selectedUserId == null ? 'Add User' : 'Save Changes'),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final users = snapshot.data!.docs;
              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final id = user.id;
                  final email = user['email'];
                  final fullName = user['fullName'];
                  final isActive = user['isActive'];

                  return ListTile(
                    title: Text(fullName),
                    subtitle: Text(email),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            setState(() {
                              selectedUserId = id;
                            });
                            _emailController.text = email;
                            _fullNameController.text = fullName;
                            this.isActive = user['isActive'];
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteUser(id),
                        ),
                        IconButton(
                          icon: Icon(isActive
                              ? Icons.check_circle
                              : Icons.remove_circle),
                          onPressed: () {
                            _updateUserStatus(id, !isActive);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
