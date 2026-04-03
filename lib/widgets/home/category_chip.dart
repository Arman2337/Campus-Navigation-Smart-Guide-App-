import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const CategoryChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
  });

  IconData _getIcon() {
    switch (label.toLowerCase()) {
      case 'all':
        return Icons.dashboard_outlined;
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
        return Icons.place_outlined;
    }
  }

  Color _getCategoryColor() {
    if (label.toLowerCase() == 'all') return AppColors.primary;
    return AppColors.getCategoryColor(label);
  }

  @override
  Widget build(BuildContext context) {
    final color = _getCategoryColor();

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.2),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIcon(),
              size: 15,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTextStyles.chipLabel.copyWith(
                color: isSelected ? Colors.white : color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
