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
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Center(
        child: RotationTransition(
          turns: _controller,
          child: Icon(
            Icons.work_history_rounded,
            size: widget.size,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}

