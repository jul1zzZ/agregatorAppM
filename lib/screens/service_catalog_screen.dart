import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:agregatorapp/models/service_model.dart';
import 'package:agregatorapp/screens/service_detail_screen.dart';
import 'package:agregatorapp/screens/compare_services_screen.dart';

class ServiceCatalogScreen extends StatefulWidget {
  final bool isDarkTheme;
  final VoidCallback onToggleTheme;

  const ServiceCatalogScreen({
    super.key,
    required this.isDarkTheme,
    required this.onToggleTheme,
  });

  @override
  _ServiceCatalogScreenState createState() => _ServiceCatalogScreenState();
}

class _ServiceCatalogScreenState extends State<ServiceCatalogScreen> {
  List<Service> allServices = [];
  List<Service> filteredServices = [];
  List<Service> selectedForComparison = [];

  String searchKeyword = '';
  String selectedCategory = 'all';
  double minPrice = 0;
  double maxPrice = 20000;
  double maxPriceLimit = 20000;
  double maxDistanceKm = 100;

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
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = position;
    });
  }

  Future<void> _loadServices() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('services').get();
    final services =
        snapshot.docs.map((doc) => Service.fromFirestore(doc)).toList();

    double foundMaxPrice = services.fold(
      0,
      (prev, s) =>
          (s.price as num).toDouble() > prev
              ? (s.price as num).toDouble()
              : prev,
    );
    final double priceSliderMax = foundMaxPrice > 1000 ? foundMaxPrice : 1000;

    setState(() {
      allServices = services;
      maxPriceLimit = priceSliderMax;
      if (maxPrice > maxPriceLimit) maxPrice = maxPriceLimit;
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<Service> results =
        allServices.where((service) {
          final matchesCategory =
              selectedCategory == 'all' || service.category == selectedCategory;
          final double price = (service.price as num).toDouble();
          final matchesPrice = price >= minPrice && price <= maxPrice;
          final matchesSearch =
              service.title.toLowerCase().contains(
                searchKeyword.toLowerCase(),
              ) ||
              service.description.toLowerCase().contains(
                searchKeyword.toLowerCase(),
              );

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

          final matchesDistance =
              _currentPosition == null || distanceKm <= maxDistanceKm;

          return matchesCategory &&
              matchesPrice &&
              matchesSearch &&
              matchesDistance;
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

  void _toggleSelection(Service service) {
    setState(() {
      if (selectedForComparison.contains(service)) {
        selectedForComparison.remove(service);
      } else {
        selectedForComparison.add(service);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkTheme;
    final bgColor = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final accentColor = Colors.blueAccent;
    final surfaceVariant = isDark ? Colors.grey[900]! : Colors.grey[100]!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        title: const Text('Каталог услуг'),
        actions: [
          if (selectedForComparison.length >= 2)
            IconButton(
              icon: const Icon(Icons.compare),
              tooltip: 'Сравнить выбранные',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => CompareServicesScreen(
                          servicesToCompare: selectedForComparison,
                          isDarkTheme: isDark,
                        ),
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Поиск по ключевым словам',
                    labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                    prefixIcon: Icon(
                      Icons.search,
                      color: textColor.withOpacity(0.7),
                    ),
                    filled: true,
                    fillColor: surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchKeyword = value;
                      _applyFilters();
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedCategory,
                        dropdownColor: surfaceVariant,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: 'Категория',
                          labelStyle: TextStyle(
                            color: textColor.withOpacity(0.7),
                          ),
                          filled: true,
                          fillColor: surfaceVariant,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            selectedCategory = value!;
                            _applyFilters();
                          });
                        },
                        items: [
                          const DropdownMenuItem(
                            value: 'all',
                            child: Text('Все'),
                          ),
                          ...['repair', 'cleaning', 'tutoring'].map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(getCategoryLabel(category)),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Макс. цена: ${maxPrice.toInt()}',
                            style: TextStyle(color: textColor),
                          ),
                          Slider(
                            min: 0,
                            max: maxPriceLimit,
                            value: maxPrice.clamp(0, maxPriceLimit),
                            onChanged: (value) {
                              setState(() {
                                maxPrice = value;
                                _applyFilters();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_currentPosition != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Макс. расстояние: ${maxDistanceKm.toInt()} км',
                        style: TextStyle(color: textColor),
                      ),
                      Slider(
                        min: 1,
                        max: 100,
                        value: maxDistanceKm,
                        onChanged: (value) {
                          setState(() {
                            maxDistanceKm = value;
                            _applyFilters();
                          });
                        },
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child:
                filteredServices.isEmpty
                    ? Center(
                      child: Text(
                        'Ничего не найдено',
                        style: TextStyle(color: textColor.withOpacity(0.6)),
                      ),
                    )
                    : ListView.builder(
                      itemCount: filteredServices.length,
                      itemBuilder: (context, index) {
                        final service = filteredServices[index];
                        final isSelected = selectedForComparison.contains(
                          service,
                        );

                        return Card(
                          color: surfaceVariant,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side:
                                isSelected
                                    ? BorderSide(color: accentColor, width: 2)
                                    : BorderSide.none,
                          ),
                          child: ListTile(
                            title: Text(
                              service.title,
                              style: TextStyle(color: textColor),
                            ),
                            subtitle: Text(
                              '${service.description} — ${service.price}₽',
                              style: TextStyle(
                                color: textColor.withOpacity(0.7),
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.visibility,
                                    color: textColor,
                                  ),
                                  tooltip: 'Подробнее',
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => ServiceDetailScreen(
                                              service: service,
                                              themeData: Theme.of(context),
                                              isDarkTheme: widget.isDarkTheme,
                                              onToggleTheme:
                                                  widget.onToggleTheme,
                                            ),
                                      ),
                                    );
                                  },
                                ),
                                Icon(
                                  isSelected
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank,
                                  color: accentColor,
                                ),
                              ],
                            ),
                            onTap: () => _toggleSelection(service),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
