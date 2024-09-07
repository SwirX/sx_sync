import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class FileExplorerPage extends StatefulWidget {
  final String? serverIp; // Make serverIp optional
  final int serverPort;

  FileExplorerPage({this.serverIp, this.serverPort = 8080});

  @override
  _FileExplorerPageState createState() => _FileExplorerPageState();
}

class _FileExplorerPageState extends State<FileExplorerPage> {
  String? serverIp;
  String query = '';
  String currentPath = '/sdcard/';
  bool listDir = true;
  int layers = 0;
  List<Map<String, String>> items = [];
  String sortBy = 'name'; // Default sorting by name
  String sortOrder = 'asc'; // Default sorting order ascending

  @override
  void initState() {
    super.initState();
    _initializeIpAddress();
  }

  Future<void> _initializeIpAddress() async {
    if (widget.serverIp == null) {
      serverIp = await _getLocalIpAddress();
    } else {
      serverIp = widget.serverIp;
    }
    _fetchFiles();
  }

  Future<String> _getLocalIpAddress() async {
    final interfaces =
        await NetworkInterface.list(type: InternetAddressType.IPv4);
    final localIp = interfaces
        .expand((interface) => interface.addresses)
        .firstWhere((address) => !address.isLoopback)
        .address;
    return localIp;
  }

  Future<void> _fetchFiles() async {
    final url = Uri.parse(
        'http://${serverIp}:${widget.serverPort}/search?query=$query&path=$currentPath&listdir=$listDir&layers=$layers&sortBy=$sortBy&sortOrder=$sortOrder');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        items = data.map((item) => Map<String, String>.from(item)).toList();
      });
    } else {
      // Handle error
      print('Failed to fetch files');
    }
  }

  void _navigateToPath(String path) {
    setState(() {
      currentPath = path;
      _fetchFiles();
    });
  }

  void _navigateToParentDirectory() {
    if (currentPath != '/sdcard/') {
      final parentPath = Directory(currentPath).parent.path;
      setState(() {
        currentPath = parentPath;
        _fetchFiles();
      });
    }
  }

  void _navigateToHome() {
    setState(() {
      currentPath = '/sdcard/';
      _fetchFiles();
    });
  }

  IconData _getFileIcon(String type, String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (type) {
      case 'directory':
        return Icons.folder;
      case 'file':
        if (['mp3', 'wav'].contains(ext)) {
          return Icons.music_note;
        } else if (['jpg', 'jpeg', 'png', 'gif'].contains(ext)) {
          return Icons.photo;
        } else if (['mp4', 'avi', 'mov'].contains(ext)) {
          return Icons.video_library;
        } else if (['pdf'].contains(ext)) {
          return Icons.picture_as_pdf;
        } else {
          return Icons.file_present;
        }
      default:
        return Icons.file_present;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('File Explorer'),
      ),
      body: Column(
        children: [
          // Path navigation widget
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.home),
                  onPressed: _navigateToHome,
                ),
                ..._buildPathNavigation(),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final type = item['type'];
                final path = item['path'];

                return ListTile(
                  leading: Icon(_getFileIcon(type ?? '', path ?? '')),
                  title: Text(path?.split("/").last ?? ""),
                  onTap: () {
                    if (type == 'directory') {
                      setState(() {
                        currentPath = path ?? '';
                        _fetchFiles();
                      });
                    } else if (type == 'file') {
                      // Handle file opening
                      print('Opening file: $path');
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.filter_list),
              onPressed: () {
                // Show filter dialog
                _showFilterDialog();
              },
            ),
            Spacer(),
            // Add more filter options here if needed
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPathNavigation() {
    final parts = currentPath.split('/');
    final widgets = <Widget>[];

    String path = '';
    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        path += '/${parts[i]}';
        widgets.add(
          GestureDetector(
            onTap: () {
              _navigateToPath(path);
            },
            child: Text(
              parts[i],
              style: TextStyle(color: Colors.blue),
            ),
          ),
        );
        if (i < parts.length - 1) {
          widgets.add(Text('/'));
        }
      }
    }
    return widgets;
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Filter Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: sortBy,
                onChanged: (String? newValue) {
                  setState(() {
                    sortBy = newValue!;
                    _fetchFiles();
                  });
                },
                items: <String>['name', 'creation', 'last_modified', 'size']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              DropdownButton<String>(
                value: sortOrder,
                onChanged: (String? newValue) {
                  setState(() {
                    sortOrder = newValue!;
                    _fetchFiles();
                  });
                },
                items: <String>['asc', 'desc']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
