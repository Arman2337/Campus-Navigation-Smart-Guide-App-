import 'package:flutter/material.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/announcement_model.dart';
import 'package:intl/intl.dart';

class AnnouncementBanner extends StatelessWidget {
  final AnnouncementModel announcement;

  const AnnouncementBanner({super.key, required this.announcement});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A73E8).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.campaign_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  announcement.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.announcementTitle,
                ),
                const SizedBox(height: 2),
                Text(
                  announcement.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.announcementBody,
                ),
              ],
            ),
          ),
          if (announcement.timestamp != null) ...[
            const SizedBox(width: 8),
            Text(
              DateFormat('MMM d').format(announcement.timestamp!),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
