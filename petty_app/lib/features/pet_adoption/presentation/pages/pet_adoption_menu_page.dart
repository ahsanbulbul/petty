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
  ConsumerState<PetAdoptionMenuPage> createState() =>
      _PetAdoptionMenuPageState();
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
    return SizedBox(
      height: 65,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22),
              const SizedBox(height: 4),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
          if (notificationCount > 0)
            Positioned(
              right: 8,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red[600],
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Center(
                  child: Text(
                    notificationCount > 9 ? '9+' : notificationCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
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
    final myReceivedRequestsAsync =
        ref.watch(myReceivedRequestsWithDetailsProvider);
    final mySentRequestsAsync = ref.watch(mySentRequestsWithDetailsProvider);

    final receivedPendingCount = myReceivedRequestsAsync.whenData(
          (requests) => requests.where((r) => r.status == 'pending').length,
        ).value ??
        0;

    final sentPendingCount = mySentRequestsAsync.whenData(
          (requests) => requests.where((r) => r.status == 'pending').length,
        ).value ??
        0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Full-width top bar with background color
          Container(
            color: const Color.fromARGB(255, 0, 188, 212),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Row with back button + tabs
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Container(
                          height: 60,
                          alignment: Alignment.centerLeft,
                          child: TabBar(
                            controller: _tabController,
                            isScrollable: false,
                            indicatorColor: Colors.white,
                            indicatorWeight: 3,
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.white.withOpacity(0.7),
                            labelPadding: EdgeInsets.zero,
                            indicatorSize: TabBarIndicatorSize.tab,
                            tabs: [
                              _buildTab(
                                text: "Available",
                                icon: Icons.pets,
                                notificationCount: 0,
                              ),
                              _buildTab(
                                text: "Add Pet",
                                icon: Icons.add_circle_outline,
                                notificationCount: 0,
                              ),
                              _buildTab(
                                text: "Sent",
                                icon: Icons.send_outlined,
                                notificationCount: sentPendingCount,
                              ),
                              _buildTab(
                                text: "Received",
                                icon: Icons.notifications_outlined,
                                notificationCount: receivedPendingCount,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(4, (index) => _buildTabView(index)),
            ),
          ),
        ],
      ),
    );
  }
}
