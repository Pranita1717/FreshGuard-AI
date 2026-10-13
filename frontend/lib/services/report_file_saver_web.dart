import 'dart:convert';
import 'dart:js_interop';

@JS('downloadFreshGuardPdf')
external void _downloadFreshGuardPdf(JSString base64, JSString filename);

Future<String?> saveReport(List<int> bytes, String filename) async {
  try {
    _downloadFreshGuardPdf(base64Encode(bytes).toJS, filename.toJS);
    return filename;
  } catch (_) {
    return null;
  }
}
