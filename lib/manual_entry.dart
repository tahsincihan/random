import 'package:flutter/material.dart';
import 'single_ticket.dart';
import 'multiple_ticket.dart';

class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final TextEditingController ticketController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar with custom style.
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Enter Ticket Manually',
          style: TextStyle(color: Colors.black),
        ),
      ),
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Label for Ticket Code.
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Ticket Code',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // TextField for manual ticket entry.
              TextField(
                controller: ticketController,
                decoration: InputDecoration(
                  hintText: 'E.g:085ce325-3b78-4ce7-8cf5-0a78b3e657a5',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),
              // Always show the hyphen disclaimer.
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Please include hyphens (e.g., 3614-56EB-5969-FCCA)',
                  style: TextStyle(color: Colors.red, fontSize: 14),
                ),
              ),
              const Spacer(),
              // Search button.
              ElevatedButton(
                onPressed: () {
                  final code = ticketController.text.trim();
                  if (code.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid ticket code.'),
                        duration: Duration(seconds: 4),
                      ),
                    );
                    return;
                  }
                  // Clear the text field.
                  ticketController.clear();
                  // Decide based on the length of the code (excluding any prefix).
                  // Group code expected length is 19 (including hyphens).
                  // A typical UUID is longer (around 36 characters).
                  if (code.length == 19) {
                    // It's a group code.
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            MultipleTicketsScreen(ticketCode: "multiple:$code"),
                      ),
                    );
                  } else if (code.length > 19) {
                    // Assume it's a single ticket code.
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SingleTicketDetailsScreen(ticketCode: "single:$code"),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Invalid ticket code.'),
                        duration: Duration(seconds: 4),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF176584),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Search',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              // Cancel button.
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD9E2),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    ticketController.dispose();
    super.dispose();
  }
}