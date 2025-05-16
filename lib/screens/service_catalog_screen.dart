import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:agregatorapp/models/service_model.dart';
import 'package:agregatorapp/screens/service_detail_screen.dart'; // импортируем экран деталей

class ServiceCatalogScreen extends StatefulWidget {
  @override
  _ServiceCatalogScreenState createState() => _ServiceCatalogScreenState();
}

class _ServiceCatalogScreenState extends State<ServiceCatalogScreen> {
  List<Service> services = [];
  String selectedCategory = 'repair';

  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadServices();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Геолокация выключена");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("Нет доступа к геолокации");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print("Геолокация навсегда заблокирована");
      return;
    }

    Position position =
        await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
    });
  }

  Future<void> _loadServices() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    QuerySnapshot snapshot = await firestore.collection('services').get();

    setState(() {
      services = snapshot.docs.map((doc) => Service.fromFirestore(doc)).toList();
    });
  }

  List<Service> _getAllServices() {
    return services;
  }

String getCategoryLabel(String category) {
  switch (category) {
    case 'repair':
      return 'Ремонт';
    case 'cleaning':
      return 'Уборка';
    case 'tutoring':
      return 'Обучение';
    default:
      return category;
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Каталог услуг')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: selectedCategory,
              onChanged: (value) {
                setState(() {
                  selectedCategory = value!;
                });
              },
              items: <String>['repair', 'cleaning', 'tutoring']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child:  Text(getCategoryLabel(value)),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _getAllServices().length,
              itemBuilder: (context, index) {
                final service = _getAllServices()[index];
                return ListTile(
                  title: Text(service.title),
                  subtitle: Text('${service.description} - \$${service.price.toStringAsFixed(2)}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ServiceDetailScreen(service: service),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
