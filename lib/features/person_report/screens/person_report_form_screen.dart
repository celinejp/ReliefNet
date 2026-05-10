import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../services/person_report_service.dart';
import 'reports_display_screen.dart';

const _criticalRed = Color(0xFFE53E3E);
const _stableGreen = Color(0xFF38A169);
const _unknownGrey = Color(0xFF718096);
const _primaryBlue = Color(0xFF3182CE);

const List<String> _ageRanges = [
  'Unknown',
  '0-10 (Child)',
  '11-17 (Teenager)',
  '18-25 (Young Adult)',
  '26-35 (Adult)',
  '36-45 (Adult)',
  '46-55 (Middle-aged)',
  '56-65 (Middle-aged)',
  '66-75 (Senior)',
  '76-85 (Elderly)',
  '85+ (Elderly)',
];

const List<String> _stepLabels = [
  'Type',
  'Identity',
  'Description',
  'Location',
  'Contact',
];

class PersonReportFormScreen extends StatefulWidget {
  const PersonReportFormScreen({super.key});

  @override
  State<PersonReportFormScreen> createState() => _PersonReportFormScreenState();
}

class _PersonReportFormScreenState extends State<PersonReportFormScreen> {
  int _step = 1;
  String _reportType = '';
  String _emergencyLevel = 'unknown';
  bool _isInjured = false;
  bool _isUnconscious = false;
  String _approximateAge = 'Unknown';
  String _gender = 'unknown';

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _reporterNameCtrl = TextEditingController();
  final _reporterPhoneCtrl = TextEditingController();

  File? _photo;
  double? _lat;
  double? _lng;
  DateTime? _lastSeenAt;

