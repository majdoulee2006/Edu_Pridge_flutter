import 'package:flutter/material.dart';
import 'package:edu_pridge_flutter/main.dart' show appNavigatorKey;

OverlayEntry? _currentBanner;

void showInAppBanner(BuildContext context, String title, String message, {VoidCallback? onTap}) {
  final overlayState = appNavigatorKey.currentState?.overlay ?? Overlay.of(context);
  _currentBanner?.remove();
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => _BannerWidget(
      title: title,
      message: message,
      onDismiss: () {
        entry.remove();
        _currentBanner = null;
      },
      onTap: onTap,
    ),
  );
  _currentBanner = entry;
  overlayState.insert(entry);
  Future.delayed(const Duration(seconds: 4), () {
    if (entry.mounted) {
      entry.remove();
      _currentBanner = null;
    }
  });
}

class _BannerWidget extends StatefulWidget {
  final String title;
  final String message;
  final VoidCallback onDismiss;
  final VoidCallback? onTap;
  const _BannerWidget({required this.title, required this.message, required this.onDismiss, this.onTap});

  @override
  State<_BannerWidget> createState() => _BannerWidgetState();
}

class _BannerWidgetState extends State<_BannerWidget> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _slide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top + 10;
    return Positioned(
      top: top,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {
              widget.onDismiss();
              widget.onTap?.call();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFCC00).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications, color: Color(0xFFFFCC00), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(widget.title,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(widget.message,
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: widget.onDismiss,
                    child: const Icon(Icons.close, color: Colors.white54, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
