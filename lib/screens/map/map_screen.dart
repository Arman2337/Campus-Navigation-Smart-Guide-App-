import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/map_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/location_model.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const LatLng _campusCenter = LatLng(28.6139, 77.2090);
  String _selectedCategory = 'All';
  LocationModel? _bottomSheetLocation;

  final List<String> _categories = [
    'All', 'Classroom', 'Office', 'Lab', 'Cafeteria', 'Library', 'Parking',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    final mapProvider = context.read<MapProvider>();
    final locationProvider = context.read<LocationProvider>();

    await mapProvider.initializeUserLocation(context);

    if (locationProvider.allLocations.isEmpty) {
      await locationProvider.fetchLocations(
        userPosition: mapProvider.currentPosition,
      );
    }

    _buildMapMarkers();
  }

  void _buildMapMarkers() {
    final mapProvider = context.read<MapProvider>();
    final locationProvider = context.read<LocationProvider>();

    final filtered = _selectedCategory == 'All'
        ? locationProvider.allLocations
        : locationProvider.allLocations
            .where((l) => l.category.toLowerCase() == _selectedCategory.toLowerCase())
            .toList();

    mapProvider.buildMarkers(filtered, onTap: (loc) {
      setState(() => _bottomSheetLocation = loc);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mapProvider = context.watch<MapProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            onMapCreated: (controller) {
              context.read<MapProvider>().setMapController(controller);
            },
            initialCameraPosition: CameraPosition(
              target: mapProvider.currentPosition ?? _campusCenter,
              zoom: 16,
            ),
            markers: mapProvider.markers,
            polylines: mapProvider.polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            onTap: (_) => setState(() => _bottomSheetLocation = null),
          ),

          // Glass Search Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  // Search bar (glassmorphism)
                  GestureDetector(
                    onTap: () => context.go('/search'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.dark
                            ? Colors.black.withOpacity(0.8)
                            : Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: AppColors.primary, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            AppStrings.searchPlaceholder,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),

                  const SizedBox(height: 10),

                  // Category filter chips
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedCategory = cat);
                              _buildMapMarkers();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : (theme.brightness == Brightness.dark
                                        ? Colors.black.withOpacity(0.8)
                                        : Colors.white.withOpacity(0.95)),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Inter',
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
                ],
              ),
            ),
          ),

          // FABs
          Positioned(
            right: 16,
            bottom: _bottomSheetLocation != null ? 220 : 100,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'locate',
                  onPressed: () => mapProvider.animateToCurrentLocation(),
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),

          // Bottom sheet (marker selection)
          if (_bottomSheetLocation != null)
            Positioned(
              bottom: 80,
              left: 16,
              right: 16,
              child: _buildBottomSheet(_bottomSheetLocation!, context),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.3, end: 0),
        ],
      ),
    );
  }

  Widget _buildBottomSheet(LocationModel location, BuildContext context) {
    final auth = context.read<AuthProvider>();
    final locationProvider = context.read<LocationProvider>();
    final categoryColor = AppColors.getCategoryColor(location.category);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.location_on, color: categoryColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(location.name, style: theme.textTheme.headlineSmall),
                    Text(
                      '${location.building} • ${location.floorLabel}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _bottomSheetLocation = null),
              ),
            ],
          ),
          if (location.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              location.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _bottomSheetLocation = null);
                    context.push('/navigate/${location.id}');
                  },
                  icon: const Icon(Icons.directions, size: 18),
                  label: const Text(AppStrings.navigate),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: () async {
                  if (auth.userModel == null) return;
                  final saved = locationProvider.isLocationSaved(
                      auth.userModel!.uid, location.id);
                  if (saved) {
                    await locationProvider.removeSavedLocation(
                        auth.userModel!.uid, location.id);
                  } else {
                    await locationProvider.saveLocation(
                        auth.userModel!.uid, location.id);
                  }
                  setState(() {});
                },
                icon: Icon(
                  auth.userModel != null &&
                          locationProvider.isLocationSaved(
                              auth.userModel!.uid, location.id)
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  foregroundColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: 4),
              IconButton.filled(
                onPressed: () => context.push('/location/${location.id}'),
                icon: const Icon(Icons.info_outline),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.secondary.withOpacity(0.1),
                  foregroundColor: AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
