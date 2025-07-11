import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
                                    value ? 'Premio activado' : 'Premio desactivado'),
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