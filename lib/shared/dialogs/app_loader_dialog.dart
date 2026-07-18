// app_loader.dart
//
// A premium, banking-themed loading UI with a 3D floating credit card.
//
// HOW TO USE:
//
// 1) GLOBAL OVERLAY (Blocks the screen, shows above everything)
//      AppLoader.show(context, message: 'Processing payment...');
//      await processPayment();
//      AppLoader.hide();
//
// 2) RETURNABLE WIDGET (Use directly in your widget tree)
//      @override
//      Widget build(BuildContext context) {
//        if (isLoading) {
//          return const Center(
//            child: BankingLoaderWidget(message: 'Loading account...'),
//          );
//        }
//        return MyScreen();
//      }

import 'dart:math' as math;
import 'package:flutter/material.dart';

// =============================================================================
// GLOBAL STATIC API (OVERLAY)
// =============================================================================

class AppLoader {
  AppLoader._();

  static OverlayEntry? _entry;
  static final ValueNotifier<String?> _messageNotifier = ValueNotifier(null);
  static final ValueNotifier<bool> _pausedNotifier = ValueNotifier(false);
  static bool _wasShowingBeforePause = false;

  static bool get isShowing => _entry != null;
  static bool get isPaused => _pausedNotifier.value;

  /// Shows the loader as a full-screen overlay above everything.
  static void show(
      BuildContext context, {
        String? message,
        bool blockInteraction = true,
      }) {
    _messageNotifier.value = message;

    if (_entry != null) return; // already showing — just update message

    final overlayState = Overlay.of(context, rootOverlay: true);

    _entry = OverlayEntry(
      builder: (_) => _FullScreenLoaderBarrier(
        messageListenable: _messageNotifier,
        pausedListenable: _pausedNotifier,
        blockInteraction: blockInteraction,
      ),
    );

    overlayState.insert(_entry!);
  }

  /// Updates the message of an already-showing loader.
  static void updateMessage(String message) {
    _messageNotifier.value = message;
  }

  /// Pauses the loader — hides it and stops blocking interaction
  /// so other dialogs can open on top. Call [resume] when done.
  static void pause() {
    if (_entry == null || _pausedNotifier.value) return;
    _wasShowingBeforePause = true;
    _pausedNotifier.value = true;
  }

  /// Resumes the loader after a [pause].
  static void resume() {
    if (!_wasShowingBeforePause) return;
    _wasShowingBeforePause = false;
    _pausedNotifier.value = false;
  }

  /// Hides the loader.
  static void hide() {
    _entry?.remove();
    _entry = null;
    _messageNotifier.value = null;
    _pausedNotifier.value = false;
    _wasShowingBeforePause = false;
  }

  /// Convenience wrapper to auto-show/hide around a Future.
  static Future<T> wrap<T>(
      BuildContext context,
      Future<T> future, {
        String? message,
        bool blockInteraction = true,
      }) async {
    show(context, message: message, blockInteraction: blockInteraction);
    try {
      return await future;
    } finally {
      hide();
    }
  }
}

// =============================================================================
// RETURNABLE INLINE WIDGET
// =============================================================================

/// A standalone widget you can return directly in your build method
/// when you don't want to use an overlay/dialog.
class BankingLoaderWidget extends StatelessWidget {
  const BankingLoaderWidget({
    super.key,
    this.message,
    this.cardWidth = 140,
  });

  final String? message;
  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PremiumCardAnimation(width: cardWidth),
        if (message != null && message!.isNotEmpty) ...[
          const SizedBox(height: 32),
          _PulsingText(message: message!),
        ],
      ],
    );
  }
}

// =============================================================================
// INTERNAL OVERLAY COMPONENTS
// =============================================================================

class _FullScreenLoaderBarrier extends StatefulWidget {
  const _FullScreenLoaderBarrier({
    required this.messageListenable,
    required this.pausedListenable,
    required this.blockInteraction,
  });

  final ValueNotifier<String?> messageListenable;
  final ValueNotifier<bool> pausedListenable;
  final bool blockInteraction;

  @override
  State<_FullScreenLoaderBarrier> createState() =>
      _FullScreenLoaderBarrierState();
}

