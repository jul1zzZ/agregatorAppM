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
    _tabController = TabController(length: 3, vsync: this, initialIndex: 2);
    _loadStatistics();
  }

  Future<void> _toggleBlock(String userId, bool currentStatus) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'isBlocked': !currentStatus,
    });
  }

  Future<void> _deleteService(String serviceId) async {
    await FirebaseFirestore.instance
        .collection('services')
        .doc(serviceId)
        .delete();
    await _loadStatistics();
  }

  Future<void> _loadStatistics() async {
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
          userData != null ? (userData['name'] ?? 'Без имени') : 'Неизвестный';
      topUsersWithNames.add(_UserCount(userName, entry.value));
    }

    setState(() {
      _servicesByDate = countByDate;
      _topUsers = topUsersWithNames;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Админ-панель'),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkTheme ? Icons.dark_mode : Icons.light_mode),
            onPressed: widget.onToggleTheme,
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
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUsersTab(),
          _buildServicesTab(),
          _buildStatisticsTab(),
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

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final data = user.data() as Map<String, dynamic>;
            final name = data['name'] ?? 'Без имени';
            final email = data['email'] ?? '';
            final userType = data['userType'] ?? 'client';
            final isBlocked =
                data.containsKey('isBlocked')
                    ? data['isBlocked'] == true
                    : false;

            return ListTile(
              leading: Icon(Icons.person, color: isBlocked ? Colors.red : null),
              title: Text(name),
              subtitle: Text('$email | роль: $userType'),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isBlocked ? Colors.green : Colors.red,
                ),
                onPressed: () async {
                  await _toggleBlock(user.id, isBlocked);
                },
                child: Text(isBlocked ? 'Разблок.' : 'Блок.'),
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

        return ListView.builder(
          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = services[index];
            final title = service['title'] ?? 'Без названия';
            final description = service['description'] ?? '';

            return ListTile(
              leading: const Icon(Icons.work),
              title: Text(title),
              subtitle: Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
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
  }

  Widget _buildStatisticsTab() {
    if (_servicesByDate.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    List<BarChartGroupData> barGroups =
        _servicesByDate.entries
            .toList()
            .asMap()
            .entries
            .map(
              (entry) => BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: entry.value.value.toDouble(),
                    width: 16,
                    color: Colors.blue,
                  ),
                ],
              ),
            )
            .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'График публикаций услуг по датам:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                barGroups: barGroups,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final index = value.toInt();
                        final key = _servicesByDate.keys.elementAt(index);
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            key.substring(5),
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'ТОП-5 пользователей по количеству услуг:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._topUsers.map(
            (user) => ListTile(
              leading: const Icon(Icons.person),
              title: Text(user.userName),
              trailing: Text(user.count.toString()),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateCount {
  final String date;
  final int count;
  _DateCount(this.date, this.count);
}

class _UserCount {
  final String userName;
  final int count;
  _UserCount(this.userName, this.count);
}
