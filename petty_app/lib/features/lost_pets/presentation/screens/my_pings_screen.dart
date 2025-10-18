import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/pet_ping.dart';
import '../widgets/pet_marker.dart';
import '../screens/pet_detail_screen.dart';
import '../../data/repositories/supabase_pet_ping_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/pings_refresh_provider.dart';

class MyPingsScreen extends ConsumerStatefulWidget {
  const MyPingsScreen({super.key});

  @override
  ConsumerState<MyPingsScreen> createState() => _MyPingsScreenState();
}

class _MyPingsScreenState extends ConsumerState<MyPingsScreen> {
  List<PetPing> _myPings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchMyPings();
  }

  Future<void> _fetchMyPings() async {
    print('Fetching my pings...');
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      print('Current user: $user');
      if (user == null) {
        print('User is null, not logged in.');
        setState(() {
          _error = 'Not logged in.';
          _isLoading = false;
        });
        return;
      }
      final repo = SupabasePetPingRepository(supabase);
      print('Calling getPingsByUser...');
      final pings = await repo.getPingsByUser(user.id);
      print('Fetched pings: $pings');
      setState(() {
        _myPings = pings;
        _isLoading = false;
      });
    } catch (e) {
      print('Exception in _fetchMyPings: $e');
      setState(() {
        _error = 'Failed to load pings.';
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePing(PetPing ping) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    final repo = SupabasePetPingRepository(supabase);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Ping'),
        content: const Text('Are you sure you want to delete this ping?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true || user == null) return;
    try {
      await repo.deletePing(ping.id, userId: user.id);
      setState(() {
        _myPings.removeWhere((p) => p.id == ping.id);
      });
      // Notify other screens to refresh their pings list
      ref.read(pingsRefreshProvider.notifier).state++;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ping deleted.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_myPings.isEmpty) {
      return const Center(child: Text('No pings posted yet.'));
    }
    return ListView.builder(
      itemCount: _myPings.length,
      itemBuilder: (context, index) {
        final ping = _myPings[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: Icon(
              Icons.pets,
              color: ping.isLost ? Colors.red : Colors.green,
              size: 30,
            ),
            title: Text(ping.title),
            subtitle: Text(ping.isLost ? 'Lost' : 'Found'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deletePing(ping),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PetDetailScreen(pet: ping)),
              );
            },
          ),
        );
      },
    );
  }
}
