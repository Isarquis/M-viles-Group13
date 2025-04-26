import 'dart:io';
import 'package:path_provider/path_provider.dart';

class SearchFileService {
  static Future<File> _getBackupFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/search_backup.txt');
  }

  static Future<void> appendSearchTerm(String term) async {
    final file = await _getBackupFile();
    await file.writeAsString('$term\n', mode: FileMode.append);
  }

  static Future<List<String>> readSearchTerms() async {
    try {
      final file = await _getBackupFile();
      final contents = await file.readAsLines();
      return contents;
    } catch (e) {
      return [];
    }
  }

  static Future<void> clearBackup() async {
    final file = await _getBackupFile();
    await file.writeAsString('');
  }
}
