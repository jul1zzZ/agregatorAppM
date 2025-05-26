import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agregatorapp/models/message_model.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String currentUserEmail;
  final ThemeData themeData;

  final bool isDarkTheme; // <- добавить
  final VoidCallback onToggleTheme; // <- добавить

  const ChatScreen({
    Key? key,
    required this.chatId,
    required this.currentUserEmail,
    required this.themeData,
    required this.isDarkTheme, // <- обязательно
    required this.onToggleTheme, // <- обязательно
  }) : super(key: key);


  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  String? otherUserEmail;
  String otherUserName = '';
  String otherUserAvatarUrl = '';

  @override
  void initState() {
    super.initState();
    _loadOtherUserData();
  }

  Future<void> _loadOtherUserData() async {
    final chatDoc = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .get();

    if (chatDoc.exists) {
      final data = chatDoc.data();
      if (data != null && data['participantsEmails'] != null) {
        final participantsEmails = List<String>.from(data['participantsEmails']);
        final otherEmail = participantsEmails.firstWhere(
          (email) => email != widget.currentUserEmail,
          orElse: () => '',
        );

        if (otherEmail.isNotEmpty) {
          setState(() {
            otherUserEmail = otherEmail;
            final participantData = data['participants']?[otherEmail];
            otherUserName = participantData?['name'] ?? 'Пользователь';
            otherUserAvatarUrl = participantData?['avatarUrl'] ?? '';
          });
          return;
        }
      }
    }

    // Если данных нет, пробуем извлечь email из chatId
    final parts = widget.chatId.split('_');
    if (parts.length == 2) {
      final candidate = parts.firstWhere((email) => email != widget.currentUserEmail, orElse: () => '');
      if (candidate.isNotEmpty) {
        final userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: candidate)
            .limit(1)
            .get();
        if (userQuery.docs.isNotEmpty) {
          final userData = userQuery.docs.first.data();
          setState(() {
            otherUserEmail = candidate;
            otherUserName = userData['name'] ?? 'Пользователь';
            otherUserAvatarUrl = userData['profileImageUrl'] ?? '';
          });
        }
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final message = {
      'senderEmail': widget.currentUserEmail,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    };

    final chatRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);
    final chatDoc = await chatRef.get();

    if (!chatDoc.exists) {
      if (otherUserEmail == null || otherUserEmail!.isEmpty) return;

      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: widget.currentUserEmail)
          .limit(1)
          .get();

      final otherUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: otherUserEmail)
          .limit(1)
          .get();

      if (currentUserDoc.docs.isEmpty || otherUserDoc.docs.isEmpty) return;

      final currentUserData = currentUserDoc.docs.first.data();
      final otherUserData = otherUserDoc.docs.first.data();

      await chatRef.set({
        'participantsEmails': [widget.currentUserEmail, otherUserEmail],
        'participants': {
          widget.currentUserEmail: {
            'name': currentUserData['name'] ?? 'Пользователь',
            'avatarUrl': currentUserData['profileImageUrl'] ?? '',
          },
          otherUserEmail!: {
            'name': otherUserData['name'] ?? 'Пользователь',
            'avatarUrl': otherUserData['profileImageUrl'] ?? '',
          },
        },
        'lastMessage': text,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } else {
      await chatRef.update({
        'lastMessage': text,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }

    await chatRef.collection('messages').add(message);

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.themeData; // используем переданную тему
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            if (otherUserAvatarUrl.isNotEmpty)
              CircleAvatar(
                backgroundImage: NetworkImage(otherUserAvatarUrl),
                radius: 20,
              )
            else
              CircleAvatar(
                backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
                radius: 20,
                child: Icon(Icons.person, color: theme.colorScheme.onSurface),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                otherUserName.isNotEmpty ? otherUserName : 'Чат',
                style: theme.textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
                }

                final messages = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Message.fromMap(data);
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderEmail == widget.currentUserEmail;

                    final bgColor = isMe
                        ? theme.colorScheme.primary.withOpacity(0.15)
                        : theme.colorScheme.surfaceVariant;
                    final textColor = isMe
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface;

                    final borderRadius = BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    );

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: borderRadius,
                        ),
                        child: Text(
                          msg.text,
                          style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Введите сообщение',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                    style: theme.textTheme.bodyMedium,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 12),
                Ink(
                  decoration: ShapeDecoration(
                    color: theme.colorScheme.primary,
                    shape: const CircleBorder(),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.send, color: theme.colorScheme.onPrimary),
                    onPressed: _sendMessage,
                    tooltip: 'Отправить сообщение',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: theme.colorScheme.background,
    );
  }
}
