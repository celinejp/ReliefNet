import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/person_report_service.dart';
import 'reports_display_screen.dart';

const _bg = Color(0xFF1A202C);
const _cardBg = Color(0xFF2D3748);
const _borderColor = Color(0xFF4A5568);
const _hintColor = Color(0xFF718096);
const _labelColor = Color(0xFFA0AEC0);
const _primaryBlue = Color(0xFF3182CE);
const _submitRed = Color(0xFFE53E3E);

class PersonReportFormScreen extends StatefulWidget {
  const PersonReportFormScreen({super.key});

  @override
  State<PersonReportFormScreen> createState() => _PersonReportFormScreenState();
}

class _PersonReportFormScreenState extends State<PersonReportFormScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  String _gender = 'unknown';

  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _reporterNameCtrl = TextEditingController();
  final _reporterPhoneCtrl = TextEditingController();

  File? _photo;
  bool _submitted = false;
  bool _loading = false;
  String _error = '';

  String get _reportType => _tab.index == 0 ? 'looking' : 'found';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _reporterNameCtrl.dispose();
    _reporterPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
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
            const Text(
              'Add Photo',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 6),
            const Text(
              'Photo helps identify the person faster',
              style: TextStyle(color: _hintColor, fontSize: 13),
            ),
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
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
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
                    label: const Text('From Gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF276749),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
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

  Future<void> _submit() async {
    if (_reporterNameCtrl.text.trim().isEmpty ||
        _reporterPhoneCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your name and phone number.');
      return;
    }
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final ok = await PersonReportService.submitReport(
        reportType: _reportType,
        emergencyLevel: 'unknown',
        isInjured: false,
        isUnconscious: false,
        name: _nameCtrl.text.trim(),
        approximateAge:
            _ageCtrl.text.trim().isEmpty ? 'Unknown' : _ageCtrl.text.trim(),
        gender: _gender,
        descriptionText: _descCtrl.text.trim(),
        locationText: _locationCtrl.text.trim(),
        lat: null,
        lng: null,
        lastSeenAt: null,
        reporterName: _reporterNameCtrl.text.trim(),
        reporterPhone: _reporterPhoneCtrl.text.trim(),
        photo: _photo,
      );
      if (!mounted) return;
      if (ok) {
        setState(() => _submitted = true);
      } else {
        setState(() => _error = 'Something went wrong. Try again.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Network error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _resetForm() {
    setState(() {
      _submitted = false;
      _gender = 'unknown';
      _nameCtrl.clear();
      _ageCtrl.clear();
      _descCtrl.clear();
      _locationCtrl.clear();
      _reporterNameCtrl.clear();
      _reporterPhoneCtrl.clear();
      _photo = null;
      _error = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _buildSuccess();
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Person Report'),
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tab,
          indicatorColor: _primaryBlue,
          labelColor: Colors.white,
          unselectedLabelColor: _hintColor,
          tabs: const [
            Tab(text: 'Looking For Someone'),
            Tab(text: 'Found / Saw Someone'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [_buildForm(), _buildForm()],
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Name (optional)'),
          const SizedBox(height: 6),
          _textField(_nameCtrl, 'Leave blank if unknown'),
          const SizedBox(height: 16),
          _label('Age'),
          const SizedBox(height: 6),
          _textField(_ageCtrl, 'e.g. 35, teenager, elderly'),
          const SizedBox(height: 16),
          _label('Gender'),
          const SizedBox(height: 6),
          _genderDropdown(),
          const SizedBox(height: 16),
          _label('Where were they last seen / found?'),
          const SizedBox(height: 6),
          _textField(_locationCtrl,
              'e.g. Third floor of mall, parking lot near gate 2'),
          const SizedBox(height: 16),
          _label('Description'),
          const SizedBox(height: 6),
          TextField(
            controller: _descCtrl,
            minLines: 5,
            maxLines: 10,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration(
                'e.g. Elderly woman, red jacket, grey hair, limping, confused'),
          ),
          const SizedBox(height: 16),
          _label('Photo (optional)'),
          const SizedBox(height: 6),
          _photoWidget(),
          const SizedBox(height: 16),
          _label('Your Full Name'),
          const SizedBox(height: 6),
          _textField(_reporterNameCtrl, 'Your name'),
          const SizedBox(height: 16),
          _label('Your Phone Number'),
          const SizedBox(height: 6),
          _textField(_reporterPhoneCtrl, 'Phone number',
              keyboard: TextInputType.phone),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 12),
            _errorBox(_error),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _submitRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Submit Report',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Report Submitted'),
        backgroundColor: _bg,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle,
                  size: 64, color: Color(0xFF38A169)),
              const SizedBox(height: 12),
              Text(
                'Report Submitted',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'AI is scanning for matches now. We will contact you if one is found.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _hintColor),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _resetForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF276749),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Submit Another'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                          builder: (_) => const ReportsDisplayScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('View Reports'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textField(TextEditingController ctrl, String hint,
          {TextInputType keyboard = TextInputType.text}) =>
      TextField(
        controller: ctrl,
        keyboardType: keyboard,
        style: const TextStyle(color: Colors.white),
        decoration: _inputDecoration(hint),
      );

  Widget _genderDropdown() => DropdownButtonFormField<String>(
        value: _gender,
        dropdownColor: _cardBg,
        style: const TextStyle(color: Colors.white),
        decoration: _inputDecoration(''),
        items: const [
          DropdownMenuItem(value: 'unknown', child: Text('Unknown')),
          DropdownMenuItem(value: 'male', child: Text('Male')),
          DropdownMenuItem(value: 'female', child: Text('Female')),
        ],
        onChanged: (v) => setState(() => _gender = v ?? 'unknown'),
      );

  Widget _photoWidget() => GestureDetector(
        onTap: _showPhotoOptions,
        child: Container(
          height: 130,
          width: double.infinity,
          decoration: BoxDecoration(
            color: _cardBg,
            border: Border.all(
              color: _photo != null ? _primaryBlue : _borderColor,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _photo != null
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(_photo!,
                          width: double.infinity,
                          height: 130,
                          fit: BoxFit.cover),
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
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Tap to change',
                            style:
                                TextStyle(color: Colors.white, fontSize: 11)),
                      ),
                    ),
                  ],
                )
              : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, size: 36, color: _hintColor),
                    SizedBox(height: 8),
                    Text('Tap to add photo',
                        style: TextStyle(
                            color: _hintColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    SizedBox(height: 4),
                    Text('Camera or Gallery',
                        style: TextStyle(color: _hintColor, fontSize: 12)),
                  ],
                ),
        ),
      );

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 14, color: _labelColor),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _hintColor),
        filled: true,
        fillColor: _cardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _primaryBlue, width: 2),
        ),
      );

  Widget _errorBox(String msg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF9B2C2C).withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFC8181)),
        ),
        child: Text(msg, style: const TextStyle(color: Color(0xFFFC8181))),
      );
}
