import 'package:flutter/material.dart';

/// An animated reload button that shows a rotation animation when pressed
class AnimatedReloadButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String tooltip;
  final double iconSize;

  const AnimatedReloadButton({
    super.key,
    required this.onPressed,
    this.tooltip = 'Refresh',
    this.iconSize = 22,
  });

  @override
  State<AnimatedReloadButton> createState() => _AnimatedReloadButtonState();
}

class _AnimatedReloadButtonState extends State<AnimatedReloadButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handlePress() {
    // Start the rotation animation
    _animationController.forward().then((_) {
      // Reset the animation for next use
      _animationController.reset();
    });

    // Call the original onPressed callback
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _handlePress,
      tooltip: widget.tooltip,
      iconSize: widget.iconSize,
      icon: AnimatedBuilder(
        animation: _rotationAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationAnimation.value * 2 * 3.14159, // Full rotation
            child: const Icon(Icons.refresh),
          );
        },
      ),
    );
  }
}
