import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
                                      : 'Beneficio desactivado'),
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