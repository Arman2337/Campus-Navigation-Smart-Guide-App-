import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/location_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/map_provider.dart';
import '../../widgets/home/category_chip.dart';
import '../../widgets/home/location_card.dart';
import '../../widgets/home/announcement_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> _categories = [
    AppStrings.all,
    AppStrings.classroom,
    AppStrings.office,
    AppStrings.lab,
    AppStrings.cafeteria,
    AppStrings.library,
    AppStrings.parking,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initData());
  }

  Future<void> _initData() async {
    final locationProvider = context.read<LocationProvider>();
    final mapProvider = context.read<MapProvider>();
    final authProvider = context.read<AuthProvider>();

    await mapProvider.initializeUserLocation(context);
    await locationProvider.fetchLocations(
      userPosition: mapProvider.currentPosition,
    );
    await locationProvider.fetchAnnouncements();

    if (authProvider.userModel != null) {
      await locationProvider.loadSavedLocations(authProvider.userModel!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final locationProvider = context.watch<LocationProvider>();
    final mapProvider = context.watch<MapProvider>();
    final theme = Theme.of(context);

    final greeting = _getGreeting();
    final userName = auth.userModel?.name.split(' ').first ?? 'Campus Explorer';

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _initData,
        child: CustomScrollView(
          slivers: [
            // Header SliverAppBar
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: theme.scaffoldBackgroundColor,
              elevation: 0,
              expandedHeight: 120,
              flexibleSpace: FlexibleSpaceBar(
                background: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$greeting, $userName! 👋',
                                  style: theme.textTheme.headlineMedium,
                                ).animate().fadeIn(duration: 400.ms),
                                Text(
                                  'Where do you want to go today?',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                              ],
                            ),
                            // Avatar
                            GestureDetector(
                              onTap: () => context.go('/profile'),
                              child: CircleAvatar(
                                radius: 22,
                                backgroundColor: AppColors.primary,
                                backgroundImage: auth.userModel?.photoUrl.isNotEmpty == true
                                    ? NetworkImage(auth.userModel!.photoUrl)
                                    : null,
                                child: auth.userModel?.photoUrl.isEmpty != false
                                    ? Text(
                                        userName[0].toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      )
                                    : null,
                              ),
                            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                if (auth.userModel?.isAdmin == true)
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => context.push('/add-location'),
                    tooltip: 'Add Location',
                  ),
              ],
            ),

            // Offline banner
            if (locationProvider.isOffline)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off, size: 18, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.offlineBannerText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Announcements
            if (locationProvider.announcements.isNotEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 90,
                  child: PageView.builder(
                    itemCount: locationProvider.announcements.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: AnnouncementBanner(
                        announcement: locationProvider.announcements[index],
                      ),
                    ),
                  ),
                ),
              ),

            // Search bar shortcut
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: GestureDetector(
                  onTap: () => context.go('/search'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: AppColors.textSecondary, size: 22),
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
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
              ),
            ),

            // Category chips
            SliverToBoxAdapter(
              child: SizedBox(
                height: 52,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: CategoryChip(
                      label: _categories[index],
                      isSelected: locationProvider.selectedCategory == _categories[index],
                      onTap: () => locationProvider.filterByCategory(_categories[index]),
                    ),
                  ),
                ),
              ),
            ),

            // Nearby section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppStrings.nearbyLocations, style: theme.textTheme.headlineSmall),
                    TextButton(
                      onPressed: () => context.go('/map'),
                      child: Text(AppStrings.seeAll,
                          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.primary)),
                    ),
                  ],
                ),
              ),
            ),

            // Nearby horizontal list
            SliverToBoxAdapter(
              child: locationProvider.isLoading
                  ? _buildShimmerList()
                  : locationProvider.nearbyLocations.isEmpty
                      ? const SizedBox.shrink()
                      : SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: locationProvider.nearbyLocations.length,
                            itemBuilder: (context, index) {
                              final loc = locationProvider.nearbyLocations[index];
                              final dist = mapProvider.currentPosition != null
                                  ? LocationUtils.formatDistance(
                                      LocationUtils.calculateDistance(
                                        mapProvider.currentPosition!.latitude,
                                        mapProvider.currentPosition!.longitude,
                                        loc.latitude,
                                        loc.longitude,
                                      ),
                                    )
                                  : '';
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: LocationCard(
                                  location: loc,
                                  distance: dist,
                                  isHorizontal: true,
                                  onTap: () => context.push('/location/${loc.id}'),
                                ),
                              ).animate().fadeIn(
                                delay: Duration(milliseconds: 50 * index),
                                duration: 300.ms,
                              );
                            },
                          ),
                        ),
            ),

            // Popular section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppStrings.popularPlaces, style: theme.textTheme.headlineSmall),
                    TextButton(
                      onPressed: () => context.go('/search'),
                      child: Text(AppStrings.seeAll,
                          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.primary)),
                    ),
                  ],
                ),
              ),
            ),

            // Popular list
            locationProvider.isLoading
                ? SliverToBoxAdapter(child: _buildShimmerGrid())
                : locationProvider.filteredLocations.isEmpty
                    ? SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(Icons.location_off, size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(AppStrings.emptySearch, style: theme.textTheme.bodyLarge),
                              ],
                            ),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, index) {
                            final loc = locationProvider.filteredLocations[index];
                            final dist = mapProvider.currentPosition != null
                                ? LocationUtils.formatDistance(
                                    LocationUtils.calculateDistance(
                                      mapProvider.currentPosition!.latitude,
                                      mapProvider.currentPosition!.longitude,
                                      loc.latitude,
                                      loc.longitude,
                                    ),
                                  )
                                : '';
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              child: LocationCard(
                                location: loc,
                                distance: dist,
                                onTap: () => context.push('/location/${loc.id}'),
                              ).animate().fadeIn(
                                delay: Duration(milliseconds: 30 * index),
                                duration: 300.ms,
                              ),
                            );
                          },
                          childCount: locationProvider.filteredLocations.length,
                        ),
                      ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _buildShimmerList() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: 3,
        itemBuilder: (context, _) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              width: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return Column(
      children: List.generate(
        3,
        (_) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
