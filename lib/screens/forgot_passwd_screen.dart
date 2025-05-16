import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Функция для отправки ссылки для восстановления пароля
  Future<void> _resetPassword() async {
    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
      print('Password reset email sent.');
      
      // Показываем уведомление об успешной отправке ссылки
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ссылка для восстановления пароля отправлена на ваш email.')),
      );
    } on FirebaseAuthException catch (e) {
      print('Password reset failed: ${e.message}');
      
      // Показываем ошибку, если не удалось отправить ссылку
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Восстановление пароля')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _resetPassword,
              child: Text('Отправить ссылку для восстановления'),
            ),
          ],
        ),
      ),
    );
  }
}
