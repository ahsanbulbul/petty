import 'package:flutter/material.dart';
import '../screens/map_screen.dart';
import 'ping_test_screen.dart';
import '../screens/my_pings_screen.dart';
import '../../../pet_similarity_matching/presentation/screens/pet_matches_tab_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const PingTestScreen(),
    const MapScreen(),
    const MyPingsScreen(),
    const PetMatchesTabScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.report),
            label: 'Report',
          ),
          NavigationDestination(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.article),
            label: 'My Posts',
          ),
          NavigationDestination(
            icon: Icon(Icons.compare_arrows),
            label: 'Matches',
          ),
        ],
      ),
    );
  }
}