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

const List<Map<String, String>> kCategories = [
  {'value': 'food', 'label': 'Food'},
  {'value': 'water', 'label': 'Water'},
  {'value': 'medical', 'label': 'Medical'},
  {'value': 'transport', 'label': 'Transport'},
  {'value': 'shelter', 'label': 'Shelter'},
  {'value': 'rescue', 'label': 'Rescue'},
  {'value': 'other', 'label': 'Other'},
];

class VolunteerFormScreen extends StatefulWidget {
  const VolunteerFormScreen({super.key});

  @override
  State<VolunteerFormScreen> createState() => _VolunteerFormScreenState();
}

class _VolunteerFormScreenState extends State<VolunteerFormScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = false;
  bool _submitted = false;
  bool _submittedNeed = false;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  List<String> _selectedCategories = [];
  double? _lat;
  double? _lng;

  String _urgency = 'normal';
  int _numberOfPeople = 1;
  int _capacity = 1;
  File? _photo;
  String? _photoPath;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 80);
      if (picked != null && mounted) {
        setState(() {
          _photo = File(picked.path);
          _photoPath = picked.path;
        });
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Could not open ${source.name}: $e');
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
                  setState(() {
                    _photo = null;
                    _photoPath = null;
                  });
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
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
        _locationController.text =
            'GPS: ${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}';
      });
      if (!mounted) return;
      _showSnack('Location detected!');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Could not detect location.');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  bool _validateForm() {
    if (_nameController.text.isEmpty) {
      _showSnack('Please enter your name.');
      return false;
    }
    if (_phoneController.text.isEmpty) {
      _showSnack('Please enter your phone number.');
      return false;
    }
    if (_selectedCategories.isEmpty) {
      _showSnack('Please select at least one category.');
      return false;
    }
    return true;
  }

  Future<void> _submitNeed() async {
    if (!_validateForm()) return;
    setState(() => _loading = true);
    final result = await VolunteerService.submitNeed(
      name: _nameController.text,
      phone: _phoneController.text,
      categories: _selectedCategories,
      urgency: _urgency,
      description: _descController.text,
      locationText: _locationController.text,
      lat: _lat,
      lng: _lng,
      numberOfPeople: _numberOfPeople,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() {
        _submitted = true;
        _submittedNeed = true;
      });
    } else {
      _showSnack('Error submitting. Please try again.');
    }
  }

  Future<void> _submitVolunteer() async {
    if (!_validateForm()) return;
    setState(() => _loading = true);
    final result = await VolunteerService.submitVolunteer(
      name: _nameController.text,
      phone: _phoneController.text,
      categories: _selectedCategories,
      description: _descController.text,
      locationText: _locationController.text,
      lat: _lat,
      lng: _lng,
      capacity: _capacity,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() {
        _submitted = true;
        _submittedNeed = false;
      });
    } else {
      _showSnack('Error submitting. Please try again.');
    }
  }

  void _resetForm() {
    setState(() {
      _submitted = false;
      _submittedNeed = false;
      _nameController.clear();
      _phoneController.clear();
      _descController.clear();
      _locationController.clear();
      _selectedCategories = [];
      _lat = null;
      _lng = null;
      _urgency = 'normal';
      _numberOfPeople = 1;
      _capacity = 1;
      _photo = null;
      _photoPath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _buildSuccess();
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Volunteer & Relief',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _primaryBlue,
          labelColor: Colors.white,
          unselectedLabelColor: _hintColor,
          tabs: const [
            Tab(text: 'I Need Help'),
            Tab(text: 'I Can Help'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNeedForm(),
          _buildVolunteerForm(),
        ],
      ),
    );
  }

  Widget _buildNeedForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Who needs help?',
              'Tell us what you need and we will find someone to help.'),
          const SizedBox(height: 20),
          _label('Your Name'),
          _textField(_nameController, 'Full name'),
          const SizedBox(height: 16),
          _label('Phone Number'),
          _phoneField(),
          const SizedBox(height: 16),
          _label('What do you need?'),
          _categorySelector(),
          const SizedBox(height: 16),
          _label('Urgency Level'),
          _urgencySelector(),
          const SizedBox(height: 16),
          _label('Number of People'),
          _numberSelector(
              _numberOfPeople, (v) => setState(() => _numberOfPeople = v)),
          const SizedBox(height: 16),
          _label('Description'),
          _textField(_descController, 'Describe your situation in detail...',
              maxLines: 4),
          const SizedBox(height: 16),
          _label('Photo (optional — helps identify the situation)'),
          _photoPickerWidget(_primaryBlue),
          const SizedBox(height: 16),
          _label('Location'),
          _textField(_locationController, 'e.g. Barangay 5 near bridge'),
          const SizedBox(height: 8),
          _gpsButton(),
          if (_lat != null) _gpsBadge(),
          const SizedBox(height: 28),
          _submitButton(
              'Submit Request for Help', _submitNeed, const Color(0xFFE53E3E)),
        ],
      ),
    );
  }

  Widget _buildVolunteerForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('How can you help?',
              'Register as a volunteer and get matched with people who need you.'),
          const SizedBox(height: 20),
          _label('Your Name'),
          _textField(_nameController, 'Full name'),
          const SizedBox(height: 16),
          _label('Phone Number'),
          _phoneField(),
          const SizedBox(height: 16),
          _label('What can you offer?'),
          _categorySelector(),
          const SizedBox(height: 16),
          _label('How many people can you help?'),
          _numberSelector(_capacity, (v) => setState(() => _capacity = v)),
          const SizedBox(height: 16),
          _label('Description'),
          _textField(_descController, 'Describe what you can offer...',
              maxLines: 4),
          const SizedBox(height: 16),
          _label('Photo (optional — helps show what you can offer)'),
          _photoPickerWidget(const Color(0xFF276749)),
          const SizedBox(height: 16),
          _label('Your Location'),
          _textField(_locationController, 'e.g. Barangay 5'),
          const SizedBox(height: 8),
          _gpsButton(),
          if (_lat != null) _gpsBadge(),
          const SizedBox(height: 28),
          _submitButton('Register as Volunteer', _submitVolunteer,
              const Color(0xFF276749)),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    final isNeed = _submittedNeed;
    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isNeed ? Icons.check_circle : Icons.volunteer_activism,
                size: 64,
                color: _primaryBlue,
              ),
              const SizedBox(height: 20),
              Text(
                isNeed ? 'Request Submitted' : 'Volunteer Registered',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                isNeed
                    ? 'We will find a volunteer for you. You will be contacted at ${_phoneController.text}.'
                    : 'Thank you! You will be contacted when someone needs your help.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _hintColor, fontSize: 15),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _resetForm,
                style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14)),
                child: const Text('Submit Another'),
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

  Widget _sectionHeader(String title, String sub) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(color: _hintColor, fontSize: 14)),
        ],
      );

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
        decoration: InputDecoration(
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
        ),
      );

  Widget _phoneField() => TextField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Phone number',
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
        ),
      );

  Widget _categorySelector() => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: kCategories.map((cat) {
          final selected = _selectedCategories.contains(cat['value']);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (selected) {
                  _selectedCategories.remove(cat['value']);
                } else {
                  _selectedCategories.add(cat['value']!);
                }
              });
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? _primaryBlue : _cardBg,
                border: Border.all(
                    color: selected ? _primaryBlue : _borderColor),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                cat['label']!,
                style: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
          );
        }).toList(),
      );

  Widget _urgencySelector() => Row(
        children: [
          _urgencyChip('critical', 'Critical', const Color(0xFF9B2C2C),
              const Color(0xFFFC8181)),
          const SizedBox(width: 8),
          _urgencyChip('urgent', 'Urgent', const Color(0xFF744210),
              const Color(0xFFF6AD55)),
          const SizedBox(width: 8),
          _urgencyChip('normal', 'Normal', const Color(0xFF1C4532),
              const Color(0xFF68D391)),
        ],
      );

  Widget _urgencyChip(
          String value, String label, Color bg, Color border) =>
      Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _urgency = value),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: _urgency == value ? bg : _cardBg,
              border: Border.all(
                  color: _urgency == value ? border : _borderColor,
                  width: _urgency == value ? 2 : 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
          ),
        ),
      );

  Widget _numberSelector(int value, Function(int) onChanged) => Row(
        children: [
          IconButton(
            onPressed: () {
              if (value > 1) onChanged(value - 1);
            },
            icon: const Icon(Icons.remove_circle_outline),
            color: _primaryBlue,
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: _borderColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$value',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ),
          IconButton(
            onPressed: () => onChanged(value + 1),
            icon: const Icon(Icons.add_circle_outline),
            color: _primaryBlue,
          ),
        ],
      );

  Widget _gpsButton() => ElevatedButton.icon(
        onPressed: _detectLocation,
        icon: const Icon(Icons.my_location),
        label: const Text('Auto-detect GPS'),
        style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF276749),
            foregroundColor: Colors.white),
      );

  Widget _gpsBadge() => Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1C4532),
          border: Border.all(color: const Color(0xFF9AE6B4)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
            'GPS: ${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}',
            style: const TextStyle(
                color: Color(0xFF9AE6B4), fontSize: 13)),
      );

  Widget _photoPickerWidget(Color accentColor) => GestureDetector(
        onTap: _showPhotoOptions,
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: _cardBg,
            border: Border.all(
              color: _photo != null ? accentColor : _borderColor,
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
                        onTap: () => setState(() {
                          _photo = null;
                          _photoPath = null;
                        }),
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

  Widget _submitButton(String label, VoidCallback onPressed, Color color) =>
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16)),
          child: _loading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(label,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      );
}
