import 'package:flutter/material.dart';
import '../utils/animation_manager.dart';

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
    with SingleTickerProviderStateMixin, AnimationManagerMixin {
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    // Use AnimationManager for optimized animation handling
    // Use a stable key based on the widget's identity, not hashCode
    _rotationAnimation = getRotationAnimation(
      'reload_elevated_button_${widget.label}',
      const Duration(milliseconds: 800),
    );
  }

  void _handlePress() {
    // Get the controller from AnimationManager
    final controller = AnimationManager.getControllerByKey(
      'reload_elevated_button_${widget.label}',
    );
    if (controller != null) {
      // Start the rotation animation
      controller.forward().then((_) {
        // Reset the animation for next use
        controller.reset();
      });
    }

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
