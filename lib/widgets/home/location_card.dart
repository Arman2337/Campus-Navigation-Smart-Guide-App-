import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/location_model.dart';

class LocationCard extends StatelessWidget {
  final LocationModel location;
  final String distance;
  final VoidCallback? onTap;
  final bool isHorizontal;

  const LocationCard({
    super.key,
    required this.location,
    this.distance = '',
    this.onTap,
    this.isHorizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = AppColors.getCategoryColor(location.category);

    if (isHorizontal) {
      return _buildHorizontalCard(theme, categoryColor);
    }
    return _buildVerticalCard(theme, categoryColor);
  }

  Widget _buildHorizontalCard(ThemeData theme, Color categoryColor) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 100,
                child: location.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: location.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: Colors.grey.shade300,
                          highlightColor: Colors.grey.shade100,
                          child: Container(color: Colors.white),
                        ),
                        errorWidget: (context, url, error) =>
                            _buildPlaceholderImage(categoryColor),
                      )
                    : _buildPlaceholderImage(categoryColor),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardTitle,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    location.building,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardSubtitle,
                  ),
                  if (distance.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.near_me, size: 12, color: categoryColor),
                        const SizedBox(width: 3),
                        Text(distance, style: AppTextStyles.distanceText),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalCard(ThemeData theme, Color categoryColor) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
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
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(16)),
              child: SizedBox(
                width: 90,
                height: 90,
                child: location.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: location.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: Colors.grey.shade300,
                          highlightColor: Colors.grey.shade100,
                          child: Container(color: Colors.white),
                        ),
                        errorWidget: (context, url, error) =>
                            _buildPlaceholderImage(categoryColor),
                      )
                    : _buildPlaceholderImage(categoryColor),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        location.category.toUpperCase(),
                        style: AppTextStyles.categoryLabel.copyWith(
                          color: categoryColor,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      location.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardTitle,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            '${location.building} • ${location.floorLabel}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.cardSubtitle,
                          ),
                        ),
                      ],
                    ),
                    if (distance.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.near_me, size: 13, color: categoryColor),
                          const SizedBox(width: 4),
                          Text(distance, style: AppTextStyles.distanceText),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(Color color) {
    return Container(
      color: color.withOpacity(0.1),
      child: Center(
        child: Icon(
          _getCategoryIcon(),
          size: 32,
          color: color,
        ),
      ),
    );
  }

  IconData _getCategoryIcon() {
    switch (location.category.toLowerCase()) {
      case 'classroom':
        return Icons.class_outlined;
      case 'office':
        return Icons.business_outlined;
      case 'lab':
        return Icons.science_outlined;
      case 'cafeteria':
        return Icons.restaurant_outlined;
      case 'library':
        return Icons.local_library_outlined;
      case 'restroom':
        return Icons.wc_outlined;
      case 'parking':
        return Icons.local_parking_outlined;
      case 'entrance':
        return Icons.door_front_door_outlined;
      default:
        return Icons.location_on_outlined;
    }
  }
}
