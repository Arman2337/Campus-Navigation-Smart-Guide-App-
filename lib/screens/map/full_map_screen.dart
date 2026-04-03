import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../providers/location_provider.dart';
import '../../providers/map_provider.dart';

/// Full-screen map screen (can be launched from location detail or home)
class FullMapScreen extends StatefulWidget {
  final String? locationId; // optional: focus on a specific location

  const FullMapScreen({super.key, this.locationId});

  @override
  State<FullMapScreen> createState() => _FullMapScreenState();
}

class _FullMapScreenState extends State<FullMapScreen> {
  static const LatLng _campusCenter = LatLng(28.6139, 77.2090);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final mapProvider = context.read<MapProvider>();
    final locationProvider = context.read<LocationProvider>();

    await mapProvider.initializeUserLocation(context);
    if (locationProvider.allLocations.isEmpty) {
      await locationProvider.fetchLocations(
          userPosition: mapProvider.currentPosition);
    }
    mapProvider.buildMarkers(locationProvider.allLocations);

    // Focus on specific location if provided
    if (widget.locationId != null) {
      final loc = locationProvider.allLocations
          .where((l) => l.id == widget.locationId)
          .firstOrNull;
      if (loc != null) {
        mapProvider.animateToLocation(loc.latLng);
        mapProvider.selectLocation(loc);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapProvider = context.watch<MapProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Map'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: GoogleMap(
        onMapCreated: (c) => context.read<MapProvider>().setMapController(c),
        initialCameraPosition: CameraPosition(
          target: mapProvider.currentPosition ?? _campusCenter,
          zoom: 16,
        ),
        markers: mapProvider.markers,
        polylines: mapProvider.polylines,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true,
        mapToolbarEnabled: false,
      ),
    );
  }
}
