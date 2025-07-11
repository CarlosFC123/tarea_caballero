import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../admin/admin_home.dart';
import '../user/user_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isAdmin = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    
    try {
      if (_isAdmin) {
        final adminData = await Supabase.instance.client
            .from('admin')
            .select()
            .eq('email', _phoneController.text.trim())
            .eq('password', _passwordController.text.trim())
            .single();
        
        if (adminData != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => AdminHome(adminData: adminData)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Credenciales incorrectas')),
          );
        }
      } else {
        final userData = await Supabase.instance.client
            .from('users')
            .select()
            .eq('telefono', _phoneController.text.trim())
            .eq('password', _passwordController.text.trim())
            .single();
        
        if (userData != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => UserHome(userData: userData)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Teléfono o contraseña incorrectos')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al iniciar sesión: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isAdmin ? 'Admin Login' : 'Programa de Fidelización',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: _isAdmin ? 'Email' : 'Teléfono',
                prefixIcon: Icon(_isAdmin ? Icons.email : Icons.phone),
              ),
              keyboardType: _isAdmin ? TextInputType.emailAddress : TextInputType.phone,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Checkbox(
                  value: _isAdmin,
                  onChanged: (value) => setState(() => _isAdmin = value ?? false),
                ),
                const Text('Soy administrador'),
              ],
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading 
                    ? const CircularProgressIndicator()
                    : const Text('Iniciar Sesión'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}