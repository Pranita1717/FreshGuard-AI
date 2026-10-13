import 'dart:convert';
import 'dart:js_interop';

@JS('performTesseractOcr')
external JSPromise<JSString> _performTesseractOcr(JSString base64Image);

Future<Map<String, dynamic>?> runClientOcr(List<int> bytes, {String? filePath}) async {
  try {
    final b64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    final jsString = await _performTesseractOcr(b64.toJS).toDart;
    final decoded = jsonDecode(jsString.toDart);
    if (decoded is Map<String, dynamic>) return decoded;
  } catch (_) {}
  return null;
}
