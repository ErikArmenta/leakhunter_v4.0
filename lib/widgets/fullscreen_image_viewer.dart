import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void showFullScreenImage(BuildContext context, String url) {
  final lower = url.toLowerCase();
  if (lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.webm') || lower.endsWith('.avi')) {
    launchUrl(Uri.parse(url));
    return;
  }

  showDialog(
    context: context,
    barrierColor: Colors.black87,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          InteractiveViewer(
            panEnabled: true,
            minScale: 1,
            maxScale: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_,__,___) => const SizedBox(
                  height: 200, 
                  child: Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 50))
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(ctx),
            ),
          ),
        ],
      ),
    ),
  );
}
