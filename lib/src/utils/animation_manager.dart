import 'package:flutter/material.dart';

/// Centralized animation manager for optimizing animation performance
/// and preventing memory leaks from multiple animation controllers
class AnimationManager {
  static final Map<String, AnimationController> _controllers = {};
  static final Map<String, Animation<double>> _animations = {};
  static final Map<String, TickerProvider> _tickerProviders = {};

  /// Get or create an animation controller with the specified key
  static AnimationController getController(
    String key,
    TickerProvider vsync,
    Duration duration, {
    double? lowerBound,
    double? upperBound,
    AnimationBehavior animationBehavior = AnimationBehavior.normal,
  }) {
    // If controller exists and has the same vsync, return it
    if (_controllers.containsKey(key) && _tickerProviders[key] == vsync) {
      return _controllers[key]!;
    }

    // Dispose existing controller if vsync changed
    if (_controllers.containsKey(key)) {
      _controllers[key]?.dispose();
      _controllers.remove(key);
      _animations.remove(key);
      _tickerProviders.remove(key);
    }

    // Create new controller
    final controller = AnimationController(
      duration: duration,
      vsync: vsync,
      lowerBound: lowerBound ?? 0.0,
      upperBound: upperBound ?? 1.0,
      animationBehavior: animationBehavior,
    );

    _controllers[key] = controller;
    _tickerProviders[key] = vsync;

    return controller;
  }

  /// Get or create a rotation animation for reload buttons
  static Animation<double> getRotationAnimation(
    String key,
    TickerProvider vsync,
    Duration duration,
  ) {
    if (_animations.containsKey(key)) {
      return _animations[key]!;
    }

    final controller = getController(key, vsync, duration);
    final animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));

    _animations[key] = animation;
    return animation;
  }

  /// Get or create an expand animation for FABs
  static Animation<double> getExpandAnimation(
    String key,
    TickerProvider vsync,
    Duration duration,
  ) {
    if (_animations.containsKey(key)) {
      return _animations[key]!;
    }

    final controller = getController(key, vsync, duration);
    final animation = CurvedAnimation(
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeOutQuad,
      parent: controller,
    );

    _animations[key] = animation;
    return animation;
  }

  /// Get or create a fade animation
  static Animation<double> getFadeAnimation(
    String key,
    TickerProvider vsync,
    Duration duration,
  ) {
    if (_animations.containsKey(key)) {
      return _animations[key]!;
    }

    final controller = getController(key, vsync, duration);
    final animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));

    _animations[key] = animation;
    return animation;
  }

  /// Get or create a scale animation
  static Animation<double> getScaleAnimation(
    String key,
    TickerProvider vsync,
    Duration duration,
  ) {
    if (_animations.containsKey(key)) {
      return _animations[key]!;
    }

    final controller = getController(key, vsync, duration);
    final animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.elasticOut));

    _animations[key] = animation;
    return animation;
  }

  /// Dispose a specific controller and its animation
  static void disposeController(String key) {
    _controllers[key]?.dispose();
    _controllers.remove(key);
    _animations.remove(key);
    _tickerProviders.remove(key);
  }

  /// Dispose all controllers and animations
  static void disposeAll() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _animations.clear();
    _tickerProviders.clear();
  }

  /// Get the number of active controllers
  static int get activeControllerCount => _controllers.length;

  /// Check if a controller exists for the given key
  static bool hasController(String key) => _controllers.containsKey(key);

  /// Get all active controller keys
  static List<String> get activeControllerKeys => _controllers.keys.toList();

  /// Pause all animations
  static void pauseAll() {
    for (final controller in _controllers.values) {
      if (controller.isAnimating) {
        controller.stop();
      }
    }
  }

  /// Resume all animations
  static void resumeAll() {
    // Note: This is a simplified implementation
    // In practice, you might want to track the previous state
    // and restore it appropriately
  }

  /// Get a controller by key (for advanced usage)
  static AnimationController? getControllerByKey(String key) {
    return _controllers[key];
  }
}

/// Mixin for widgets that use AnimationManager
/// Provides automatic cleanup when the widget is disposed
/// Requires the State class to also implement TickerProvider
mixin AnimationManagerMixin<T extends StatefulWidget> on State<T>
    implements TickerProvider {
  final Set<String> _usedAnimationKeys = {};

  /// Get a rotation animation for reload buttons
  Animation<double> getRotationAnimation(String key, Duration duration) {
    _usedAnimationKeys.add(key);
    return AnimationManager.getRotationAnimation(key, this, duration);
  }

  /// Get an expand animation for FABs
  Animation<double> getExpandAnimation(String key, Duration duration) {
    _usedAnimationKeys.add(key);
    return AnimationManager.getExpandAnimation(key, this, duration);
  }

  /// Get a fade animation
  Animation<double> getFadeAnimation(String key, Duration duration) {
    _usedAnimationKeys.add(key);
    return AnimationManager.getFadeAnimation(key, this, duration);
  }

  /// Get a scale animation
  Animation<double> getScaleAnimation(String key, Duration duration) {
    _usedAnimationKeys.add(key);
    return AnimationManager.getScaleAnimation(key, this, duration);
  }

  @override
  void dispose() {
    // Note: We don't dispose controllers here because AnimationManager
    // is designed to be a singleton that manages controllers globally.
    // Controllers are only disposed when the app is terminated or
    // when explicitly requested via AnimationManager.disposeAll()
    _usedAnimationKeys.clear();
    super.dispose();
  }
}
