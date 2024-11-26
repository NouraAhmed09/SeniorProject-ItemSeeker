import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatelessWidget {
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Messages')),
        body: Center(child: Text('Please log in to view messages')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Messages'),
        backgroundColor: Colors.amber[900],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No messages found'));
          }

          final chatDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              var chatData = chatDocs[index];
              String chatId = chatData.id;
              List participants = chatData['participants'];

              String? receiverId;
              if (participants.length == 2) {
                receiverId = participants.firstWhere(
                  (id) => id != currentUser!.uid,
                  orElse: () => null,
                );
              }

              if (receiverId == null) {
                return ListTile(
                  title: Text('Unknown user'),
                  subtitle: Text('Unable to load user details'),
                );
              }

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(receiverId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) return Container();

                  var userDoc = userSnapshot.data!;
                  String receiverName = userDoc['fullName'] ?? 'Unknown';

                  return ListTile(
                    title: Text(receiverName),
                    subtitle: Text('Tap to continue chat'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            chatId: chatId,
                            receiverId: receiverId!,
                            receiverName: receiverName,
                          ),
                        ),
                      );
                    },
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
