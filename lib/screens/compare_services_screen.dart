import 'package:flutter/material.dart';
import 'package:agregatorapp/models/service_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CompareServicesScreen extends StatefulWidget {
  final List<Service> servicesToCompare;
  final bool isDarkTheme;

  const CompareServicesScreen({
    super.key,
    required this.servicesToCompare,
    required this.isDarkTheme,
  });

  @override
  State<CompareServicesScreen> createState() => _CompareServicesScreenState();
}

class _CompareServicesScreenState extends State<CompareServicesScreen> {
  Map<String, Map<String, dynamic>> userInfo = {};

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    for (var service in widget.servicesToCompare) {
      final uid = service.masterId;
      if (!userInfo.containsKey(uid)) {
        final doc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          userInfo[uid] = {
            'name': data['name'] ?? 'Неизвестно',
            'rating': (data['rating'] ?? 0).toDouble(),
          };
        }
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkTheme;
    final textColor = isDark ? Colors.white : Colors.black87;
    final bgColor = isDark ? Colors.black : Colors.white;
    final cardColor = isDark ? Colors.grey[900] : Colors.grey[100];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        title: const Text('Сравнение услуг'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children:
              widget.servicesToCompare.map((service) {
                final master = userInfo[service.masterId];
                final masterName = master?['name'] ?? 'Загрузка...';
                final rating = master?['rating']?.toStringAsFixed(1) ?? '-';

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color:
                            isDark
                                ? Colors.black26
                                : Colors.grey.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.person, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              masterName,
                              style: TextStyle(color: textColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 18, color: Colors.amber),
                          const SizedBox(width: 6),
                          Text(rating, style: TextStyle(color: textColor)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.attach_money, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            '${service.price} ₽',
                            style: TextStyle(color: textColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Описание:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        service.description,
                        maxLines: 6,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: textColor.withOpacity(0.8)),
                      ),
                    ],
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }
}
