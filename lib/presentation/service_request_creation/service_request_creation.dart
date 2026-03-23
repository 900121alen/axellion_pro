import 'dart:async';
import 'dart:io' if (dart.library.io) 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './widgets/location_section_map_stub.dart'
    if (dart.library.io) './widgets/location_section_map_real.dart';

const Color _accentBlue = Color(0xFF2C3E63);
const Color _darkBg = Color(0xFFEEEFF4);
const Color _cardBg = Color(0xFFFFFFFF);
const Color _sectionBg = Color(0xFFF5F6FA);
const Color _fieldBg = Color(0xFFDDE0E8);
const Color _textPrimary = Color(0xFF1A1A2A);
const Color _textSecondary = Color(0xFF5A5A7A);
const Color _textHint = Color(0xFF8888AA);
const Color _borderColor = Color(0xFFD0D3DC);
const Color _errorColor = Color(0xFFEF4444);

// Categories that REQUIRE photos
const Set<String> _photoRequiredCategories = {
  'Wheel & Tire',
  'Exterior & Body',
};

// ─── Vehicle data ──────────────────────────────────────────────────────────
const Map<String, List<String>> _vehicleModels = {
  'Toyota': [
    'Camry',
    'Corolla',
    'RAV4',
    'Highlander',
    'Tacoma',
    'Tundra',
    'Prius',
    '4Runner',
    'Sienna',
    'Avalon',
  ],
  'Honda': [
    'Civic',
    'Accord',
    'CR-V',
    'Pilot',
    'Odyssey',
    'HR-V',
    'Ridgeline',
    'Passport',
    'Fit',
    'Insight',
  ],
  'Ford': [
    'F-150',
    'Mustang',
    'Explorer',
    'Escape',
    'Edge',
    'Bronco',
    'Ranger',
    'Expedition',
    'Maverick',
    'EcoSport',
  ],
  'Chevrolet': [
    'Silverado',
    'Equinox',
    'Malibu',
    'Traverse',
    'Colorado',
    'Tahoe',
    'Suburban',
    'Blazer',
    'Trax',
    'Camaro',
  ],
  'BMW': [
    '3 Series',
    '5 Series',
    '7 Series',
    'X3',
    'X5',
    'X7',
    'M3',
    'M5',
    '4 Series',
    '2 Series',
  ],
  'Mercedes-Benz': [
    'C-Class',
    'E-Class',
    'S-Class',
    'GLC',
    'GLE',
    'GLS',
    'A-Class',
    'CLA',
    'GLB',
    'G-Class',
  ],
  'Audi': ['A3', 'A4', 'A6', 'Q3', 'Q5', 'Q7', 'Q8', 'A5', 'A8', 'TT'],
  'Nissan': [
    'Altima',
    'Sentra',
    'Rogue',
    'Pathfinder',
    'Frontier',
    'Titan',
    'Murano',
    'Kicks',
    'Armada',
    'Versa',
  ],
  'Hyundai': [
    'Elantra',
    'Sonata',
    'Tucson',
    'Santa Fe',
    'Palisade',
    'Kona',
    'Ioniq',
    'Venue',
    'Accent',
    'Nexo',
  ],
  'Kia': [
    'Forte',
    'Optima',
    'Sportage',
    'Sorento',
    'Telluride',
    'Soul',
    'Stinger',
    'Carnival',
    'Niro',
    'Seltos',
  ],
  'Volkswagen': [
    'Jetta',
    'Passat',
    'Tiguan',
    'Atlas',
    'Golf',
    'ID.4',
    'Taos',
    'Arteon',
    'GTI',
    'Touareg',
  ],
  'Subaru': [
    'Outback',
    'Forester',
    'Impreza',
    'Legacy',
    'Crosstrek',
    'Ascent',
    'WRX',
    'BRZ',
    'Solterra',
    'Baja',
  ],
  'Mazda': [
    'Mazda3',
    'Mazda6',
    'CX-5',
    'CX-9',
    'CX-30',
    'MX-5 Miata',
    'CX-50',
    'CX-3',
    'CX-90',
    'MX-30',
  ],
  'Jeep': [
    'Wrangler',
    'Grand Cherokee',
    'Cherokee',
    'Compass',
    'Renegade',
    'Gladiator',
    'Wagoneer',
    'Grand Wagoneer',
    'Patriot',
    'Liberty',
  ],
  'Ram': ['1500', '2500', '3500', 'ProMaster', 'ProMaster City'],
  'GMC': [
    'Sierra',
    'Terrain',
    'Acadia',
    'Canyon',
    'Yukon',
    'Envoy',
    'Jimmy',
    'Safari',
  ],
  'Dodge': [
    'Charger',
    'Challenger',
    'Durango',
    'Journey',
    'Grand Caravan',
    'Dart',
    'Viper',
  ],
  'Chrysler': [
    '300',
    'Pacifica',
    'Voyager',
    'Town & Country',
    'Sebring',
    'PT Cruiser',
  ],
  'Tesla': [
    'Model 3',
    'Model S',
    'Model X',
    'Model Y',
    'Cybertruck',
    'Roadster',
  ],
  'Lexus': ['ES', 'IS', 'GS', 'LS', 'RX', 'NX', 'GX', 'LX', 'UX', 'LC'],
  'Acura': ['ILX', 'TLX', 'RDX', 'MDX', 'NSX', 'Integra', 'ZDX'],
  'Infiniti': ['Q50', 'Q60', 'QX50', 'QX60', 'QX80', 'G35', 'G37', 'FX35'],
  'Cadillac': [
    'CT4',
    'CT5',
    'XT4',
    'XT5',
    'XT6',
    'Escalade',
    'Lyriq',
    'ATS',
    'CTS',
  ],
  'Lincoln': [
    'Corsair',
    'Nautilus',
    'Aviator',
    'Navigator',
    'Continental',
    'MKZ',
  ],
  'Buick': ['Encore', 'Envision', 'Enclave', 'LaCrosse', 'Regal', 'Verano'],
  'Volvo': ['S60', 'S90', 'V60', 'V90', 'XC40', 'XC60', 'XC90', 'C40'],
  'Land Rover': [
    'Defender',
    'Discovery',
    'Range Rover',
    'Range Rover Sport',
    'Range Rover Evoque',
    'Range Rover Velar',
    'Freelander',
  ],
  'Porsche': [
    '911',
    'Cayenne',
    'Macan',
    'Panamera',
    'Taycan',
    'Boxster',
    'Cayman',
  ],
  'Mitsubishi': [
    'Outlander',
    'Eclipse Cross',
    'Galant',
    'Lancer',
    'Mirage',
    'Montero',
    'Endeavor',
  ],
  'Suzuki': [
    'Swift',
    'Vitara',
    'Grand Vitara',
    'Jimny',
    'Baleno',
    'Ignis',
    'S-Cross',
  ],
  'Other': [],
};

