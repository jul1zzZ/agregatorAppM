import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';


class HomeScreen extends StatelessWidget {
  final String userId;
  final String userName;
  final String userEmail;
  final String userAvatarUrl;

  const HomeScreen({
    Key? key,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userAvatarUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Агрегатор услуг'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              // Выход из Firebase Auth
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (userAvatarUrl.isNotEmpty)
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(userAvatarUrl),
                  )
                else
                  CircleAvatar(
                    radius: 30,
                    child: Icon(Icons.person, size: 30),
                  ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Здравствуйте, $userName!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              userEmail,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Что вы хотите сделать?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton.icon(
              icon: Icon(Icons.search),
              label: Text('Перейти в каталог услуг'),
              onPressed: () {
                Navigator.pushNamed(context, '/catalog');
              },
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              icon: Icon(Icons.add),
              label: Text('Добавить услугу'),
              onPressed: () {
                Navigator.pushNamed(context, '/add_service');
              },
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              icon: Icon(Icons.chat),
              label: Text('Перейти к чатам'),
              onPressed: () {
                Navigator.pushNamed(context, '/chat_list');
              },
            ),
          ],
        ),
      ),
    );
  }
}
