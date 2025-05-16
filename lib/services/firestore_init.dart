import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseInitializer {
  static Future<void> initializeAppData() async {
    final firestore = FirebaseFirestore.instance;

    // 1. Категории услуг
    await firestore.collection('serviceCategories').doc('repair').set({
      'name': 'Ремонт',
    });
    await firestore.collection('serviceCategories').doc('cleaning').set({
      'name': 'Уборка',
    });
    await firestore.collection('serviceCategories').doc('tutoring').set({
      'name': 'Репетиторы',
    });

    // 2. Тестовый мастер
    await firestore.collection('users').doc('test_master_1').set({
      'name': 'Иван Мастер',
      'email': 'master@example.com',
      'userType': 'master',
      'profileImageUrl': '',
      'rating': 4.9,
      'reviewCount': 12,
      'createdAt': DateTime.now().toIso8601String(),
    });

    // 3. Тестовый клиент
    await firestore.collection('users').doc('test_client_1').set({
      'name': 'Анна Клиент',
      'email': 'client@example.com',
      'userType': 'client',
      'profileImageUrl': '',
      'createdAt': DateTime.now().toIso8601String(),
    });

    // 4. Услуга мастера
    final serviceRef = await firestore.collection('services').add({
      'title': 'Ремонт мебели',
      'description': 'Сборка, починка и модернизация мебели',
      'price': 2500,
      'category': 'repair',
      'masterId': 'test_master_1',
      'location': {'lat': 55.75, 'lng': 37.61},
      'imageUrls': [],
      'createdAt': DateTime.now().toIso8601String(),
    });

    // 5. Заказ от клиента
    final orderRef = await firestore.collection('orders').add({
      'serviceId': serviceRef.id,
      'clientId': 'test_client_1',
      'masterId': 'test_master_1',
      'status': 'pending',
      'scheduledDate': DateTime.now().add(Duration(days: 2)).toIso8601String(),
      'createdAt': DateTime.now().toIso8601String(),
      'reviewLeft': false,
    });

    // 6. Отзыв к заказу
    await firestore.collection('reviews').add({
      'masterId': 'test_master_1',
      'clientId': 'test_client_1',
      'orderId': orderRef.id,
      'rating': 5,
      'comment': 'Отличная работа, спасибо!',
      'createdAt': DateTime.now().toIso8601String(),
    });

    // 7. Чат поддержки
    final supportChatRef = firestore.collection('supportChats').doc('chat_test_1');
    await supportChatRef.set({
      'userId': 'test_client_1',
      'createdAt': DateTime.now().toIso8601String(),
      'status': 'open',
    });

    await supportChatRef.collection('messages').add({
      'sender': 'user',
      'text': 'У меня проблема с заказом.',
      'timestamp': DateTime.now().toIso8601String(),
    });

    await supportChatRef.collection('messages').add({
      'sender': 'support',
      'text': 'Опишите, пожалуйста, подробнее проблему.',
      'timestamp': DateTime.now().toIso8601String(),
    });

    print('Firestore инициализирован с тестовыми данными.');
  }
}
