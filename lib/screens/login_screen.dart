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
      appBar: AppBar(
        title: Text(_isLogin ? 'Login' : 'Register'),
      ),
      body: Padding(
      
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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
              if (!_isLogin)  // Show name field only during registration
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _submit,
                    child: Text(_isLogin ? 'Login' : 'Register'),
                  ),
            TextButton(
              onPressed: _toggleMode,
              child: Text(_isLogin
                  ? 'Don\'t have an account? Register'
                  : 'Already have an account? Login'),
            ),
          ],
        ),
      ),
    );
  }
}
