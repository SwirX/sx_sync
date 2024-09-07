import 'dart:convert';
import 'dart:io' show HttpClient, Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sx_sync/src/pages/file_explorer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isConnected = false;
  String ipAddress = '';
  String statusMessage = '';
  final TextEditingController ipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadConnectionStatus();
    _loadIpAddress();
  }

  Future<void> _loadConnectionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isConnected = prefs.getBool('isConnected') ?? false;
    });
  }

  Future<void> _updateConnectionStatus(bool connected) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isConnected = connected;
      prefs.setBool('isConnected', connected);
    });
  }

  Future<void> _loadIpAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIp = prefs.getString('ipAddress') ?? '';
    ipController.text = savedIp;
    setState(() {
      ipAddress = savedIp;
    });
  }

  Future<void> _updateIpAddress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      ipAddress = ipController.text;
      prefs.setString('ipAddress', ipController.text);
    });
  }

  Future<void> _fetchServerStatus() async {
    try {
      final response = await get(Uri.parse('http://$ipAddress:8080/status'));
      final responseBody = response.body;
      final status = jsonDecode(responseBody);
      setState(() {
        statusMessage = 'Server is up and running';
        _updateConnectionStatus(true);
      });
    } catch (e) {
      setState(() {
        statusMessage = 'Failed to connect to server';
        _updateConnectionStatus(false);
      });
    }
  }

  Widget _buildStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Server Status:',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (statusMessage.isNotEmpty) ...[
          Text(statusMessage),
        ],
      ],
    );
  }

  Widget _buildDesktopView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: ipController,
            decoration: InputDecoration(
              labelText: 'Server IP Address',
            ),
            keyboardType: TextInputType.number,
          ),
          ElevatedButton(
            onPressed: () async {
              await _updateIpAddress();
              await _fetchServerStatus();
            },
            child: Text('Update IP and Check Connection'),
          ),
          SizedBox(height: 20),
          if (isConnected) ...[
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FileExplorerPage(serverIp: ipAddress)),
                );
              },
              child: Text('Open File Explorer'),
            ),
          ],
          SizedBox(height: 20),
          _buildStatusSection(),
        ],
      ),
    );
  }

  Widget _buildMobileView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isConnected) ...[
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FileExplorerPage(serverIp: ipAddress)),
                );
              },
              child: Text('Open File Explorer'),
            ),
          ],
          SizedBox(height: 20),
          _buildStatusSection(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
      ),
      body: kIsWeb || !Platform.isAndroid ? _buildDesktopView() : _buildMobileView(),
    );
  }
}