  bool _submitted = false;
  bool _loading = false;
  String _error = '';

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechReady = false;
  bool _isListening = false;
  String _voiceError = '';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _reporterNameCtrl.dispose();
    _reporterPhoneCtrl.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _toggleVoice() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }
    if (!_speechReady) {
      _speechReady = await _speech.initialize(
        onError: (e) {
          if (mounted) {
            setState(() {
              _voiceError = 'Mic error: ${e.errorMsg}';
              _isListening = false;
            });
          }
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
      );
    }
    if (!_speechReady) {
      if (!mounted) return;
      setState(() => _voiceError = 'Voice not available on this device.');
      return;
    }
    if (!mounted) return;
    setState(() {
      _isListening = true;
      _voiceError = '';
    });
    await _speech.listen(
      onResult: (res) {
        if (!mounted) return;
        setState(() => _descCtrl.text = res.recognizedWords);
      },
      listenFor: const Duration(minutes: 2),
      pauseFor: const Duration(seconds: 5),
      partialResults: true,
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (picked != null && mounted) {
      setState(() => _photo = File(picked.path));
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add Photo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Photo helps identify the person faster',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
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
                      backgroundColor: const Color(0xFF3182CE),
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

  Future<void> _detectGps() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) _showSnack('Location permission denied.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _lat = pos.latitude;
          _lng = pos.longitude;
        });
      }
    } catch (_) {
      if (mounted) _showSnack('Could not detect GPS. Type it manually.');
    }
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _lastSeenAt ?? now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_lastSeenAt ?? now),
    );
    if (time == null) return;
    setState(() {
      _lastSeenAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  void _next() {
    if (_step == 1 && _reportType.isEmpty) {
      setState(() => _error = 'Please select a report type.');
      return;
    }
    if (_step == 3 && _descCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please add a description.');
      return;
    }
    setState(() {
      _error = '';
      _step += 1;
    });
  }

  void _back() {
    setState(() {
      _error = '';
      _step -= 1;
    });
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
        emergencyLevel: _emergencyLevel,
        isInjured: _isInjured,
        isUnconscious: _isUnconscious,
        name: _nameCtrl.text.trim(),
        approximateAge: _approximateAge,
        gender: _gender,
        descriptionText: _descCtrl.text.trim(),
        locationText: _locationCtrl.text.trim(),
        lat: _lat,
        lng: _lng,
        lastSeenAt: _lastSeenAt,
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
      _step = 1;
      _reportType = '';
      _emergencyLevel = 'unknown';
      _isInjured = false;
      _isUnconscious = false;
      _approximateAge = 'Unknown';
      _gender = 'unknown';
      _nameCtrl.clear();
      _descCtrl.clear();
      _locationCtrl.clear();
      _reporterNameCtrl.clear();
      _reporterPhoneCtrl.clear();
      _photo = null;
      _lat = null;
      _lng = null;
      _lastSeenAt = null;
      _error = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _buildSuccess();

    return Scaffold(
      appBar: AppBar(title: const Text('Person Report')),
      body: SafeArea(
        child: Column(
          children: [
            _buildProgress(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _stepBody(),
                    if (_error.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _errorBox(_error),
                    ],
                  ],
                ),
              ),
            ),
            _buildNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        children: [
          Row(
            children: List.generate(_stepLabels.length, (i) {
              final n = i + 1;
              final done = _step > n;
              final active = _step == n;
              final color = done
                  ? _stableGreen
                  : active
                      ? _primaryBlue
                      : Colors.white24;
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        done ? '✓' : '$n',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _stepLabels[i],
                      style: TextStyle(
                        fontSize: 11,
                        color: active ? _primaryBlue : Colors.white60,
                        fontWeight:
                            active ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: (_step - 1) / (_stepLabels.length - 1),
              minHeight: 4,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(_primaryBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepBody() {
    switch (_step) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      case 4:
        return _buildStep4();
      case 5:
        return _buildStep5();
    }
    return const SizedBox.shrink();
  }

  Widget _buildStep1() {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('What are you reporting?',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(
          'Choose the type that best describes your situation.',
          style: textTheme.bodySmall?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _selectableCard(
                selected: _reportType == 'looking',
                accent: _primaryBlue,
                icon: '🔍',
                title: 'LOOKING for someone',
                subtitle: 'Report a missing person',
                onTap: () => setState(() => _reportType = 'looking'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _selectableCard(
                selected: _reportType == 'found',
                accent: _stableGreen,
                icon: '👁️',
                title: 'FOUND or SAW someone',
                subtitle: 'Report a person you encountered',
                onTap: () => setState(() => _reportType = 'found'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _label('Emergency Level'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _emergencyChip(
                value: 'critical',
                label: '🔴 Critical',
                sub: 'Needs help now',
                accent: _criticalRed,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _emergencyChip(
                value: 'stable',
                label: '🟢 Stable',
                sub: 'Not in danger',
                accent: _stableGreen,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _emergencyChip(
                value: 'unknown',
                label: '⚪ Unknown',
                sub: 'Unclear',
                accent: _unknownGrey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _label('Medical Status'),
        const SizedBox(height: 8),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _isInjured,
          title: const Text('🩹 Person is injured'),
          onChanged: (v) => setState(() => _isInjured = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _isUnconscious,
          title: const Text('😶 Person is unconscious'),
          onChanged: (v) => setState(() => _isUnconscious = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepHeader(
          'Person\'s Identity',
          'Fill in what you know. All fields are optional except description.',
        ),
        const SizedBox(height: 16),
        _label('Name (if known)'),
        const SizedBox(height: 6),
        TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(
            hintText: 'Leave blank if unknown',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _label('Age Range'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _approximateAge,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                    isExpanded: true,
                    items: _ageRanges
                        .map((a) =>
                            DropdownMenuItem(value: a, child: Text(a, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _approximateAge = v ?? 'Unknown'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _label('Gender'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _gender,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'unknown', child: Text('Unknown')),
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                      DropdownMenuItem(value: 'female', child: Text('Female')),
                    ],
                    onChanged: (v) => setState(() => _gender = v ?? 'unknown'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _label('Photo (optional but very helpful)'),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _showPhotoOptions,
          child: Container(
            height: 130,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: _photo != null
                    ? const Color(0xFF3182CE)
                    : const Color(0xFFE2E8F0),
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
                          height: 130,
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
                              style: TextStyle(
                                  color: Colors.white, fontSize: 11)),
                        ),
                      ),
                    ],
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, size: 36, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Tap to add photo',
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      SizedBox(height: 4),
                      Text('📷 Camera  or  🖼️ Gallery',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepHeader(
          'Describe the Person',
          'Clothing, hair, height, build, injuries — anything you remember.',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _toggleVoice,
              icon: Icon(_isListening ? Icons.stop_circle : Icons.mic),
              label: Text(_isListening ? 'Stop Recording' : 'Voice Input'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isListening ? _criticalRed : _primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            if (_isListening)
              const Text(
                '● Recording...',
                style: TextStyle(
                  color: _criticalRed,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        if (_voiceError.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(_voiceError, style: const TextStyle(color: _criticalRed)),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: _descCtrl,
          minLines: 5,
          maxLines: 10,
          decoration: const InputDecoration(
            hintText:
                'e.g. "Elderly woman, red jacket, grey hair, limping, confused"',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFF0),
            border: Border.all(color: const Color(0xFFF6E05E)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '💡 Helpful details to include:',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: Colors.black87),
              ),
              SizedBox(height: 4),
              Text('• Clothing colors and type',
                  style: TextStyle(color: Colors.black87, fontSize: 13)),
              Text('• Hair color and length',
                  style: TextStyle(color: Colors.black87, fontSize: 13)),
              Text('• Height (short / average / tall)',
                  style: TextStyle(color: Colors.black87, fontSize: 13)),
              Text('• Any injuries or distinctive marks',
                  style: TextStyle(color: Colors.black87, fontSize: 13)),
              Text('• What they were carrying or wearing',
                  style: TextStyle(color: Colors.black87, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepHeader('Location & Time', 'Where and when was this person seen?'),
        const SizedBox(height: 16),
        _label('Location Description'),
        const SizedBox(height: 6),
        TextField(
          controller: _locationCtrl,
          decoration: const InputDecoration(
            hintText: 'e.g. "Near west bridge"',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _detectGps,
          icon: const Icon(Icons.gps_fixed),
          label: const Text('Auto-detect GPS'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF276749),
            foregroundColor: Colors.white,
          ),
        ),
        if (_lat != null && _lng != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FFF4),
              border: Border.all(color: const Color(0xFF9AE6B4)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '✅ GPS: ${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}',
              style: const TextStyle(color: Color(0xFF276749)),
            ),
          ),
        ],
        const SizedBox(height: 18),
        _label('Date & Time Last Seen / Found'),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          onPressed: _pickDateTime,
          icon: const Icon(Icons.event),
          label: Text(
            _lastSeenAt == null
                ? 'Pick date & time'
                : DateFormat('MMM d, y · h:mm a').format(_lastSeenAt!),
          ),
        ),
      ],
    );
  }

  Widget _buildStep5() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepHeader(
          'Your Contact Info',
          'We need this to contact you if a match is found.',
        ),
        const SizedBox(height: 16),
        _label('Your Full Name'),
        const SizedBox(height: 6),
        TextField(
          controller: _reporterNameCtrl,
          decoration: const InputDecoration(
            hintText: 'Your name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        _label('Your Phone Number'),
        const SizedBox(height: 6),
        TextField(
          controller: _reporterPhoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: 'Phone number',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 18),
        _summaryCard(),
      ],
    );
  }

  Widget _summaryCard() {
    final desc = _descCtrl.text.trim();
    final descPreview =
        desc.length > 100 ? '${desc.substring(0, 100)}...' : desc;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📋 Report Summary',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _kv('Type',
                  _reportType == 'looking' ? '🔍 Looking For' : '👁️ Found/Saw'),
              _kv(
                'Emergency',
                _emergencyLevel == 'critical'
                    ? '🔴 Critical'
                    : _emergencyLevel == 'stable'
                        ? '🟢 Stable'
                        : '⚪ Unknown',
              ),
              _kv('Age', _approximateAge),
              _kv('Gender', _gender),
              if (_isInjured) const _Tag(text: '🩹 Injured'),
              if (_isUnconscious) const _Tag(text: '😶 Unconscious'),
            ],
          ),
          if (descPreview.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Description: $descPreview',
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$k: $v', style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildNav() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          if (_step > 1)
            OutlinedButton.icon(
              onPressed: _back,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
            ),
          const Spacer(),
          if (_step < 5)
            ElevatedButton.icon(
              onPressed: _next,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Next'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
                foregroundColor: Colors.white,
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: _loading ? null : _submit,
              icon: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check),
              label: Text(_loading ? 'Submitting...' : 'Submit Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF276749),
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Submitted')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('✅', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              Text(
                'Report Submitted',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'AI is scanning for matches now. We will contact you if one is found.',
                textAlign: TextAlign.center,
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

  Widget _selectableCard({
    required bool selected,
    required Color accent,
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected
          ? accent.withValues(alpha: 0.18)
          : Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? accent : Colors.white24,
              width: selected ? 2.5 : 1.5,
            ),
          ),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emergencyChip({
    required String value,
    required String label,
    required String sub,
    required Color accent,
  }) {
    final selected = _emergencyLevel == value;
    return Material(
      color: selected
          ? accent.withValues(alpha: 0.18)
          : Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _emergencyLevel = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? accent : Colors.white24,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 2),
              Text(sub,
                  style: const TextStyle(fontSize: 10, color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    );
  }

  Widget _stepHeader(String title, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                )),
        const SizedBox(height: 4),
        Text(
          sub,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }

  Widget _errorBox(String msg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFC8181)),
      ),
      child: Text(msg, style: const TextStyle(color: Color(0xFFC53030))),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFED7D7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF9B2C2C),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
