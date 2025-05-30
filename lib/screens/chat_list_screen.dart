import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  final bool isDarkTheme;
  final VoidCallback onToggleTheme;

  const ChatListScreen({
    super.key,
    required this.isDarkTheme,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Чаты')),
        body: Center(
          child: Text(
            'Пользователь не авторизован',
            style: theme.textTheme.bodyLarge,
          ),
        ),
      );
    }

    final currentUserEmail = currentUser.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Чаты'),
        backgroundColor: theme.appBarTheme.backgroundColor,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('chats')
                .where('participantsEmails', arrayContains: currentUserEmail)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final chatDocs = snapshot.data!.docs;

          if (chatDocs.isEmpty) {
            return Center(
              child: Text(
                'Нет активных чатов',
                style: theme.textTheme.bodyLarge,
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: chatDocs.length,
            separatorBuilder: (_, __) => Divider(color: theme.dividerColor),
            itemBuilder: (context, index) {
              final chat = chatDocs[index];
              final chatId = chat.id;

              final participantsMap = Map<String, dynamic>.from(
                chat['participants'] ?? {},
              );
              final participantsEmails = List<String>.from(
                chat['participantsEmails'] ?? [],
              );

              final otherUserEmail = participantsEmails.firstWhere(
                (email) => email != currentUserEmail,
                orElse: () => '',
              );

              String otherUserName = 'Ожидание ответа';
              String? otherUserAvatarUrl;

              if (otherUserEmail.isNotEmpty) {
                final otherUserData = Map<String, dynamic>.from(
                  participantsMap[otherUserEmail] ?? {},
                );
                otherUserName = otherUserData['name'] ?? 'Пользователь';
                otherUserAvatarUrl = otherUserData['avatarUrl'];
              }

              return ListTile(
                leading:
                    (otherUserAvatarUrl != null &&
                            otherUserAvatarUrl.isNotEmpty)
                        ? CircleAvatar(
                          backgroundImage: NetworkImage(otherUserAvatarUrl),
                        )
                        : CircleAvatar(
                          backgroundColor: theme.colorScheme.primary
                              .withOpacity(0.2),
                          child: Icon(
                            Icons.person,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                title: Text(otherUserName, style: theme.textTheme.titleMedium),
                subtitle: Text(
                  'Нажмите, чтобы открыть',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ChatScreen(
                            chatId: chatId,
                            currentUserEmail: currentUserEmail,
                            themeData: theme,
                            isDarkTheme: isDarkTheme,
                            onToggleTheme: onToggleTheme,
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
