import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Lost & Found feature
import '../../lost_pets/presentation/pages/home_page.dart';

// Pet Adoption feature
import '../../pet_adoption/presentation/pages/pet_adoption_menu_page.dart';

// Auth
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Drawer items
  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Lost & Found Pets',
      'widget': const HomePage(),
      'icon': Icons.search,
    },
    {
      'title': 'Pet Adoption',
      'widget': const PetAdoptionMenuPage(),
      'icon': Icons.pets,
    },
  ];

  void _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_selectedIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(page['title']),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Column(
          children: [
            const UserAccountsDrawerHeader(
              accountName: Text('Petty User'),
              accountEmail: Text('Welcome to Petty!'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.pets, color: Colors.teal, size: 32),
              ),
              decoration: BoxDecoration(color: Colors.teal),
            ),
            ..._pages.asMap().entries.map((entry) {
              int idx = entry.key;
              var page = entry.value;
              return ListTile(
                leading: Icon(page['icon']),
                title: Text(page['title']),
                selected: _selectedIndex == idx,
                onTap: () {
                  setState(() => _selectedIndex = idx);
                  Navigator.pop(context);
                },
              );
            }).toList(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Container(
          key: ValueKey(_selectedIndex),
          child: page['widget'],
        ),
      ),
      // REMOVED FAB - "Add Pet" is now a tab in PetAdoptionMenuPage
    );
  }
}