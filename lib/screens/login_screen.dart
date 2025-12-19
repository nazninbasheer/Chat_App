import 'dart:math';
import 'package:chat_webapp/screens/list_user.dart';
import 'package:chat_webapp/widgets/hover_text_button.dart';
import 'package:chat_webapp/widgets/shake_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _error = '';
  String _success = '';

bool _obscurePassword = true;

  // 🔴 Error flags
  bool _nameError = false;
  bool _emailError = false;
  bool _passwordError = false;

  // 🔁 Toggle login/register
  void _toggleMode() {
  setState(() {
    _isLogin = !_isLogin;

    // ✅ Reset messages
    _error = '';
    _success = '';

    // ✅ Reset error borders & shake triggers
    _nameError = false;
    _emailError = false;
    _passwordError = false;

    // (Optional but recommended)
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
  });
}


  // 🚀 Submit
 Future<void> _submit() async {
   final email = _emailController.text.trim();
  final password = _passwordController.text.trim();
  final name = _nameController.text.trim();

  setState(() {
    _nameError = !_isLogin && _nameController.text.trim().isEmpty;
    _emailError = _emailController.text.trim().isEmpty ||
        !_emailController.text.contains('@');
    _passwordError = _passwordController.text.length < 6;
  });

  // ❌ Empty fields
  if ((!_isLogin && _nameController.text.trim().isEmpty) ||
      _emailController.text.trim().isEmpty ||
      _passwordController.text.isEmpty) {
    setState(() {
      _error = "Please fill all fields";
      _success = '';
    });
    return;
  }

  // ❌ Invalid email
  if (!_emailController.text.contains('@')) {
    setState(() {
      _error = "Please enter a valid email";
      _success = '';
    });
    return;
  }

  // ❌ Password too short
  if (_passwordController.text.length < 6) {
    setState(() {
      _error = "Password must be at least 6 characters";
      _success = '';
    });
    return;
  }

  // ✅ All valid
  setState(() {
    _error = '';
    _success = "Success 🎉";
  });


  try {
    if (_isLogin) {
      // Sign in
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Navigate to user list after successful login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => UserListScreen()),
      );
    } else {
      // Register
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'uid': user.uid,
        'email': email,
        'name':name,
      });

      // After register, switch mode back to login and show success message
      setState(() {
        _isLogin = true;
        _success = 'Registration successful! Please login now.';
      });
      _emailController.clear();
      _passwordController.clear();
    }
  } on FirebaseAuthException catch (e) {
    setState(() {
      _error = e.message ?? 'Authentication error';
    });
  } catch (e) {
    setState(() {
      _error = 'Something went wrong';
    });
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage("assets/enterbg.jpg"),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.5),
                  BlendMode.darken,
                ),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              child: Container( 
                constraints: const BoxConstraints(maxWidth: 600), 
                child: Card(
                elevation: 12,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: Colors.white.withOpacity(0.95),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isLogin ? 'Welcome Back 👋' : 'Create Account 🚀',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isLogin
                            ? "Login to continue"
                            : "Register to get started",
                      ),
                      const SizedBox(height: 20),

                      if (_error.isNotEmpty)
                        Text(_error,
                            style: const TextStyle(color: Colors.red)),

                      if (_success.isNotEmpty)
                        Text(_success,
                            style: const TextStyle(color: Colors.green)),

                      const SizedBox(height: 16),

                      // 👤 NAME
                      if (!_isLogin)
                        ShakeWidget(
                          shake: _nameError,
                          child: _buildField(
                            controller: _nameController,
                            label: "Name",
                            icon: Icons.person_outline,
                            error: _nameError,
                          ),
                        ),

                      if (!_isLogin) const SizedBox(height: 15),

                      // 📧 EMAIL
                      ShakeWidget(
                        shake: _emailError,
                        child: _buildField(
                          controller: _emailController,
                          label: "Email",
                          icon: Icons.email_outlined,
                          error: _emailError,
                        ),
                      ),

                      const SizedBox(height: 15),

                      // 🔒 PASSWORD
                      ShakeWidget(
  shake: _passwordError,
  child: _buildField(
    controller: _passwordController,
    label: "Password",
    icon: Icons.lock_outline,
    obscure: _obscurePassword,
    error: _passwordError,
    isPassword: true,
    onTogglePassword: () {
      setState(() {
        _obscurePassword = !_obscurePassword;
      });
    },
  ),
),


                      const SizedBox(height: 25),

                      _isLoading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _submit,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                  backgroundColor: Colors.deepPurple,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  _isLogin ? 'Login' : 'Register',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      ),      
                                ),
                              ),
                            ),

                      const SizedBox(height: 10),

                      HoverTextButton(
                        onPressed: _toggleMode,
                        text: _isLogin
                            ? "Don't have an account? Register"
                            : "Already have an account? Login",
                      ),
                    ],
                  ),
                ),
              ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🧩 Reusable Field
  Widget _buildField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  bool obscure = false,
  bool error = false,
  bool isPassword = false,
  VoidCallback? onTogglePassword,
}) {
  return TextField(
    controller: controller,
    obscureText: obscure,
    onChanged: (_) {
      if (error) {
        setState(() {});
      }
    },
    decoration: InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      prefixIcon: Icon(icon),

      // 👁️ Show / Hide only for password
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: onTogglePassword,
            )
          : null,

      filled: true,
      fillColor: Colors.white,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: error ? Colors.red : Colors.grey.shade400,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: error ? Colors.red : Colors.deepPurple,
          width: 2,
        ),
      ),
    ),
  );
}

}
