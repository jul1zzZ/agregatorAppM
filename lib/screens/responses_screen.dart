import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResponsesScreen extends StatelessWidget {
  final bool isDarkTheme;
  final VoidCallback onToggleTheme;

  const ResponsesScreen({
    super.key,
    required this.isDarkTheme,
    required this.onToggleTheme,
  });

  Future<void> markJobAsCompleted(
    BuildContext context,
    String serviceId,
    String responseId,
    Map<String, dynamic> serviceData,
    Map<String, dynamic> responseData,
  ) async {
    final archiveServiceRef = FirebaseFirestore.instance
        .collection('services_archive')
        .doc(serviceId);
    final archiveResponseRef = FirebaseFirestore.instance
        .collection('responses_archive')
        .doc(responseId);
    final serviceRef = FirebaseFirestore.instance
        .collection('services')
        .doc(serviceId);
    final responseRef = FirebaseFirestore.instance
        .collection('responses')
        .doc(responseId);

    try {
      // Копируем услугу в архив
      await archiveServiceRef.set(serviceData);

      // Копируем отклик в архив с обновлением статуса
      final updatedResponseData = Map<String, dynamic>.from(responseData);
      updatedResponseData['status'] = 'done';
      await archiveResponseRef.set(updatedResponseData);

      // Удаляем из основных коллекций
      await serviceRef.delete();
      await responseRef.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Работа завершена и перемещена в архив')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка при завершении: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Отклики')),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('responses')
                .where('ownerId', isEqualTo: currentUserId)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty)
            return const Center(child: Text('Пока нет откликов'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final workerName = data['workerName'] ?? 'Без имени';
              final serviceTitle = data['serviceTitle'] ?? 'Без названия';
              final accepted = data['accepted'] ?? false;
              final serviceId = data['serviceId'];

              return FutureBuilder<DocumentSnapshot>(
                future:
                    FirebaseFirestore.instance
                        .collection('services')
                        .doc(serviceId)
                        .get(),
                builder: (context, serviceSnapshot) {
                  if (!serviceSnapshot.hasData) {
                    return const ListTile(
                      title: Text('Загрузка данных услуги...'),
                    );
                  }

                  final serviceData =
                      serviceSnapshot.data!.data() as Map<String, dynamic>?;

                  return ListTile(
                    title: Text('$workerName — $serviceTitle'),
                    subtitle: Text(accepted ? 'Принят' : 'Ожидает решения'),
                    trailing:
                        accepted
                            ? ElevatedButton(
                              onPressed: () {
                                if (serviceData != null) {
                                  markJobAsCompleted(
                                    context,
                                    serviceId,
                                    doc.id,
                                    serviceData,
                                    data,
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Ошибка: услуга не найдена',
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: const Text('Работа выполнена'),
                            )
                            : ElevatedButton(
                              onPressed: () {
                                FirebaseFirestore.instance
                                    .collection('responses')
                                    .doc(doc.id)
                                    .update({'accepted': true});
                              },
                              child: const Text('Принять'),
                            ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
