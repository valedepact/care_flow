import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:care_flow/screens/login_page.dart';
import 'package:care_flow/screens/register_page.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F0FF), Color(0xFFF8FBFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'assets/images/bre.png',
                  height: 100,
                  width: 100,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.local_hospital,
                    size: 100,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 24),
                // App Title
                Text(
                  "Care Flow",
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                        letterSpacing: 2,
                      ),
                ),
                const SizedBox(height: 8),
                // Tagline
                Text(
                  "Streamlining healthcare for a better patient experience",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w400,
                      ),
                ),
                const SizedBox(height: 32),
                // Login/Register Cards
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 700) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Card(
                              elevation: 6,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: LoginPage(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 40),
                          Expanded(
                            child: Card(
                              elevation: 6,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: RegisterCard(),
                              ),
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          Card(
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: LoginPage(),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Card(
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: RegisterCard(),
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 32),
                // Social Login
                Text(
                  "Or login with",
                  style: TextStyle(color: Colors.grey[700], fontSize: 16),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: const FaIcon(FontAwesomeIcons.google),
                      label: const Text("Google"),
                      onPressed: () {
                        debugPrint('Google login pressed');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
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
                        debugPrint('Facebook login pressed');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade800,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Terms and Privacy
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        debugPrint('Terms and Conditions pressed');
                      },
                      child: const Text("Terms and Conditions"),
                    ),
                    const SizedBox(
                      height: 20,
                      child: VerticalDivider(
                        color: Colors.grey,
                        thickness: 1,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        debugPrint('Privacy Policy pressed');
                      },
                      child: const Text("Privacy Policy"),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
