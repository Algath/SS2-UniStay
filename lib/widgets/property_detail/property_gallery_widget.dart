import 'package:flutter/material.dart';

class PropertyGalleryWidget extends StatefulWidget {
  final List<String> photoUrls;
  final bool isTablet;

  const PropertyGalleryWidget({
    super.key,
    required this.photoUrls,
    required this.isTablet,
  });

  @override
  State<PropertyGalleryWidget> createState() => _PropertyGalleryWidgetState();
}

class _PropertyGalleryWidgetState extends State<PropertyGalleryWidget> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 1.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasPhotos = widget.photoUrls.isNotEmpty;
    return Container(
      width: double.infinity,
      height: widget.isTablet ? 300 : 250,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: hasPhotos
            ? Stack(
                children: [
                  PageView.builder(
                    controller: _controller,
                    itemCount: widget.photoUrls.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) {
                      final url = widget.photoUrls[i];
                      return Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade200,
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_index + 1}/${widget.photoUrls.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              )
            : Container(
                color: Colors.grey.shade200,
                child: Icon(
                  Icons.apartment,
                  size: 60,
                  color: Colors.grey[400],
                ),
              ),
      ),
    );
  }
}


