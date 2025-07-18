import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:care_flow/screens/login_page.dart'; // Import the LoginPage widget
import 'package:care_flow/screens/register_page.dart'; // Updated: Import the RegisterCard widget
// For debugPrint

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  MyHomePageState createState() {
    return MyHomePageState();
  }
}

class MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0), // Add some padding around the content
        child: Column(
          children: [
            const SizedBox(height: 32),
            // Application Title
            Center(
              child: Text(
                "Care Flow",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Login and Register Cards side-by-side
            // Using a Flexible layout to ensure responsiveness on different screen sizes
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) { // For wider screens (e.g., desktop, tablet landscape)
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start, // Align cards at the top
                    children: [ // Removed 'const' here
                      Expanded(child: LoginPage()), // Changed to LoginPage()
                      const SizedBox(width: 24), // Increased spacing for larger screens
                      Expanded(child: RegisterCard()), // Changed to RegisterCard()
                    ],
                  );
                } else { // For smaller screens (e.g., mobile, tablet portrait)
                  return Column(
                    children: [ // Removed 'const' here
                      LoginPage(), // Changed to LoginPage()
                      const SizedBox(height: 24), // Increased spacing for smaller screens
                      RegisterCard(), // Changed to RegisterCard()
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 24),
            // Terms and Privacy Policy links
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    // Handle navigation to Terms and Conditions page
                    debugPrint('Terms and Conditions pressed');
                  },
                  child: const Text("Terms and Conditions"),
                ),
                // Using a SizedBox instead of VerticalDivider for better control in a Row
                const SizedBox(
                  height: 20, // Height of the divider
                  child: VerticalDivider(
                    color: Colors.grey,
                    thickness: 1,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Handle navigation to Privacy Policy page
                    debugPrint('Privacy Policy pressed');
                  },
                  child: const Text("Privacy Policy"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              "Or login with",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            // Social Login Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const FaIcon(FontAwesomeIcons.google),
                  label: const Text("Google"),
                  onPressed: () {
                    // Handle Google login logic
                    debugPrint('Google login pressed');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent, // Google's brand color
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.facebook),
                  label: const Text("Facebook"),
                  onPressed: () {
                    // Handle Facebook login logic
                    debugPrint('Facebook login pressed');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800, // Facebook's brand color
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32), // Add some space at the bottom
          ],
        ),
      ),
    );
  }
}
