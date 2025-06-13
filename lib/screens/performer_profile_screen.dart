import 'package:agregatorapp/models/service_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PerformerProfileScreen extends StatefulWidget {
  final String performerId;
  final bool isDarkTheme;
  final VoidCallback onToggleTheme;

  const PerformerProfileScreen({
    super.key,
    required this.performerId,
    required this.isDarkTheme,
    required this.onToggleTheme,
  });

  @override
  State<PerformerProfileScreen> createState() => _PerformerProfileScreenState();
}

class _PerformerProfileScreenState extends State<PerformerProfileScreen> {
  late String currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  Future<Map<String, dynamic>?> fetchUserData() async {
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.performerId)
            .get();
    return userDoc.exists ? userDoc.data() : null;
  }

  Future<List<Service>> fetchUserServices() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('services')
            .where('masterId', isEqualTo: widget.performerId)
            .get();
    return snapshot.docs.map((doc) => Service.fromFirestore(doc)).toList();
  }

  Future<List<Map<String, dynamic>>> fetchReviews() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('reviews')
            .where('toUserId', isEqualTo: widget.performerId)
            .where('status', isEqualTo: 'approved') // Только одобренные отзывы
            .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> leaveReviewDialog() async {
    final controller = TextEditingController();
    double rating = 5.0;

    await showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setStateDialog) => AlertDialog(
                  title: const Text('Оставить отзыв'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          labelText: 'Комментарий',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('Оценка:'),
                      Slider(
                        value: rating,
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: rating.toString(),
                        onChanged:
                            (value) => setStateDialog(() => rating = value),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Отмена'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('reviews')
                            .add({
                              'fromUserId': currentUserId,
                              'toUserId': widget.performerId,
                              'comment': controller.text,
                              'rating': rating,
                              'createdAt': Timestamp.now(),
                              'status': 'pending',
                            });

                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Отзыв отправлен на модерацию и будет опубликован после одобрения.',
                            ),
                            duration: Duration(seconds: 4),
                          ),
                        );

                        setState(() {});
                      },
                      child: const Text('Оставить'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> reportUser() async {
    await FirebaseFirestore.instance.collection('complaints').add({
      'fromUserId': currentUserId,
      'toUserId': widget.performerId,
      'createdAt': Timestamp.now(),
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Жалоба отправлена')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = widget.isDarkTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль исполнителя')),
      body: FutureBuilder(
        future: Future.wait([
          fetchUserData(),
          fetchUserServices(),
          fetchReviews(),
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final userData = snapshot.data![0] as Map<String, dynamic>?;
          final services = snapshot.data![1] as List<Service>;
          final reviews = snapshot.data![2] as List<Map<String, dynamic>>;

          if (userData == null)
            return const Center(child: Text('Пользователь не найден'));

          double avgRating = 0;
          if (reviews.isNotEmpty) {
            avgRating =
                reviews.map((r) => r['rating'] as num).reduce((a, b) => a + b) /
                reviews.length;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage:
                            (userData['profileImageUrl'] ?? '')
                                    .toString()
                                    .isNotEmpty
                                ? NetworkImage(userData['profileImageUrl'])
                                : null,
                        child:
                            (userData['profileImageUrl'] ?? '')
                                    .toString()
                                    .isEmpty
                                ? const Icon(Icons.person, size: 40)
                                : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        userData['name'] ?? 'Без имени',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (userData['bio'] != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            userData['bio'],
                            style: TextStyle(
                              fontSize: 16,
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withOpacity(0.7),
                            ),
                          ),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            '${avgRating.toStringAsFixed(1)} (${reviews.length} отзывов)',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: leaveReviewDialog,
                  icon: const Icon(Icons.rate_review),
                  label: const Text('Оставить отзыв'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: reportUser,
                  icon: const Icon(Icons.report),
                  label: const Text('Пожаловаться'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Объявления исполнителя',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...services.map(
                  (s) => ListTile(
                    title: Text(s.title),
                    subtitle: Text(s.description),
                    trailing: Text('${s.price}₽'),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Отзывы',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ...reviews.map(
                  (r) => ListTile(
                    leading: const Icon(Icons.person),
                    title: Text('Оценка: ${r['rating']}/5'),
                    subtitle: Text(r['comment'] ?? ''),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      backgroundColor: theme.colorScheme.surface,
    );
  }
}
