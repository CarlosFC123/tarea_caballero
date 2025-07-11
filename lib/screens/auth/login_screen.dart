import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import '../admin/admin_home.dart';
import '../user/user_home.dart';
import 'package:flutter/foundation.dart';
import '../../services/speech_service.dart';

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
  bool _showVoiceAuth = false;
  String _voiceAuthStatus = '';
  String _recognizedText = '';
  bool _isListening = false;
  String _expectedPhrase = "soy un usuario";
  
  // Instancia del servicio de reconocimiento de voz
  final SpeechRecognitionService _speechService = SpeechRecognitionService();
  bool _speechServiceInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeSpeechService();
  }

  Future<void> _initializeSpeechService() async {
    if (!kIsWeb) {
      print('No es web, omitiendo inicialización de voz');
      return;
    }

    // Verificar soporte antes de inicializar
    if (!SpeechRecognitionService.isSupported()) {
      print('Speech Recognition no soportado en este navegador');
      return;
    }

    try {
      await _speechService.initialize();
      
      // Configurar callbacks
      _speechService.onResult = (text) {
        print('Texto reconocido: $text');
        setState(() {
          _recognizedText = text.toLowerCase();
          _isListening = false;
          _voiceAuthStatus = 'Verificando...';
        });
        _verifyVoiceAuth();
      };

      _speechService.onError = (error) {
        print('Error en reconocimiento de voz: $error');
        setState(() {
          _isListening = false;
          _voiceAuthStatus = 'Error al escuchar. Intenta nuevamente';
        });
      };

      _speechServiceInitialized = true;
      print('Servicio de voz inicializado correctamente');
    } catch (e) {
      print('Error al inicializar el servicio de voz: $e');
      _speechServiceInitialized = false;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _speechService.dispose();
    super.dispose();
  }

  Future<void> _startVoiceAuth() async {
    if (!kIsWeb) {
      setState(() {
        _voiceAuthStatus = 'Reconocimiento de voz solo disponible en web';
      });
      return;
    }

    if (!_speechServiceInitialized) {
      setState(() {
        _voiceAuthStatus = 'Servicio de voz no disponible';
      });
      return;
    }

    if (!SpeechRecognitionService.isSupported()) {
      setState(() {
        _voiceAuthStatus = 'Tu navegador no soporta reconocimiento de voz';
      });
      return;
    }

    setState(() {
      _isListening = true;
      _voiceAuthStatus = 'Por favor di: "$_expectedPhrase"';
      _recognizedText = '';
    });

    try {
      _speechService.startListening();
      print('Reconocimiento de voz iniciado');
    } catch (e) {
      print('Error al iniciar reconocimiento: $e');
      setState(() {
        _isListening = false;
        _voiceAuthStatus = 'Error al iniciar reconocimiento de voz';
      });
    }
  }

  Future<void> _verifyVoiceAuth() async {
    // Eliminar signos de puntuación y espacios extras
    final cleanedText = _recognizedText
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .trim()
        .toLowerCase();
    
    final cleanedExpected = _expectedPhrase
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .trim()
        .toLowerCase();

    print('Comparando: "$cleanedText" con "$cleanedExpected"');

    await Future.delayed(const Duration(seconds: 1));
    
    if (cleanedText == cleanedExpected) {
      setState(() {
        _voiceAuthStatus = 'Voz verificada ✅';
      });
      await Future.delayed(const Duration(seconds: 1));
      _completeLogin();
    } else {
      setState(() {
        _voiceAuthStatus = 'Frase incorrecta. Intenta nuevamente';
        _isListening = false;
      });
    }
  }

  Future<void> _completeLogin() async {
    try {
      final userData = await Supabase.instance.client
          .from('users')
          .select()
          .eq('telefono', _phoneController.text.trim())
          .single();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => UserHome(userData: userData)),
        );
      }
    } catch (e) {
      print('Error al completar login: $e');
      setState(() {
        _voiceAuthStatus = 'Error al completar el login';
      });
    }
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
          // Mostrar autenticación por voz antes de redirigir
          setState(() {
            _showVoiceAuth = true;
            _isLoading = false;
          });
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
      if (mounted && !_showVoiceAuth) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showVoiceAuth) {
      return _buildVoiceAuthScreen();
    }
    
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

  Widget _buildVoiceAuthScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mic, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'Verificación de Voz',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (_speechServiceInitialized) ...[
              Text(
                'Por favor di:',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),
              Text(
                '"$_expectedPhrase"',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ] else ...[
              const Text(
                'Reconocimiento de voz no disponible',
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              _voiceAuthStatus,
              style: TextStyle(
                fontSize: 18,
                color: _voiceAuthStatus.contains('✅') ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 30),
            if (_recognizedText.isNotEmpty && !_voiceAuthStatus.contains('✅'))
              Text(
                'Dijiste: "$_recognizedText"',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            const SizedBox(height: 40),
            if (_speechServiceInitialized)
              ElevatedButton.icon(
                onPressed: _isListening ? null : _startVoiceAuth,
                icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
                label: Text(_isListening ? 'Escuchando...' : 'Iniciar Verificación'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                setState(() {
                  _showVoiceAuth = false;
                  _isListening = false;
                  _voiceAuthStatus = '';
                });
                _speechService.stopListening();
              },
              child: const Text('Volver al login'),
            ),
            if (!_speechServiceInitialized)
              TextButton(
                onPressed: () {
                  _completeLogin(); // Permitir continuar sin voz
                },
                child: const Text('Continuar sin verificación de voz'),
              ),
          ],
        ),
      ),
    );
  }
}