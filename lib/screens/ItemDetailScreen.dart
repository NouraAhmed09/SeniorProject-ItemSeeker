import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:seeker_app/screens/chat_screen.dart';

class ItemDetailScreen extends StatelessWidget {
  final String description;
  final String color;
  final String location;
  final String dateTime;
  final String imageUrl;
  final bool showName;
  final bool showPhone;
  final String userId;
  final String itemId;
  final bool isSeeker;
  final String collectionName;

  const ItemDetailScreen({
    super.key,
    required this.description,
    required this.color,
    required this.location,
    required this.dateTime,
    required this.imageUrl,
    required this.showName,
    required this.showPhone,
    required this.userId,
    required this.itemId,
    required this.isSeeker,
    required this.collectionName,
  });

  Future<void> markItemAsFound(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(itemId)
          .update({
        'isSeeker': true,
      });

      String receiverId = userId;

      DocumentSnapshot itemDoc = await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(itemId)
          .get();

      if (!itemDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Item not found.')),
        );
        return;
      }

      Map<String, dynamic> itemData = itemDoc.data() as Map<String, dynamic>;
      String dateTime = itemData['date_time'] ?? "Unknown";
      String description =
          itemData['description'] ?? "No description available";
      String imageUrl = itemData['image_url'] ?? "";
      bool isSeeker = itemData['isSeeker'] ?? false;
      String itemType = itemData['item_type'] ?? "Unknown";
      String location = itemData['location'] ?? "Unknown location";
      String color = itemData['color'] ?? "Unknown color";
      bool showName = itemData['show_name'] ?? false;
      bool showPhone = itemData['show_phone'] ?? false;

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'senderId': currentUser.uid,
          'receiverId': receiverId,
          'itemId': itemId,
          'collectionName': collectionName,
          'timestamp': Timestamp.now(),
          'date_time': dateTime,
          'description': description,
          'image_url': imageUrl,
          'isSeeker': isSeeker,
          'item_type': itemType,
          'location': location,
          'color': color,
          'show_name': showName,
          'show_phone': showPhone,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item marked as found!')),
      );
    } catch (e) {
      print("Error marking item as found: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking item as found.')),
      );
    }
  }

  Future<Map<String, String?>> _fetchUserDetails(String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        return {
          'name': userDoc['fullName'],
          'phone': userDoc['phone'],
        };
      } else {
        return {'name': 'Unknown', 'phone': 'Unknown'};
      }
    } catch (e) {
      print("Error fetching user details: $e");
      return {'name': 'Unknown', 'phone': 'Unknown'};
    }
  }

  Future<void> _startChat(BuildContext context, String receiverId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final chatId = '${currentUser.uid}_$receiverId';

    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'participants': [currentUser.uid, receiverId],
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatId: chatId,
          receiverId: receiverId,
          receiverName: "Receiver's Name",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print(
        "ItemDetailScreen loaded with isSeeker: $isSeeker, collectionName: $collectionName");
    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Details'),
        backgroundColor: Colors.amber[900],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection(collectionName)
            .doc(itemId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Item not found"));
          }

          var itemData = snapshot.data!;
          bool isSeeker = itemData['isSeeker'] ?? false;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.network(imageUrl),
                  const SizedBox(height: 16),
                  Text(
                    "Description: $description",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text("Location: $location"),
                  Text("Date & Time: $dateTime"),
                  Text("Color: $color"),
                  const SizedBox(height: 16),
                  if (showName || showPhone) ...[
                    FutureBuilder<Map<String, String?>>(
                      future: _fetchUserDetails(userId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        if (snapshot.hasError) {
                          return Text(
                              'Error fetching user details: ${snapshot.error}');
                        }
                        if (!snapshot.hasData) {
                          return const Text('No user data found');
                        }

                        var userDetails = snapshot.data!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (showName)
                              Text("User Name: ${userDetails['name']}"),
                            if (showPhone)
                              Text("Phone: ${userDetails['phone']}"),
                          ],
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _startChat(context, userId),
                    child: const Text("Chat with Owner"),
                  ),
                  const SizedBox(height: 16),
                  if (isSeeker)
                    Text(
                      "This item has already been marked as found.",
                      style: TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold),
                    )
                  else
                    ElevatedButton(
                      onPressed: () async {
                        await markItemAsFound(context);
                      },
                      child: Text('Mark as Found'),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
