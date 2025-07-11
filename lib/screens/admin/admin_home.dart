import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import 'clients_list.dart';
import 'rewards_list.dart';
import 'partners_list.dart';

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