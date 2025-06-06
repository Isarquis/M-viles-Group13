import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'package:uni_marketplace_flutter/screens/profile_view.dart';
import 'package:uni_marketplace_flutter/main.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final ValueNotifier<bool> _rememberMe = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    if (savedEmail != null) {
      setState(() {
        _emailController.text = savedEmail;
        _rememberMe.value = true;
      });
    }
  }

  Future<void> _saveEmail() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe.value) {
      await prefs.setString('saved_email', _emailController.text.trim());
    } else {
      await prefs.remove('saved_email');
    }
  }

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
                  Text(
                    viewModel.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _emailController,
                  decoration: _inputDecoration('E-mail'),
                  validator:
                      (value) =>
                          value != null && value.contains('@')
                              ? null
                              : 'Enter a valid email',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: _inputDecoration('Password'),
                  validator:
                      (value) =>
                          value != null && value.length >= 6
                              ? null
                              : 'Min 6 characters',
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<bool>(
                  valueListenable: _rememberMe,
                  builder: (context, value, child) => Row(
                    children: [
                      Checkbox(
                        value: value,
                        onChanged: (checked) => _rememberMe.value = checked ?? false,
                      ),
                      const Text('Remember me'),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: _buttonStyle(),
                  onPressed:
                      viewModel.loading
                          ? null
                          : () async {
                            if (_formKey.currentState!.validate()) {
                              final connectivityResult =
                                  await Connectivity().checkConnectivity();
                              if (connectivityResult ==
                                  ConnectivityResult.none) {
                                _showAlert(
                                  'No Connection',
                                  'Please connect to the internet to login.',
                                );
                                return;
                              }

                              viewModel.setLoading(true);

                              try {
                                final user = await viewModel.login(
                                  _emailController.text.trim(),
                                  _passwordController.text.trim(),
                                );

                                if (user != null) {
                                  await _saveEmail();
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => HomeScreen(userId: user.uid),
                                    ),
                                  );
                                }
                              } catch (error) {
                                _showAlert('Login Failed', error.toString());
                              } finally {
                                viewModel.setLoading(false);
                              }
                            }
                          },
                  child:
                      viewModel.loading
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF1F7A8C),
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}
