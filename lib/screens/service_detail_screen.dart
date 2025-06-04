import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agregatorapp/models/service_model.dart';
import 'package:agregatorapp/screens/chat_screen.dart';

class ServiceDetailScreen extends StatelessWidget {
  final Service service;
  final bool isDarkTheme;
  final ThemeData themeData;
  final VoidCallback
  onToggleTheme; // Уже не нужен, но оставлю на случай, если в будущем понадобится

  const ServiceDetailScreen({
    super.key,
    required this.service,
    required this.isDarkTheme,
    required this.themeData,
    required this.onToggleTheme,
  });

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

  Future<void> sendResponse(
    BuildContext context,
    String userId,
    String chatId,
  ) async {
    final responseRef = FirebaseFirestore.instance
        .collection('responses')
        .doc(chatId);
    final doc = await responseRef.get();

    if (!doc.exists) {
      final workerSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
      final workerName = workerSnapshot.data()?['name'] ?? 'Исполнитель';

      final ownerSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(service.masterId)
              .get();
      final ownerName = ownerSnapshot.data()?['name'] ?? 'Работодатель';

      await responseRef.set({
        'chatId': chatId,
        'serviceId': service.id,
        'serviceTitle': service.title,
        'ownerId': service.masterId,
        'ownerName': ownerName,
        'workerId': userId,
        'workerName': workerName,
        'status': 'pending',
        'createdAt': Timestamp.now(),
        'accepted': false,
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Отклик отправлен!')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Вы уже откликнулись.')));
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

    final bgColor = isDarkTheme ? Colors.black : Colors.white;
    final textColor = isDarkTheme ? Colors.white : Colors.black87;
    final cardColor = isDarkTheme ? Colors.grey[900]! : Colors.grey[100]!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(service.title),
        backgroundColor: bgColor,
        foregroundColor: textColor,
        // Убрана кнопка переключения темы:
        // actions: [ ... ],
        elevation: 0,
      ),
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
                  Text(
                    'Описание:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(service.description, style: TextStyle(color: textColor)),
                  const SizedBox(height: 16),
                  Text(
                    'Категория: ${getCategoryLabel(service.category)}',
                    style: TextStyle(color: textColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Цена: \$${service.price.toStringAsFixed(2)}',
                    style: TextStyle(color: textColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Местоположение:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 250,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(
                          service.location.latitude,
                          service.location.longitude,
                        ),
                        initialZoom: 13,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: ['a', 'b', 'c'],
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(
                                service.location.latitude,
                                service.location.longitude,
                              ),
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.location_pin,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
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
                Navigator.pushNamed(
                  context,
                  '/performer_profile',
                  arguments: service.masterId,
                );
              },
            ),
            const SizedBox(height: 8),
            if (!isOwner)
              ElevatedButton.icon(
                icon: const Icon(Icons.chat),
                label: const Text('Написать исполнителю'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ChatScreen(
                            chatId: chatId,
                            currentUserEmail: currentUserEmail,
                            themeData: themeData,
                            isDarkTheme: isDarkTheme,
                            onToggleTheme: onToggleTheme,
                          ),
                    ),
                  );
                },
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Это ваше объявление',
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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
