import "package:flutter/widgets.dart";

/// Whether the soft keyboard currently covers part of the window.
///
/// Read via [KeyboardVisibility.of] instead of `MediaQuery.viewInsetsOf`
/// anywhere below a [Scaffold]: Scaffold strips the bottom inset from the
/// [MediaQuery] it hands to its body (resizeToAvoidBottomInset), so deep
/// widgets would always see zero. [IdeShell] captures the unstripped value
/// above its own Scaffold and provides it here, keeping every descendant
/// reactive to keyboard show/hide.
class KeyboardVisibility extends InheritedWidget {
  const KeyboardVisibility({
    super.key,
    required this.visible,
    required super.child,
  });

  final bool visible;

  static bool of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<KeyboardVisibility>()
          ?.visible ??
      false;

  @override
  bool updateShouldNotify(KeyboardVisibility oldWidget) =>
      visible != oldWidget.visible;
}
