import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'service_catalog_screen.dart';
import 'addedit_service_screen.dart';
import 'chat_list_screen.dart';
import 'services_map_screen.dart';
import 'my_jobs_screen.dart';
import 'responses_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String userEmail;
  final String userAvatarUrl;
  final VoidCallback? onToggleTheme; // <- добавьте
  final bool? isDarkTheme;

  const HomeScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userAvatarUrl,
    this.onToggleTheme,
    this.isDarkTheme,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late bool isDarkTheme;

  @override
  void initState() {
    super.initState();
    isDarkTheme = widget.isDarkTheme ?? false;
  }

  void toggleTheme() {
    setState(() {
      isDarkTheme = !isDarkTheme;
    });
    if (widget.onToggleTheme != null) {
      widget.onToggleTheme!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = isDarkTheme ? Colors.black : Colors.white;
    final textColor = isDarkTheme ? Colors.white : Colors.black87;
    final accentColor = Colors.blueAccent;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        titleSpacing: 0,
        title: Row(
          children: [
            Hero(
              tag: 'app_logo',
              child: Icon(
                Icons.miscellaneous_services_rounded,
                color: accentColor,
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Агрегатор услуг',
              style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDarkTheme ? Icons.light_mode : Icons.dark_mode,
              color: textColor,
            ),
            onPressed: toggleTheme,
            tooltip: isDarkTheme ? 'Светлая тема' : 'Тёмная тема',
          ),
          IconButton(
            icon: Icon(Icons.logout, color: textColor),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/');
            },
            tooltip: 'Выйти',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage:
                      widget.userAvatarUrl.isNotEmpty
                          ? NetworkImage(widget.userAvatarUrl)
                          : null,
                  backgroundColor:
                      isDarkTheme ? Colors.grey[800] : Colors.grey[300],
                  child:
                      widget.userAvatarUrl.isEmpty
                          ? Icon(Icons.person, size: 30, color: Colors.white70)
                          : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Здравствуйте, ${widget.userName}!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.userEmail,
              style: TextStyle(fontSize: 16, color: textColor.withOpacity(0.7)),
            ),
            const SizedBox(height: 30),
            Text(
              'Что вы хотите сделать?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: textColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),

            _buildMenuButton(
              context,
              icon: Icons.search,
              label: 'Перейти в каталог услуг',
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ServiceCatalogScreen(
                            isDarkTheme: isDarkTheme,
                            onToggleTheme: toggleTheme,
                          ),
                    ),
                  ),
              accentColor: accentColor,
            ),
            const SizedBox(height: 12),
            _buildMenuButton(
              context,
              icon: Icons.add,
              label: 'Добавить услугу',
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddEditServiceScreen(),
                    ),
                  ),
              accentColor: accentColor,
            ),
            const SizedBox(height: 12),
            _buildMenuButton(
              context,
              icon: Icons.chat,
              label: 'Перейти к чатам',
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ChatListScreen(
                            isDarkTheme: isDarkTheme,
                            onToggleTheme: toggleTheme,
                          ),
                    ),
                  ),
              accentColor: accentColor,
            ),
            const SizedBox(height: 12),
            _buildMenuButton(
              context,
              icon: Icons.map,
              label: 'Услуги на карте',
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ServicesMapScreen(
                            isDarkTheme: isDarkTheme,
                            onToggleTheme: toggleTheme,
                          ),
                    ),
                  ),
              accentColor: accentColor,
            ),
            const SizedBox(height: 12),
            _buildMenuButton(
              context,
              icon: Icons.work,
              label: 'Мои работы',
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => MyJobsScreen(
                            isDarkTheme: isDarkTheme,
                            onToggleTheme: toggleTheme,
                          ),
                    ),
                  ),
              accentColor: accentColor,
            ),
            const SizedBox(height: 12),
            _buildMenuButton(
              context,
              icon: Icons.people,
              label: 'Отклики',
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ResponsesScreen(
                            isDarkTheme: isDarkTheme,
                            onToggleTheme: toggleTheme,
                          ),
                    ),
                  ),
              accentColor: accentColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color accentColor,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          shadowColor: accentColor.withOpacity(0.5),
        ),
      ),
    );
  }
}
