import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FacebookImageGrid extends StatelessWidget {
  final List<String> imageUrls;
  final double maxHeight;

  const FacebookImageGrid({
    super.key,
    required this.imageUrls,
    this.maxHeight = 320,
  });

  void _openLightbox(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ImageLightboxGallery(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();

    final count = imageUrls.length;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      height: maxHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: _buildLayout(context, count),
    );
  }

  Widget _buildLayout(BuildContext context, int count) {
    if (count == 1) {
      return _buildImageTile(context, imageUrls[0], 0);
    } else if (count == 2) {
      return Row(
        children: [
          Expanded(child: _buildImageTile(context, imageUrls[0], 0)),
          const SizedBox(width: 3),
          Expanded(child: _buildImageTile(context, imageUrls[1], 1)),
        ],
      );
    } else if (count == 3) {
      return Row(
        children: [
          Expanded(
            flex: 6,
            child: _buildImageTile(context, imageUrls[0], 0),
          ),
          const SizedBox(width: 3),
          Expanded(
            flex: 4,
            child: Column(
              children: [
                Expanded(child: _buildImageTile(context, imageUrls[1], 1)),
                const SizedBox(height: 3),
                Expanded(child: _buildImageTile(context, imageUrls[2], 2)),
              ],
            ),
          ),
        ],
      );
    } else if (count == 4) {
      return Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildImageTile(context, imageUrls[0], 0)),
                const SizedBox(width: 3),
                Expanded(child: _buildImageTile(context, imageUrls[1], 1)),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildImageTile(context, imageUrls[2], 2)),
                const SizedBox(width: 3),
                Expanded(child: _buildImageTile(context, imageUrls[3], 3)),
              ],
            ),
          ),
        ],
      );
    } else {
      // 5 or more images
      final remaining = count - 4;
      return Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildImageTile(context, imageUrls[0], 0)),
                const SizedBox(width: 3),
                Expanded(child: _buildImageTile(context, imageUrls[1], 1)),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildImageTile(context, imageUrls[2], 2)),
                const SizedBox(width: 3),
                Expanded(
                  child: _buildImageTile(
                    context,
                    imageUrls[3],
                    3,
                    remainingOverlay: remaining,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _buildImageTile(
    BuildContext context,
    String url,
    int index, {
    int remainingOverlay = 0,
  }) {
    return GestureDetector(
      onTap: () => _openLightbox(context, index),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey.withAlpha(40),
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey.withAlpha(50),
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
          if (remainingOverlay > 0)
            Container(
              color: Colors.black.withAlpha(160),
              child: Center(
                child: Text(
                  '+$remainingOverlay',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ImageLightboxGallery extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const ImageLightboxGallery({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  @override
  State<ImageLightboxGallery> createState() => _ImageLightboxGalleryState();
}

class _ImageLightboxGalleryState extends State<ImageLightboxGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        title: Text(
          '${_currentIndex + 1} / ${widget.imageUrls.length}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imageUrls.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            panEnabled: true,
            minScale: 0.8,
            maxScale: 4.0,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: widget.imageUrls[index],
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.amber),
                ),
                errorWidget: (context, url, error) => const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, size: 60, color: Colors.white54),
                    SizedBox(height: 10),
                    Text('تعذر تحميل الصورة', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
