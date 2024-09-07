import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:path/path.dart' as p;
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class FileServer {
  final String ipAddress;
  final int port;

  FileServer({required this.ipAddress, this.port = 8080});

  Future<void> start() async {
    final router = Router();

    // Endpoint to search for files
    router.get('/search', (Request request) async {
      final query = request.requestedUri.queryParameters['query'] ?? '';
      final initialPath = request.requestedUri.queryParameters["path"] ?? "/sdcard/";
      final listDir = request.requestedUri.queryParameters["listdir"] == "true";
      final layers = int.parse(request.requestedUri.queryParameters["layers"] ?? "0");
      final sortBy = request.requestedUri.queryParameters["sortBy"] ?? 'name';
      final sortOrder = request.requestedUri.queryParameters["sortOrder"] ?? 'asc';

      final List<Map<String, String>> results = await _searchFiles(
        query,
        parentDir: initialPath,
        layers: layers,
        listDir: listDir,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );

      return Response.ok(
        jsonEncode(results),
        headers: {'Content-Type': 'application/json'},
      );
    });

    // Endpoint to get file
    router.get('/file', (Request request) async {
      String filePath = request.requestedUri.queryParameters['path'] ?? '';
      if (!filePath.startsWith("/")) {
        filePath = "/sdcard/$filePath";
      }
      final file = File(filePath);
      if (await file.exists()) {
        return Response.ok(
          file.openRead(),
          headers: {
            'Content-Type': 'application/octet-stream',
            'Content-Disposition': 'attachment; filename="${p.basename(filePath)}"',
          },
        );
      } else {
        return Response.notFound('$filePath File not found');
      }
    });

    // Endpoint to download a file
    router.get('/download', (Request request) async {
      String filePath = request.requestedUri.queryParameters['path'] ?? '';
      if (!filePath.startsWith("/")) {
        filePath = "/sdcard/$filePath";
      }
      final file = File(filePath);
      if (await file.exists()) {
        final fileStream = file.openRead();
        return Response.ok(
          fileStream,
          headers: {
            'Content-Type': 'application/octet-stream',
            'Content-Disposition': 'attachment; filename="${p.basename(filePath)}"',
          },
        );
      } else {
        return Response.notFound('File not found');
      }
    });

    // Endpoint to get server status
    router.get('/status', (Request request) async {
      final batteryStatus = await _getBatteryStatus();
      final connectivityStatus = await _getConnectivityStatus();

      final status = {
        'connection_status': 'connected', // Update based on actual connection status
        'battery_status': jsonDecode(batteryStatus),
        'connectivity_status': jsonDecode(connectivityStatus),
        'timestamp': DateTime.now().toIso8601String(),
      };

      return Response.ok(
        jsonEncode(status),
        headers: {'Content-Type': 'application/json'},
      );
    });

    // Start the server
    final handler =
        const Pipeline().addMiddleware(logRequests()).addHandler(router);
    final server = await io.serve(handler, ipAddress, port);
    print('Serving at http://${server.address}:${server.port}');
  }

  Future<List<Map<String, String>>> _searchFiles(
    String query, {
    String parentDir = "/sdcard/",
    int layers = 0,
    bool listDir = false,
    String sortBy = 'name',
    String sortOrder = 'asc',
  }) async {
    final List<Map<String, String>> results = [];
    final directory = Directory(parentDir);

    if (!await directory.exists()) {
      print('Directory does not exist');
      return results;
    }

    try {
      final List<Map<String, String>> filesAndDirs = [];

      await for (var entity in directory.list(recursive: false, followLinks: false)) {
        if (entity.path.startsWith('/sdcard/Android')) {
          continue;
        }

        if (entity is File) {
          final fileName = p.basename(entity.path);
          if (RegExp(query).hasMatch(fileName) || fileName.endsWith(query)) {
            final stats = entity.statSync();
            filesAndDirs.add({
              'type': 'file',
              'path': entity.path,
              'name': fileName,
              'last_access': stats.accessed.toIso8601String(),
              'last_modified': stats.changed.toIso8601String(),
              'size': stats.size.toString(),
            });
          }
        } else if (entity is Directory) {
          if (listDir) {
            filesAndDirs.add({
              'type': 'directory',
              'path': entity.path,
              'name': p.basename(entity.path),
              'last_access': Directory(entity.path).statSync().accessed.toIso8601String(),
              'last_modified': Directory(entity.path).statSync().changed.toIso8601String(),
              'size': Directory(entity.path).listSync().length.toString(),
            });
          }
          if (layers > 0) {
            final innerRes = await _searchFiles(
              query,
              parentDir: entity.path,
              layers: layers - 1,
              listDir: listDir,
              sortBy: sortBy,
              sortOrder: sortOrder,
            );
            filesAndDirs.addAll(innerRes);
          }
        }
      }

      filesAndDirs.sort((a, b) {
        int comparison = 0;
        switch (sortBy) {
          case 'name':
            comparison = a['name']!.compareTo(b['name']!);
            break;
          case 'creation':
            comparison = a['last_access']!.compareTo(b['last_access']!);
            break;
          case 'last_modified':
            comparison = a['last_modified']!.compareTo(b['last_modified']!);
            break;
          case 'size':
            comparison = int.parse(a['size']!).compareTo(int.parse(b['size']!));
            break;
        }
        return sortOrder == 'asc' ? comparison : -comparison;
      });

      final directories = filesAndDirs.where((item) => item['type'] == 'directory').toList();
      final files = filesAndDirs.where((item) => item['type'] == 'file').toList();

      results.addAll(directories);
      results.addAll(files);

    } catch (e) {
      print('Error accessing directory: $e');
    }

    return results;
  }

  Future<String> _getBatteryStatus() async {
    final battery = Battery();
    final batteryLevel = await battery.batteryLevel;
    final batteryState = await battery.batteryState;
    final batteryStatus = {
      'level': batteryLevel,
      'is_charging': batteryState == BatteryState.charging,
    };
    return jsonEncode(batteryStatus);
  }

  Future<String> _getConnectivityStatus() async {
    final connectivity = Connectivity();
    final result = await connectivity.checkConnectivity();
    final connectivityStatus = {
      'status': result.toString(),
    };
    return jsonEncode(connectivityStatus);
  }
}
