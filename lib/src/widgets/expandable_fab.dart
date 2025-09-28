import 'package:flutter/material.dart';
import '../utils/animation_manager.dart';

class ExpandableFab extends StatefulWidget {
  const ExpandableFab({
    super.key,
    this.initialOpen,
    required this.distance,
    required this.children,
  });

  final bool? initialOpen;
  final double distance;
  final List<Widget> children;

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin, AnimationManagerMixin {
  late final Animation<double> _expandAnimation;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _open = widget.initialOpen ?? false;

    // Use AnimationManager for optimized animation handling
    // Use a stable key based on the widget's properties
    _expandAnimation = getExpandAnimation(
      'expandable_fab_${widget.distance}_${widget.children.length}',
      const Duration(milliseconds: 250),
    );

    if (_open) {
      final controller = AnimationManager.getControllerByKey(
        'expandable_fab_${widget.distance}_${widget.children.length}',
      );
      controller?.value = 1;
    }
  }

  void _toggle() {
    setState(() {
      _open = !_open;
      final controller = AnimationManager.getControllerByKey(
        'expandable_fab_${widget.distance}_${widget.children.length}',
      );
      if (controller != null) {
        if (_open) {
          controller.forward();
        } else {
          controller.reverse();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          _buildTapToCloseFab(),
          ..._buildExpandingActionButtons(),
          _buildTapToOpenFab(),
        ],
      ),
    );
  }

  Widget _buildTapToCloseFab() {
    return IgnorePointer(
      ignoring: !_open,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        color: Colors.transparent,
        child: AnimatedOpacity(
          opacity: _open ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 250),
          child: GestureDetector(onTap: _toggle),
        ),
      ),
    );
  }

  List<Widget> _buildExpandingActionButtons() {
    final children = <Widget>[];
    final count = widget.children.length;
    for (var i = 0; i < count; i++) {
      children.add(
        _ExpandingActionButton(
          directionInDegrees: 90 - (i * 45),
          maxDistance: widget.distance,
          progress: _expandAnimation,
          child: widget.children[i],
        ),
      );
    }
    return children;
  }

  Widget _buildTapToOpenFab() {
    return AnimatedContainer(
      transformAlignment: Alignment.center,
      duration: const Duration(milliseconds: 250),
      transform: Matrix4.diagonal3Values(
        _open ? 0.7 : 1.0,
        _open ? 0.7 : 1.0,
        1.0,
      ),
      child: FloatingActionButton(
        onPressed: _toggle,
        child: Icon(_open ? Icons.close : Icons.add),
      ),
    );
  }
}

@immutable
class _ExpandingActionButton extends StatelessWidget {
  const _ExpandingActionButton({
    required this.directionInDegrees,
    required this.maxDistance,
    required this.progress,
    required this.child,
  });

  final double directionInDegrees;
  final double maxDistance;
  final Animation<double> progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        final offset = Offset.fromDirection(
          directionInDegrees * (3.1415926 / 180.0),
          progress.value * maxDistance,
        );
        return Positioned(
          right: 4 + offset.dx,
          bottom: 4 + offset.dy,
          child: Transform.rotate(
            angle: (1.0 - progress.value) * 3.1415926 / 2,
            child: FadeTransition(opacity: progress, child: child),
          ),
        );
      },
      child: child,
    );
  }
}
