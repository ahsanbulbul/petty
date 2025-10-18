import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'add_pet_screen.dart';
import 'adoption_requests_page.dart';
import 'my_pet_requests_page.dart';
import 'pet_adoption_home_page.dart';
import '../providers/pet_adoption_providers.dart';

class PetAdoptionMenuPage extends ConsumerStatefulWidget {
  const PetAdoptionMenuPage({super.key});

  @override
  ConsumerState<PetAdoptionMenuPage> createState() => _PetAdoptionMenuPageState();
}

class _PetAdoptionMenuPageState extends ConsumerState<PetAdoptionMenuPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Tab> myTabs = const [
    Tab(text: "Available Pets", icon: Icon(Icons.pets)),
    Tab(text: "Add Pet", icon: Icon(Icons.add)),
    Tab(text: "My Requests", icon: Icon(Icons.send)),
    Tab(text: "Requests for My Pets", icon: Icon(Icons.notifications)),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: myTabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildTabView(int index) {
    switch (index) {
      case 0:
        return const PetAdoptionHomePage(); // List of available pets
      case 1:
        // Wrap AddPetScreen with a Navigator callback
        return AddPetScreen(
          onPetAdded: () {
            // Switch to Available Pets tab after adding
            if (mounted) {
              _tabController.animateTo(0);
              // Refresh the pet list
              ref.invalidate(petListProvider);
            }
          },
        );
      case 2:
        return const AdoptionRequestsPage(); // Requests user sent
      case 3:
        return const MyPetRequestsPage(); // Requests for user's pets
      default:
        return const Center(child: Text('Page not found'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // TabBar without AppBar
        Material(
          color: Colors.teal,
          child: TabBar(
            controller: _tabController,
            tabs: myTabs,
            isScrollable: false,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: List.generate(myTabs.length, (index) => _buildTabView(index)),
          ),
        ),
      ],
    );
  }
}

// Import this provider reference
