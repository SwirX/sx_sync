import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sx_sync/src/classes/server.dart';

import 'src/pages/permissions.dart';

void main() async {
  // Determine the local IP address (you may need to hard-code this or use another method to get the IP)
  final ipAddress = await _getLocalIpAddress();

  // Create and start the server
  final fileServer = FileServer(ipAddress: ipAddress);
  await fileServer.start();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
        useMaterial3: true,
      ),
      home: const PermissionsRequestPage(),
    );
  }
}

Future<String> _getLocalIpAddress() async {
  // Get the local IP address of the device
  // For a phone, it is generally reachable via a local network address
  final interfaces =
      await NetworkInterface.list(type: InternetAddressType.IPv4);
  final localIp = interfaces
      .expand((interface) => interface.addresses)
      .firstWhere((address) => !address.isLoopback)
      .address;
  return localIp;
}