const String _otherModelOption = 'Other model';

class ServiceRequestCreation extends StatefulWidget {
  const ServiceRequestCreation({super.key});

  @override
  State<ServiceRequestCreation> createState() => _ServiceRequestCreationState();
}

class _ServiceRequestCreationState extends State<ServiceRequestCreation>
    with SingleTickerProviderStateMixin {
  // Step control
  int _currentStep = 0; // 0, 1, 2, 3
  late final PageController _pageController;

  // Route args
  Map<String, dynamic>? _categoryArg;
  String? _categoryName; // parent category (price_range_text)
  String? _serviceName; // selected service (name)

  // Step 1 — Description
  final _descriptionController = TextEditingController();
  String? _descriptionError;

  // Step 2 — Location
  final _locationController = TextEditingController();
  dynamic _selectedLocation;
  String _selectedAddress = '';
  String? _locationError;

  // Step 2 — Vehicle
  List<Map<String, dynamic>> _savedVehicles = [];
  bool _loadingVehicles = true;
  Map<String, dynamic>? _selectedSavedVehicle;
  bool _addingNewVehicle = false;
  // Dropdown-based vehicle fields
  String? _selectedMake;
  String? _selectedModel;
  final _customModelController = TextEditingController();
  String? _selectedYear;
  bool _saveVehicleToProfile = false;
  String? _vehicleError;

  // Step 2 — Preferred Date & Time
  DateTime? _preferredDate;
  String _preferredTime = 'Flexible';

  // Step 3 — Photos
  List<XFile> _mediaFiles = [];
  List<String> _uploadedPhotoUrls = []; // public URLs after upload
  final _picker = ImagePicker();
  bool _mediaLoading = false;
  String? _photoError;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic> && _categoryArg == null) {
      _categoryArg = args;
      _serviceName = args['name'] as String?;
      _categoryName = args['price_range_text'] as String?;
      _loadSavedVehicles();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _customModelController.dispose();
    super.dispose();
  }

  // ─── Vehicle loading ───────────────────────────────────────────────────────

  Future<void> _loadSavedVehicles() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _loadingVehicles = false);
        return;
      }
      final data = await Supabase.instance.client
          .from('user_vehicles')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _savedVehicles = List<Map<String, dynamic>>.from(data as List);
          if (_savedVehicles.isNotEmpty) {
            _selectedSavedVehicle = _savedVehicles.first;
            _addingNewVehicle = false;
          } else {
            _addingNewVehicle = true;
          }
          _loadingVehicles = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingVehicles = false;
          _addingNewVehicle = true;
        });
      }
    }
  }

  // ─── Navigation ────────────────────────────────────────────────────────────

  bool _validateStep(int step) {
    if (step == 0) {
      final desc = _descriptionController.text.trim();
      if (desc.isEmpty || desc.length < 10) {
        setState(
          () => _descriptionError = desc.isEmpty
              ? 'Description is required.'
              : 'Minimum 10 characters.',
        );
        if (!kIsWeb) HapticFeedback.mediumImpact();
        return false;
      }
      setState(() => _descriptionError = null);
      return true;
    }
    if (step == 1) {
      bool valid = true;
      if (_locationController.text.trim().isEmpty) {
        setState(() => _locationError = 'Service location is required.');
        valid = false;
      } else {
        setState(() => _locationError = null);
      }
      // Vehicle validation
      if (_addingNewVehicle) {
        final make = _selectedMake;
        final model = _selectedModel;
        final customModel = _customModelController.text.trim();
        final year = _selectedYear;
        if (make == null || make.isEmpty) {
          setState(() => _vehicleError = 'Please select a vehicle make.');
          valid = false;
        } else if (model == null || model.isEmpty) {
          setState(() => _vehicleError = 'Please select a vehicle model.');
          valid = false;
        } else if (model == _otherModelOption && customModel.isEmpty) {
          setState(() => _vehicleError = 'Please enter the vehicle model.');
          valid = false;
        } else if (year == null || year.isEmpty) {
          setState(() => _vehicleError = 'Please select a vehicle year.');
          valid = false;
        } else {
          setState(() => _vehicleError = null);
        }
      } else {
        if (_selectedSavedVehicle == null) {
          setState(() => _vehicleError = 'Please select a vehicle.');
          valid = false;
        } else {
          setState(() => _vehicleError = null);
        }
      }
      if (!valid) if (!kIsWeb) HapticFeedback.mediumImpact();
      return valid;
    }
    if (step == 2) {
      final photosRequired = _isPhotoRequired();
      if (photosRequired && _mediaFiles.isEmpty) {
        setState(
          () =>
              _photoError = 'At least one photo is required for this category.',
        );
        if (!kIsWeb) HapticFeedback.mediumImpact();
        return false;
      }
      setState(() => _photoError = null);
      return true;
    }
    return true;
  }

  void _goNext() {
    if (!_validateStep(_currentStep)) return;
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _confirmCancel();
    }
  }

  // ─── Location ──────────────────────────────────────────────────────────────

  Future<void> _useCurrentLocation() async {
    if (!kIsWeb) {
      final status = await Permission.location.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied.')),
          );
        }
        return;
      }
    }
    const mockAddress = 'Current Location, San Francisco, CA';
    setState(() {
      _selectedAddress = mockAddress;
      _locationController.text = mockAddress;
      _selectedLocation = kIsWeb ? null : buildLatLng(37.7749, -122.4194);
      _locationError = null;
    });
  }

  // ─── Photos ────────────────────────────────────────────────────────────────

  bool _isPhotoRequired() {
    return _photoRequiredCategories.contains(_categoryName);
  }

  Future<bool> _requestMediaPermission(ImageSource source) async {
    if (kIsWeb) return true;
    final permission = source == ImageSource.camera
        ? Permission.camera
        : Permission.photos;
    final status = await permission.request();
    return status.isGranted;
  }

  Future<void> _pickMedia(ImageSource source) async {
    final granted = await _requestMediaPermission(source);
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission denied. Please enable in settings.'),
          ),
        );
      }
      return;
    }
    setState(() => _mediaLoading = true);
    try {
      List<XFile> picked = [];
      if (source == ImageSource.camera) {
        final file = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
          maxWidth: 1920,
          maxHeight: 1080,
        );
        if (file != null) picked = [file];
      } else {
        final files = await _picker.pickMultiImage(
          imageQuality: 80,
          maxWidth: 1920,
          maxHeight: 1080,
        );
        picked = files;
      }

      if (picked.isEmpty) {
        if (mounted) setState(() => _mediaLoading = false);
        return;
      }

      final remaining = 5 - _mediaFiles.length;
      final toUpload = picked.take(remaining).toList();

      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final newFiles = <XFile>[];
      final newUrls = <String>[];

      for (final xfile in toUpload) {
        try {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final storagePath = '$userId/$timestamp.jpg';

          if (kIsWeb) {
            final bytes = await xfile.readAsBytes();
            await client.storage
                .from('request_photos')
                .uploadBinary(
                  storagePath,
                  bytes,
                  fileOptions: const FileOptions(
                    contentType: 'image/jpeg',
                    upsert: true,
                  ),
                );
          } else {
            await client.storage
                .from('request_photos')
                .upload(
                  storagePath,
                  File(xfile.path),
                  fileOptions: const FileOptions(
                    contentType: 'image/jpeg',
                    upsert: true,
                  ),
                );
          }

          final publicUrl = client.storage
              .from('request_photos')
              .getPublicUrl(storagePath);

          newFiles.add(xfile);
          newUrls.add(publicUrl);
        } catch (uploadError) {
          // Skip failed uploads silently, show error at end
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to upload one photo. Please try again.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }

      if (mounted && newFiles.isNotEmpty) {
        setState(() {
          _mediaFiles = [..._mediaFiles, ...newFiles];
          _uploadedPhotoUrls = [..._uploadedPhotoUrls, ...newUrls];
          _photoError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not pick media. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _mediaLoading = false);
    }
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _sectionBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _accentBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: _accentBlue,
                  size: 20,
                ),
              ),
              title: const Text(
                'Take Photo',
                style: TextStyle(color: _textPrimary, fontSize: 14),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickMedia(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _accentBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: const Icon(
                  Icons.photo_library,
                  color: _accentBlue,
                  size: 20,
                ),
              ),
              title: const Text(
                'Choose from Gallery',
                style: TextStyle(color: _textPrimary, fontSize: 14),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickMedia(ImageSource.gallery);
              },
            ),
            SizedBox(height: 1.h),
          ],
        ),
      ),
    );
  }

  void _removePhoto(int index) {
    setState(() {
      final updatedFiles = [..._mediaFiles];
      final updatedUrls = [..._uploadedPhotoUrls];
      updatedFiles.removeAt(index);
      if (index < updatedUrls.length) updatedUrls.removeAt(index);
      _mediaFiles = updatedFiles;
      _uploadedPhotoUrls = updatedUrls;
    });
  }

  // ─── Submit ────────────────────────────────────────────────────────────────

  String _buildVehicleInfo() {
    if (!_addingNewVehicle && _selectedSavedVehicle != null) {
      final v = _selectedSavedVehicle!;
      return '${v['make']} ${v['model']} ${v['year']}';
    }
    final make = _selectedMake ?? '';
    final model = _selectedModel == _otherModelOption
        ? _customModelController.text.trim()
        : (_selectedModel ?? '');
    final year = _selectedYear ?? '';
    return '$make $model $year'.trim();
  }

  Future<void> _submitRequest() async {
    if (!_validateStep(2)) return;
    setState(() => _isSubmitting = true);
    try {
      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser;
      if (currentUser == null) throw Exception('You must be logged in.');

      String? vehicleId;

      if (_addingNewVehicle) {
        // Create new vehicle record and get its id
        final make = _selectedMake ?? '';
        final model = _selectedModel == _otherModelOption
            ? _customModelController.text.trim()
            : (_selectedModel ?? '');
        final year = _selectedYear ?? '';
        if (make.isNotEmpty && model.isNotEmpty && year.isNotEmpty) {
          final inserted = await client
              .from('user_vehicles')
              .insert({
                'user_id': currentUser.id,
                'make': make,
                'model': model,
                'year': year,
              })
              .select('id')
              .single();
          vehicleId = inserted['id'] as String?;
        }
      } else if (_selectedSavedVehicle != null) {
        vehicleId = _selectedSavedVehicle!['id'] as String?;
      }

      final vehicleInfo = _buildVehicleInfo();
      final categoryId = _categoryArg?['id'] as String?;

      await client.from('requests').insert({
        'client_id': currentUser.id,
        'category_id': categoryId,
        'category_name': _categoryName,
        'service_name': _serviceName,
        'description': _descriptionController.text.trim(),
        'vehicle_id': vehicleId,
        'vehicle_info': vehicleInfo.isNotEmpty ? vehicleInfo : null,
        'budget_option': null,
        'status': 'searching',
        'media_url': _uploadedPhotoUrls.isNotEmpty ? _uploadedPhotoUrls : null,
        'address_full': _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
        'preferred_date': _preferredDate != null
            ? '${_preferredDate!.year}-${_preferredDate!.month.toString().padLeft(2, '0')}-${_preferredDate!.day.toString().padLeft(2, '0')}'
            : null,
        'preferred_time': _preferredTime,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _confirmCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard Request?'),
        content: const Text('Are you sure you want to cancel this request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: _errorColor),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) Navigator.of(context).pop();
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      appBar: AppBar(
        backgroundColor: _darkBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: _textSecondary,
            size: 20,
          ),
          onPressed: _goBack,
        ),
        title: Text(
          _categoryName != null
              ? '$_categoryName Request'
              : 'New Service Request',
          style: GoogleFonts.inter(
            color: _textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _confirmCancel,
            child: const Text(
              'Cancel',
              style: TextStyle(color: _errorColor, fontSize: 14),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _borderColor),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildStepIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                  _buildStep4(),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ─── Step Indicator ────────────────────────────────────────────────────────

  Widget _buildStepIndicator() {
    final labels = ['Service', 'Location', 'Photos', 'Review'];
    return Container(
      color: _cardBg,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      child: Row(
        children: List.generate(4, (i) {
          final isActive = i == _currentStep;
          final isDone = i < _currentStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isDone
                                  ? Colors.green
                                  : isActive
                                  ? _accentBlue
                                  : _fieldBg,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDone
                                    ? Colors.green
                                    : isActive
                                    ? _accentBlue
                                    : _borderColor,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: isDone
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 14,
                                    )
                                  : Text(
                                      '${i + 1}',
                                      style: TextStyle(
                                        color: isActive
                                            ? Colors.white
                                            : _textHint,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 0.4.h),
                      Text(
                        labels[i],
                        style: TextStyle(
                          color: isActive
                              ? _accentBlue
                              : isDone
                              ? Colors.green
                              : _textHint,
                          fontSize: 10,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < 3)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      color: i < _currentStep ? Colors.green : _borderColor,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ─── Step 1: Service & Description ────────────────────────────────────────

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category + Service banner (read-only)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _accentBlue.withValues(alpha: 0.10),
                  _accentBlue.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(color: _accentBlue.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (_categoryName ?? '').toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF2B2B2B),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.3.h),
                Text(
                  (_serviceName ?? '').toUpperCase(),
                  style: GoogleFonts.inter(
                    color: const Color(0xFF1F1F1F),
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 2.5.h),
          _buildSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionLabel('DESCRIPTION', required: true),
                SizedBox(height: 1.2.h),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 5,
                  minLines: 4,
                  style: const TextStyle(color: _textPrimary, fontSize: 14),
                  onChanged: (_) {
                    if (_descriptionError != null) {
                      setState(() => _descriptionError = null);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Describe the problem or service you need.',
                    hintStyle: const TextStyle(color: _textHint, fontSize: 13),
                    errorText: _descriptionError,
                    errorStyle: const TextStyle(color: _errorColor),
                    filled: true,
                    fillColor: _fieldBg,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 1.5.h,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(color: _borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(color: _borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(
                        color: _accentBlue,
                        width: 1.5,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(color: _errorColor),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(
                        color: _errorColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Minimum 10 characters',
                  style: TextStyle(color: _textHint, fontSize: 11),
                ),
                SizedBox(height: 1.5.h),
                Text(
                  'Quick start suggestions',
                  style: TextStyle(
                    color: _textHint,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 0.8.h),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      [
                        'I need help with',
                        'There is a problem with',
                        'I would like to repair',
                      ].map((suggestion) {
                        return _SuggestionChip(
                          label: suggestion,
                          onTap: () {
                            final controller = _descriptionController;
                            final currentText = controller.text;
                            final selection = controller.selection;
                            final insertText = currentText.isEmpty
                                ? suggestion
                                : (selection.isValid && selection.start >= 0
                                      ? currentText.substring(
                                              0,
                                              selection.start,
                                            ) +
                                            suggestion +
                                            currentText.substring(selection.end)
                                      : currentText + suggestion);
                            controller.value = TextEditingValue(
                              text: insertText,
                              selection: TextSelection.collapsed(
                                offset: insertText.length,
                              ),
                            );
                            if (_descriptionError != null) {
                              setState(() => _descriptionError = null);
                            }
                          },
                        );
                      }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 2: Location & Vehicle ────────────────────────────────────────────

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location
          _buildSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionLabel('Service location', required: true),
                SizedBox(height: 1.2.h),
                TextFormField(
                  controller: _locationController,
                  style: const TextStyle(color: _textPrimary, fontSize: 14),
                  onChanged: (_) {
                    if (_locationError != null) {
                      setState(() => _locationError = null);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'ZIP code, area, or address',
                    hintStyle: const TextStyle(color: _textHint, fontSize: 13),
                    errorText: _locationError,
                    errorStyle: const TextStyle(color: _errorColor),
                    filled: true,
                    fillColor: _fieldBg,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 1.5.h,
                    ),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(
                        Icons.location_on_outlined,
                        color: _textSecondary,
                        size: 20,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(color: _borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(color: _borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(
                        color: _accentBlue,
                        width: 1.5,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(color: _errorColor),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(
                        color: _errorColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 1.h),
                GestureDetector(
                  onTap: _useCurrentLocation,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.h,
                    ),
                    decoration: BoxDecoration(
                      color: _accentBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(
                        color: _accentBlue.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.my_location,
                          color: _accentBlue,
                          size: 16,
                        ),
                        SizedBox(width: 2.w),
                        const Text(
                          'Use my current location',
                          style: TextStyle(
                            color: _accentBlue,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          // Vehicle
          _buildSectionCard(
            child: _loadingVehicles
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _accentBlue,
                      ),
                    ),
                  )
                : _buildVehicleSection(),
          ),
          SizedBox(height: 2.h),
          // Preferred Date & Time
          _buildSectionCard(child: _buildPreferredDateTimeSection()),
        ],
      ),
    );
  }

  Widget _buildVehicleSection() {
    if (_savedVehicles.isNotEmpty && !_addingNewVehicle) {
      return _buildSavedVehicleSelector();
    }
    return _buildNewVehicleForm();
  }

  Widget _buildSavedVehicleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Vehicle', required: true),
        SizedBox(height: 1.2.h),
        // List of saved vehicles
        ..._savedVehicles.map((vehicle) {
          final isSelected = _selectedSavedVehicle?['id'] == vehicle['id'];
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedSavedVehicle = vehicle;
                _vehicleError = null;
              });
            },
            child: Container(
              margin: EdgeInsets.only(bottom: 1.h),
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.2.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? _accentBlue.withValues(alpha: 0.08)
                    : _fieldBg,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: isSelected ? _accentBlue : _borderColor,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? _accentBlue : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? _accentBlue : _borderColor,
                        width: 1.5,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 12)
                        : null,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${vehicle['make']} ${vehicle['model']}',
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${vehicle['year']}',
                          style: TextStyle(color: _textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        if (_vehicleError != null) ...[
          SizedBox(height: 0.5.h),
          Text(
            _vehicleError!,
            style: const TextStyle(color: _errorColor, fontSize: 12),
          ),
        ],
        SizedBox(height: 1.h),
        // Add new vehicle button
        GestureDetector(
          onTap: () {
            setState(() {
              _addingNewVehicle = true;
              _selectedSavedVehicle = null;
              _selectedMake = null;
              _selectedModel = null;
              _selectedYear = null;
              _customModelController.clear();
              _vehicleError = null;
            });
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.2.h),
            decoration: BoxDecoration(
              color: _accentBlue.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: _accentBlue.withValues(alpha: 0.35),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.add_circle_outline,
                  color: _accentBlue,
                  size: 18,
                ),
                SizedBox(width: 2.w),
                const Text(
                  'Add new vehicle',
                  style: TextStyle(
                    color: _accentBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewVehicleForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionLabel('New Vehicle', required: true),
            const Spacer(),
            if (_savedVehicles.isNotEmpty)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _addingNewVehicle = false;
                    _selectedSavedVehicle = _savedVehicles.first;
                    _vehicleError = null;
                  });
                },
                child: const Text(
                  'Use saved vehicle',
                  style: TextStyle(
                    color: _accentBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 1.2.h),
        _buildVehicleDropdownLabel('Vehicle Make'),
        SizedBox(height: 0.5.h),
        _buildDropdown<String>(
          hint: 'Select make',
          value: _selectedMake,
          items: _vehicleModels.keys.toList(),
          itemLabel: (v) => v,
          onChanged: (v) {
            setState(() {
              _selectedMake = v;
              _selectedModel = null;
              _customModelController.clear();
              if (_vehicleError != null) _vehicleError = null;
            });
          },
        ),
        SizedBox(height: 1.2.h),
        _buildVehicleDropdownLabel('Vehicle Model'),
        SizedBox(height: 0.5.h),
        _buildDropdown<String>(
          hint: _selectedMake == null ? 'Select make first' : 'Select model',
          value: _selectedModel,
          items: _selectedMake != null
              ? [...(_vehicleModels[_selectedMake] ?? []), _otherModelOption]
              : [],
          itemLabel: (v) => v,
          onChanged: _selectedMake == null
              ? null
              : (v) {
                  setState(() {
                    _selectedModel = v;
                    _customModelController.clear();
                    if (_vehicleError != null) _vehicleError = null;
                  });
                },
        ),
        if (_selectedModel == _otherModelOption) ...[
          SizedBox(height: 1.2.h),
          _buildVehicleDropdownLabel('Enter vehicle model manually'),
          SizedBox(height: 0.5.h),
          TextFormField(
            controller: _customModelController,
            style: const TextStyle(color: _textPrimary, fontSize: 14),
            onChanged: (_) {
              if (_vehicleError != null) setState(() => _vehicleError = null);
            },
            decoration: InputDecoration(
              hintText: 'e.g. Supra, Prado, Hilux…',
              hintStyle: const TextStyle(color: _textHint, fontSize: 13),
              filled: true,
              fillColor: _fieldBg,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 3.w,
                vertical: 1.2.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: const BorderSide(color: _borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: const BorderSide(color: _borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: const BorderSide(color: _accentBlue, width: 1.5),
              ),
            ),
          ),
        ],
        SizedBox(height: 1.2.h),
        _buildVehicleDropdownLabel('Vehicle Year'),
        SizedBox(height: 0.5.h),
        _buildDropdown<String>(
          hint: 'Select year',
          value: _selectedYear,
          items: List.generate(26, (i) => (2025 - i).toString()),
          itemLabel: (v) => v,
          onChanged: (v) {
            setState(() {
              _selectedYear = v;
              if (_vehicleError != null) _vehicleError = null;
            });
          },
        ),
        if (_vehicleError != null) ...[
          SizedBox(height: 0.5.h),
          Text(
            _vehicleError!,
            style: const TextStyle(color: _errorColor, fontSize: 12),
          ),
        ],
        SizedBox(height: 1.2.h),
        GestureDetector(
          onTap: () =>
              setState(() => _saveVehicleToProfile = !_saveVehicleToProfile),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: _saveVehicleToProfile ? _accentBlue : _fieldBg,
                  borderRadius: BorderRadius.circular(6.0),
                  border: Border.all(
                    color: _saveVehicleToProfile ? _accentBlue : _borderColor,
                  ),
                ),
                child: _saveVehicleToProfile
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
              SizedBox(width: 2.w),
              const Expanded(
                child: Text(
                  'Save this vehicle to my profile',
                  style: TextStyle(color: _textPrimary, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleDropdownLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: _textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String hint,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?)? onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.2.h),
      decoration: BoxDecoration(
        color: _fieldBg,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: _borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: _cardBg,
          style: const TextStyle(color: _textPrimary, fontSize: 14),
          hint: Text(
            hint,
            style: const TextStyle(color: _textHint, fontSize: 13),
          ),
          icon: const Icon(Icons.keyboard_arrow_down, color: _textSecondary),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(
                itemLabel(item),
                overflow: TextOverflow.ellipsis,
                style: item.toString() == _otherModelOption
                    ? const TextStyle(
                        color: _accentBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      )
                    : null,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ─── Step 3: Photos ────────────────────────────────────────────────────────

  Widget _buildStep3() {
    final required = _isPhotoRequired();
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildSectionLabel('Photos', required: required),
                    if (!required)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: const Text(
                          'Optional',
                          style: TextStyle(
                            color: _textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 1.h),
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: required
                        ? const Color(0xFFFFF3CD)
                        : _accentBlue.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                      color: required
                          ? const Color(0xFFFFD700).withValues(alpha: 0.5)
                          : _accentBlue.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        required
                            ? Icons.warning_amber_rounded
                            : Icons.info_outline,
                        color: required ? const Color(0xFFB8860B) : _accentBlue,
                        size: 18,
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          required
                              ? 'Upload photos of the problem. Photos are required so technicians can understand the issue and estimate the job.'
                              : 'Upload photos (optional). Photos help technicians understand the request faster.',
                          style: TextStyle(
                            color: required
                                ? const Color(0xFF7A5C00)
                                : _textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 1.5.h),
                // Photo grid
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._mediaFiles.asMap().entries.map((entry) {
                      final index = entry.key;
                      final uploadedUrl = index < _uploadedPhotoUrls.length
                          ? _uploadedPhotoUrls[index]
                          : null;
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10.0),
                            child: uploadedUrl != null
                                ? Image.network(
                                    uploadedUrl,
                                    width: 22.w,
                                    height: 22.w,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (ctx, child, progress) {
                                      if (progress == null) return child;
                                      return Container(
                                        width: 22.w,
                                        height: 22.w,
                                        color: _fieldBg,
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: _accentBlue,
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 22.w,
                                      height: 22.w,
                                      color: _fieldBg,
                                      child: const Icon(
                                        Icons.broken_image_outlined,
                                        color: _textHint,
                                        size: 28,
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 22.w,
                                    height: 22.w,
                                    color: _fieldBg,
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: _accentBlue,
                                      ),
                                    ),
                                  ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removePhoto(index),
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  color: _errorColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                    if (_mediaFiles.length < 5)
                      GestureDetector(
                        onTap: _showPickerOptions,
                        child: Container(
                          width: 22.w,
                          height: 22.w,
                          decoration: BoxDecoration(
                            color: _fieldBg,
                            borderRadius: BorderRadius.circular(10.0),
                            border: Border.all(
                              color: _accentBlue.withValues(alpha: 0.35),
                            ),
                          ),
                          child: _mediaLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: _accentBlue,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate,
                                      color: _accentBlue,
                                      size: 24,
                                    ),
                                    SizedBox(height: 0.4.h),
                                    Text(
                                      'Add',
                                      style: TextStyle(
                                        color: _textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 0.8.h),
                Text(
                  '${_mediaFiles.length}/5 photos',
                  style: const TextStyle(color: _textHint, fontSize: 11),
                ),
                if (_photoError != null) ...[
                  SizedBox(height: 0.5.h),
                  Text(
                    _photoError!,
                    style: const TextStyle(color: _errorColor, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 4: Review ───────────────────────────────────────────────────────

  Widget _buildStep4() {
    // Build formatted date string for review
    String reviewDate() {
      if (_preferredDate == null) return '—';
      const months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      return '${months[_preferredDate!.month - 1]} ${_preferredDate!.day}, ${_preferredDate!.year}';
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _accentBlue.withValues(alpha: 0.10),
                  _accentBlue.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(color: _accentBlue.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.checklist_rounded,
                  color: _accentBlue,
                  size: 22,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Review Your Request',
                        style: GoogleFonts.inter(
                          color: _textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 0.3.h),
                      Text(
                        'Please confirm the details before submitting.',
                        style: TextStyle(color: _textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),

          // Service card
          _buildReviewCard(
            icon: Icons.build_outlined,
            title: 'Service',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReviewRow('Category', _categoryName ?? '—'),
                SizedBox(height: 0.8.h),
                _buildReviewRow('Service', _serviceName ?? '—'),
              ],
            ),
          ),
          SizedBox(height: 1.5.h),

          // Location card
          _buildReviewCard(
            icon: Icons.location_on_outlined,
            title: 'Location',
            child: _buildReviewRow(
              'Address',
              _locationController.text.trim().isNotEmpty
                  ? _locationController.text.trim()
                  : '—',
            ),
          ),
          SizedBox(height: 1.5.h),

          // Schedule card
          _buildReviewCard(
            icon: Icons.calendar_month_outlined,
            title: 'Schedule',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReviewRow('Date', reviewDate()),
                SizedBox(height: 0.8.h),
                _buildReviewRow(
                  'Time',
                  _preferredTime.isNotEmpty ? _preferredTime : 'Flexible',
                ),
              ],
            ),
          ),
          SizedBox(height: 1.5.h),

          // Description card
          _buildReviewCard(
            icon: Icons.description_outlined,
            title: 'Description',
            child: Text(
              _descriptionController.text.trim().isNotEmpty
                  ? _descriptionController.text.trim()
                  : '—',
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ),
          SizedBox(height: 1.5.h),

          // Photos card
          _buildReviewCard(
            icon: Icons.photo_library_outlined,
            title: 'Photos',
            child: _uploadedPhotoUrls.isEmpty
                ? Text(
                    'No photos added',
                    style: TextStyle(color: _textHint, fontSize: 14),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _uploadedPhotoUrls.map((url) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          url,
                          width: 18.w,
                          height: 18.w,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 18.w,
                            height: 18.w,
                            color: _fieldBg,
                            child: const Icon(
                              Icons.broken_image_outlined,
                              color: _textHint,
                              size: 24,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildReviewCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.8.h),
      decoration: BoxDecoration(
        color: _sectionBg,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  color: _accentBlue,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
              SizedBox(width: 2.w),
              Icon(icon, color: _accentBlue, size: 20),
              SizedBox(width: 1.5.w),
              Text(
                title.toUpperCase(),
                style: GoogleFonts.inter(
                  color: const Color(0xFF1A1A2A),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.4.h),
          child,
        ],
      ),
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 22.w,
          child: Text(
            label,
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 3,
          ),
        ),
      ],
    );
  }

  // ─── Bottom Bar ────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    final isLastStep = _currentStep == 3;
    final isPhotosStep = _currentStep == 2;
    final photosOptional = !_isPhotoRequired();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: _cardBg,
        border: const Border(top: BorderSide(color: _borderColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: _goBack,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(color: _textSecondary, fontSize: 14),
                ),
              ),
            ),
          if (_currentStep > 0) SizedBox(width: 3.w),
          Expanded(
            flex: 2,
            child: isLastStep
                ? _buildPrimaryButton(
                    label: 'Submit Request',
                    onTap: _isSubmitting ? null : _submitRequest,
                    isLoading: _isSubmitting,
                  )
                : isPhotosStep
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildPrimaryButton(
                        label: 'Continue to Review',
                        onTap: _goNext,
                      ),
                      if (photosOptional && _mediaFiles.isEmpty) ...[
                        SizedBox(height: 0.8.h),
                        GestureDetector(
                          onTap: _goNext,
                          child: const Text(
                            'Skip photos and continue',
                            style: TextStyle(
                              color: _textSecondary,
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ],
                  )
                : _buildPrimaryButton(label: 'Continue', onTap: _goNext),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return Container(
      width: double.infinity,
      height: 6.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: (onTap == null && !isLoading)
              ? [Colors.grey.shade400, Colors.grey.shade500]
              : [_accentBlue, const Color(0xFF1A2B4A)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14.0),
        boxShadow: onTap == null
            ? []
            : [
                BoxShadow(
                  color: _accentBlue.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14.0),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: _sectionBg,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionLabel(String label, {bool required = false}) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: _accentBlue,
            borderRadius: BorderRadius.circular(2.0),
          ),
        ),
        SizedBox(width: 2.w),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            color: const Color(0xFF3A3A3A),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (required) ...[
          SizedBox(width: 1.w),
          const Text('*', style: TextStyle(color: _errorColor, fontSize: 15)),
        ],
      ],
    );
  }

  // ─── Preferred Date & Time ─────────────────────────────────────────────────

  Widget _buildPreferredDateTimeSection() {
    final timeOptions = [
      'Morning (8:00 – 12:00)',
      'Afternoon (12:00 – 16:00)',
      'Evening (16:00 – 20:00)',
      'Flexible',
    ];
    final now = DateTime.now();
    final maxDate = now.add(const Duration(days: 60));

    String? displayDate;
    if (_preferredDate != null) {
      const months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      displayDate =
          '${months[_preferredDate!.month - 1]} ${_preferredDate!.day}, ${_preferredDate!.year}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Preferred Date & Time', required: false),
        SizedBox(height: 1.2.h),
        // Date picker field
        Text(
          'Select preferred date',
          style: const TextStyle(
            color: _textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 0.5.h),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _preferredDate ?? now,
              firstDate: now,
              lastDate: maxDate,
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: _accentBlue,
                    onPrimary: Colors.white,
                    surface: _cardBg,
                    onSurface: _textPrimary,
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) {
              setState(() => _preferredDate = picked);
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.4.h),
            decoration: BoxDecoration(
              color: _fieldBg,
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: _borderColor),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: _textSecondary,
                  size: 18,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    displayDate ?? 'Tap to select a date',
                    style: TextStyle(
                      color: displayDate != null ? _textPrimary : _textHint,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (_preferredDate != null)
                  GestureDetector(
                    onTap: () => setState(() => _preferredDate = null),
                    child: const Icon(Icons.close, color: _textHint, size: 16),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(height: 1.5.h),
        // Time selector
        Text(
          'Preferred time',
          style: const TextStyle(
            color: _textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 0.8.h),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: timeOptions.map((option) {
            final isSelected = _preferredTime == option;
            return GestureDetector(
              onTap: () => setState(() => _preferredTime = option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _accentBlue.withValues(alpha: 0.10)
                      : _cardBg,
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(
                    color: isSelected ? _accentBlue : _borderColor,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    color: isSelected ? _accentBlue : const Color(0xFF2B2B2B),
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 0.8.h),
        Text(
          'Optional — if not selected, Flexible will be used.',
          style: TextStyle(color: _textHint, fontSize: 11),
        ),
      ],
    );
  }
}

class _SuggestionChip extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({required this.label, required this.onTap});

  @override
  State<_SuggestionChip> createState() => _SuggestionChipState();
}

class _SuggestionChipState extends State<_SuggestionChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _pressed ? const Color(0xFFF3F4F6) : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: _pressed ? const Color(0xFF2C3E63) : const Color(0xFFDCDCDC),
            width: 1,
          ),
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            color: _pressed ? const Color(0xFF2C3E63) : const Color(0xFF2B2B2B),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
