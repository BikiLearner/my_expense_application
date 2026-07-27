import 'dart:math' as math;
import 'package:flutter/material.dart';

class LinkedFlipCard extends StatefulWidget {
  final bool showBack;
  final Widget front;
  final Widget back;
  final Duration duration;

  const LinkedFlipCard({
    super.key,
    required this.showBack,
    required this.front,
    required this.back,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<LinkedFlipCard> createState() => _LinkedFlipCardState();
}

class _LinkedFlipCardState extends State<LinkedFlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _angle;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: widget.showBack ? 1.0 : 0.0,
    );
    _angle = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void didUpdateWidget(covariant LinkedFlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }

    if (widget.showBack != oldWidget.showBack) {
      // Animate from wherever the controller currently is — no jump,
      // even if the user toggles rapidly mid-flip.
      if (widget.showBack) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _angle,
      builder: (context, child) {
        final progress = _angle.value; // 0 -> 1
        final radians = progress * math.pi;
        final isFront = progress < 0.5;

        // Subtle "lift" scale as the card turns edge-on, settling back
        // to 1.0 at both ends — makes the flip feel dimensional rather
        // than a flat rotation.
        final liftProgress = math.sin(progress * math.pi); // 0 -> 1 -> 0
        final scale = 1.0 - (liftProgress * 0.04);

        // Fade the face slightly as it crosses the edge-on point to
        // hide any z-fighting/aliasing at exactly 90 degrees.
        final edgeFade = 1.0 - (liftProgress * 0.15);

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0015) // slightly stronger perspective
            ..scale(scale)
            ..rotateY(radians),
          child: Opacity(
            opacity: edgeFade.clamp(0.0, 1.0),
            child: isFront
                ? widget.front
                : Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..rotateY(math.pi),
              child: widget.back,
            ),
          ),
        );
      },
    );
  }
}