import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/map_provider.dart';
import '../../providers/location_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../models/location_model.dart';
import '../../models/direction_model.dart';

class NavigationScreen extends StatefulWidget {
  final String locationId;
  const NavigationScreen({super.key, required this.locationId});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  LocationModel? _destination;
  GoogleMapController? _mapController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAndStartNavigation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadAndStartNavigation() async {
    final mapProvider = context.read<MapProvider>();
    final navProvider = context.read<NavigationProvider>();

    _destination = await _firestoreService.getLocationById(widget.locationId);
    if (_destination == null || !mounted) return;

    if (mapProvider.currentPosition == null) {
      await mapProvider.initializeUserLocation(context);
    }

    if (mapProvider.currentPosition == null || !mounted) {
      setState(() => _isLoading = false);
      return;
    }

    await navProvider.startNavigation(
      origin: mapProvider.currentPosition!,
      destination: _destination!,
    );

    if (mounted) setState(() => _isLoading = false);
  }

  Future<bool> _confirmEndNavigation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('End Navigation?'),
        content: const Text('Are you sure you want to end the current navigation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text(AppStrings.confirm, style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldEnd = await _confirmEndNavigation();
        if (shouldEnd && mounted) {
          navProvider.endNavigation();
          context.pop();
        }
      },
      child: Scaffold(
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  GoogleMap(
                    onMapCreated: (c) => _mapController = c,
                    initialCameraPosition: CameraPosition(
                      target: _destination?.latLng ?? const LatLng(28.6139, 77.2090),
                      zoom: 16,
                    ),
                    markers: {
                      if (_destination != null)
                        Marker(
                          markerId: const MarkerId('destination'),
                          position: _destination!.latLng,
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueRed,
                          ),
                        ),
                    },
                    polylines: {
                      if (navProvider.polylineCoords.isNotEmpty)
                        Polyline(
                          polylineId: const PolylineId('nav_route'),
                          points: navProvider.polylineCoords,
                          color: AppColors.primary,
                          width: 5,
                          startCap: Cap.roundCap,
                          endCap: Cap.roundCap,
                        ),
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                  ),

                  // Top bar
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                onPressed: () async {
                                  final shouldEnd = await _confirmEndNavigation();
                                  if (shouldEnd && mounted) {
                                    navProvider.endNavigation();
                                    context.pop();
                                  }
                                },
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _destination?.name ?? 'Navigating',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (navProvider.currentDirections != null)
                                      Text(
                                        '${navProvider.currentDirections!.durationText} • ${navProvider.currentDirections!.distanceText}',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.85),
                                          fontFamily: 'Inter',
                                          fontSize: 13,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // Mute button
                              IconButton(
                                icon: Icon(
                                  navProvider.isMuted
                                      ? Icons.volume_off
                                      : Icons.volume_up,
                                  color: Colors.white,
                                ),
                                onPressed: navProvider.toggleMute,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Bottom navigation steps panel
                  if (navProvider.currentDirections != null)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 280),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Handle
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            // Current step
                            if (navProvider.currentStep != null)
                              _buildCurrentStep(navProvider.currentStep!, theme),
                            // Steps list
                            Flexible(
                              child: ListView.builder(
                                shrinkWrap: true,
                                padding: const EdgeInsets.only(bottom: 16),
                                itemCount: navProvider.currentDirections!.steps.length,
                                itemBuilder: (ctx, i) {
                                  final step = navProvider.currentDirections!.steps[i];
                                  final isActive = i == navProvider.currentStepIndex;
                                  return _buildStepTile(step, isActive, theme);
                                },
                              ),
                            ),
                          ],
                        ),
                      ).animate().slideY(begin: 0.3, end: 0, duration: 400.ms),
                    ),

                  // Error state
                  if (navProvider.error != null)
                    Positioned(
                      bottom: 100,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          navProvider.error!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildCurrentStep(DirectionStep step, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        border: Border(
          bottom: BorderSide(color: AppColors.primary.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.turn_right,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.instruction,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  step.distance,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepTile(DirectionStep step, bool isActive, ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary.withOpacity(0.06) : null,
        border: Border(
          left: BorderSide(
            color: isActive ? AppColors.primary : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.navigation_rounded,
            size: 18,
            color: isActive ? AppColors.primary : AppColors.textHint,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              step.instruction,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            step.distance,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isActive ? AppColors.primary : AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}
