import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:agregatorapp/models/service_model.dart';
import 'package:agregatorapp/screens/service_detail_screen.dart';

class ServiceCatalogScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final bool isDarkTheme;

  ServiceCatalogScreen({
    this.onToggleTheme,
    this.isDarkTheme = false, // дефолтное значение
  });

  @override
  _ServiceCatalogScreenState createState() => _ServiceCatalogScreenState();
}

class _ServiceCatalogScreenState extends State<ServiceCatalogScreen> {
  List<Service> allServices = [];
  List<Service> filteredServices = [];
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

    double foundMaxPrice = 0;
    for (var s in services) {
      final double price = (s.price as num).toDouble();
      if (price > foundMaxPrice) foundMaxPrice = price;
    }

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

      final double price = (service.price as num).toDouble();
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('Каталог услуг'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6, color: colorScheme.onPrimary),
            tooltip: 'Переключить тему',
            onPressed: widget.onToggleTheme,
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
                  style: theme.textTheme.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Поиск по ключевым словам',
                    labelStyle: theme.textTheme.labelLarge?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
                    prefixIcon: Icon(Icons.search, color: colorScheme.onSurface.withOpacity(0.7)),
                    filled: true,
                    fillColor: colorScheme.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.primary),
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
                        dropdownColor: colorScheme.surfaceVariant,
                        style: theme.textTheme.bodyMedium,
                        decoration: InputDecoration(
                          labelText: 'Категория',
                          labelStyle: theme.textTheme.labelLarge?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
                          filled: true,
                          fillColor: colorScheme.surfaceVariant,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colorScheme.primary),
                          ),
                        ),
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Макс. цена: ${maxPrice.toInt()}', style: theme.textTheme.bodySmall),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: colorScheme.primary,
                              inactiveTrackColor: colorScheme.onSurface.withOpacity(0.3),
                              thumbColor: colorScheme.primary,
                              overlayColor: colorScheme.primary.withOpacity(0.2),
                              valueIndicatorColor: colorScheme.primary,
                            ),
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
                const SizedBox(height: 12),
                if (_currentPosition != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Макс. расстояние: ${maxDistanceKm.toInt()} км', style: theme.textTheme.bodySmall),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: colorScheme.primary,
                          inactiveTrackColor: colorScheme.onSurface.withOpacity(0.3),
                          thumbColor: colorScheme.primary,
                          overlayColor: colorScheme.primary.withOpacity(0.2),
                          valueIndicatorColor: colorScheme.primary,
                        ),
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
          Divider(height: 1, color: colorScheme.onSurface.withOpacity(0.2)),
          Expanded(
  child: filteredServices.isEmpty
      ? Center(
          child: Text(
            'Ничего не найдено',
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
          ),
        )
      : ListView.builder(
          itemCount: filteredServices.length,
          itemBuilder: (context, index) {
            final service = filteredServices[index];
            return Card(
              color: colorScheme.surface,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: Text(service.title, style: theme.textTheme.bodyLarge),
                subtitle: Text(
                  '${service.description} — \$${service.price}',
                  style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
                ),
                trailing: Icon(Icons.arrow_forward_ios, color: colorScheme.primary, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ServiceDetailScreen(
                        service: service,
                        themeData: Theme.of(context),
                        isDarkTheme: widget.isDarkTheme,
                        onToggleTheme: widget.onToggleTheme ?? () {},
                      ),
                    ),
                  );
                },
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
