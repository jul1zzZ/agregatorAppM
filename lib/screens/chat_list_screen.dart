import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Чаты')),
        body: const Center(child: Text('Пользователь не авторизован')),
      );
    }

    final currentUserEmail = currentUser.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Чаты')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participantsEmails', arrayContains: currentUserEmail)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final chatDocs = snapshot.data!.docs;

          if (chatDocs.isEmpty) {
            return const Center(child: Text('Нет активных чатов'));
          }

          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              final chat = chatDocs[index];
              final chatId = chat.id;

              final participantsMap = Map<String, dynamic>.from(chat['participants'] ?? {});
              final participantsEmails = List<String>.from(chat['participantsEmails'] ?? []);

              // Найти email собеседника
              final otherUserEmail = participantsEmails.firstWhere(
                (email) => email != currentUserEmail,
                orElse: () => '',
              );

              String otherUserName = 'Ожидание ответа';
              String? otherUserAvatarUrl;

              if (otherUserEmail.isNotEmpty) {
                final otherUserData = Map<String, dynamic>.from(participantsMap[otherUserEmail] ?? {});
                otherUserName = otherUserData['name'] ?? 'Пользователь';
                otherUserAvatarUrl = otherUserData['avatarUrl'];
              }

              return ListTile(
                leading: (otherUserAvatarUrl != null && otherUserAvatarUrl.isNotEmpty)
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(otherUserAvatarUrl),
                      )
                    : const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                title: Text(otherUserName),
                subtitle: const Text('Нажмите, чтобы открыть'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        chatId: chatId,
                        currentUserEmail: currentUserEmail,
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
