import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sx_sync/src/pages/connection.dart';
import 'package:sx_sync/src/pages/home.dart';

class PermissionsRequestPage extends StatefulWidget {
  const PermissionsRequestPage({Key? key}) : super(key: key);

  @override
  State<PermissionsRequestPage> createState() => _PermissionsRequestPageState();
}

class _PermissionsRequestPageState extends State<PermissionsRequestPage> {
  final List<_PermissionInfo> permissions = [
    _PermissionInfo("Manage Storage", Icons.folder, Permission.manageExternalStorage),
    _PermissionInfo("Phone", Icons.phone, Permission.phone),
    _PermissionInfo("Photos", Icons.photo, Permission.photos),
    _PermissionInfo("Videos", Icons.video_library, Permission.videos),
    _PermissionInfo("Notifications", Icons.notifications, Permission.notification),
    _PermissionInfo("Contacts", Icons.contacts, Permission.contacts),
    _PermissionInfo("Media", Icons.library_music, Permission.mediaLibrary),
    _PermissionInfo("Audio", Icons.audiotrack, Permission.audio),
    _PermissionInfo("Battery Optimization", Icons.battery_saver, Permission.ignoreBatteryOptimizations),
    _PermissionInfo("Install Packages", Icons.system_update_alt, Permission.requestInstallPackages),
    _PermissionInfo("Bluetooth", Icons.bluetooth, Permission.bluetooth),
  ];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    for (var permission in permissions) {
      permission.status = await permission.permission.status;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              const Text(
                "Permissions Required",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Please grant the following permissions to proceed:",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: permissions.length,
                  itemBuilder: (context, index) {
                    return PermissionTile(
                      permissionInfo: permissions[index],
                      onGranted: _checkAllPermissionsGranted,
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: ElevatedButton(
                  onPressed: _requestAllPermissions,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "Grant All Permissions",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _requestAllPermissions() async {
    for (var permission in permissions) {
      await permission.permission.request();
    }
    _checkAllPermissionsGranted();
  }

  Future<void> _checkAllPermissionsGranted() async {
    bool allGranted = true;

    for (var permission in permissions) {
      if (await permission.permission.isGranted == false) {
        allGranted = false;
        break;
      }
    }

    if (allGranted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) {
          if (Platform.isAndroid) {
            return const HomePage();
          } else {
            return ConnectionPage();
          }
        }),
      );
    } else {
      setState(() {});  // Update UI when permission statuses change.
    }
  }
}

class PermissionTile extends StatelessWidget {
  final _PermissionInfo permissionInfo;
  final VoidCallback onGranted;

  const PermissionTile({
    Key? key,
    required this.permissionInfo,
    required this.onGranted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isGranted = permissionInfo.status.isGranted;
    final tileColor = isGranted ? Colors.blueAccent : Colors.redAccent;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      color: tileColor,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Icon(permissionInfo.icon, size: 30, color: Colors.white),
        title: Text(permissionInfo.title, style: const TextStyle(fontSize: 18, color: Colors.white)),
        trailing: ElevatedButton(
          onPressed: () async {
            await permissionInfo.permission.request();
            permissionInfo.status = await permissionInfo.permission.status;
            onGranted();
          },
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
          ),
          child: Text(
            isGranted ? "Granted" : "Grant",
            style: TextStyle(color: isGranted ? Colors.green : Colors.red),
          ),
        ),
      ),
    );
  }
}

class _PermissionInfo {
  final String title;
  final IconData icon;
  final Permission permission;
  PermissionStatus status = PermissionStatus.denied;

  _PermissionInfo(this.title, this.icon, this.permission);
}