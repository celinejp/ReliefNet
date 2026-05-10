import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../services/volunteer_service.dart';

const _bg = Color(0xFF1A202C);
const _cardBg = Color(0xFF2D3748);
const _borderColor = Color(0xFF4A5568);
const _hintColor = Color(0xFF718096);
const _labelColor = Color(0xFFA0AEC0);
const _primaryBlue = Color(0xFF3182CE);

const List<Map<String, String>> kDonationTypes = [
  {'value': 'food', 'label': 'Food'},
  {'value': 'water', 'label': 'Water'},
  {'value': 'money', 'label': 'Money'},
  {'value': 'clothes', 'label': 'Clothes'},
  {'value': 'medicine', 'label': 'Medicine'},
  {'value': 'other', 'label': 'Other'},
];

class DonationFormScreen extends StatefulWidget {
  const DonationFormScreen({super.key});

  @override
  State<DonationFormScreen> createState() => _DonationFormScreenState();
}

class _DonationFormScreenState extends State<DonationFormScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _locationController = TextEditingController();
  String _selectedType = '';
  double? _lat;
  double? _lng;
  bool _loading = false;
  bool _submitted = false;
  File? _photo;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked != null && mounted) {
      setState(() => _photo = File(picked.path));
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add Photo',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _pickPhoto(ImageSource.camera);
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _pickPhoto(ImageSource.gallery);
                    },
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Choose Photo'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF276749),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
              ],
            ),
            if (_photo != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  setState(() => _photo = null);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text('Remove Photo',
                    style: TextStyle(color: Colors.red)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _detectLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Location services disabled.');
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnack('Location permission denied.');
          return;
        }
      }
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
        _locationController.text =
            'GPS: ${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}';
      });
    } catch (e) {
      if (!mounted) return;
      _showSnack('Could not detect location.');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submit() async {
    if (_nameController.text.isEmpty) {
      _showSnack('Please enter your name.');
      return;
    }
    if (_phoneController.text.isEmpty) {
      _showSnack('Please enter your phone.');
      return;
    }
    if (_selectedType.isEmpty) {
      _showSnack('Please select donation type.');
      return;
    }
    setState(() => _loading = true);
    final result = await VolunteerService.submitDonation(
      donorName: _nameController.text,
      donorPhone: _phoneController.text,
      type: _selectedType,
      amount: _amountController.text,
      locationText: _locationController.text,
      notes: _notesController.text,
      lat: _lat,
      lng: _lng,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() => _submitted = true);
    } else {
      _showSnack('Error submitting. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite, size: 64, color: Color(0xFF805AD5)),
                const SizedBox(height: 20),
                const Text('Donation Recorded',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
                const SizedBox(height: 12),
                const Text(
                  'Thank you for your generosity! Your donation has been recorded.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _hintColor, fontSize: 15),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => setState(() => _submitted = false),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14)),
                  child: const Text('Donate Again'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: _borderColor),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14)),
                  child: const Text('Back to Home'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Donate',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _bg,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Make a Donation',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
            const SizedBox(height: 4),
            const Text('Your donation helps disaster victims directly.',
                style: TextStyle(color: _hintColor, fontSize: 14)),
            const SizedBox(height: 24),
            _label('Your Name'),
            _textField(_nameController, 'Full name'),
            const SizedBox(height: 16),
            _label('Phone Number'),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Your phone number'),
            ),
            const SizedBox(height: 16),
            _label('What are you donating?'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kDonationTypes.map((type) {
                final selected = _selectedType == type['value'];
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedType = type['value']!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? _primaryBlue : _cardBg,
                      border: Border.all(
                          color: selected ? _primaryBlue : _borderColor),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      type['label']!,
                      style: TextStyle(
                          color: selected ? Colors.white : Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            _label('Amount / Quantity'),
            _textField(_amountController,
                'e.g. 50 canned goods, PHP 500, 10 bottles'),
            const SizedBox(height: 16),
            _label('Photo of Donation (optional)'),
            _photoPickerWidget(),
            const SizedBox(height: 16),
            _label('Pickup Location'),
            _textField(_locationController, 'Where can this be picked up?'),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _detectLocation,
              icon: const Icon(Icons.my_location),
              label: const Text('Use GPS'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF276749),
                  foregroundColor: Colors.white),
            ),
            const SizedBox(height: 16),
            _label('Additional Notes'),
            _textField(_notesController, 'Any other details...', maxLines: 3),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF805AD5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Donation',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: _labelColor)),
      );

  Widget _textField(TextEditingController ctrl, String hint,
          {int maxLines = 1}) =>
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: _inputDecoration(hint),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _hintColor),
        filled: true,
        fillColor: _cardBg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _borderColor)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _borderColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _primaryBlue, width: 2)),
      );

  Widget _photoPickerWidget() => GestureDetector(
        onTap: _showPhotoOptions,
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: _cardBg,
            border: Border.all(
              color: _photo != null
                  ? const Color(0xFF805AD5)
                  : _borderColor,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _photo != null
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        _photo!,
                        width: double.infinity,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _photo = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                )
              : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, size: 32, color: _hintColor),
                    SizedBox(height: 8),
                    Text('Tap to add photo',
                        style: TextStyle(color: _hintColor, fontSize: 13)),
                    Text('Camera or Gallery',
                        style: TextStyle(color: _hintColor, fontSize: 11)),
                  ],
                ),
        ),
      );
}
