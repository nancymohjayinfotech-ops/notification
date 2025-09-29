import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class OptimizedImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool enableMemoryCache;
  final Duration cacheDuration;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.enableMemoryCache = true,
    this.cacheDuration = const Duration(hours: 24),
  });

  @override
  State<OptimizedImage> createState() => _OptimizedImageState();
}

class _OptimizedImageState extends State<OptimizedImage> {
  static final Map<String, ui.Image> _imageCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  
  ui.Image? _cachedImage;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(OptimizedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Check cache first
      if (widget.enableMemoryCache && _imageCache.containsKey(widget.imageUrl)) {
        final cacheTime = _cacheTimestamps[widget.imageUrl];
        if (cacheTime != null && 
            DateTime.now().difference(cacheTime) < widget.cacheDuration) {
          setState(() {
            _cachedImage = _imageCache[widget.imageUrl];
            _isLoading = false;
          });
          return;
        } else {
          // Remove expired cache
          _imageCache.remove(widget.imageUrl);
          _cacheTimestamps.remove(widget.imageUrl);
        }
      }

      // Load image
      ui.Image image;
      if (widget.imageUrl.startsWith('assets/')) {
        image = await _loadAssetImage(widget.imageUrl);
      } else {
        image = await _loadNetworkImage(widget.imageUrl);
      }

      // Cache the image
      if (widget.enableMemoryCache) {
        _imageCache[widget.imageUrl] = image;
        _cacheTimestamps[widget.imageUrl] = DateTime.now();
      }

      if (mounted) {
        setState(() {
          _cachedImage = image;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<ui.Image> _loadAssetImage(String assetPath) async {
    final data = await DefaultAssetBundle.of(context).load(assetPath);
    final bytes = data.buffer.asUint8List();
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: widget.width?.toInt(),
      targetHeight: widget.height?.toInt(),
    );
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<ui.Image> _loadNetworkImage(String url) async {
    // For demo purposes, we'll simulate network loading
    // In a real app, you would use http package or similar
    await Future.delayed(const Duration(milliseconds: 500));
    
    // For now, load a placeholder asset
    return await _loadAssetImage('assets/images/homescreen.png');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildPlaceholder();
    }

    if (_hasError) {
      return _buildErrorWidget();
    }

    if (_cachedImage != null) {
      return CustomPaint(
        size: Size(
          widget.width ?? double.infinity,
          widget.height ?? 200,
        ),
        painter: ImagePainter(
          image: _cachedImage!,
          fit: widget.fit,
        ),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return widget.placeholder ??
        Container(
          width: widget.width,
          height: widget.height ?? 200,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
  }

  Widget _buildErrorWidget() {
    return widget.errorWidget ??
        Container(
          width: widget.width,
          height: widget.height ?? 200,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(
              Icons.error_outline,
              color: Colors.grey,
              size: 40,
            ),
          ),
        );
  }

  @override
  void dispose() {
    // Don't dispose cached images as they might be used elsewhere
    super.dispose();
  }

  // Static method to clear cache
  static void clearCache() {
    _imageCache.clear();
    _cacheTimestamps.clear();
  }

  // Static method to get cache size
  static int getCacheSize() {
    return _imageCache.length;
  }
}

class ImagePainter extends CustomPainter {
  final ui.Image image;
  final BoxFit fit;

  ImagePainter({required this.image, required this.fit});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..filterQuality = FilterQuality.high;
    
    final imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final targetSize = size;
    
    Rect sourceRect = Offset.zero & imageSize;
    Rect targetRect = Offset.zero & targetSize;
    
    switch (fit) {
      case BoxFit.cover:
        final scale = (targetSize.width / imageSize.width)
            .max(targetSize.height / imageSize.height);
        final scaledSize = imageSize * scale;
        final offset = Offset(
          (targetSize.width - scaledSize.width) / 2,
          (targetSize.height - scaledSize.height) / 2,
        );
        targetRect = offset & scaledSize;
        break;
      case BoxFit.contain:
        final scale = (targetSize.width / imageSize.width)
            .min(targetSize.height / imageSize.height);
        final scaledSize = imageSize * scale;
        final offset = Offset(
          (targetSize.width - scaledSize.width) / 2,
          (targetSize.height - scaledSize.height) / 2,
        );
        targetRect = offset & scaledSize;
        break;
      case BoxFit.fill:
        // targetRect is already correct
        break;
      case BoxFit.fitWidth:
        final scale = targetSize.width / imageSize.width;
        final scaledSize = imageSize * scale;
        final offset = Offset(
          0,
          (targetSize.height - scaledSize.height) / 2,
        );
        targetRect = offset & scaledSize;
        break;
      case BoxFit.fitHeight:
        final scale = targetSize.height / imageSize.height;
        final scaledSize = imageSize * scale;
        final offset = Offset(
          (targetSize.width - scaledSize.width) / 2,
          0,
        );
        targetRect = offset & scaledSize;
        break;
      case BoxFit.none:
        final offset = Offset(
          (targetSize.width - imageSize.width) / 2,
          (targetSize.height - imageSize.height) / 2,
        );
        targetRect = offset & imageSize;
        break;
      case BoxFit.scaleDown:
        if (imageSize.width <= targetSize.width && 
            imageSize.height <= targetSize.height) {
          final offset = Offset(
            (targetSize.width - imageSize.width) / 2,
            (targetSize.height - imageSize.height) / 2,
          );
          targetRect = offset & imageSize;
        } else {
          final scale = (targetSize.width / imageSize.width)
              .min(targetSize.height / imageSize.height);
          final scaledSize = imageSize * scale;
          final offset = Offset(
            (targetSize.width - scaledSize.width) / 2,
            (targetSize.height - scaledSize.height) / 2,
          );
          targetRect = offset & scaledSize;
        }
        break;
    }
    
    canvas.drawImageRect(image, sourceRect, targetRect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! ImagePainter || 
           oldDelegate.image != image || 
           oldDelegate.fit != fit;
  }
}

extension on num {
  double max(num other) => this > other ? toDouble() : other.toDouble();
  double min(num other) => this < other ? toDouble() : other.toDouble();
}
