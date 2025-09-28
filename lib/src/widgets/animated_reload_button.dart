import 'package:flutter/material.dart';
import '../utils/animation_manager.dart';

/// An animated reload button that shows a rotation animation when pressed
class AnimatedReloadButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String tooltip;
  final double iconSize;
  final String? uniqueId; // Optional unique identifier for animation key

  const AnimatedReloadButton({
    super.key,
    required this.onPressed,
    this.tooltip = 'Refresh',
    this.iconSize = 22,
    this.uniqueId,
  });

  @override
  State<AnimatedReloadButton> createState() => _AnimatedReloadButtonState();
}

class _AnimatedReloadButtonState extends State<AnimatedReloadButton>
    with SingleTickerProviderStateMixin, AnimationManagerMixin {
  late Animation<double> _rotationAnimation;
  late String _animationKey;

  @override
  void initState() {
    super.initState();
    // Use AnimationManager for optimized animation handling
    // Generate a unique key that includes the uniqueId if provided
    _animationKey = widget.uniqueId != null
        ? 'reload_button_${widget.uniqueId}_${widget.tooltip}_${widget.iconSize}'
        : 'reload_button_${widget.tooltip}_${widget.iconSize}';

    _rotationAnimation = getRotationAnimation(
      _animationKey,
      const Duration(milliseconds: 800),
    );
  }

  void _handlePress() {
    // Get the controller from AnimationManager using the stored key
    final controller = AnimationManager.getControllerByKey(_animationKey);
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
