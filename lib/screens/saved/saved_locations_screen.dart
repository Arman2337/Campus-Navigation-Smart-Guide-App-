import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../widgets/home/location_card.dart';

class SavedLocationsScreen extends StatefulWidget {
  const SavedLocationsScreen({super.key});

  @override
  State<SavedLocationsScreen> createState() => _SavedLocationsScreenState();
}

class _SavedLocationsScreenState extends State<SavedLocationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSaved());
  }

  Future<void> _loadSaved() async {
    final auth = context.read<AuthProvider>();
    if (auth.userModel == null) return;
    await context.read<LocationProvider>().loadSavedLocations(auth.userModel!.uid);
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.savedLocations, style: theme.textTheme.headlineMedium),
        automaticallyImplyLeading: false,
      ),
      body: locationProvider.savedLocations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_outline, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 20),
                  Text(AppStrings.emptySaved, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.emptySavedSubtitle,
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/search'),
                    icon: const Icon(Icons.search),
                    label: const Text('Browse Locations'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),
            )
          : RefreshIndicator(
              onRefresh: _loadSaved,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: locationProvider.savedLocations.length,
                itemBuilder: (context, index) {
                  final loc = locationProvider.savedLocations[index];
                  return Dismissible(
                    key: Key(loc.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bookmark_remove, color: Colors.white, size: 28),
                          SizedBox(height: 4),
                          Text(
                            'Remove',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          title: const Text('Remove Saved Location?'),
                          content: Text('Remove "${loc.name}" from saved locations?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text(AppStrings.cancel),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                              ),
                              child: const Text('Remove',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (_) async {
                      if (auth.userModel == null) return;
                      await locationProvider.removeSavedLocation(
                          auth.userModel!.uid, loc.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${loc.name} removed from saved'),
                            action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () {
                                locationProvider.saveLocation(
                                    auth.userModel!.uid, loc.id);
                              },
                            ),
                          ),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: LocationCard(
                        location: loc,
                        onTap: () => context.push('/location/${loc.id}'),
                      ).animate().fadeIn(
                        delay: Duration(milliseconds: 40 * index),
                        duration: 250.ms,
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
