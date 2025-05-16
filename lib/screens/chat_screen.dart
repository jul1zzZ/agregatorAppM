import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agregatorapp/models/message_model.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String currentUserEmail;

  const ChatScreen({
    Key? key,
    required this.chatId,
    required this.currentUserEmail,
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

    // Если чат ещё не существует — создаём
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
      // Обновляем lastMessage
      await chatRef.update({
        'lastMessage': text,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }

    // Добавляем сообщение
    await chatRef.collection('messages').add(message);

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (otherUserAvatarUrl.isNotEmpty)
              CircleAvatar(
                backgroundImage: NetworkImage(otherUserAvatarUrl),
                radius: 18,
              )
            else
              const CircleAvatar(
                child: Icon(Icons.person),
                radius: 18,
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                otherUserName.isNotEmpty ? otherUserName : 'Чат',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
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
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final messages = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Message.fromMap(data);
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderEmail == widget.currentUserEmail;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[200] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(msg.text),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Введите сообщение',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
