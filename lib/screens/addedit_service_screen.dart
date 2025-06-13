import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:agregatorapp/models/service_model.dart';

class AddEditServiceScreen extends StatefulWidget {
  final Service? existingService;

  const AddEditServiceScreen({super.key, this.existingService});

  @override
  State<AddEditServiceScreen> createState() => _AddEditServiceScreenState();
}

class _AddEditServiceScreenState extends State<AddEditServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  String _title = '';
  String _description = '';
  double _price = 0;
  String _category = 'repair';
  GeoPoint _location = const GeoPoint(0, 0);
  List<File> _selectedImages = [];
  int _durationInHours = 1;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingService != null) {
      final s = widget.existingService!;
      _title = s.title;
      _description = s.description;
      _price = s.price;
      _category = s.category;
      _location = s.location;
    }
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    final hasPermission = await Geolocator.checkPermission();
    if (hasPermission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _location = GeoPoint(position.latitude, position.longitude);
    });
  }

  Future<void> _pickImages() async {
    final pickedFiles = await _picker.pickMultiImage();
    setState(() {
      _selectedImages = pickedFiles.map((e) => File(e.path)).toList();
    });
  }

  Future<List<String>> _saveImagesLocally() async {
    List<String> localPaths = [];

    for (final file in _selectedImages) {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final localFile = File('${directory.path}/$fileName.jpg');
      await file.copy(localFile.path);
      localPaths.add(localFile.path);
    }

    return localPaths;
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка: пользователь не авторизован')),
      );
      return;
    }

    final localFilePaths = await _saveImagesLocally();

    final now = Timestamp.now();
    final expiresAt = Timestamp.fromDate(
      now.toDate().add(Duration(hours: _durationInHours)),
    );

    final data = {
      'title': _title,
      'description': _description,
      'price': _price,
      'category': _category,
      'location': {'lat': _location.latitude, 'lng': _location.longitude},
      'imagePaths': localFilePaths,
      'createdAt': now,
      'expiresAt': expiresAt,
      'masterId': currentUser.uid,
      'masterEmail': currentUser.email ?? '',
    };

    if (widget.existingService == null) {
      await FirebaseFirestore.instance.collection('services').add(data);
    } else {
      await FirebaseFirestore.instance
          .collection('services')
          .doc(widget.existingService!.id)
          .update(data);
    }

    setState(() {
      _isLoading = false;
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingService == null
              ? 'Добавить услугу'
              : 'Редактировать услугу',
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      TextFormField(
                        initialValue: _title,
                        decoration: const InputDecoration(
                          labelText: 'Заголовок',
                        ),
                        validator:
                            (value) =>
                                value!.isEmpty ? 'Введите заголовок' : null,
                        onSaved: (value) => _title = value!,
                      ),
                      TextFormField(
                        initialValue: _description,
                        decoration: const InputDecoration(
                          labelText: 'Описание',
                        ),
                        maxLines: 3,
                        validator:
                            (value) =>
                                value!.isEmpty ? 'Введите описание' : null,
                        onSaved: (value) => _description = value!,
                      ),
                      TextFormField(
                        initialValue: _price > 0 ? _price.toString() : '',
                        decoration: const InputDecoration(labelText: 'Цена'),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        validator:
                            (value) =>
                                value == null || value.isEmpty
                                    ? 'Введите цену'
                                    : null,
                        onSaved:
                            (value) => _price = double.tryParse(value!) ?? 0,
                      ),
                      DropdownButtonFormField<String>(
                        value: _category,
                        decoration: const InputDecoration(
                          labelText: 'Категория',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'repair',
                            child: Text('Ремонт'),
                          ),
                          DropdownMenuItem(
                            value: 'cleaning',
                            child: Text('Уборка'),
                          ),
                          DropdownMenuItem(
                            value: 'tutoring',
                            child: Text('Обучение'),
                          ),
                        ],
                        onChanged:
                            (value) => setState(() => _category = value!),
                      ),
                      DropdownButtonFormField<int>(
                        value: _durationInHours,
                        decoration: const InputDecoration(
                          labelText: 'Срок действия (ч)',
                        ),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('1 час')),
                          DropdownMenuItem(value: 3, child: Text('3 часа')),
                          DropdownMenuItem(value: 6, child: Text('6 часов')),
                          DropdownMenuItem(value: 12, child: Text('12 часов')),
                          DropdownMenuItem(value: 24, child: Text('1 день')),
                          DropdownMenuItem(value: 48, child: Text('2 дня')),
                          DropdownMenuItem(value: 72, child: Text('3 дня')),
                        ],
                        onChanged:
                            (value) =>
                                setState(() => _durationInHours = value!),
                      ),
                      const SizedBox(height: 10),
                      Text('Фото (${_selectedImages.length})'),
                      ElevatedButton(
                        onPressed: _pickImages,
                        child: const Text('Выбрать фото'),
                      ),
                      const SizedBox(height: 10),
                      _location.latitude == 0
                          ? const Text('Определение местоположения...')
                          : Text(
                            'Ваше местоположение: ${_location.latitude}, ${_location.longitude}',
                          ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _saveService,
                        child: const Text('Сохранить услугу'),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
