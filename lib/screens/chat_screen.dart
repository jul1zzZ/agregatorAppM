import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agregatorapp/models/message_model.dart'; // модель Message

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String currentUserEmail;  // теперь email

   const ChatScreen({
    Key? key, // ✅ добавили key
    required this.chatId,
    required this.currentUserEmail,
  }) : super(key: key); // ✅ передали key в super

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

    if (!chatDoc.exists) return;

    final data = chatDoc.data();
    if (data == null) return;

    // Берём список email участников
    final participantsEmails = List<String>.from(data['participantsEmails'] ?? []);

    // Ищем email собеседника (не текущий)
    final otherEmail = participantsEmails.firstWhere(
      (email) => email != widget.currentUserEmail,
      orElse: () => '',
    );

    if (otherEmail.isEmpty) return;

    // Ищем пользователя в users по email
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: otherEmail)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return;

    final userData = querySnapshot.docs.first.data();

    setState(() {
      otherUserEmail = otherEmail;
      otherUserName = userData['name'] ?? 'Пользователь';
      otherUserAvatarUrl = userData['profileImageUrl'] ?? '';
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final message = {
      'senderEmail': widget.currentUserEmail,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    };

    FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add(message);

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
