import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  final TextRecognizer _recognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  Future<String> recognizeFile(String path) async {
    final input = InputImage.fromFilePath(path);
    final result = await _recognizer.processImage(input);
    return result.text.trim();
  }

  Future<RecognizedText> recognizeInput(InputImage input) =>
      _recognizer.processImage(input);

  void dispose() => _recognizer.close();
}
