import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/cache_service.dart';
import '../../providers/location_provider.dart';
import '../../providers/map_provider.dart';
import '../../core/utils/location_utils.dart';
import '../../models/location_model.dart';
import '../../widgets/home/location_card.dart';
import '../../widgets/home/category_chip.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final CacheService _cacheService = CacheService();
  final FocusNode _focusNode = FocusNode();

  List<LocationModel> _results = [];
  List<String> _recentSearches = [];
  String _selectedCategory = 'All';
  bool _isLoading = false;
  bool _hasSearched = false;

  final List<String> _categories = [
    'All', 'Classroom', 'Office', 'Lab', 'Cafeteria', 'Library', 'Parking',
  ];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final searches = await _cacheService.getRecentSearches();
    setState(() => _recentSearches = searches);
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty && _selectedCategory == 'All') {
      setState(() {
        _results = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    if (query.trim().isNotEmpty) {
      await _cacheService.addRecentSearch(query.trim());
      await _loadRecentSearches();
    }

    final locationProvider = context.read<LocationProvider>();
    final results = await locationProvider.searchLocations(
      query: query,
      category: _selectedCategory == 'All' ? null : _selectedCategory,
    );

    setState(() {
      _results = results;
      _isLoading = false;
      _hasSearched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mapProvider = context.watch<MapProvider>();
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            autofocus: true,
            decoration: InputDecoration(
              hintText: AppStrings.searchPlaceholder,
              border: InputBorder.none,
              prefixIcon: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/home'),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch('');
                      },
                    )
                  : null,
            ),
            onChanged: (q) {
              setState(() {});
              _performSearch(q);
            },
            onSubmitted: _performSearch,
          ),
        ),
        body: Column(
          children: [
            // Category filter
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                itemCount: _categories.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: CategoryChip(
                    label: _categories[i],
                    isSelected: _selectedCategory == _categories[i],
                    onTap: () {
                      setState(() => _selectedCategory = _categories[i]);
                      _performSearch(_searchController.text);
                    },
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : !_hasSearched && _searchController.text.isEmpty
                      ? _buildRecentSearches()
                      : _results.isEmpty
                          ? _buildEmptyState()
                          : _buildResults(mapProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearches() {
    if (_recentSearches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Start typing to search', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Searches', style: Theme.of(context).textTheme.headlineSmall),
              TextButton(
                onPressed: () async {
                  await _cacheService.clearRecentSearches();
                  setState(() => _recentSearches = []);
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
        ),
        ..._recentSearches.map((s) => ListTile(
              leading: const Icon(Icons.history, color: AppColors.textSecondary),
              title: Text(s),
              onTap: () {
                _searchController.text = s;
                _performSearch(s);
              },
              trailing: IconButton(
                icon: const Icon(Icons.north_west, size: 16),
                onPressed: () {
                  _searchController.text = s;
                  _performSearch(s);
                },
              ),
            )),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(AppStrings.emptySearch, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(AppStrings.emptySearchSubtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  Widget _buildResults(MapProvider mapProvider) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final loc = _results[index];
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
          ).animate().fadeIn(delay: Duration(milliseconds: 30 * index), duration: 250.ms),
        );
      },
    );
  }
}
