import 'package:chat_webapp/screens/list_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController(); 
  bool _isLogin = true;
  String _error = '';
   String _success = '';
  bool _isLoading = false;

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _error = '';
      _success = '';
       _nameController.clear();
    });
  }

Future<void> _submit() async {
  final email = _emailController.text.trim();
  final password = _passwordController.text.trim();
  final name = _nameController.text.trim();

  if (email.isEmpty || password.isEmpty) {
    setState(() => _error = 'Please enter email and password.');
    return;
  }

  setState(() {
    _isLoading = true;
    _error = '';
    _success ='';
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
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose(); 
    super.dispose();
  }
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Stack(
      children: [
        // Background image with fade/opacity
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
             image: AssetImage("assets/connect.jpg"),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.5), // fade effect
                BlendMode.darken,
              ),
            ),
          ),
        ),

        // Center card
        Center(
          child: SingleChildScrollView(
            child: Card(
              elevation: 12,
              shadowColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: Colors.white.withOpacity(0.3),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      _isLogin ? 'Welcome Back 👋' : 'Create Account 🚀',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _isLogin
                          ? "Login to continue your journey"
                          : "Register to start connecting",
                      style: TextStyle(color: Colors.black),
                    ),
                    const SizedBox(height: 20),

                    // Error / Success messages
                    if (_error.isNotEmpty)
                      Text(
                        _error,
                        style: const TextStyle(color: Colors.red),
                      ),
                    if (_success.isNotEmpty)
                      Text(
                        _success,
                        style: const TextStyle(color: Colors.green),
                      ),
                    const SizedBox(height: 10),

                    // Fields
                    if (!_isLogin)
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    if (!_isLogin) const SizedBox(height: 15),

                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 15),

                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      obscureText: true,
                    ),

                    const SizedBox(height: 25),

                    // Login / Register Button
                    _isLoading
                        ? const CircularProgressIndicator()
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: Colors.deepPurple,
                              ),
                              onPressed: _submit,
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

                    // Switch Mode
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
      ],
    ),
  );
}
}


class HoverTextButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;

  const HoverTextButton({super.key, required this.onPressed, required this.text});

  @override
  State<HoverTextButton> createState() => _HoverTextButtonState();
}

class _HoverTextButtonState extends State<HoverTextButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: TextButton(
        onPressed: widget.onPressed,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: _isHovered ? 18 : 16, // grows on hover
            color: _isHovered ? const Color(0xFF321B58)  : Colors.deepPurple ,
            fontWeight: FontWeight.bold,
          ),
          child: Text(widget.text),
        ),
      ),
    );
  }
}
