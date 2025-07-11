// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'main.dart'; // Importa la clase LoginScreen
// // Pantalla de Usuario
// class UserHome extends StatefulWidget {
//   final Map<String, dynamic> userData;

//   const UserHome({super.key, required this.userData});

//   @override
//   _UserHomeState createState() => _UserHomeState();
// }

// class _UserHomeState extends State<UserHome> {
//   int _currentIndex = 0;
//   late Map<String, dynamic> _userData;

//   @override
//   void initState() {
//     super.initState();
//     _userData = widget.userData;
//   }

//   Future<void> _refreshUserData() async {
//     if (!mounted) return;
    
//     try {
//       final userData = await Supabase.instance.client
//           .from('users')
//           .select()
//           .eq('id', _userData['id'])
//           .single();

//       if (mounted && userData != null) {
//         setState(() => _userData = userData);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Datos actualizados correctamente'),
//             duration: Duration(seconds: 1),
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error al actualizar: ${e.toString()}'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   Future<void> _redeemReward(String rewardId, int pointsNeeded) async {
//     if (!mounted) return;
    
//     if (_userData['puntos'] < pointsNeeded) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('No tienes suficientes puntos'),
//           backgroundColor: Colors.orange,
//         ),
//       );
//       return;
//     }

//     try {
//       final newPoints = _userData['puntos'] - pointsNeeded;
      
//       await Supabase.instance.client.rpc('redeem_reward', params: {
//         'user_id': _userData['id'],
//         'reward_id': rewardId,
//         'points_needed': pointsNeeded,
//         'new_points': newPoints,
//       });

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('✅ Premio canjeado con éxito'),
//             backgroundColor: Colors.green,
//             duration: Duration(seconds: 2),
//           ),
//         );
//         _refreshUserData();
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('❌ Error: ${e.toString()}'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Mi Fidelización'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.exit_to_app),
//             onPressed: () => Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(builder: (_) => const LoginScreen()),
//             ),
//           ),
//         ],
//       ),
//       body: _currentIndex == 0
//           ? Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(
//                     'Hola, ${_userData['nombre']}',
//                     style: const TextStyle(fontSize: 24),
//                   ),
//                   const SizedBox(height: 20),
//                   const Text('Tus puntos acumulados:'),
//                   Text(
//                     '${_userData['puntos']}',
//                     style: const TextStyle(fontSize: 36, color: Colors.blue),
//                   ),
//                   const SizedBox(height: 30),
//                   ElevatedButton(
//                     onPressed: () {
//                       showDialog(
//                         context: context,
//                         builder: (context) => AlertDialog(
//                           title: const Text('Tarjeta Digital'),
//                           content: Column(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               const Icon(Icons.credit_card, size: 100, color: Colors.blue),
//                               Text(
//                                 _userData['telefono'],
//                                 style: const TextStyle(fontSize: 24),
//                               ),
//                               Text('${_userData['puntos']} puntos'),
//                             ],
//                           ),
//                           actions: [
//                             TextButton(
//                               onPressed: () => Navigator.pop(context),
//                               child: const Text('Cerrar'),
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                     child: const Text('Ver mi tarjeta digital'),
//                   ),
//                 ],
//               ),
//             )
//           : _currentIndex == 1
//               ? FutureBuilder(
//                   future: Supabase.instance.client
//                       .from('rewards')
//                       .select()
//                       .eq('activo', true),
//                   builder: (context, snapshot) {
//                     if (snapshot.connectionState == ConnectionState.waiting) {
//                       return const Center(child: CircularProgressIndicator());
//                     }
                    
//                     if (snapshot.hasError || !snapshot.hasData || (snapshot.data as List).isEmpty) {
//                       return const Center(child: Text('No hay premios disponibles'));
//                     }
                    
//                     final rewards = snapshot.data as List<dynamic>;
                    
//                     return ListView.builder(
//                       itemCount: rewards.length,
//                       itemBuilder: (context, index) {
//                         final reward = rewards[index] as Map<String, dynamic>;
//                         return Card(
//                           margin: const EdgeInsets.all(8.0),
//                           child: ListTile(
//                             title: Text(reward['nombre']),
//                             subtitle: Text('${reward['puntos_necesarios']} puntos'),
//                             trailing: ElevatedButton(
//                               onPressed: () => _redeemReward(
//                                 reward['id'],
//                                 reward['puntos_necesarios'],
//                               ),
//                               child: const Text('Canjear'),
//                             ),
//                           ),
//                         );
//                       },
//                     );
//                   },
//                 )
//               : FutureBuilder(
//                   future: Supabase.instance.client
//                       .from('partners')
//                       .select()
//                       .eq('activo', true),
//                   builder: (context, snapshot) {
//                     if (snapshot.connectionState == ConnectionState.waiting) {
//                       return const Center(child: CircularProgressIndicator());
//                     }
                    
//                     if (snapshot.hasError || !snapshot.hasData || (snapshot.data as List).isEmpty) {
//                       return const Center(child: Text('No hay beneficios disponibles'));
//                     }
                    
//                     final partners = snapshot.data as List<dynamic>;
                    
//                     return ListView.builder(
//                       itemCount: partners.length,
//                       itemBuilder: (context, index) {
//                         final partner = partners[index] as Map<String, dynamic>;
//                         return Card(
//                           margin: const EdgeInsets.all(8.0),
//                           child: ListTile(
//                             title: Text(partner['empresa']),
//                             subtitle: Text(partner['descuento'] ?? ''),
//                           ),
//                         );
//                       },
//                     );
//                   },
//                 ),
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _currentIndex,
//         onTap: (index) => setState(() => _currentIndex = index),
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
//           BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: 'Premios'),
//           BottomNavigationBarItem(icon: Icon(Icons.discount), label: 'Beneficios'),
//         ],
//       ),
//     );
//   }
// }