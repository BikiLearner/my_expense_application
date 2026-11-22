import 'package:flutter/material.dart';

class LongPressMessage extends StatelessWidget {
  final String message;
  final Widget child;

  const LongPressMessage({
    super.key,
    required this.message,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      triggerMode: TooltipTriggerMode.longPress,
      showDuration: const Duration(seconds: 4),
      child: child,
    );
  }
}