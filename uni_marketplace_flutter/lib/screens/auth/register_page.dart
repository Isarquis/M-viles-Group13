import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';

class RegisterPage extends StatefulWidget {
  RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  String _gender = 'Male'; // Default gender

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<AuthViewModel>(context);
    final themeColor = const Color(0xFF1F7A8C);

    return Scaffold(
      appBar: AppBar(
        title: const Text("UNIMARKET"),
        centerTitle: true,
        leading: const BackButton(),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                  ),
                ),
                const SizedBox(height: 24),
                if (viewModel.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      viewModel.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) => v!.isEmpty ? 'Enter your name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  decoration: InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) => v!.isEmpty ? 'Enter your phone' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: ['Male', 'Female'].map((gender) {
                    return DropdownMenuItem(
                      value: gender,
                      child: Text(gender),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _gender = value!;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  decoration: InputDecoration(
                    labelText: 'E-mail',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) =>
                      v!.contains('@') ? null : 'Enter valid email',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) =>
                      v!.length >= 6 ? null : 'Min 6 characters',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmPassword,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) => v == _password.text
                      ? null
                      : 'Passwords do not match',
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: viewModel.loading
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              final user = await viewModel.register(
                                _email.text,
                                _password.text,
                                _name.text,
                                _phone.text,
                                _gender,
                              );
                              if (user != null) {
                                Navigator.pushReplacementNamed(
                                    context, '/home');
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: viewModel.loading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            "REGISTER",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text("Already have an account? Login"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
