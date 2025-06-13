import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://kngtqjpdmzbvwuevxarx.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtuZ3RxanBkbXpidnd1ZXZ4YXJ4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk3NzEwNjgsImV4cCI6MjA2NTM0NzA2OH0.PgP2uS6kOs4Zlk-e3Q80TsDEQRhP6WCUaXRQv6k9wWk',
  );
  
  runApp(const FidelizacionApp());
}

class FidelizacionApp extends StatelessWidget {
  const FidelizacionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Programa de Fidelización',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginScreen(),
    );
  }
}

// Pantalla de Login
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
      // Login admin
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
      // Login usuario
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

// Pantalla de Administrador
class AdminHome extends StatefulWidget {
  final Map<String, dynamic> adminData;

  const AdminHome({super.key, required this.adminData});

  @override
  _AdminHomeState createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
          ),
        ],
      ),
      body: _currentIndex == 0 
          ? ClientsList() 
          : _currentIndex == 1 
              ? RewardsList() 
              : PartnersList(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clientes'),
          BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: 'Premios'),
          BottomNavigationBarItem(icon: Icon(Icons.discount), label: 'Beneficios'),
        ],
      ),
    );
  }
}

// Lista de Clientes
class ClientsList extends StatefulWidget {
  @override
  _ClientsListState createState() => _ClientsListState();
}

