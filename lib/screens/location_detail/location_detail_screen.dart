import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../models/location_model.dart';

class LocationDetailScreen extends StatefulWidget {
  final String locationId;
  const LocationDetailScreen({super.key, required this.locationId});

  @override
  State<LocationDetailScreen> createState() => _LocationDetailScreenState();
}

class _LocationDetailScreenState extends State<LocationDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  LocationModel? _location;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    // First check in-memory cache
    final provider = context.read<LocationProvider>();
    final cached = provider.allLocations.where((l) => l.id == widget.locationId).firstOrNull;

    if (cached != null) {
      setState(() {
        _location = cached;
        _isLoading = false;
      });
    } else {
      final loc = await _firestoreService.getLocationById(widget.locationId);
      if (mounted) setState(() {
        _location = loc;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final locationProvider = context.watch<LocationProvider>();
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        body: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(color: Colors.white),
        ),
      );
    }

    if (_location == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Location not found')),
      );
    }

    final loc = _location!;
    final categoryColor = AppColors.getCategoryColor(loc.category);
    final isSaved = auth.userModel != null &&
        locationProvider.isLocationSaved(auth.userModel!.uid, loc.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: loc.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: loc.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (ctx, url) => Container(
                        color: categoryColor.withOpacity(0.1),
                        child: Icon(Icons.image_outlined, size: 64, color: categoryColor),
                      ),
                      errorWidget: (ctx, url, err) => Container(
                        color: categoryColor.withOpacity(0.1),
                        child: Icon(Icons.location_on, size: 64, color: categoryColor),
                      ),
                    )
                  : Container(
                      color: categoryColor.withOpacity(0.1),
                      child: Icon(Icons.location_on, size: 80, color: categoryColor),
                    ),
            ),
            actions: [
              IconButton(
                icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: Colors.white),
                onPressed: () async {
                  if (auth.userModel == null) return;
                  if (isSaved) {
                    await locationProvider.removeSavedLocation(
                        auth.userModel!.uid, loc.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text(AppStrings.successLocationRemoved)),
                      );
                    }
                  } else {
                    await locationProvider.saveLocation(
                        auth.userModel!.uid, loc.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(AppStrings.successLocationSaved),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.category_outlined, size: 14, color: categoryColor),
                        const SizedBox(width: 4),
                        Text(
                          loc.category.toUpperCase(),
                          style: TextStyle(
                            color: categoryColor,
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 300.ms),
                  const SizedBox(height: 12),
                  Text(loc.name, style: theme.textTheme.displaySmall)
                      .animate().fadeIn(delay: 50.ms, duration: 300.ms),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Icon(Icons.business_outlined, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(loc.building, style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary)),
                      const SizedBox(width: 16),
                      Icon(Icons.layers_outlined, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(loc.floorLabel, style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary)),
                    ],
                  ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),

                  Text('About', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    loc.description.isNotEmpty ? loc.description : 'No description available.',
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                  ).animate().fadeIn(delay: 150.ms, duration: 300.ms),

                  // Tags
                  if (loc.tags.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: loc.tags.map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('#$tag', style: theme.textTheme.labelSmall),
                      )).toList(),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Action buttons
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/navigate/${loc.id}'),
                          icon: const Icon(Icons.directions),
                          label: const Text(AppStrings.navigate),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                if (auth.userModel == null) return;
                                if (isSaved) {
                                  await locationProvider.removeSavedLocation(
                                      auth.userModel!.uid, loc.id);
                                } else {
                                  await locationProvider.saveLocation(
                                      auth.userModel!.uid, loc.id);
                                }
                              },
                              icon: Icon(
                                isSaved ? Icons.bookmark : Icons.bookmark_border,
                              ),
                              label: Text(isSaved ? 'Saved' : AppStrings.save),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          if (loc.isIndoor && loc.indoorFloorPlanUrl != null) ...[
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  // Show floor plan
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => Dialog(
                                      child: CachedNetworkImage(
                                        imageUrl: loc.indoorFloorPlanUrl!,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.map_outlined),
                                label: const Text('Floor Plan'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
