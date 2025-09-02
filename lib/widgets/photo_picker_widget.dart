import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:unistay/services/image_optimization_service.dart';
import 'package:unistay/services/storage_service.dart'; // You'll need to provide this

class PhotoPickerWidget extends StatefulWidget {
  final List<String> uploadedPhotoUrls; // Changed to store URLs instead of files
  final Function(List<String>) onPhotosChanged;
  final int maxPhotos;
  final bool showPhotoCount;

  const PhotoPickerWidget({
    super.key,
    required this.uploadedPhotoUrls,
    required this.onPhotosChanged,
    this.maxPhotos = 3, // Changed from 10 to 3
    this.showPhotoCount = true,
  });

  @override
  State<PhotoPickerWidget> createState() => _PhotoPickerWidgetState();
}

class _PhotoPickerWidgetState extends State<PhotoPickerWidget> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  int get _photoCount => widget.uploadedPhotoUrls.length;
  bool get _canAddMorePhotos => _photoCount < widget.maxPhotos && !_isUploading;

  Future<void> _pickPhotos() async {
    try {
      if (!_canAddMorePhotos) {
        _showMaxPhotosDialog();
        return;
      }

      final remainingSlots = widget.maxPhotos - _photoCount;
      final images = await _picker.pickMultiImage(
        imageQuality: 100, // Start with high quality, we'll optimize it
        maxWidth: 2000, // Allow higher initial resolution for better optimization
        maxHeight: 2000,
      );

      if (images.isEmpty) return;

      // Limit to available slots
      final imagesToProcess = images.take(remainingSlots).toList();

      if (images.length > remainingSlots) {
        _showPhotosLimitedDialog(images.length - remainingSlots);
      }

      await _processAndUploadImages(imagesToProcess);

    } catch (e) {
      _showErrorDialog('Failed to pick photos: $e');
    }
  }

  Future<void> _processAndUploadImages(List<XFile> images) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    List<String> newUrls = [];

    try {
      for (int i = 0; i < images.length; i++) {
        final image = images[i];

        // Update progress
        setState(() {
          _uploadProgress = (i / images.length) * 0.8; // Reserve 20% for upload
        });

        // Read image bytes
        final originalBytes = await image.readAsBytes();

        // Optimize image (resize to 1200px max and convert to WebP)
        final optimizedBytes = await ImageOptimizationService.optimizeImage(originalBytes);

        // Update progress to show optimization is done
        setState(() {
          _uploadProgress = ((i + 0.8) / images.length) * 0.9;
        });

        // Upload to Firebase Storage
        final downloadUrl = await _uploadToFirebase(optimizedBytes, i);

        if (downloadUrl != null) {
          newUrls.add(downloadUrl);
        }

        // Update progress
        setState(() {
          _uploadProgress = ((i + 1) / images.length);
        });
      }

      // Update the photo URLs list
      final updatedUrls = [...widget.uploadedPhotoUrls, ...newUrls];
      widget.onPhotosChanged(updatedUrls);

    } catch (e) {
      _showErrorDialog('Failed to process and upload photos: $e');
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  Future<String?> _uploadToFirebase(Uint8List imageBytes, int index) async {
    try {
      // Generate unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = ImageOptimizationService.getOptimizedExtension();
      final fileName = 'property_${timestamp}_$index.$extension';

      // Upload to Firebase Storage (you'll need to implement this in your storage service)
      final downloadUrl = await StorageService.uploadPropertyImage(
          imageBytes,
          fileName
      );

      return downloadUrl;
    } catch (e) {
      print('Failed to upload image: $e');
      return null;
    }
  }

  void _removePhoto(int index) {
    final updatedUrls = [...widget.uploadedPhotoUrls];
    final removedUrl = updatedUrls.removeAt(index);

    // Optionally delete from Firebase Storage
    _deleteFromFirebase(removedUrl);

    widget.onPhotosChanged(updatedUrls);
    setState(() {});
  }

  Future<void> _deleteFromFirebase(String imageUrl) async {
    try {
      await StorageService.deletePropertyImage(imageUrl);
    } catch (e) {
      print('Failed to delete image from Firebase: $e');
    }
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
        if (_isUploading) _buildUploadProgress(),
        if (_photoCount > 0) ...[
          const SizedBox(height: 16),
          _buildPhotoCountInfo(),
          const SizedBox(height: 12),
          _buildPhotosGrid(),
        ] else if (!_isUploading)
          _buildEmptyState(),
      ],
    );
  }

  Widget _buildAddPhotosButton() {
    return OutlinedButton.icon(
      onPressed: _canAddMorePhotos ? _pickPhotos : null,
      icon: _isUploading
          ? const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      )
          : const Icon(Icons.add_photo_alternate_outlined),
      label: Text(_isUploading
          ? 'Processing...'
          : _canAddMorePhotos
          ? 'Add Photos'
          : 'Maximum Photos Reached'),
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

  Widget _buildUploadProgress() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.cloud_upload, color: Colors.blue[600], size: 16),
              const SizedBox(width: 8),
              Text(
                'Processing and uploading photos...',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _uploadProgress,
            backgroundColor: Colors.blue[100],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
          ),
          const SizedBox(height: 4),
          Text(
            '${(_uploadProgress * 100).toInt()}% complete',
            style: TextStyle(
              color: Colors.blue[600],
              fontSize: 12,
            ),
          ),
        ],
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
              'Add up to ${widget.maxPhotos} photos to showcase your property',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
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
            child: Image.network(
              widget.uploadedPhotoUrls[index],
              width: 160,
              height: 120,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 160,
                  height: 120,
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
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
              onPressed: _isUploading ? null : () => _removePhoto(index),
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