class _ClientsListState extends State<ClientsList> {
  List<Map<String, dynamic>> _clients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
  setState(() => _isLoading = true);
  try {
    final List<dynamic> data = await Supabase.instance.client
        .from('users')
        .select()
        .order('created_at', ascending: false);
    
    setState(() => _clients = List<Map<String, dynamic>>.from(data));
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al cargar clientes: ${e.toString()}')),
    );
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
  Future<void> _addPoints(String userId, int currentPoints, double amount) async {
  final pointsToAdd = (amount ~/ 100) * 5;
  final newPoints = currentPoints + pointsToAdd;
  
  try {
    // Update user points
    await Supabase.instance.client
        .from('users')
        .update({'puntos': newPoints})
        .eq('id', userId);

    // Record transaction
    await Supabase.instance.client
        .from('transactions')
        .insert({
          'user_id': userId,
          'monto_compra': amount,
          'puntos_otorgados': pointsToAdd,
          'created_at': DateTime.now().toIso8601String(),
        });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ $pointsToAdd puntos agregados')),
    );
    
    // Refresh client list
    _loadClients();
  } catch (e) {
    debugPrint('Error adding points: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ Error al agregar puntos: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _clients.length,
              itemBuilder: (context, index) {
                final client = _clients[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(client['nombre']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(client['telefono']),
                        Text('Puntos: ${client['puntos']}'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            final amountController = TextEditingController();
                            return AlertDialog(
                              title: const Text('Agregar Puntos'),
                              content: TextField(
                                controller: amountController,
                                decoration: const InputDecoration(
                                  labelText: 'Monto de compra',
                                  prefixText: '\$',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    final amount = double.tryParse(amountController.text) ?? 0;
                                    _addPoints(client['id'], client['puntos'], amount);
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Agregar'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
  onPressed: () {
    showDialog(
      context: context,
      builder: (context) {
        final phoneController = TextEditingController();
        final nameController = TextEditingController();
        final passwordController = TextEditingController();
        
        return StatefulBuilder(
          builder: (context, setState) {
            bool isLoading = false;
            
            return AlertDialog(
              title: const Text('Nuevo Cliente'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        hintText: 'Ej: +51987654321'
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo'
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña'
                      ),
                      obscureText: true,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    if (phoneController.text.isEmpty || 
                        nameController.text.isEmpty || 
                        passwordController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Complete todos los campos')),
                      );
                      return;
                    }

                    setState(() => isLoading = true);
                    try {
                      await Supabase.instance.client.from('users').insert({
                        'telefono': phoneController.text.trim(),
                        'nombre': nameController.text.trim(),
                        'password': passwordController.text.trim(),
                        'puntos': 0,
                        'created_at': DateTime.now().toIso8601String(),
                      });

                      if (mounted) {
                        _loadClients();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cliente creado exitosamente')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${e.toString()}')),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => isLoading = false);
                    }
                  },
                  child: isLoading 
                      ? const CircularProgressIndicator()
                      : const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  },
  child: const Icon(Icons.add),
),
    );
  }
}

// Lista de Premios
class RewardsList extends StatefulWidget {
  @override
  _RewardsListState createState() => _RewardsListState();
}

class _RewardsListState extends State<RewardsList> {
  List<Map<String, dynamic>> _rewards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRewards();
  }

  Future<void> _loadRewards() async {
  if (!mounted) return;
  setState(() => _isLoading = true);
  
  try {
    final List<dynamic> rewards = await Supabase.instance.client
        .from('rewards')
        .select()
        .order('created_at', ascending: false);

    if (mounted) {
      setState(() {
        _rewards = List<Map<String, dynamic>>.from(rewards);
      });
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar premios: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint('Error loading rewards: $e');
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  @override
  Widget build(BuildContext context) {
return Scaffold(
  appBar: AppBar(
    title: const Text('Gestión de Premios'),
    centerTitle: true,
  ),
  body: _isLoading
      ? const Center(child: CircularProgressIndicator())
      : RefreshIndicator(
          onRefresh: _loadRewards,
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _rewards.length,
            itemBuilder: (context, index) {
              final reward = _rewards[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    reward['nombre'],
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    '${reward['puntos_necesarios']} puntos',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  trailing: Switch.adaptive(
                    value: reward['activo'],
                    onChanged: (value) async {
                      try {
                        await Supabase.instance.client
                            .from('rewards')
                            .update({'activo': value})
                            .eq('id', reward['id']);
                        
                        if (mounted) {
                          _loadRewards();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                value ? 'Premio activado' : 'Premio desactivado',
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ),
  floatingActionButton: FloatingActionButton(
    backgroundColor: Theme.of(context).primaryColor,
    onPressed: () {
      showDialog(
        context: context,
        builder: (context) {
          final nameController = TextEditingController();
          final pointsController = TextEditingController();
          bool isLoading = false;
          
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Nuevo Premio'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: pointsController,
                        decoration: const InputDecoration(
                          labelText: 'Puntos necesarios',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                    onPressed: isLoading ? null : () async {
                      if (nameController.text.isEmpty || pointsController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Complete todos los campos')),
                        );
                        return;
                      }

                      setState(() => isLoading = true);
                      try {
                        await Supabase.instance.client.from('rewards').insert({
                          'nombre': nameController.text.trim(),
                          'puntos_necesarios': int.parse(pointsController.text),
                          'activo': true,
                          'created_at': DateTime.now().toIso8601String(),
                        });

                        if (mounted) {
                          _loadRewards();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Premio creado exitosamente'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => isLoading = false);
                      }
                    },
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Guardar'),
                  ),
                ],
              );
            },
          );
        },
      );
    },
    child: const Icon(Icons.add, color: Colors.white),
  ),
);
  }
}

// Lista de Beneficios
class PartnersList extends StatefulWidget {
  @override
  _PartnersListState createState() => _PartnersListState();
}

class _PartnersListState extends State<PartnersList> {
  List<Map<String, dynamic>> _partners = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPartners();
  }

    Future<void> _loadPartners() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final List<dynamic> partners = await Supabase.instance.client
          .from('partners')
          .select()
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _partners = List<Map<String, dynamic>>.from(partners);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar beneficios: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        debugPrint('Error loading partners: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Beneficios para Clientes'),
      centerTitle: true,
    ),
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadPartners,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _partners.length,
              itemBuilder: (context, index) {
                final partner = _partners[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    leading: partner['logo_url'] != null
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(partner['logo_url']),
                          )
                        : const CircleAvatar(
                            child: Icon(Icons.business),
                          ),
                    title: Text(
                      partner['empresa'] ?? 'Sin nombre',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    subtitle: Text(
                      partner['descuento'] ?? 'Sin descuento especificado',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    trailing: Switch.adaptive(
                      value: partner['activo'] ?? false,
                      onChanged: (value) async {
                        try {
                          await Supabase.instance.client
                              .from('partners')
                              .update({'activo': value})
                              .eq('id', partner['id']);
                          
                          if (mounted) {
                            _loadPartners();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  value 
                                    ? 'Beneficio activado' 
                                    : 'Beneficio desactivado',
                                ),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
    floatingActionButton: FloatingActionButton(
      backgroundColor: Theme.of(context).primaryColor,
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) {
            final companyController = TextEditingController();
            final discountController = TextEditingController();
            bool isLoading = false;
            
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: const Text('Nuevo Beneficio'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: companyController,
                          decoration: const InputDecoration(
                            labelText: 'Empresa*',
                            border: OutlineInputBorder(),
                            hintText: 'Ej. Café del Centro',
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: discountController,
                          decoration: const InputDecoration(
                            labelText: 'Descuento*',
                            border: OutlineInputBorder(),
                            hintText: 'Ej. 20% de descuento',
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                      onPressed: isLoading ? null : () async {
                        if (companyController.text.isEmpty || 
                            discountController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Complete todos los campos obligatorios'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }

                        setState(() => isLoading = true);
                        try {
                          await Supabase.instance.client.from('partners').insert({
                            'empresa': companyController.text.trim(),
                            'descuento': discountController.text.trim(),
                            'activo': true,
                            'created_at': DateTime.now().toIso8601String(),
                          });

                          if (mounted) {
                            _loadPartners();
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Beneficio creado exitosamente'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => isLoading = false);
                        }
                      },
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Guardar'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
      child: const Icon(Icons.add, color: Colors.white),
    ),
  );
}
}

// Pantalla de Usuario
class UserHome extends StatefulWidget {
  final Map<String, dynamic> userData;

  const UserHome({super.key, required this.userData});

  @override
  _UserHomeState createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  int _currentIndex = 0;
  late Map<String, dynamic> _userData;

  @override
  void initState() {
    super.initState();
    _userData = widget.userData;
  }

  Future<void> _refreshUserData() async {
  if (!mounted) return;
  
  try {
    final userData = await Supabase.instance.client
        .from('users')
        .select()
        .eq('id', _userData['id'])
        .single();

    if (mounted && userData != null) {
      setState(() => _userData = userData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Datos actualizados correctamente'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint('Error refreshing user data: $e');
    }
  }
}

  Future<void> _redeemReward(String rewardId, int pointsNeeded) async {
  if (!mounted) return;
  
  // Validación de puntos
  if (_userData['puntos'] < pointsNeeded) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No tienes suficientes puntos'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  try {
    final newPoints = _userData['puntos'] - pointsNeeded;
    
    // Usar transacción para asegurar consistencia
    await Supabase.instance.client.rpc('redeem_reward', params: {
      'user_id': _userData['id'],
      'reward_id': rewardId,
      'points_needed': pointsNeeded,
      'new_points': newPoints,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Premio canjeado con éxito'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      _refreshUserData();
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint('Error redeeming reward: $e');
    }
  }
}

 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Mi Fidelización'),
      actions: [
        IconButton(
          icon: const Icon(Icons.exit_to_app),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          ),
        ),
      ],
    ),
    body: _currentIndex == 0
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Hola, ${_userData['nombre']}',
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 20),
                const Text('Tus puntos acumulados:'),
                Text(
                  '${_userData['puntos']}',
                  style: const TextStyle(fontSize: 36, color: Colors.blue),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Tarjeta Digital'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.credit_card, size: 100, color: Colors.blue),
                            Text(
                              _userData['telefono'],
                              style: const TextStyle(fontSize: 24),
                            ),
                            Text('${_userData['puntos']} puntos'),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cerrar'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Ver mi tarjeta digital'),
                ),
              ],
            ),
          )
        : _currentIndex == 1
            ? FutureBuilder(
                future: Supabase.instance.client
                    .from('rewards')
                    .select()
                    .eq('activo', true),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError || !snapshot.hasData || (snapshot.data as List).isEmpty) {
                    return const Center(child: Text('No hay premios disponibles'));
                  }
                  
                  final rewards = snapshot.data as List<dynamic>;
                  
                  return ListView.builder(
                    itemCount: rewards.length,
                    itemBuilder: (context, index) {
                      final reward = rewards[index] as Map<String, dynamic>;
                      return Card(
                        margin: const EdgeInsets.all(8.0),
                        child: ListTile(
                          title: Text(reward['nombre']),
                          subtitle: Text('${reward['puntos_necesarios']} puntos'),
                          trailing: ElevatedButton(
                            onPressed: () => _redeemReward(
                              reward['id'],
                              reward['puntos_necesarios'],
                            ),
                            child: const Text('Canjear'),
                          ),
                        ),
                      );
                    },
                  );
                },
              )
            : FutureBuilder(
                future: Supabase.instance.client
                    .from('partners')
                    .select()
                    .eq('activo', true),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError || !snapshot.hasData || (snapshot.data as List).isEmpty) {
                    return const Center(child: Text('No hay beneficios disponibles'));
                  }
                  
                  final partners = snapshot.data as List<dynamic>;
                  
                  return ListView.builder(
                    itemCount: partners.length,
                    itemBuilder: (context, index) {
                      final partner = partners[index] as Map<String, dynamic>;
                      return Card(
                        margin: const EdgeInsets.all(8.0),
                        child: ListTile(
                          title: Text(partner['empresa']),
                          subtitle: Text(partner['descuento'] ?? ''),
                        ),
                      );
                    },
                  );
                },
              ),
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
        BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: 'Premios'),
        BottomNavigationBarItem(icon: Icon(Icons.discount), label: 'Beneficios'),
      ],
    ),
  );
}
}