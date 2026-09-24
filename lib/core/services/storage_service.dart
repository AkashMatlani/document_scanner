import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ocr_models.dart';

class StorageService {
  static const _key = 'ocr_documents';

  Future<Directory> _scansDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final scansDir = Directory(p.join(appDir.path, 'scans'));
    if (!await scansDir.exists()) {
      await scansDir.create(recursive: true);
    }
    return scansDir;
  }

  Future<String> saveImage(String sourcePath, String documentId) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw Exception('Image file not found: $sourcePath');
    }
    final scansDir = await _scansDirectory();
    final extension = p.extension(sourcePath).isEmpty
        ? '.jpg'
        : p.extension(sourcePath);
    final destination = File(
      p.join(scansDir.path, 'scan_$documentId$extension'),
    );
    await source.copy(destination.path);
    return destination.path;
  }

  Future<void> deleteImage(String imagePath) async {
    final file = File(imagePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<List<OcrDocument>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);

    if (raw == null) {
      return [];
    }
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
    final document = docs.where((d) => d.id == id).firstOrNull;
    if (document != null) {
      final imageFile = File(document.imagePath);
      if (await imageFile.exists()) {
        await imageFile.delete();
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(docs.where((d) => d.id != id).map((d) => d.toJson()).toList()),
    );
  }
}
