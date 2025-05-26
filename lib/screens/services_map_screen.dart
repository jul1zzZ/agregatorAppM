import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

// Модель услуги
class Service {
  final String id;
  final String title;
  final double price;
  final LatLng location;

  Service({
    required this.id,
    required this.title,
    required this.price,
    required this.location,
  });
}

class ServicesMapScreen extends StatefulWidget {
  final bool isDarkTheme;
  final VoidCallback onToggleTheme;

  const ServicesMapScreen({
    Key? key,
    required this.isDarkTheme,
    required this.onToggleTheme,
  }) : super(key: key);

  @override
  _ServicesMapScreenState createState() => _ServicesMapScreenState();
}

class _ServicesMapScreenState extends State<ServicesMapScreen> {
  final MapController _mapController = MapController();

  LatLng? _currentPosition;
  double _searchRadiusKm = 5;

  // Пример данных, позже подгружать из Firestore
  List<Service> allServices = [
    Service(id: '1', title: 'Услуга 1', price: 100, location: LatLng(55.751244, 37.618423)),
    Service(id: '2', title: 'Услуга 2', price: 200, location: LatLng(55.761244, 37.628423)),
    Service(id: '3', title: 'Услуга 3', price: 150, location: LatLng(55.781244, 37.638423)),
  ];

  List<Service> filteredServices = [];

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Включите службы геолокации')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Разрешение на геолокацию отклонено')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Разрешение на геолокацию отклонено навсегда')),
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition();

    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });

    _filterServices();
  }

  void _filterServices() {
    if (_currentPosition == null) return;

    final Distance distance = Distance();

    setState(() {
      filteredServices = allServices.where((service) {
        final double km = distance.as(
          LengthUnit.Kilometer,
          _currentPosition!,
          service.location,
        );
        return km <= _searchRadiusKm;
      }).toList();
    });

    _mapController.move(_currentPosition!, 13);
  }

  void _onRadiusChanged(double? value) {
    if (value == null) return;
    setState(() {
      _searchRadiusKm = value;
    });
    _filterServices();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Услуги на карте'),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
            tooltip: isDark ? 'Светлая тема' : 'Тёмная тема',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Text('Радиус поиска:'),
                const SizedBox(width: 8),
                DropdownButton<double>(
                  value: _searchRadiusKm,
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1 км')),
                    DropdownMenuItem(value: 5, child: Text('5 км')),
                    DropdownMenuItem(value: 10, child: Text('10 км')),
                    DropdownMenuItem(value: 20, child: Text('20 км')),
                  ],
                  onChanged: _onRadiusChanged,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.my_location),
                  label: const Text('Найти рядом со мной'),
                  onPressed: () async {
                    await _determinePosition();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _currentPosition == null
                ? const Center(child: CircularProgressIndicator())
                : FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentPosition!,
                      initialZoom: 13,
                      maxZoom: 18,
                      minZoom: 3,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
                        userAgentPackageName: 'com.example.agregatorapp',
                      ),
                      MarkerLayer(
                        markers: filteredServices.map((service) {
                          return Marker(
                            width: 40,
                            height: 40,
                            point: service.location,
                            child: GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Выбрана услуга: ${service.title}')),
                                );
                              },
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            width: 40,
                            height: 40,
                            point: _currentPosition!,
                            child: const Icon(
                              Icons.my_location,
                              color: Colors.blue,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
