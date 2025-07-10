import 'package:flutter/material.dart';
import 'package:care_flow/screens/dashboard_page.dart'; // The welcome/landing page
import 'package:care_flow/screens/nurse_dashboard_board.dart'; // Import Nurse/Caregiver Dashboard
import 'package:care_flow/screens/patient_dashboard_page.dart'; // Import Patient Dashboard (will create this)

class LoginCard extends StatefulWidget {
  const LoginCard({super.key});

  @override
  State<LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends State<LoginCard> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); // For form validation

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      final String username = _usernameController.text.trim();
      final String password = _passwordController.text.trim();

      // --- Simulated Login Logic ---
      // In a real application, you would send these credentials to an authentication service
      // (e.g., Firebase Auth, your custom backend API) and receive the user's role.

      // For demonstration:
      if (username == 'patient' && password == 'password') {
        print('Logging in as Patient');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PatientDashboardPage()),
        );
      } else if (username == 'nurse' && password == 'password') {
        print('Logging in as Nurse');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CaregiverDashboard()), // Nurse Dashboard
        );
      } else {
        // Show an error message for invalid credentials
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid username or password. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        print('Login failed: Invalid credentials');
      }
      // --- End Simulated Login Logic ---
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4, // Added elevation for better visual separation
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Rounded corners
      child: Padding(
        padding: const EdgeInsets.all(24.0), // Increased padding
        child: Form( // Wrapped with Form for validation
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min, // Make column take minimum space
            children: [
              Text(
                "Login into your account",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24), // Increased spacing

              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: "Username or email",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your username or email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
                ),
                child: const Text("Login"),
                onPressed: _login, // Call the _login function
              ),
              const SizedBox(height: 8),

              TextButton(
                child: const Text("Forgot Password?"),
                onPressed: () {
                  // Forgot password logic will lie here
                  print('Forgot Password pressed');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
