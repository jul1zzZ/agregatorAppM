import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:agregatorapp/models/service_model.dart';
import 'package:agregatorapp/screens/service_detail_screen.dart';

class ServiceCatalogScreen extends StatefulWidget {
  @override
  _ServiceCatalogScreenState createState() => _ServiceCatalogScreenState();
}

class _ServiceCatalogScreenState extends State<ServiceCatalogScreen> {
  List<Service> allServices = [];
  List<Service> filteredServices = [];
  String searchKeyword = '';
  String selectedCategory = 'all';

  double minPrice = 0;
  double maxPrice = 20000; // текущий выбранный максимум цены
  double maxPriceLimit = 20000; // динамический максимум для слайдера цены

  double maxDistanceKm = 100; // максимум 100 км
  Position? _currentPosition;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadServices();
  }

  Future<void> _getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied)
      permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = position;
    });
  }

  Future<void> _loadServices() async {
    final snapshot = await FirebaseFirestore.instance.collection('services').get();
    final services = snapshot.docs.map((doc) => Service.fromFirestore(doc)).toList();

    // Найдём максимальную цену среди загруженных услуг
    double foundMaxPrice = 0;
    for (var s in services) {
      final double price = (s.price as num).toDouble(); // Явное приведение к double
      if (price > foundMaxPrice) foundMaxPrice = price;
    }

    // Если максимум слишком маленький, установим минимум для слайдера (например, 1000)
    final double priceSliderMax = foundMaxPrice > 1000 ? foundMaxPrice : 1000;

    setState(() {
      allServices = services;
      maxPriceLimit = priceSliderMax;
      if (maxPrice > maxPriceLimit) maxPrice = maxPriceLimit;
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<Service> results = allServices.where((service) {
      final matchesCategory = selectedCategory == 'all' || service.category == selectedCategory;

      final double price = (service.price as num).toDouble(); // Явное приведение к double
      final matchesPrice = price >= minPrice && price <= maxPrice;

      final matchesSearch = service.title.toLowerCase().contains(searchKeyword.toLowerCase()) ||
          service.description.toLowerCase().contains(searchKeyword.toLowerCase());

      double distanceKm = 0;
      if (_currentPosition != null) {
        final distance = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          service.location.latitude,
          service.location.longitude,
        );
        distanceKm = distance / 1000;
      }

      final matchesDistance = _currentPosition == null || distanceKm <= maxDistanceKm;

      return matchesCategory && matchesPrice && matchesSearch && matchesDistance;
    }).toList();

    setState(() {
      filteredServices = results;
    });
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
      appBar: AppBar(title: const Text('Каталог услуг')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Поиск по ключевым словам',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchKeyword = value;
                      _applyFilters();
                    });
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: const InputDecoration(labelText: 'Категория'),
                        onChanged: (value) {
                          setState(() {
                            selectedCategory = value!;
                            _applyFilters();
                          });
                        },
                        items: [
                          const DropdownMenuItem(value: 'all', child: Text('Все')),
                          ...['repair', 'cleaning', 'tutoring'].map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(getCategoryLabel(category)),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        children: [
                          const Text('Цена:'),
                          Expanded(
                            child: Slider(
                              min: 0,
                              max: maxPriceLimit,
                              divisions: 20,
                              value: maxPrice.clamp(0, maxPriceLimit),
                              label: '${maxPrice.toInt()}',
                              onChanged: (value) {
                                setState(() {
                                  maxPrice = value;
                                  _applyFilters();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_currentPosition != null)
                  Row(
                    children: [
                      const Text('Макс. расстояние:'),
                      Expanded(
                        child: Slider(
                          min: 1,
                          max: 100,
                          divisions: 20,
                          value: maxDistanceKm,
                          label: '${maxDistanceKm.toInt()} км',
                          onChanged: (value) {
                            setState(() {
                              maxDistanceKm = value;
                              _applyFilters();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: filteredServices.isEmpty
                ? const Center(child: Text('Ничего не найдено'))
                : ListView.builder(
                    itemCount: filteredServices.length,
                    itemBuilder: (context, index) {
                      final service = filteredServices[index];
                      return ListTile(
                        title: Text(service.title),
                        subtitle: Text('${service.description} — \$${service.price}'),
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
