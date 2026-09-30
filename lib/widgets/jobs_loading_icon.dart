import 'dart:math' as math;

import 'package:flutter/material.dart';

class JobsLoadingIcon extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;

  const JobsLoadingIcon({
    super.key,
    this.size = 24,
    this.color = Colors.white,
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  State<JobsLoadingIcon> createState() => _JobsLoadingIconState();
}

class _JobsLoadingIconState extends State<JobsLoadingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
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
        return Transform.rotate(
          angle: _controller.value * 2 * math.pi,
          child: Icon(
            Icons.work_history_rounded,
            size: widget.size,
            color: widget.color,
          ),
        );
      },
    );
  }
}

