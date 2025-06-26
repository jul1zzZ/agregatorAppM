import 'package:agregatorapp/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminPanelScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String userEmail;
  final VoidCallback onToggleTheme;
  final bool isDarkTheme;

  const AdminPanelScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.onToggleTheme,
    required this.isDarkTheme,
  });

  @override
  _AdminPanelScreenState createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Map<String, int> _servicesByDate = {};
  List<_UserCount> _topUsers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      final servicesSnap =
          await FirebaseFirestore.instance.collection('services').get();
      final services = servicesSnap.docs;

      Map<String, int> countByDate = {};
      Map<String, int> countByUser = {};
      final dateFormat = DateFormat('yyyy-MM-dd');

      for (var service in services) {
        final data = service.data();
        final createdAt = data['createdAt'];
        if (createdAt is Timestamp) {
          String day = dateFormat.format(createdAt.toDate());
          countByDate[day] = (countByDate[day] ?? 0) + 1;
        }

        String? masterId = data['masterId'];
        if (masterId != null && masterId.isNotEmpty) {
          countByUser[masterId] = (countByUser[masterId] ?? 0) + 1;
        }
      }

      var sortedUsers =
          countByUser.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
      sortedUsers = sortedUsers.take(5).toList();

      List<_UserCount> topUsersWithNames = [];

      for (var entry in sortedUsers) {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(entry.key)
                .get();
        final userData = userDoc.data();
        String userName =
            userData != null
                ? (userData['name'] ?? 'Без имени')
                : 'Неизвестный';
        topUsersWithNames.add(_UserCount(userName, entry.value));
      }

      setState(() {
        _servicesByDate = countByDate;
        _topUsers = topUsersWithNames;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки статистики: $e');
    }
  }

  Future<void> _toggleBlockUser(String userId, bool isBlocked) async {
    if (isBlocked) {
      // Разблокировать пользователя - удалить blockedUntil
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'blockedUntil': null,
      });
    } else {
      // Заблокировать без срока (по умолчанию 7 дней)
      final blockedUntil = DateTime.now().add(Duration(days: 7));
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'blockedUntil': blockedUntil,
      });
    }
  }

  Future<void> _deleteService(String serviceId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Подтвердите удаление'),
            content: const Text('Вы действительно хотите удалить эту услугу?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Удалить'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('services')
          .doc(serviceId)
          .delete();
      await _loadStatistics();
    }
  }

  Future<void> _approveReview(String reviewId) async {
    await FirebaseFirestore.instance.collection('reviews').doc(reviewId).update(
      {'status': 'approved'},
    );
  }

  Future<void> _rejectReview(String reviewId) async {
    await FirebaseFirestore.instance.collection('reviews').doc(reviewId).update(
      {'status': 'rejected'},
    );
  }

  Future<void> _approveComplaint(String complaintId) async {
    final days = await _showBlockDurationDialog();
    if (days == null) return; // отмена

    // Получаем жалобу
    final complaintDoc =
        await FirebaseFirestore.instance
            .collection('complaints')
            .doc(complaintId)
            .get();
    final complaintData = complaintDoc.data();
    if (complaintData == null) return;

    final toUserId = complaintData['toUserId'] ?? '';

    // Устанавливаем блокировку для пользователя
    final blockedUntil = DateTime.now().add(Duration(days: days));
    await FirebaseFirestore.instance.collection('users').doc(toUserId).update({
      'isBlocked': true,
      'blockedUntil': blockedUntil,
    });

    // Обновляем статус жалобы
    await FirebaseFirestore.instance
        .collection('complaints')
        .doc(complaintId)
        .update({'status': 'approved'});
  }

  Future<void> _rejectComplaint(String complaintId) async {
    await FirebaseFirestore.instance
        .collection('complaints')
        .doc(complaintId)
        .update({'status': 'rejected'});
  }

  Future<int?> _showBlockDurationDialog() async {
    final controller = TextEditingController(text: '7');
    return showDialog<int>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Введите срок блокировки (в днях)'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Количество дней'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () {
                  final value = int.tryParse(controller.text);
                  if (value == null || value <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Введите корректное число')),
                    );
                    return;
                  }
                  Navigator.of(context).pop(value);
                },
                child: const Text('Подтвердить'),
              ),
            ],
          ),
    );
  }

  String _translateStatus(String status) {
    switch (status) {
      case 'pending':
        return 'Ожидает одобрения';
      case 'approved':
        return 'Одобрен';
      case 'rejected':
        return 'Отклонён';
      default:
        return 'Неизвестно';
    }
  }

  Future<String> _getUserName(String userId) async {
    if (userId.isEmpty) return 'Неизвестный';
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
      final data = doc.data();
      return data?['name'] ?? 'Без имени';
    } catch (_) {
      return 'Неизвестный';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Админ-панель'),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkTheme ? Icons.dark_mode : Icons.light_mode),
            onPressed: widget.onToggleTheme,
            tooltip: 'Переключить тему',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder:
                        (context) => LoginScreen(
                          onToggleTheme: widget.onToggleTheme,
                          isDarkTheme: widget.isDarkTheme,
                        ),
                  ),
                );
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Пользователи'),
            Tab(text: 'Заявки'),
            Tab(text: 'Статистика'),
            Tab(text: 'Отзывы'),
            Tab(text: 'Жалобы'),
          ],
          isScrollable: true,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUsersTab(),
          _buildServicesTab(),
          _buildStatisticsTab(),
          _buildReviewsTab(),
          _buildComplaintsTab(),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final users = snapshot.data!.docs;

        if (users.isEmpty) {
          return const Center(child: Text('Нет пользователей'));
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final data = user.data() as Map<String, dynamic>;
            final name = data['name'] ?? 'Без имени';
            final email = data['email'] ?? '';
            final userType = data['userType'] ?? 'client';
            final blockedUntilTimestamp = data['blockedUntil'];
            DateTime? blockedUntil;
            if (blockedUntilTimestamp is Timestamp) {
              blockedUntil = blockedUntilTimestamp.toDate();
            }
            final now = DateTime.now();
            final isBlocked = blockedUntil != null && blockedUntil.isAfter(now);

            String blockedInfo = '';
            if (isBlocked) {
              blockedInfo =
                  ' (заблокирован до ${DateFormat('dd.MM.yyyy').format(blockedUntil)})';
            }

            return ListTile(
              leading: CircleAvatar(
                child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
              ),
              title: Text('$name$blockedInfo'),
              subtitle: Text('$email — $userType'),
              trailing: ElevatedButton(
                onPressed: () async {
                  await _toggleBlockUser(user.id, isBlocked);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isBlocked ? Colors.green : Colors.red,
                ),
                child: Text(isBlocked ? 'Разблокировать' : 'Заблокировать'),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildServicesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('services').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final services = snapshot.data!.docs;

        if (services.isEmpty) {
          return const Center(child: Text('Нет заявок'));
        }

        return ListView.builder(
          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = services[index];
            final data = service.data() as Map<String, dynamic>;
            final title = data['title'] ?? '';
            final masterId = data['masterId'] ?? '';
            final price = data['price'] ?? 0;

            return FutureBuilder<String>(
              future: _getUserName(masterId),
              builder: (context, snapshotName) {
                final masterName = snapshotName.data ?? 'Неизвестный';

                return ListTile(
                  title: Text(title),
                  subtitle: Text('Исполнитель: $masterName, Цена: $price'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await _deleteService(service.id);
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStatisticsTab() {
    final sortedDates = _servicesByDate.keys.toList()..sort();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'График публикаций услуг по датам',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (int i = 0; i < sortedDates.length; i++)
                        FlSpot(
                          i.toDouble(),
                          _servicesByDate[sortedDates[i]]!.toDouble(),
                        ),
                    ],
                    isCurved: true,
                    barWidth: 3,
                    color: Colors.blue,
                    dotData: FlDotData(show: false),
                  ),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < 0 ||
                            value.toInt() >= sortedDates.length) {
                          return const SizedBox.shrink();
                        }
                        final date = sortedDates[value.toInt()];
                        return Text(
                          DateFormat('MM-dd').format(DateTime.parse(date)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                ),
                gridData: FlGridData(show: true),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'ТОП-5 пользователей по количеству услуг',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _topUsers.length,
              itemBuilder: (context, index) {
                final user = _topUsers[index];
                return ListTile(
                  title: Text(user.userName),
                  trailing: Text(user.count.toString()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('reviews').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final reviews = snapshot.data!.docs;

        if (reviews.isEmpty) {
          return const Center(child: Text('Нет отзывов'));
        }

        return ListView.builder(
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final review = reviews[index];
            final data = review.data() as Map<String, dynamic>;
            final content = data['content'] ?? '';
            final status = data['status'] ?? 'pending';
            final userId = data['userId'] ?? '';

            return FutureBuilder<String>(
              future: _getUserName(userId),
              builder: (context, snapshotName) {
                final userName = snapshotName.data ?? 'Неизвестный';

                return ListTile(
                  title: Text(content),
                  subtitle: Text(
                    'Автор: $userName — Статус: ${_translateStatus(status)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (status == 'pending')
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () async {
                            await _approveReview(review.id);
                          },
                        ),
                      if (status == 'pending')
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () async {
                            await _rejectReview(review.id);
                          },
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildComplaintsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('complaints').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final complaints = snapshot.data!.docs;

        if (complaints.isEmpty) {
          return const Center(child: Text('Нет жалоб'));
        }

        return ListView.builder(
          itemCount: complaints.length,
          itemBuilder: (context, index) {
            final complaint = complaints[index];
            final data = complaint.data() as Map<String, dynamic>;
            final content = data['content'] ?? '';
            final status = data['status'] ?? 'pending';
            final fromUserId = data['fromUserId'] ?? '';
            final toUserId = data['toUserId'] ?? '';

            return FutureBuilder<List<String>>(
              future: Future.wait([
                _getUserName(fromUserId),
                _getUserName(toUserId),
              ]),
              builder: (context, snapshotNames) {
                if (!snapshotNames.hasData) {
                  return const ListTile(title: Text('Загрузка...'));
                }

                final names = snapshotNames.data!;
                final fromUserName = names[0];
                final toUserName = names[1];

                return ListTile(
                  title: Text(content),
                  subtitle: Text(
                    'От: $fromUserName\nКому: $toUserName\nСтатус: ${_translateStatus(status)}',
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (status == 'pending')
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () async {
                            await _approveComplaint(complaint.id);
                          },
                        ),
                      if (status == 'pending')
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () async {
                            await _rejectComplaint(complaint.id);
                          },
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _UserCount {
  final String userName;
  final int count;

  _UserCount(this.userName, this.count);
}
