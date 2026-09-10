import 'dart:io';

import 'package:document_scanner/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

class OcrPage extends ConsumerStatefulWidget {
  const OcrPage({super.key, this.entityMode = false});

  final bool entityMode;

  @override
  ConsumerState<OcrPage> createState() => _OcrPageState();
}

class _OcrPageState extends ConsumerState<OcrPage> {
  final _picker = ImagePicker();

  Future<void> _pick(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 95);
    if (file == null) return;
    final cropped = await ImageCropper().cropImage(
      sourcePath: file.path,
      compressQuality: 95,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop document',
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: 'Crop document'),
      ],
    );
    final path = cropped?.path ?? file.path;
    await ref.read(scanControllerProvider.notifier).recognize(path);
  }

  Future<void> _enhance() async {
    final state = ref.read(scanControllerProvider);
    if (state.imagePath == null) return;
    final path = await ref
        .read(imageServiceProvider)
        .enhance(state.imagePath!, grayscale: true);
    if (path != null) {
      await ref.read(scanControllerProvider.notifier).recognize(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scanControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.entityMode ? 'Business Card / Entities' : 'OCR from Image',
        ),
        actions: [
          if (state.text.isNotEmpty)
            IconButton(
              onPressed: () =>
                  SharePlus.instance.share(ShareParams(text: state.text)),
              icon: const Icon(Icons.share),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _pick(ImageSource.camera),
                  label: const Text('Camera'),
                  icon: const Icon(Icons.camera_alt),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pick(ImageSource.gallery),
                  label: const Text("Gallery"),
                  icon: const Icon(Icons.photo_library),
                ),
              ),
            ],
          ),

          if (state.imagePath != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(state.imagePath!),
                height: 260,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: state.busy ? null : _enhance,
              label: const Text('Enhance + grayscale + OCR'),
              icon: const Icon(Icons.auto_fix_high),
            ),
          ],
          const SizedBox(height: 16),
          if (state.busy) const LinearProgressIndicator(),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                state.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'Recognized text',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          SelectableText(
            state.text.isEmpty
                ? 'Your extracted text will appear here.'
                : state.text,
          ),
          if (state.entities.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Detected entities',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            ...state.entities.map(
              (e) => ListTile(
                dense: true,
                leading: const Icon(Icons.sell_outlined),
                title: Text(e.value),
                subtitle: Text(e.type),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
