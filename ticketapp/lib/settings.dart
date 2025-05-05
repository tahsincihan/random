import 'package:flutter/material.dart';
import 'home.dart';  

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,  
        children: [ 
          // Top Section
          Container(
            color: const Color(0xFFEAEEF2), 
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Back Icon
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const QrScanScreen()),
                        );
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
                      width: 40, 
                      height: 40,
                    ),
                    const SizedBox(width: 10),
                    // Welcome Text
                    const Text(
                      "Welcome Joe",
                      style: TextStyle(
                        color: Color(0xFF8C4A5F),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        // Handle search functionality
                      },
                      child: Image.asset(
                        'assets/images/search.png',
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Page Title
                const Text(
                  "Settings",
                  style: TextStyle(
                    color: Color(0xFF176584), 
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // App Preferences Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "App Preferences",
                  style: TextStyle(
                    color: Color(0xFF176584),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                // Dark Mode Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Dark Mode",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Switch(
                      value: false, // Default value
                      onChanged: (bool value) {
                        // Handle dark mode toggle
                      },
                      activeColor: const Color(0xFF176584),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                // Scan Notifications Section
                const Text(
                  "Scan Notifications",
                  style: TextStyle(
                    color: Color(0xFF176584),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                // Push Notification Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Push",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Switch(
                      value: true, // Default value
                      onChanged: (bool value) {
                        // Handle push notification toggle
                      },
                      activeColor: Colors.blue, // Blue toggle color
                    ),
                  ],
                ),
                // Email Alerts Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Email Alerts",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Switch(
                      value: false, // Default value
                      onChanged: (bool value) {
                        // Handle email alerts toggle
                      },
                      activeColor: const Color(0xFF176584),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          // Log Out Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const QrScanScreen()),
                  (route) => false, // Clears all previous screens
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD9E2),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "LOG OUT",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20), 
        ],
      ),
    );
  }
}
