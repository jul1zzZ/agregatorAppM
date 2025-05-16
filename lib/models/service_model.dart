import 'package:cloud_firestore/cloud_firestore.dart';

class Service {
  final String id;
  final String title;
  final String description;
  final double price;
  final String category;
  final GeoPoint location;
  final List<String> imageUrls;
  final String masterId;
  final String masterEmail; // ✅ Добавлено

  Service({
    this.id = '',
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.location,
    required this.imageUrls,
    required this.masterId,
    required this.masterEmail, // ✅ Добавлено
  });

  factory Service.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    GeoPoint location;
    if (data['location'] != null &&
        data['location']['lat'] != null &&
        data['location']['lng'] != null) {
      location = GeoPoint(
        (data['location']['lat'] as num).toDouble(),
        (data['location']['lng'] as num).toDouble(),
      );
    } else {
      location = GeoPoint(0, 0);
    }

    double price = 0.0;
    if (data['price'] != null && data['price'] is num) {
      price = (data['price'] as num).toDouble();
    }

    List<String> imageUrls = [];
    if (data['imageUrls'] != null && data['imageUrls'] is List) {
      imageUrls = List<String>.from(data['imageUrls']);
    }

    return Service(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: price,
      category: data['category'] ?? '',
      location: location,
      imageUrls: imageUrls,
      masterId: data['masterId'] ?? '',
      masterEmail: data['masterEmail'] ?? '', // ✅ Добавлено
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'location': {
        'lat': location.latitude,
        'lng': location.longitude,
      },
      'imageUrls': imageUrls,
      'masterId': masterId,
      'masterEmail': masterEmail, // ✅ Добавлено
    };
  }

  Future<void> create() async {
    await FirebaseFirestore.instance.collection('services').add(toMap());
  }

  Future<void> update() async {
    if (id.isEmpty) return;
    await FirebaseFirestore.instance.collection('services').doc(id).update(toMap());
  }

  Future<void> delete() async {
    if (id.isEmpty) return;
    await FirebaseFirestore.instance.collection('services').doc(id).delete();
  }
}
