import 'package:flutter/material.dart';

class StaggeredFadeSlide extends StatefulWidget {
  const StaggeredFadeSlide({
    super.key,
    required this.child,
    required this.index,
    this.baseDelayMs = 35,
    this.stepDelayMs = 40,
    this.duration = const Duration(milliseconds: 300),
    this.offsetY = 6,
  });

  final Widget child;
  final int index;
  final int baseDelayMs;
  final int stepDelayMs;
  final Duration duration;
  final double offsetY;

  @override
  State<StaggeredFadeSlide> createState() => _StaggeredFadeSlideState();
}

class _StaggeredFadeSlideState extends State<StaggeredFadeSlide> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    final delay = widget.baseDelayMs + (widget.index * widget.stepDelayMs);
    Future.delayed(Duration(milliseconds: delay), () {
      if (!mounted) return;
      setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: widget.duration,
      curve: Curves.easeOutCubic,
      offset: _visible ? Offset.zero : Offset(0, widget.offsetY / 100),
      child: AnimatedOpacity(
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        opacity: _visible ? 1 : 0,
        child: widget.child,
      ),
    );
  }
}
