import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final void Function(XFile image)? onImageSelected;

  const ImagePickerCard({
    super.key,
    required this.title,
    this.icon = Icons.add_a_photo_outlined,
    this.onImageSelected,
  });

  @override
  State<ImagePickerCard> createState() => _ImagePickerCardState();
}

class _ImagePickerCardState extends State<ImagePickerCard> {
  XFile? _image;
  final _picker = ImagePicker();

  Future<void> _showSourceDialog() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text('Choose from Gallery',
                  style: GoogleFonts.poppins()),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text('Take a Photo', style: GoogleFonts.poppins()),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      setState(() => _image = picked);
      widget.onImageSelected?.call(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showSourceDialog,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _image != null
                ? const Color(0xFF2E7D32)
                : Colors.grey.withValues(alpha: 0.4),
            width: _image != null ? 2 : 1,
          ),
        ),
        child: _image == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 10),
                  Text(
                    widget.title,
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to add from gallery or camera',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 11,
                    ),
                  ),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      File(_image!.path),
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _showSourceDialog,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.edit,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
