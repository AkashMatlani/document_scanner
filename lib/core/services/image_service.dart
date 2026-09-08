import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageService {
  Future<String?> enhance(String sourcePath, {bool grayscale = false}) async {
    final bytes = await File(sourcePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;

    var output = img.adjustColor(decoded, contrast: 1.25, brightness: 0.05);
    if (grayscale) output = img.grayscale(output);
    output = img.normalize(output, min: 0, max: 255);

    final dir = await getApplicationDocumentsDirectory();
    final out = p.join(
      dir.path,
      'enhanced_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await File(out).writeAsBytes(img.encodeJpg(output, quality: 92));
    return out;
  }
}
