import 'package:flutter/material.dart';

/// An animated reload elevated button that shows a rotation animation when pressed
class AnimatedReloadElevatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  final ButtonStyle? style;

  const AnimatedReloadElevatedButton({
    super.key,
    required this.onPressed,
    this.label = 'Reload',
    this.style,
  });

  @override
  State<AnimatedReloadElevatedButton> createState() =>
      _AnimatedReloadElevatedButtonState();
}

class _AnimatedReloadElevatedButtonState
    extends State<AnimatedReloadElevatedButton>
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
    return ElevatedButton.icon(
      onPressed: _handlePress,
      style: widget.style,
      label: Text(widget.label),
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
