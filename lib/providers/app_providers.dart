import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/ocr_models.dart';
import '../core/services/entity_extraction_service.dart';
import '../core/services/image_service.dart';
import '../core/services/ocr_service.dart';
import '../core/services/storage_service.dart';

final ocrServiceProvider = Provider<OcrService>((ref) {
  final service = OcrService();
  ref.onDispose(service.dispose);
  return service;
});

final entityExtractionProvider = Provider((ref) => EntityExtractionService());
final imageServiceProvider = Provider((ref) => ImageService());
final storageServiceProvider = Provider((ref) => StorageService());

final documentsProvider =
    AsyncNotifierProvider<DocumentsNotifier, List<OcrDocument>>(
      DocumentsNotifier.new,
    );

class DocumentsNotifier extends AsyncNotifier<List<OcrDocument>> {
  @override
  Future<List<OcrDocument>> build() => ref.read(storageServiceProvider).load();

  Future<void> add(OcrDocument document) async {
    state = AsyncData([document, ...?state.value]);
    await ref.read(storageServiceProvider).save(document);
  }

  Future<void> remove(String id) async {
    state = AsyncData((state.value ?? []).where((d) => d.id != id).toList());
    await ref.read(storageServiceProvider).delete(id);
  }
}

class ScanState {
  const ScanState({
    this.imagePath,
    this.text = '',
    this.entities = const [],
    this.busy = false,
    this.error,
  });

  final String? imagePath;
  final String text;
  final List<EntityMatch> entities;
  final bool busy;
  final String? error;

  ScanState copyWith({
    String? imagePath,
    String? text,
    List<EntityMatch>? entities,
    bool? busy,
    String? error,
    bool clearError = false,
  }) => ScanState(
    imagePath: imagePath ?? this.imagePath,
    text: text ?? this.text,
    entities: entities ?? this.entities,
    busy: busy ?? this.busy,
    error: clearError ? null : error ?? this.error,
  );
}

final scanControllerProvider = NotifierProvider<ScanController, ScanState>(
  ScanController.new,
);

class ScanController extends Notifier<ScanState> {
  @override
  ScanState build() => const ScanState();

  Future<void> recognize(String path) async {
    state = state.copyWith(imagePath: path, busy: true, clearError: true);
    try {
      final text = await ref.read(ocrServiceProvider).recognizeFile(path);
      final entities = ref.read(entityExtractionProvider).extract(text);
      state = state.copyWith(text: text, entities: entities, busy: false);
      final doc = OcrDocument(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        imagePath: path,
        text: text,
        createdAt: DateTime.now(),
        entities: entities,
      );
      await ref.read(documentsProvider.notifier).add(doc);
    } catch (e) {
      state = state.copyWith(busy: false, error: e.toString());
    }
  }

  void clear() => state = const ScanState();
}
