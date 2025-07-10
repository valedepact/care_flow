import 'package:flutter/material.dart';
import 'package:care_flow/screens/dashboard_page.dart'; // Assuming DashboardPage is the next screen after registration

class RegisterCard extends StatefulWidget { // Changed to StatefulWidget to manage dropdown value
  const RegisterCard({super.key});

  @override
  State<RegisterCard> createState() => _RegisterCardState();
}

class _RegisterCardState extends State<RegisterCard> {
  final _formKey = GlobalKey<FormState>(); // Added a GlobalKey for form validation
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String _selectedRole = "Patient"; // Default role changed to Patient

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
                "Create a New Account",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24), // Increased spacing

              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: "Full Name",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: "Username",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_circle),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email address';
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
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters long';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Confirm Password",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_reset),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Role Selection Dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Register as", // Changed label for clarity
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
                value: _selectedRole,
                onChanged: (newValue) {
                  setState(() {
                    _selectedRole = newValue!;
                  });
                },
                items: const [
                  DropdownMenuItem(value: "Patient", child: Text("Patient")),
                  DropdownMenuItem(value: "Nurse", child: Text("Nurse")),
                  DropdownMenuItem(value: "Doctor", child: Text("Doctor")),
                ],
              ),
              const SizedBox(height: 24), // Increased spacing

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
                child: const Text("Register"),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // All fields are valid, proceed with registration logic
                    print('Registration successful for role: $_selectedRole');
                    print('Full Name: ${_fullNameController.text}');
                    print('Username: ${_usernameController.text}');
                    print('Email: ${_emailController.text}');
                    // In a real app, you would send this data to your backend
                    // for user creation and authentication.

                    // Navigate to DashboardPage after successful registration
                    Navigator.pushReplacement( // Use pushReplacement to prevent going back to register page
                      context,
                      MaterialPageRoute(builder: (context) => const DashboardPage()),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
