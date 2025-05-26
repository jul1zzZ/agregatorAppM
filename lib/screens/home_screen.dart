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
        titleSpacing: 0,
        title: Row(
          children: [
            Hero(
              tag: 'app_logo',
              child: Icon(
                Icons.miscellaneous_services_rounded,
                color: Colors.blueAccent,
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Агрегатор услуг',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
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
                CircleAvatar(
                  radius: 30,
                  backgroundImage:
                      userAvatarUrl.isNotEmpty ? NetworkImage(userAvatarUrl) : null,
                  child: userAvatarUrl.isEmpty ? const Icon(Icons.person, size: 30) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Здравствуйте, $userName!',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(userEmail, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
            const SizedBox(height: 20),
            const Text(
              'Что вы хотите сделать?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('Перейти в каталог услуг'),
              onPressed: () => Navigator.pushNamed(context, '/catalog'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Добавить услугу'),
              onPressed: () => Navigator.pushNamed(context, '/add_service'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.chat),
              label: const Text('Перейти к чатам'),
              onPressed: () => Navigator.pushNamed(context, '/chat_list'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.map),
              label: const Text('Услуги на карте'),
              onPressed: () => Navigator.pushNamed(context, '/map'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.work),
              label: const Text('Мои работы'),
              onPressed: () => Navigator.pushNamed(context, '/my_jobs'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.people),
              label: const Text('Отклики'),
              onPressed: () => Navigator.pushNamed(context, '/responses'),
            ),
          ],
        ),
      ),
    );
  }
}
