import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/person_group_model.dart';
import '../models/person_report_model.dart';

class PersonReportService {
  static const String baseUrl = 'http://192.168.137.1:3000';

  static Future<bool> submitReport({
    required String reportType,
    required String emergencyLevel,
    required bool isInjured,
    required bool isUnconscious,
    required String name,
    required String approximateAge,
    required String gender,
    required String descriptionText,
    required String locationText,
    double? lat,
    double? lng,
    DateTime? lastSeenAt,
    required String reporterName,
    required String reporterPhone,
    File? photo,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/person-reports');
      print('SUBMIT: posting to $uri');
      final request = http.MultipartRequest('POST', uri);

      request.fields['reportType'] = reportType;
      request.fields['emergencyLevel'] = emergencyLevel;
      request.fields['isInjured'] = isInjured.toString();
      request.fields['isUnconscious'] = isUnconscious.toString();
      request.fields['name'] = name.isEmpty ? 'Unknown' : name;
      request.fields['approximateAge'] = approximateAge;
      request.fields['gender'] = gender;
      request.fields['descriptionText'] = descriptionText;
      request.fields['locationText'] = locationText;
      if (lat != null) request.fields['lat'] = lat.toString();
      if (lng != null) request.fields['lng'] = lng.toString();
      if (lastSeenAt != null) {
        request.fields['lastSeenAt'] = lastSeenAt.toIso8601String();
      }
      request.fields['reporterName'] = reporterName;
      request.fields['reporterPhone'] = reporterPhone;

      if (photo != null) {
        request.files
            .add(await http.MultipartFile.fromPath('photo', photo.path));
      }

      request.headers['Connection'] = 'keep-alive';
      final streamed = await request.send()
          .timeout(const Duration(seconds: 10));
      final resp = await http.Response.fromStream(streamed);
      print('SUBMIT: status=${resp.statusCode} body=${resp.body}');
      if (resp.statusCode != 201 && resp.statusCode != 200) {
        return false;
      }
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return data['success'] == true;
    } catch (e) {
      print('SUBMIT ERROR: $e');
      return false;
    }
  }

  static Future<List<PersonReport>> getAllReports() async {
    final resp = await http.get(Uri.parse('$baseUrl/api/person-reports'));
    if (resp.statusCode != 200) return <PersonReport>[];
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final list = data['reports'] as List?;
    if (list == null) return <PersonReport>[];
    return list
        .whereType<Map<String, dynamic>>()
        .map(PersonReport.fromJson)
        .toList();
  }

  static Future<List<PersonGroup>> getGroups() async {
    final resp =
        await http.get(Uri.parse('$baseUrl/api/person-reports/groups'));
    if (resp.statusCode != 200) return <PersonGroup>[];
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final list = data['groups'] as List?;
    if (list == null) return <PersonGroup>[];
    return list
        .whereType<Map<String, dynamic>>()
        .map(PersonGroup.fromJson)
        .toList();
  }

  static Future<bool> resolveGroup(String groupId) async {
    final resp = await http.patch(
      Uri.parse('$baseUrl/api/person-reports/groups/$groupId/resolve'),
    );
    return resp.statusCode == 200;
  }
}
