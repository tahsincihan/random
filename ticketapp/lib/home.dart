import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'single_ticket.dart';
import 'multiple_ticket.dart';
import 'manual_entry.dart';
import 'events.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> with WidgetsBindingObserver {
  final MobileScannerController cameraController = MobileScannerController();
  String storedUserName = 'User';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    fetchUserInfo();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    cameraController.dispose();
    super.dispose();
  }

  // When the app lifecycle changes, stop/start the camera accordingly.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      cameraController.stop();
    } else if (state == AppLifecycleState.resumed) {
      cameraController.start();
    }
  }

  // Logout function: clears stored credentials and navigates to the login screen.
  Future<void> _logout() async {
    var box = Hive.box('secureBox');
    await box.delete('access_token');
    await box.delete('login_time');
    await box.delete('user_name');
    Navigator.pushReplacementNamed(context, '/login');
  }

  /// Fetch user info from the API (/api/user) using a GET request.
  Future<void> fetchUserInfo() async {
    try {
      final box = Hive.box('secureBox');
      final token = box.get('access_token');
      if (token != null) {
        final response = await http.get(
          Uri.parse('https://mapyourevent.myeenterprises.co.uk/api/user'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
        if (response.statusCode == 200) {
          final Map<String, dynamic> userData = jsonDecode(response.body);
          setState(() {
            storedUserName = userData['name'] ?? 'User';
          });
          await box.put('user_name', storedUserName);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ticket not found'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error fetching user info: $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Retrieve the stored user name (it might have been updated in fetchUserInfo).
    final box = Hive.box('secureBox');
    storedUserName = box.get('user_name') ?? storedUserName;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[300],
        title: Text(
          'Welcome, $storedUserName',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.brown,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.brown),
          ),
          // Notifications icon (if needed)
          Stack(
            children: [
              IconButton(
                onPressed: () {
                  // Implement notification action if needed.
                },
                icon: const Icon(Icons.notifications, color: Colors.brown),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '',
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Title for QR scanning.
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 15),
              child: Text(
                'Scan QR Code',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF176584),
                ),
              ),
            ),
            // QR Scanner area.
            Expanded(
              child: Container(
                color: Colors.grey[300],
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    MobileScanner(
                      controller: cameraController,
                      onDetect: (capture) async {
                        final List<Barcode> barcodes = capture.barcodes;
                        if (barcodes.isNotEmpty) {
                          final String scannedCode = barcodes.first.rawValue ?? '';
                          cameraController.stop();
                          // Navigate based on the prefix.
                          if (scannedCode.startsWith("multiple:")) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MultipleTicketsScreen(ticketCode: scannedCode),
                              ),
                            ).then((_) => cameraController.start());
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SingleTicketDetailsScreen(ticketCode: scannedCode),
                              ),
                            ).then((_) => cameraController.start());
                          }
                        }
                      },
                    ),
                    // QR Frame overlay.
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF176584),
                          width: 4,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'Align QR code to fill inside the frame',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 15),
            // Bottom Buttons.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      cameraController.stop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ManualEntryScreen()),
                      ).then((_) => cameraController.start());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF176584),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text(
                      'Enter Manually',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      cameraController.stop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EventsScreen()),
                      ).then((_) => cameraController.start());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD9E2),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text(
                      'View Reservations',
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}