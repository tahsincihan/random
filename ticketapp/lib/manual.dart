import 'package:flutter/material.dart';


class ManualEntryPage extends StatelessWidget {
  const ManualEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Section
          Container(
            color: const Color(0xFFEAEEF2), // Background color for the top section
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Row(
              children: [
                // Back Icon
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context); // Navigate back to the previous screen
                  },
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 10),
                // User Icon
                Image.asset(
                  'assets/images/user.png',
                  width: 30,
                  height: 30,
                ),
                const SizedBox(width: 10),
                // Title
                const Text(
                  "Welcome Joe",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Page Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Enter Ticket Manually",
              style: TextStyle(
                color: Color(0xFF176584), // Font color
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 40),
          // Ticket Number Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Ticket Number",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: InputDecoration(
                    hintText: "E.g: FFHK-JJTY-GFRK-HHGA",
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Colors.black,
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Divider Line
          Container(
            height: 1,
            color: Colors.black,
          ),
          const SizedBox(height: 10),
          // Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              children: [
                // Admit Button
                ElevatedButton(
                  onPressed: () {
                    // Handle admit functionality
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF176584), // Button color
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "Admit",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Cancel Button
                ElevatedButton(
                  onPressed: () {
                    // Handle cancel functionality
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD9E2), // Button color
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}