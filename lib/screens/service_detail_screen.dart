import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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

  @override
  Widget build(BuildContext context) {
    final LatLng serviceLatLng = LatLng(
      service.location.latitude,
      service.location.longitude,
    );

    final currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    final otherUserEmail = service.masterEmail;

    // Простой способ создать уникальный chatId из двух email
    final sortedEmails = [currentUserEmail, otherUserEmail]..sort();
    final chatId = '${sortedEmails[0]}_${sortedEmails[1]}';

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
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 220,
                  color: Colors.grey[300],
                  child: const Center(child: Icon(Icons.broken_image, size: 40)),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Описание:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(service.description, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  Text('Категория: ${getCategoryLabel(service.category)}', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Цена: \$${service.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  const Text('Местоположение:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: serviceLatLng,
                          initialZoom: 13,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                            subdomains: ['a', 'b', 'c'],
                            userAgentPackageName: 'com.example.agregatorapp',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                width: 40,
                                height: 40,
                                point: serviceLatLng,
                                child: const Icon(Icons.location_pin, size: 40, color: Colors.red),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.chat),
          label: const Text('Написать исполнителю'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  key: UniqueKey(),
                  chatId: chatId,
                  currentUserEmail: currentUserEmail,
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
