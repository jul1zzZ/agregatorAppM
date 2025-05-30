import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

class MyJobsScreen extends StatelessWidget {
  final bool isDarkTheme;
  final VoidCallback onToggleTheme;

  const MyJobsScreen({
    super.key,
    required this.isDarkTheme,
    required this.onToggleTheme,
  });

  Stream<List<QueryDocumentSnapshot>> _activeResponsesStream(String userId) {
    return FirebaseFirestore.instance
        .collection('responses')
        .where('workerId', isEqualTo: userId)
        .where('accepted', isEqualTo: true)
        .where('status', isNotEqualTo: 'done') // активные
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  Stream<List<QueryDocumentSnapshot>> _archivedResponsesStream(String userId) {
    return FirebaseFirestore.instance
        .collection('responses_archive')
        .where('workerId', isEqualTo: userId)
        .where('status', isEqualTo: 'done') // завершённые
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    final combinedStream = CombineLatestStream.combine2<
      List<QueryDocumentSnapshot>,
      List<QueryDocumentSnapshot>,
      List<QueryDocumentSnapshot>
    >(
      _activeResponsesStream(currentUserId),
      _archivedResponsesStream(currentUserId),
      (active, archived) => [...active, ...archived],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Мои работы')),
      body: StreamBuilder<List<QueryDocumentSnapshot>>(
        stream: combinedStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          final docs = snapshot.data ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text('Нет активных и завершённых работ'),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final status = data['status'] ?? 'unknown';
              final isDone = status == 'done';

              return ListTile(
                title: Text(data['serviceTitle'] ?? 'Без названия'),
                subtitle: Text(
                  'Работодатель: ${data['ownerName'] ?? 'Неизвестен'}',
                ),
                trailing:
                    isDone
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Text(
                          'В процессе',
                          style: TextStyle(color: Colors.orange),
                        ),
              );
            },
          );
        },
      ),
    );
  }
}
