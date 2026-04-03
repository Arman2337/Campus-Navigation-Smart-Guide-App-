import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/storage_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final StorageService _storageService = StorageService();
  final TextEditingController _nameController = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameController.text = auth.userModel?.name ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _changeProfilePhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      imageQuality: 80,
    );
    if (image == null) return;

    final auth = context.read<AuthProvider>();
    if (auth.userModel == null) return;

    setState(() => _isSaving = true);
    try {
      final file = File(image.path);
      final url = await _storageService.uploadProfilePhoto(
          auth.userModel!.uid, file);
      await auth.updateProfile(photoUrl: url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.errorImageUpload),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _saveName() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    final auth = context.read<AuthProvider>();
    final success =
        await auth.updateProfile(name: _nameController.text.trim());
    setState(() {
      _isSaving = false;
      _isEditing = !success;
    });
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.successProfileUpdated),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(AppStrings.signOut),
        content: const Text(AppStrings.signOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text(AppStrings.signOut,
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final locationProvider = context.watch<LocationProvider>();
    final user = auth.userModel;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.profile, style: theme.textTheme.headlineMedium),
        automaticallyImplyLeading: false,
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _isSaving ? null : _saveName,
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            )
          else
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                GestureDetector(
                  onTap: _changeProfilePhoto,
                  child: CircleAvatar(
                    radius: 52,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    backgroundImage:
                        user?.photoUrl.isNotEmpty == true
                            ? CachedNetworkImageProvider(user!.photoUrl)
                            : null,
                    child: user?.photoUrl.isEmpty != false
                        ? Text(
                            (user?.name.isNotEmpty == true
                                    ? user!.name[0]
                                    : 'U')
                                .toUpperCase(),
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                ),
                if (_isSaving)
                  const CircularProgressIndicator()
                else
                  GestureDetector(
                    onTap: _changeProfilePhoto,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                    ),
                  ),
              ],
            ).animate().fadeIn(duration: 400.ms).scale(),
            const SizedBox(height: 16),
            // Name
            _isEditing
                ? TextField(
                    controller: _nameController,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      hintText: 'Your name',
                      border: UnderlineInputBorder(),
                    ),
                    style: theme.textTheme.headlineMedium,
                  )
                : Text(user?.name ?? 'User', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(user?.email ?? '', style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            // Role badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                (user?.role ?? 'student').toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Stats card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat(
                    '${locationProvider.savedLocations.length}',
                    'Saved',
                    Icons.bookmark,
                  ),
                  Container(width: 1, height: 40, color: AppColors.borderLight),
                  _buildStat(
                    '${locationProvider.allLocations.length}',
                    'Locations',
                    Icons.location_on,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

            const SizedBox(height: 16),

            // Menu items
            _buildMenuCard(context, theme),

            const SizedBox(height: 16),

            // Sign Out
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout, color: AppColors.error),
                label: Text(
                  AppStrings.signOut,
                  style: const TextStyle(color: AppColors.error),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard(BuildContext context, ThemeData theme) {
    final auth = context.read<AuthProvider>();
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.bookmark_outline, color: AppColors.primary),
            title: const Text('Saved Locations'),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => context.go('/saved'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.location_on_outlined, color: AppColors.secondary),
            title: const Text('Explore Map'),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => context.go('/map'),
          ),
          if (auth.userModel?.isAdmin == true) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.add_location_alt_outlined,
                  color: AppColors.accent),
              title: const Text('Add Location (Admin)'),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () => context.push('/add-location'),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 250.ms, duration: 400.ms);
  }
}
