import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'punch_error_screen.dart';

class TicketDetailsScreen extends StatefulWidget {
  // Now expects the ticket code, e.g. "single:<uuid>" or "multiple:<group-code>"
  final String ticketCode;
  const TicketDetailsScreen({super.key, required this.ticketCode});

  @override
  State<TicketDetailsScreen> createState() => _TicketDetailsScreenState();
}

class _TicketDetailsScreenState extends State<TicketDetailsScreen> {
  bool isLoading = true;
  bool isScannedOutsideTime = false;
  Map<String, dynamic>? ticketInfo;
  List<dynamic> tickets = []; // For multiple tickets (if returned)
  
  // Optional event-level fields (if provided by the API)
  String? eventName;
  String? dateTime;
  String? location;
  String? userName;
  String validFrom = '';
  String validTo = '';

  @override
  void initState() {
    super.initState();
    fetchTicketDetails();
  }

  Future<void> fetchTicketDetails() async {
    const String apiUrl = 'https://mapyourevent.myeenterprises.co.uk/api/scan';
    // Use the key "ticket_code" with the passed ticketCode
    final Map<String, dynamic> payload = {
      'ticket_code': widget.ticketCode,
    };

    print("Fetching ticket details with payload: $payload");

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        // The API returns an array of ticket objects.
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isEmpty) {
          setState(() {
            isLoading = false;
          });
          return;
        }
        setState(() {
          tickets = data;
          // Optionally, if event-level info is in the first ticket:
          eventName = data[0]['event_name']?.toString();
          dateTime = data[0]['event_date']?.toString(); // Adjust field if needed.
          location = data[0]['location']?.toString();
          userName = data[0]['user']?['name']?.toString();
          validFrom = data[0]['valid_from']?.toString() ?? '';
          validTo   = data[0]['valid_to']?.toString() ?? '';
          ticketInfo = data[0]; // Use first ticket as a reference for details.
          isLoading = false;
        });

        if (validFrom.isNotEmpty && validTo.isNotEmpty) {
          checkValidityTime(validFrom, validTo);
        }
      } else {
        print("Error: ${response.statusCode} ${response.body}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Exception fetching ticket details: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void checkValidityTime(String from, String to) {
    try {
      final now = DateTime.now();
      final start = DateTime.parse(from);
      final end = DateTime.parse(to);
      setState(() {
        isScannedOutsideTime = now.isBefore(start) || now.isAfter(end);
      });
    } catch (e) {
      print("Error parsing validity times: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ticket Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (ticketInfo == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ticket Details')),
        body: const Center(child: Text('Failed to fetch ticket details.')),
      );
    }

    // Extract fields from the first ticket object as reference
    final String uuid = ticketInfo?['uuid']?.toString() ?? 'N/A';
    final String status = ticketInfo?['status']?.toString() ?? 'N/A';
    final bool reserved = ticketInfo?['reserved'] == true;
    final String purchasedOn = ticketInfo?['purchased_on']?.toString() ?? 'N/A';
    final String price = ticketInfo?['price']?.toString() ?? 'N/A';

    // Enable Admit if status is "active" or "reserved"
    final bool canAdmit = status.toLowerCase() == 'active' || status.toLowerCase() == 'reserved';

    return Scaffold(
      appBar: AppBar(title: const Text('Ticket Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ticket Type Title (if available)
                Center(
                  child: Text(
                    ticketInfo?['name']?.toString() ?? 'Adult Ticket',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Event Info
                Text(
                  eventName ?? 'Unknown Event',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dateTime ?? 'Date & Time',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        location ?? 'Location details',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'Name: ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: Text(
                        userName ?? 'N/A',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isScannedOutsideTime ? Colors.red : Colors.grey,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Valid from\n$validFrom - $validTo',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'Purchase Date: ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: Text(
                        purchasedOn,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'Reserved: ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      reserved ? 'Yes' : 'No',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'Status: ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      status,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'Ticket Code: ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: Text(
                        uuid,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: canAdmit
                          ? () async {
                              const String punchUrl = 'https://mapyourevent.myeenterprises.co.uk/api/tickets/punch';
                              final Map<String, dynamic> payload = {
                                "tickets": [uuid]
                              };

                              try {
                                final response = await http.post(
                                  Uri.parse(punchUrl),
                                  headers: {"Content-Type": "application/json"},
                                  body: jsonEncode(payload),
                                );
                                if (response.statusCode == 200) {
                                  final Map<String, dynamic> data = jsonDecode(response.body);
                                  if (data["success"] == true) {
                                    final punchResult = data["data"][0];
                                    if (punchResult["success"] == true) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Ticket punched successfully"),
                                          backgroundColor: Colors.green,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                      // Navigate back to the QR scanner screen
                                      Navigator.popUntil(context, (route) => route.isFirst);
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PunchErrorScreen(
                                            errorMessage: punchResult["message"] ?? "Punch failed",
                                            ticketUUID: uuid,
                                          ),
                                        ),
                                      );
                                    }
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PunchErrorScreen(
                                          errorMessage: data["message"] ?? "Unknown error",
                                          ticketUUID: uuid,
                                        ),
                                      ),
                                    );
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Error: ${response.statusCode}"),
                                      backgroundColor: Colors.red,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Error: $e"),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            }
                          : null,
                      child: const Text('Admit', style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
