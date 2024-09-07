import 'dart:io';
import 'package:path/path.dart' as p;

class FileIndexer {
  final Map<String, FileSystemEntity> _fileIndex = {};

  Future<void> indexFiles(Directory rootDir) async {
    await for (var entity in rootDir.list(recursive: true, followLinks: false)) {
      if (entity is File || entity is Directory) {
        _fileIndex[p.basename(entity.path)] = entity;
      }
    }
  }

  List<String> searchFiles(String query) {
    List<String> results = [];
    _fileIndex.forEach((fileName, entity) {
      if (fileName.contains(query)) {
        results.add(entity.path);
      }
    });
    return results;
  }

  void clearIndex() {
    _fileIndex.clear();
  }

  List<String> getAllIndexedFiles() {
    return _fileIndex.keys.toList();
  }

  FileSystemEntity getFile(String path) {
    return _fileIndex[path]!;
  }
}
