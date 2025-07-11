import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      await Supabase.instance.client
          .from('users')
          .update({'puntos': newPoints})
          .eq('id', userId);

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
      
      _loadClients();
    } catch (e) {
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