import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agregatorapp/models/service_model.dart';
import 'package:agregatorapp/screens/chat_screen.dart';

class ServiceDetailScreen extends StatelessWidget {
  final Service service;

  const ServiceDetailScreen({Key? key, required this.service}) : super(key: key);

  String getCategoryLabel(String category) {
    switch (category) {
      case 'repair':
        return 'Ремонт';
      case 'cleaning':
        return 'Уборка';
      case 'tutoring':
        return 'Обучение';
      default:
        return category;
    }
  }

  Future<void> sendResponse(BuildContext context, String userId, String chatId) async {
  final responseRef = FirebaseFirestore.instance.collection('responses').doc(chatId);
  final doc = await responseRef.get();

  if (!doc.exists) {
    // Получаем имя исполнителя (кто откликается)
    final workerSnapshot = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final workerName = workerSnapshot.data()?['name'] ?? 'Исполнитель';

    // Получаем имя работодателя (владелец услуги)
    final ownerSnapshot = await FirebaseFirestore.instance.collection('users').doc(service.masterId).get();
    final ownerName = ownerSnapshot.data()?['name'] ?? 'Работодатель';

    await responseRef.set({
      'chatId': chatId,
      'serviceId': service.id,
      'serviceTitle': service.title,
      'ownerId': service.masterId,
      'ownerName': ownerName,      // кешируем для отображения
      'workerId': userId,
      'workerName': workerName,    // кешируем для отображения
      'status': 'pending',
      'createdAt': Timestamp.now(),
      'accepted': false,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Отклик отправлен!')),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Вы уже откликнулись.')),
    );
  }
}



  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserEmail = currentUser?.email ?? '';
    final currentUserId = currentUser?.uid ?? '';
    final otherUserEmail = service.masterEmail;

    final sortedEmails = [currentUserEmail, otherUserEmail]..sort();
    final chatId = '${sortedEmails[0]}_${sortedEmails[1]}';

    final isOwner = service.masterId == currentUserId;

    return Scaffold(
      appBar: AppBar(title: Text(service.title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (service.imageUrls.isNotEmpty)
              Image.network(
                service.imageUrls.first,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Описание:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(service.description),
                  const SizedBox(height: 16),
                  Text('Категория: ${getCategoryLabel(service.category)}'),
                  const SizedBox(height: 8),
                  Text('Цена: \$${service.price.toStringAsFixed(2)}'),
                  const SizedBox(height: 16),
                  const Text('Местоположение:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 250,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(service.location.latitude, service.location.longitude),
                        initialZoom: 13,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: ['a', 'b', 'c'],
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(service.location.latitude, service.location.longitude),
                              width: 40,
                              height: 40,
                              child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.person),
              label: const Text('Профиль исполнителя'),
              onPressed: () {
                Navigator.pushNamed(context, '/performer_profile', arguments: service.masterId);
              },
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.chat),
              label: const Text('Написать исполнителю'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(chatId: chatId, currentUserEmail: currentUserEmail),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            if (!isOwner)
              ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('Откликнуться'),
                onPressed: () => sendResponse(context, currentUserId, chatId),
              ),
          ],
        ),
      ),
    );
  }
}
