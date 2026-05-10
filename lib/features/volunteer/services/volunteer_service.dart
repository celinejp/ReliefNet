import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../models/need_model.dart';
import '../models/volunteer_model.dart';
import '../models/donation_model.dart';
import '../models/match_model.dart';

class VolunteerService {
  static const String baseUrl = ApiConfig.baseUrl;

  static String _absolutePhotoUrl(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return '';
    if (v.startsWith('http://') || v.startsWith('https://')) return v;
    if (v.startsWith('/')) return '$baseUrl$v';
    return '$baseUrl/$v';
  }

  static Future<Map<String, dynamic>> submitNeed({
    required String name,
    required String phone,
    required List<String> categories,
    required String urgency,
    required String description,
    required String locationText,
    double? lat,
    double? lng,
    int numberOfPeople = 1,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/needs'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'phone': phone,
          'categories': categories,
          'urgency': urgency,
          'description': description,
          'locationText': locationText,
          'lat': lat,
          'lng': lng,
          'numberOfPeople': numberOfPeople,
        }),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      print('submitNeed error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> submitVolunteer({
    required String name,
    required String phone,
    required List<String> categories,
    required String description,
    required String locationText,
    double? lat,
    double? lng,
    int capacity = 1,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/volunteers'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'phone': phone,
          'categories': categories,
          'description': description,
          'locationText': locationText,
          'lat': lat,
          'lng': lng,
          'capacity': capacity,
        }),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      print('submitVolunteer error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> submitDonation({
    required String donorName,
    required String donorPhone,
    required String type,
    required String amount,
    required String locationText,
    String notes = '',
    double? lat,
    double? lng,
    File? photo,
  }) async {
    try {
      final request =
          http.MultipartRequest('POST', Uri.parse('$baseUrl/api/donations'));
      request.fields['donorName'] = donorName;
      request.fields['donorPhone'] = donorPhone;
      request.fields['type'] = type;
      request.fields['amount'] = amount;
      request.fields['notes'] = notes;
      request.fields['locationText'] = locationText;
      if (lat != null) request.fields['lat'] = lat.toString();
      if (lng != null) request.fields['lng'] = lng.toString();
      if (photo != null) {
        request.files
            .add(await http.MultipartFile.fromPath('photo', photo.path));
      }
      final streamed =
          await request.send().timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamed);
      return jsonDecode(response.body);
    } catch (e) {
      print('submitDonation error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<List<NeedModel>> getNeeds() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/needs'),
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      if (data['success']) {
        return (data['needs'] as List).map((n) => NeedModel.fromJson(n)).toList();
      }
      return [];
    } catch (e) {
      print('getNeeds error: $e');
      return [];
    }
  }

  static Future<List<VolunteerModel>> getVolunteers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/volunteers'),
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      if (data['success']) {
        return (data['volunteers'] as List)
            .map((v) => VolunteerModel.fromJson(v))
            .toList();
      }
      return [];
    } catch (e) {
      print('getVolunteers error: $e');
      return [];
    }
  }

  static Future<List<DonationModel>> getDonations() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/donations'),
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      if (data['success']) {
        return (data['donations'] as List)
            .map((d) {
              final normalized = Map<String, dynamic>.from(d);
              normalized['photoUrl'] =
                  _absolutePhotoUrl('${normalized['photoUrl'] ?? ''}');
              return DonationModel.fromJson(normalized);
            })
            .toList();
      }
      return [];
    } catch (e) {
      print('getDonations error: $e');
      return [];
    }
  }

  static Future<List<MatchModel>> getMatches() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/match-volunteers'),
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      if (data['success']) {
        return (data['matches'] as List)
            .map((m) => MatchModel.fromJson(m))
            .toList();
      }
      return [];
    } catch (e) {
      print('getMatches error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> runMatching() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/match-volunteers'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 60));
      return jsonDecode(response.body);
    } catch (e) {
      print('runMatching error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<bool> resolveMatch(String matchId) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/match-volunteers/$matchId/resolve'),
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      return data['success'] ?? false;
    } catch (e) {
      print('resolveMatch error: $e');
      return false;
    }
  }
}
