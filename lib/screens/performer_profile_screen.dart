import 'package:agregatorapp/models/service_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PerformerProfileScreen extends StatelessWidget {
  final String performerId;

  const PerformerProfileScreen({Key? key, required this.performerId}) : super(key: key);

  Future<Map<String, dynamic>?> fetchUserData() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(performerId).get();
    return userDoc.exists ? userDoc.data() : null;
  }

  Future<List<Service>> fetchUserServices() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('services')
        .where('masterId', isEqualTo: performerId)
        .get();

    return snapshot.docs.map((doc) => Service.fromFirestore(doc)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Профиль исполнителя')),
      body: FutureBuilder(
        future: Future.wait([fetchUserData(), fetchUserServices()]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final userData = snapshot.data![0] as Map<String, dynamic>?;
          final services = snapshot.data![1] as List<Service>;

          if (userData == null) return Center(child: Text('Пользователь не найден'));

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: userData['profileImageUrl'] != null &&
                          userData['profileImageUrl'].toString().isNotEmpty
                      ? NetworkImage(userData['profileImageUrl'])
                      : null,
                  child: userData['profileImageUrl'] == null ||
                          userData['profileImageUrl'].toString().isEmpty
                      ? Icon(Icons.person, size: 40)
                      : null,
                ),
                SizedBox(height: 12),
                Text(userData['name'] ?? 'Без имени',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                if (userData['bio'] != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(userData['bio'],
                        style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, color: Colors.amber),
                    SizedBox(width: 4),
                    Text('${userData['rating'] ?? 0} (${userData['reviewCount'] ?? 0} отзывов)'),
                  ],
                ),
                SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Объявления исполнителя',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                SizedBox(height: 8),
                ...services.map((s) => ListTile(
                      title: Text(s.title),
                      subtitle: Text(s.description),
                      trailing: Text('${s.price}₽'),
                    )),
              ],
            ),
          );
        },
      ),
    );
  }
}
