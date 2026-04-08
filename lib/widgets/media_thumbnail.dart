import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'fullscreen_image_viewer.dart';

class MediaThumbnail extends StatelessWidget {
  final String url;
  final double height;

  const MediaThumbnail({
    super.key,
    required this.url,
    this.height = 100,
  });

  bool _isVideo() {
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.webm') || lower.endsWith('.avi');
  }

  @override
  Widget build(BuildContext context) {
    if (_isVideo()) {
      return GestureDetector(
        onTap: () => launchUrl(Uri.parse(url)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: height,
            color: Colors.black87,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_circle_fill, color: Colors.blueAccent, size: 36),
                  SizedBox(height: 4),
                  Text("Reproducir", style: TextStyle(color: Colors.white, fontSize: 11)),
                ],
              ),
            ),
          ),
        ),
      );
    }
    
    return GestureDetector(
      onTap: () => showFullScreenImage(context, url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => SizedBox(
            height: height,
            child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
          ),
        ),
      ),
    );
  }
}
