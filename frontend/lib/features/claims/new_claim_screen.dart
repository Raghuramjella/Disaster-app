import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../providers/claim_provider.dart';
import '../../services/notification_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/image_picker_card.dart';
import 'map_picker_screen.dart';

class NewClaimScreen extends ConsumerStatefulWidget {
  const NewClaimScreen({super.key});

  @override
  ConsumerState<NewClaimScreen> createState() => _NewClaimScreenState();
}

class _NewClaimScreenState extends ConsumerState<NewClaimScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _propertyValueCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  String? _selectedDisasterType;
  String? _selectedPropertyType;
  DateTime? _incidentDate;
  XFile? _pickedImage;
  double? _pickedLatitude;
  double? _pickedLongitude;
  bool _isSubmitting = false;
  bool _imageMissing = false;

  final List<String> _propertyTypes = [
    'Residential',
    'Commercial',
    'Agricultural',
    'Vehicle',
    'Livestock',
  ];

  int _statusIndex = 0;
  final List<String> _statusMessages = [
    'Uploading images...',
    'Running AI analysis...',
    'Comparing damage patterns...',
    'Calculating compensation...',
    'Finalizing report...',
  ];

  @override
  void dispose() {
    _locationCtrl.dispose();
    _descriptionCtrl.dispose();
    _propertyValueCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _cycleStatus() async {
    while (mounted && _isSubmitting) {
      for (var i = 0; i < _statusMessages.length; i++) {
        if (!mounted || !_isSubmitting) return;
        setState(() => _statusIndex = i);
        await Future.delayed(const Duration(milliseconds: 700));
      }
    }
  }

  Future<void> _handleSubmit() async {
    setState(() => _imageMissing = _pickedImage == null);
    if (!_formKey.currentState!.validate() || _pickedImage == null) return;

    setState(() {
      _isSubmitting = true;
      _statusIndex = 0;
    });

    _cycleStatus();

    try {
      final propertyValue = double.parse(_propertyValueCtrl.text.trim());
      final report = await ref.read(claimProvider.notifier).submitClaim(
            disasterType: _selectedDisasterType!,
            location: _locationCtrl.text.trim(),
            description: _descriptionCtrl.text.trim(),
            propertyType: _selectedPropertyType!,
            propertyValue: propertyValue,
            incidentDate: _incidentDate!,
            imagePath: _pickedImage!.path,
            latitude: _pickedLatitude,
            longitude: _pickedLongitude,
          );
      await NotificationService.showClaimVerified(
        disasterType: _selectedDisasterType!,
        compensation: report.compensationAmount,
      );
      if (mounted) {
        context.pushReplacement('/report', extra: report);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission failed: ${e.toString()}'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSubmitting,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: const Color(0xFF2E7D32),
          title: const Text(
            'New Claim',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: _isSubmitting ? null : () => context.pop(),
          ),
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FadeInDown(
                      duration: const Duration(milliseconds: 400),
                      child: const Text(
                        'Claim Details',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    FadeInDown(
                      delay: const Duration(milliseconds: 50),
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        'Fill in all fields accurately for faster verification',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FadeInUp(
                      delay: const Duration(milliseconds: 100),
                      duration: const Duration(milliseconds: 400),
                      child: CustomTextField(
                        label: 'Incident Location',
                        prefixIcon: Icons.location_on_outlined,
                        controller: _locationCtrl,
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.map_outlined,
                            color: Color(0xFF2E7D32),
                          ),
                          tooltip: 'Pick from map',
                          onPressed: () async {
                            final result = await Navigator.push<
                                ({
                                  String address,
                                  double latitude,
                                  double longitude
                                })>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MapPickerScreen(),
                              ),
                            );
                            if (result != null && mounted) {
                              _locationCtrl.text = result.address;
                              _pickedLatitude = result.latitude;
                              _pickedLongitude = result.longitude;
                            }
                          },
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Location is required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeInUp(
                      delay: const Duration(milliseconds: 150),
                      duration: const Duration(milliseconds: 400),
                      child: DropdownButtonFormField<String>(
                        value: _selectedDisasterType,
                        decoration: InputDecoration(
                          labelText: 'Disaster Type',
                          prefixIcon: const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFF2E7D32),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF2E7D32),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          labelStyle: const TextStyle(fontFamily: 'Poppins'),
                        ),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.black87,
                          fontSize: 15,
                        ),
                        items: AppConstants.disasterTypes
                            .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t),
                                ))
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedDisasterType = val),
                        validator: (val) =>
                            val == null ? 'Please select a disaster type' : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeInUp(
                      delay: const Duration(milliseconds: 200),
                      duration: const Duration(milliseconds: 400),
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: Color(0xFF2E7D32),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() {
                              _incidentDate = picked;
                              _dateCtrl.text =
                                  DateFormat('d MMM yyyy').format(picked);
                            });
                          }
                        },
                        child: AbsorbPointer(
                          child: TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Incident Date',
                              prefixIcon: const Icon(
                                Icons.calendar_today_outlined,
                                color: Color(0xFF2E7D32),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF2E7D32),
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              labelStyle: const TextStyle(fontFamily: 'Poppins'),
                            ),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                            ),
                            controller: _dateCtrl,
                            validator: (_) {
                              if (_incidentDate == null) {
                                return 'Please select the incident date';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeInUp(
                      delay: const Duration(milliseconds: 250),
                      duration: const Duration(milliseconds: 400),
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedPropertyType,
                        decoration: InputDecoration(
                          labelText: 'Property Type',
                          prefixIcon: const Icon(
                            Icons.home_outlined,
                            color: Color(0xFF2E7D32),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF2E7D32),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          labelStyle: const TextStyle(fontFamily: 'Poppins'),
                        ),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.black87,
                          fontSize: 15,
                        ),
                        items: _propertyTypes
                            .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t),
                                ))
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedPropertyType = val),
                        validator: (val) =>
                            val == null ? 'Please select a property type' : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeInUp(
                      delay: const Duration(milliseconds: 300),
                      duration: const Duration(milliseconds: 400),
                      child: CustomTextField(
                        label: 'Estimated Property Value (₹)',
                        prefixIcon: Icons.currency_rupee,
                        controller: _propertyValueCtrl,
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Property value is required';
                          }
                          final parsed = double.tryParse(val);
                          if (parsed == null) {
                            return 'Enter a valid number';
                          }
                          if (parsed <= 0) {
                            return 'Value must be greater than 0';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeInUp(
                      delay: const Duration(milliseconds: 350),
                      duration: const Duration(milliseconds: 400),
                      child: CustomTextField(
                        label: 'Incident Description',
                        prefixIcon: Icons.notes_outlined,
                        controller: _descriptionCtrl,
                        maxLines: 4,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Description is required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeInUp(
                      delay: const Duration(milliseconds: 400),
                      duration: const Duration(milliseconds: 400),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Post-Disaster Photo',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Upload a clear photo showing the damage for AI verification',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 12),
                          ImagePickerCard(
                            title: 'Upload Photo',
                            icon: Icons.add_photo_alternate_outlined,
                            onImageSelected: (file) {
                              setState(() {
                                _pickedImage = file;
                                _imageMissing = false;
                              });
                            },
                          ),
                          if (_imageMissing)
                            Padding(
                              padding: const EdgeInsets.only(top: 6, left: 4),
                              child: Text(
                                'Please upload a photo',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: Colors.red[700],
                                ),
                              ),
                            ),
                          if (_pickedImage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF2E7D32),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Photo selected: ${_pickedImage!.name}',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        color: Color(0xFF2E7D32),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeInUp(
                      delay: const Duration(milliseconds: 450),
                      duration: const Duration(milliseconds: 400),
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        icon: const Icon(Icons.verified_outlined),
                        label: const Text(
                          'Submit & Verify Claim',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            if (_isSubmitting)
              Container(
                color: Colors.black87,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 56,
                        height: 56,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'AI Verification',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: Text(
                          _statusMessages[_statusIndex],
                          key: ValueKey(_statusIndex),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please do not close this screen',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
