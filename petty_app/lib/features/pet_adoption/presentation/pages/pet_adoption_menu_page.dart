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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildTabView(int index) {
    switch (index) {
      case 0:
        return const PetAdoptionHomePage();
      case 1:
        return AddPetScreen(
          onPetAdded: () {
            if (mounted) {
              _tabController.animateTo(0);
              ref.invalidate(petListProvider);
            }
          },
        );
      case 2:
        return const AdoptionRequestsPage();
      case 3:
        return const MyPetRequestsPage();
      default:
        return const Center(child: Text('Page not found'));
    }
  }

  Widget _buildTab({
    required String text,
    required IconData icon,
    required int notificationCount,
  }) {
    return Tab(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon),
              const SizedBox(height: 4),
              Text(
                text,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          if (notificationCount > 0)
            Positioned(
              right: -8,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                child: Center(
                  child: Text(
                    notificationCount > 99 ? '99+' : notificationCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch the notification counts
    final myReceivedRequestsAsync = ref.watch(myReceivedRequestsWithDetailsProvider);
    final mySentRequestsAsync = ref.watch(mySentRequestsWithDetailsProvider);

    // Count pending requests
    final receivedPendingCount = myReceivedRequestsAsync.whenData(
      (requests) => requests.where((r) => r.status == 'pending').length,
    ).value ?? 0;

    final sentPendingCount = mySentRequestsAsync.whenData(
      (requests) => requests.where((r) => r.status == 'pending').length,
    ).value ?? 0;

    return Column(
      children: [
        Material(
          color: Colors.teal,
          child: TabBar(
            controller: _tabController,
            isScrollable: false,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              _buildTab(
                text: "Available Pets",
                icon: Icons.pets,
                notificationCount: 0,
              ),
              _buildTab(
                text: "Add Pet",
                icon: Icons.add,
                notificationCount: 0,
              ),
              _buildTab(
                text: "My Requests",
                icon: Icons.send,
                notificationCount: sentPendingCount,
              ),
              _buildTab(
                text: "Requests for My Pets",
                icon: Icons.notifications,
                notificationCount: receivedPendingCount,
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: List.generate(4, (index) => _buildTabView(index)),
          ),
        ),
      ],
    );
  }
}