import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'package:uni_marketplace_flutter/screens/profile_view.dart';
import 'package:uni_marketplace_flutter/main.dart';

class LoginPage extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<AuthViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'UNIMARKET',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F7A8C),
                  ),
                ),
                const SizedBox(height: 40),
                if (viewModel.error != null)
                  Text(viewModel.error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _email,
                  decoration: _inputDecoration('e-mail'),
                  validator: (v) => v!.contains('@') ? null : 'Enter a valid email',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: _inputDecoration('Password'),
                  validator: (v) => v!.length >= 6 ? null : 'Min 6 characters',
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: _buttonStyle(),
                  onPressed: viewModel.loading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            final user = await viewModel.login(_email.text, _password.text);
                            if (user != null) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => HomeScreen(userId: user.uid),
                                  ),
                                );
                              }
                          }
                        },
                  child: viewModel.loading
                      ? const CircularProgressIndicator()
                      : const Text("LOGIN"),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: const Text("Need an account? Register"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF1F7A8C), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF1F7A8C),
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
