import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/ocr_models.dart';

class StorageService {
  static const _key = 'ocr_documents';

  Future<List<OcrDocument>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => OcrDocument.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> save(OcrDocument document) async {
    final docs = await load();
    final updated = [document, ...docs.where((d) => d.id != document.id)];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(updated.map((d) => d.toJson()).toList()),
    );
  }

  Future<void> delete(String id) async {
    final docs = await load();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(docs.where((d) => d.id != id).map((d) => d.toJson()).toList()),
    );
  }
}
