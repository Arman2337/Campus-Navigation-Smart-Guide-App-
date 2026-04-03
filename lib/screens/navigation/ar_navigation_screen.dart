import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';

class ARNavigationScreen extends StatelessWidget {
  final String locationId;
  const ARNavigationScreen({super.key, required this.locationId});

  @override
  Widget build(BuildContext context) {
    // AR navigation is an advanced optional feature.
    // We show a graceful fallback since ARCore/ARKit may not be available.
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.arNavigation),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.view_in_ar_rounded,
                    size: 52, color: Colors.purple),
              ),
              const SizedBox(height: 24),
              const Text(
                'AR Navigation',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                AppStrings.arNotSupported,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  color: Color(0xFF5F6368),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  context.pop();
                  context.push('/navigate/$locationId');
                },
                icon: const Icon(Icons.directions),
                label: const Text('Use Standard Navigation'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
