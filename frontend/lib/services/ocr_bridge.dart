import 'ocr_stub.dart'
    if (dart.library.js_interop) 'ocr_web_impl.dart'
    if (dart.library.io) 'ocr_mobile_impl.dart';

Future<Map<String, dynamic>?> executeClientOcr(List<int> bytes, {String? filePath}) =>
    runClientOcr(bytes, filePath: filePath);
