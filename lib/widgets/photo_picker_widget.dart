import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PhotoPickerWidget extends StatefulWidget {
  final List<File> localPhotos;
  final List<Uint8List> webPhotos;
  final Function() onPickPhotos;
  final Function(int) onRemovePhoto;
  final int maxPhotos;
  final bool showPhotoCount;

  const PhotoPickerWidget({
    super.key,
    required this.localPhotos,
    required this.webPhotos,
    required this.onPickPhotos,
    required this.onRemovePhoto,
    this.maxPhotos = 10,
    this.showPhotoCount = true,
  });

  @override
  State<PhotoPickerWidget> createState() => _PhotoPickerWidgetState();
}

class _PhotoPickerWidgetState extends State<PhotoPickerWidget> {
  final ImagePicker _picker = ImagePicker();

  int get _photoCount => kIsWeb ? widget.webPhotos.length : widget.localPhotos.length;
  bool get _canAddMorePhotos => _photoCount < widget.maxPhotos;

  Future<void> _pickPhotos() async {
    try {
      if (!_canAddMorePhotos) {
        _showMaxPhotosDialog();
        return;
      }

      final remainingSlots = widget.maxPhotos - _photoCount;
      final images = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (images.isEmpty) return;

      // Limit to available slots
      final imagesToProcess = images.take(remainingSlots).toList();

      if (kIsWeb) {
        for (final image in imagesToProcess) {
          final bytes = await image.readAsBytes();
          widget.webPhotos.add(bytes);
        }
      } else {
        for (final image in imagesToProcess) {
          widget.localPhotos.add(File(image.path));
        }
      }

      if (images.length > remainingSlots) {
        _showPhotosLimitedDialog(images.length - remainingSlots);
      }

      setState(() {});
    } catch (e) {
      _showErrorDialog('Failed to pick photos: $e');
    }
  }

  void _removePhoto(int index) {
    widget.onRemovePhoto(index);
    setState(() {});
  }

  void _showMaxPhotosDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Maximum Photos Reached'),
        content: Text('You can only add up to ${widget.maxPhotos} photos per property.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPhotosLimitedDialog(int skippedCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Photos Limited'),
        content: Text('$skippedCount photo(s) were not added to stay within the ${widget.maxPhotos} photo limit.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAddPhotosButton(),
        if (_photoCount > 0) ...[
          const SizedBox(height: 16),
          _buildPhotoCountInfo(),
          const SizedBox(height: 12),
          _buildPhotosGrid(),
        ] else
          _buildEmptyState(),
      ],
    );
  }

  Widget _buildAddPhotosButton() {
    return OutlinedButton.icon(
      onPressed: _canAddMorePhotos ? _pickPhotos : null,
      icon: const Icon(Icons.add_photo_alternate_outlined),
      label: Text(_canAddMorePhotos ? 'Add Photos' : 'Maximum Photos Reached'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        foregroundColor: _canAddMorePhotos ? null : Colors.grey,
      ),
    );
  }

  Widget _buildPhotoCountInfo() {
    if (!widget.showPhotoCount) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.photo_library, color: Colors.blue[600], size: 16),
          const SizedBox(width: 8),
          Text(
            '$_photoCount of ${widget.maxPhotos} photos',
            style: TextStyle(
              color: Colors.blue[700],
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          if (_canAddMorePhotos)
            Text(
              '${widget.maxPhotos - _photoCount} more allowed',
              style: TextStyle(
                color: Colors.blue[600],
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                color: Colors.grey[400], size: 48),
            const SizedBox(height: 12),
            Text(
              'No photos added yet',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add photos to showcase your property',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosGrid() {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) => _buildPhotoItem(index),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: _photoCount,
      ),
    );
  }

  Widget _buildPhotoItem(int index) {
    return Stack(
      children: [
        Container(
          width: 160,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: kIsWeb
                ? Image.memory(
              widget.webPhotos[index],
              width: 160,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
            )
                : Image.file(
              widget.localPhotos[index],
              width: 160,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(15),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.close,
                color: Colors.white,
                size: 18,
              ),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              onPressed: () => _removePhoto(index),
            ),
          ),
        ),
        Positioned(
          bottom: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorImage() {
    return Container(
      width: 160,
      height: 120,
      color: Colors.grey[300],
      child: const Icon(
        Icons.broken_image,
        color: Colors.grey,
        size: 40,
      ),
    );
  }
}