import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

Future<Map<String, dynamic>?> runClientOcr(List<int> bytes, {String? filePath}) async {
  if (filePath == null || filePath.isEmpty) return null;
  final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  try {
    final input = InputImage.fromFilePath(filePath);
    final result = await recognizer.processImage(input);
    final text = result.text.trim();
    if (text.isEmpty) return null;
    // ML Kit does not expose a single document confidence value. Keep this
    // explicitly marked as client OCR instead of inventing a confidence score.
    return {'text': text, 'confidence': null, 'engine': 'Google ML Kit'};
  } finally {
    await recognizer.close();
  }
}
