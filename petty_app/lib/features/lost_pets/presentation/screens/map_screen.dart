import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'pet_detail_screen.dart';
import 'package:petty_app/core/services/location_service.dart';
import '../../domain/entities/pet_ping.dart';
import '../../data/repositories/supabase_pet_ping_repository.dart';
import '../widgets/pet_marker.dart';
import '../providers/pet_filter_provider.dart';
import '../widgets/pet_filter_sheet.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> with TickerProviderStateMixin {
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(begin: currentLocation?.latitude ?? destLocation.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: currentLocation?.longitude ?? destLocation.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: currentZoom, end: destZoom);

    var controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    Animation<double> animation = CurvedAnimation(parent: controller, curve: Curves.easeInOut);

    controller.addListener(() {
      final lat = latTween.evaluate(animation);
      final lng = lngTween.evaluate(animation);
      final zoom = zoomTween.evaluate(animation);
      _mapController.move(LatLng(lat, lng), zoom);
    });
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          currentLocation = destLocation;
          currentZoom = destZoom;
        });
        controller.dispose();
      }
    });
    controller.forward();
  }
  // ...existing code...
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  List<PetPing> nearbyPings = [];
  LatLng? currentLocation;
  double currentZoom = 13.0;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Try to get user's current location first
    _initLocationAndLoadPets();
  }

  Future<void> _initLocationAndLoadPets() async {
    try {
      final location = await _locationService.getCurrentLocation();
      if (!_isDisposed && mounted) {
        setState(() {
          currentLocation = location;
        });
        // Move the map to the user's location immediately
        _mapController.move(location, currentZoom);
      }
    } catch (e) {
      // If location fails, fallback to Dhaka
      if (!_isDisposed && mounted) {
        setState(() {
          currentLocation = LatLng(23.8103, 90.4125);
        });
        _mapController.move(LatLng(23.8103, 90.4125), currentZoom);
      }
    } finally {
      if (!_isDisposed && mounted) {
        _loadLostPets();
      }
    }
  }

  Future<void> _loadLostPets() async {
    if (_isDisposed || !mounted) return;
    
    if (!_isLoading) {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
      });
      
      try {
        final repository = ref.read(petPingRepositoryProvider);
        final pings = await repository.getAllLostPets();
        debugPrint('Received ${pings.length} lost pets');
        
        if (!_isDisposed && mounted) {
          setState(() {
            nearbyPings = pings;
            _isLoading = false;
            
            // Center map on first pet if available
            if (pings.isNotEmpty && currentLocation == null) {
              debugPrint('Centering map on first pet at ${pings.first.location}');
              currentLocation = pings.first.location;
              _mapController.move(pings.first.location, 13.0);
            }
          });
        }
      } catch (e) {
        print('Error loading lost pets: $e');
        if (!_isDisposed && mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(petFilterProvider);
    // Apply filter to nearbyPings
    final filteredPings = nearbyPings.where((ping) {
  if (filter.isLost != null && ping.isLost != filter.isLost) return false;
  if (filter.gender != null && ping.gender != filter.gender) return false;
  if (filter.petType != null && ping.petType != filter.petType) return false;
  if (filter.startTime != null && ping.timestamp.isBefore(filter.startTime!)) return false;
  if (filter.endTime != null && ping.timestamp.isAfter(filter.endTime!)) return false;
  return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLostPets,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const PetFilterSheet(),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: currentLocation ?? LatLng(23.8103, 90.4125),
              initialZoom: currentZoom,
              minZoom: 3.0,
              maxZoom: 18.0,
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onTap: (tapPosition, point) {
                setState(() {
                  currentLocation = point;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.petty',
              ),
              MarkerLayer(
                markers: [
                  if (currentLocation != null)
                    Marker(
                      point: currentLocation!,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.blue,
                        size: 40,
                      ),
                    ),
                  for (final ping in filteredPings)
                    PetMarker(
                      point: ping.location,
                      isLost: ping.isLost,
                      title: ping.title,
                      onTap: () => _showPetDetails(context, ping),
                    ),
                ],
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          Positioned(
            top: 32,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'zoom_in',
                  mini: true,
                  onPressed: () {
                    setState(() {
                      if (currentZoom < 18.0) {
                        currentZoom += 1.0;
                        _mapController.move(currentLocation ?? LatLng(23.8103, 90.4125), currentZoom);
                      }
                    });
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'zoom_out',
                  mini: true,
                  onPressed: () {
                    setState(() {
                      if (currentZoom > 3.0) {
                        currentZoom -= 1.0;
                        _mapController.move(currentLocation ?? LatLng(23.8103, 90.4125), currentZoom);
                      }
                    });
                  },
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          setState(() => _isLoading = true);
          try {
            final location = await _locationService.getCurrentLocation();
            if (!mounted) return;
            setState(() {
              currentLocation = location;
              currentZoom = 15.0;
              _isLoading = false;
            });
            _animatedMapMove(location, 15.0);
          } catch (e) {
            if (!mounted) return;
            setState(() => _isLoading = false);
            String errorMessage = 'Could not get your location';
            if (e.toString().contains('disabled')) {
              errorMessage = 'Please enable location services';
            } else if (e.toString().contains('denied')) {
              errorMessage = 'Location permission required';
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMessage)),
            );
          }
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.my_location),
      ),
    );
  }

  void _showPetDetails(BuildContext context, PetPing ping) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => GestureDetector(
        onTap: () {
          // Close bottom sheet and navigate to detail screen
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PetDetailScreen(pet: ping),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.pets,
                    color: ping.isLost ? Colors.red : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                        child: Text(
                          ping.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Text(
                    ping.isLost ? 'Lost' : 'Found',
                    style: TextStyle(
                      color: ping.isLost ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Type: ${ping.petType}'),
              const SizedBox(height: 4),
              Text('Description: ${ping.description}'),
              if (ping.contactInfo != null) ...[
                const SizedBox(height: 4),
                Text('Contact: ${ping.contactInfo}'),
              ],
              const SizedBox(height: 4),
              Text(
                'Reported: ${ping.timestamp.toString()}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Provider for the repository
final petPingRepositoryProvider = Provider<SupabasePetPingRepository>((ref) {
  final supabase = Supabase.instance.client;
  return SupabasePetPingRepository(supabase);
});