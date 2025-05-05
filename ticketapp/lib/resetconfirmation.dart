import 'package:flutter/material.dart';

class ResetConfirmationPage extends StatefulWidget {
  const ResetConfirmationPage({super.key});

  @override
  State<ResetConfirmationPage> createState() => _ResetConfirmationPageState();
}

class _ResetConfirmationPageState extends State<ResetConfirmationPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize the AnimationController
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500), 
    );

    // Define the scale animation
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack, 
      ),
    );

    // Start the animation
    _controller.forward();
  }

  @override
  void dispose() {
    // Dispose of the animation controller to free up resources
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF176584), Color(0xFFC1E8FF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const Text(
                  "Map your Event Ticket Scanning",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 200), 
                // Confirmation Text
                const Center(
                  child: Text(
                    "Your password has been successfully reset",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 30), 
                // Animated Tick Icon
                Center(
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Image.asset(
                      'assets/images/tick.png',
                      width: 80,
                      height: 80,
                    ),
                  ),
                ),
                const SizedBox(height: 30), 
                // Black Line
                Container(
                  height: 1,
                  color: Colors.black,
                  width: double.infinity,
                ),
                const SizedBox(height: 100), 
                // Back to Login Button
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate back to the login screen
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF176584),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      "Back to Login",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
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
