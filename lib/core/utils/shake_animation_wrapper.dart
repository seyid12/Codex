import 'dart:math' as math;
import 'package:flutter/material.dart';

class ShakeWrapper extends StatefulWidget {
  final Widget child;
  final bool shake;
  final VoidCallback onShakeCompleted;

  const ShakeWrapper({
    super.key,
    required this.child,
    required this.shake,
    required this.onShakeCompleted,
  });

  @override
  State<ShakeWrapper> createState() => _ShakeWrapperState();
}

class _ShakeWrapperState extends State<ShakeWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reset();
        widget.onShakeCompleted();
      }
    });
  }

  @override
  void didUpdateWidget(covariant ShakeWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shake && !oldWidget.shake) {
      _controller.forward();
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
      animation: _controller,
      builder: (context, child) {
        // Sine wave formula for shaking left and right
        // _controller.value goes from 0.0 to 1.0
        // math.pi * 4 means 2 full sine waves (4 back and forths)
        // 10 is the pixel intensity of the shake
        final dx = math.sin(_controller.value * math.pi * 4) * 10;
        
        // Dampen the shake towards the end
        final dampenedDx = dx * (1.0 - _controller.value);

        return Transform.translate(
          offset: Offset(dampenedDx, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
