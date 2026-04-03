import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/storage_service.dart';
import '../../providers/auth_provider.dart';
import '../../models/location_model.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class AddLocationScreen extends StatefulWidget {
  const AddLocationScreen({super.key});

  @override
  State<AddLocationScreen> createState() => _AddLocationScreenState();
}

class _AddLocationScreenState extends State<AddLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _buildingController = TextEditingController();
  final _floorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  String _selectedCategory = 'classroom';
  File? _imageFile;
  bool _isIndoor = false;
  bool _isLoading = false;

  final List<String> _categories = [
    'classroom', 'office', 'lab', 'cafeteria', 'library',
    'restroom', 'parking', 'entrance', 'other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _buildingController.dispose();
    _floorController.dispose();
    _descriptionController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (image != null) setState(() => _imageFile = File(image.path));
  }

  void _onMapTap(LatLng pos) {
    setState(() {
      _latController.text = pos.latitude.toStringAsFixed(6);
      _lngController.text = pos.longitude.toStringAsFixed(6);
    });
  }

  Future<void> _saveLocation() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthProvider>();
    if (auth.userModel?.isAdmin != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only admins can add locations'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String imageUrl = '';
      if (_imageFile != null) {
        imageUrl = await _storageService.uploadLocationImage(
          DateTime.now().millisecondsSinceEpoch.toString(),
          _imageFile!,
        );
      }

      final location = LocationModel(
        id: '',
        name: _nameController.text.trim(),
        category: _selectedCategory,
        building: _buildingController.text.trim(),
        floor: int.tryParse(_floorController.text) ?? 0,
        description: _descriptionController.text.trim(),
        latitude: double.tryParse(_latController.text) ?? 0,
        longitude: double.tryParse(_lngController.text) ?? 0,
        imageUrl: imageUrl,
        isIndoor: _isIndoor,
        createdAt: DateTime.now(),
      );

      await _firestoreService.addLocation(location);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.successLocationAdded),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.addLocation),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => context.pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image picker
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: _imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(_imageFile!, fit: BoxFit.cover,
                                width: double.infinity),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_photo_alternate,
                                    size: 40, color: AppColors.textSecondary),
                                const SizedBox(height: 8),
                                Text(AppStrings.uploadImage,
                                    style: theme.textTheme.bodySmall),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                CustomTextField(
                  controller: _nameController,
                  label: AppStrings.locationName,
                  hint: 'e.g., Main Library',
                  prefixIcon: Icons.location_on_outlined,
                  validator: (v) => v?.isEmpty == true ? 'Name is required' : null,
                ),
                const SizedBox(height: 14),

                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    prefixIcon: const Icon(Icons.category_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _categories.map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c[0].toUpperCase() + c.substring(1)),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v!),
                ),
                const SizedBox(height: 14),

                CustomTextField(
                  controller: _buildingController,
                  label: AppStrings.buildingLabel,
                  hint: 'e.g., Building A',
                  prefixIcon: Icons.business_outlined,
                  validator: (v) => v?.isEmpty == true ? 'Building is required' : null,
                ),
                const SizedBox(height: 14),

                CustomTextField(
                  controller: _floorController,
                  label: AppStrings.floorLabel,
                  hint: '0 = Ground, 1 = 1st, etc.',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.layers_outlined,
                  validator: (v) => v?.isEmpty == true ? 'Floor is required' : null,
                ),
                const SizedBox(height: 14),

                CustomTextField(
                  controller: _descriptionController,
                  label: AppStrings.descriptionLabel,
                  hint: 'Brief description of this location',
                  maxLines: 3,
                  prefixIcon: Icons.description_outlined,
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _latController,
                        label: 'Latitude',
                        hint: '28.6139',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        prefixIcon: Icons.gps_fixed,
                        validator: (v) {
                          if (v?.isEmpty == true) return 'Required';
                          if (double.tryParse(v!) == null) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        controller: _lngController,
                        label: 'Longitude',
                        hint: '77.2090',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        prefixIcon: Icons.gps_fixed,
                        validator: (v) {
                          if (v?.isEmpty == true) return 'Required';
                          if (double.tryParse(v!) == null) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.tapMapToFill,
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 14),

                // Map tap to fill
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(28.6139, 77.2090),
                      zoom: 15,
                    ),
                    onTap: _onMapTap,
                    markers: _latController.text.isNotEmpty && _lngController.text.isNotEmpty
                        ? {
                            Marker(
                              markerId: const MarkerId('selected'),
                              position: LatLng(
                                double.tryParse(_latController.text) ?? 28.6139,
                                double.tryParse(_lngController.text) ?? 77.2090,
                              ),
                            ),
                          }
                        : {},
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    mapToolbarEnabled: false,
                  ),
                ),
                const SizedBox(height: 14),

                // Indoor toggle
                Card(
                  child: SwitchListTile(
                    value: _isIndoor,
                    onChanged: (v) => setState(() => _isIndoor = v),
                    title: const Text('Indoor Location'),
                    subtitle: const Text('Has indoor floor plan'),
                    secondary: const Icon(Icons.home_outlined),
                  ),
                ),
                const SizedBox(height: 24),

                CustomButton(
                  label: AppStrings.addLocation,
                  isLoading: _isLoading,
                  icon: Icons.add_location_alt,
                  onPressed: _saveLocation,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