class _FullScreenLoaderBarrierState extends State<_FullScreenLoaderBarrier>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  )..forward();

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.pausedListenable,
      builder: (context, paused, _) {
        if (paused) {
          return const SizedBox.shrink();
        }
        return IgnorePointer(
          ignoring: !widget.blockInteraction,
          child: AnimatedBuilder(
            animation: _fadeCtrl,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned.fill(
                    child: Opacity(
                      opacity: _fadeCtrl.value,
                      child: Container(
                        color: Colors.black.withOpacity(0.65),
                      ),
                    ),
                  ),
                  Center(
                    child: Opacity(
                      opacity: _fadeCtrl.value,
                      child: Transform.scale(
                        scale: 0.9 + (0.1 * _fadeCtrl.value),
                        child: ValueListenableBuilder<String?>(
                          valueListenable: widget.messageListenable,
                          builder: (context, msg, _) {
                            return BankingLoaderWidget(message: msg);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

// =============================================================================
// THE ANIMATION - 3D Floating & Flipping Credit Card
// =============================================================================

class _PremiumCardAnimation extends StatefulWidget {
  const _PremiumCardAnimation({required this.width});

  final double width;

  @override
  State<_PremiumCardAnimation> createState() => _PremiumCardAnimationState();
}

class _PremiumCardAnimationState extends State<_PremiumCardAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _flipCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  late final AnimationController _floatCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _flipCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Standard credit card ratio is ~1.58
    final height = widget.width / 1.58;

    return AnimatedBuilder(
      animation: Listenable.merge([_flipCtrl, _floatCtrl]),
      builder: (context, _) {
        final flipAngle = _flipCtrl.value * 2 * math.pi;
        final floatOffset = _floatCtrl.value * -15.0; // Floats up
        final shadowScale = 1.0 - (_floatCtrl.value * 0.3); // Shadow shrinks
        final shadowOpacity = 0.4 - (_floatCtrl.value * 0.2);

        // Determine if we are looking at the front or back of the card
        final isFrontVisible = math.cos(flipAngle) > 0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The Card
            Transform.translate(
              offset: Offset(0, floatOffset),
              child: Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.002) // Perspective depth
                  ..rotateY(flipAngle),
                alignment: Alignment.center,
                child: isFrontVisible
                    ? _CardFront(width: widget.width, height: height)
                    : Transform(
                  // Un-mirror the back face
                  transform: Matrix4.identity()..rotateY(math.pi),
                  alignment: Alignment.center,
                  child: _CardBack(width: widget.width, height: height),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // The dynamic shadow on the "floor"
            Container(
              width: widget.width * 0.7 * shadowScale,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(shadowOpacity),
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(shadowOpacity),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// --- CARD DESIGNS ---

class _CardFront extends StatelessWidget {
  const _CardFront({required this.width, required this.height});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C3E50), Color(0xFF000000)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 12,
            offset: Offset(0, 6),
          )
        ],
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
      ),
      child: Stack(
        children: [
          // Glass/gloss reflection
          Positioned(
            top: -height * 0.5,
            left: -width * 0.5,
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: width * 2,
                height: height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.0),
                      Colors.white.withOpacity(0.05),
                      Colors.white.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Chip
          Positioned(
            top: height * 0.25,
            left: width * 0.12,
            child: Container(
              width: width * 0.18,
              height: height * 0.22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFDAA520)],
                ),
              ),
              // Chip lines
              child: CustomPaint(painter: _ChipPainter()),
            ),
          ),
          // Contactless Icon (using rotated wifi icon)
          Positioned(
            top: height * 0.28,
            right: width * 0.12,
            child: Transform.rotate(
              angle: math.pi / 2,
              child: const Icon(Icons.wifi, color: Colors.white70, size: 20),
            ),
          ),
          // Fake Card Number
          Positioned(
            bottom: height * 0.25,
            left: width * 0.12,
            child: Row(
              children: List.generate(4, (index) {
                return Container(
                  margin: EdgeInsets.only(right: width * 0.05),
                  width: width * 0.12,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack({required this.width, required this.height});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.bottomRight,
          end: Alignment.topLeft,
          colors: [Color(0xFF1A1A1A), Color(0xFF2C3E50)],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
      ),
      child: Stack(
        children: [
          // Magnetic Stripe
          Positioned(
            top: height * 0.15,
            left: 0,
            right: 0,
            child: Container(
              height: height * 0.2,
              color: Colors.black87,
            ),
          ),
          // Signature Bar
          Positioned(
            top: height * 0.45,
            left: width * 0.1,
            right: width * 0.2,
            child: Container(
              height: height * 0.18,
              color: Colors.white.withOpacity(0.8),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                width: width * 0.12,
                height: height * 0.12,
                color: Colors.black26,
              ), // Fake CVV
            ),
          ),
        ],
      ),
    );
  }
}

// --- HELPERS ---

class _ChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final path = Path();
    // Center rectangle
    path.addRect(Rect.fromLTWH(
        size.width * 0.35, size.height * 0.3,
        size.width * 0.3, size.height * 0.4
    ));
    // Side lines
    path.moveTo(0, size.height * 0.3);
    path.lineTo(size.width * 0.35, size.height * 0.3);
    path.moveTo(0, size.height * 0.7);
    path.lineTo(size.width * 0.35, size.height * 0.7);

    path.moveTo(size.width, size.height * 0.3);
    path.lineTo(size.width * 0.65, size.height * 0.3);
    path.moveTo(size.width, size.height * 0.7);
    path.lineTo(size.width * 0.65, size.height * 0.7);

    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PulsingText extends StatefulWidget {
  const _PulsingText({required this.message});
  final String message;

  @override
  State<_PulsingText> createState() => _PulsingTextState();
}

class _PulsingTextState extends State<_PulsingText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, _) {
        return Opacity(
          opacity: 0.5 + (_pulseCtrl.value * 0.5),
          child: Text(
            widget.message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.none, // Required if used without Scaffold
            ),
          ),
        );
      },
    );
  }
}