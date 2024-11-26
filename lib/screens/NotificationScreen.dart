import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:seeker_app/screens/ItemDetailScreen.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  Stream<QuerySnapshot> _getUserNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    print("Current User ID: ${user?.uid}");
    if (user == null) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('receiverId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.amber[900],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getUserNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No notifications found"));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var notification = snapshot.data!.docs[index];
              String itemId = notification['itemId'];
              String description =
                  notification['description'] ?? "No description available";
              String color = notification['color'] ?? "Unknown color";
              String location = notification['location'] ?? "Unknown location";
              String dateTime =
                  notification['date_time'] ?? "Unknown date and time";
              String imageUrl = notification['image_url'] ?? "";
              bool isSeeker = notification['isSeeker'] ?? false;
              String itemType = notification['item_type'] ?? "Unknown type";
              bool showName = notification['show_name'] ?? false;
              bool showPhone = notification['show_phone'] ?? false;
              String collectionName =
                  notification['collectionName'] ?? "unknown_collection";

              return ListTile(
                leading: imageUrl.isNotEmpty
                    ? Image.network(imageUrl,
                        width: 50, height: 50, fit: BoxFit.cover)
                    : null,
                title: Text("Item Found!"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Description: $description"),
                    Text("Location: $location"),
                    Text("Color: $color"),
                    Text("Date & Time: $dateTime"),
                    Text("Item Type: $itemType"),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ItemDetailScreen(
                        description: description,
                        color: color,
                        location: location,
                        dateTime: dateTime,
                        imageUrl: imageUrl,
                        showName: showName,
                        showPhone: showPhone,
                        userId: notification['receiverId'],
                        itemId: itemId,
                        isSeeker: isSeeker,
                        collectionName: collectionName,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
