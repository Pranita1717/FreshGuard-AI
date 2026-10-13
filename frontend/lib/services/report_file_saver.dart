import 'report_file_saver_stub.dart'
    if (dart.library.js_interop) 'report_file_saver_web.dart'
    if (dart.library.io) 'report_file_saver_io.dart';

Future<String?> saveReportFile(List<int> bytes, String filename) =>
    saveReport(bytes, filename);
