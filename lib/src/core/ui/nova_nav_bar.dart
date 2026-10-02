import "package:flutter/material.dart";

/// One destination in [NovaNavBar].
@immutable
class NovaNavItem {
  const NovaNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Compact floating bottom navigation bar: a ~60px pill instead of the
/// full-bleed ~80px Material bar.
///
/// Selection is shown by a pill that *slides* behind the active item
/// ([AnimatedAlign] over equal-width slots, so no measuring code), while
/// each item pops its icon and brightens its label through its own 0→1
/// tween on the same duration/curve, keeping everything in sync.
///
/// Labels sit under their icons at 11sp (full slot width, ellipsized),
/// so long Arabic labels can never overflow. RTL-safe: the slide position
/// mirrors with [Directionality]. Fully theme-driven ([ColorScheme] only),
/// so editor-theme following keeps working.
class NovaNavBar extends StatelessWidget {
  const NovaNavBar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.items,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final List<NovaNavItem> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final slotWidth =
                    constraints.maxWidth / items.length;
                final step = 2 / (items.length - 1);
                final x = selectedIndex * step - 1;
                final alignment = Directionality.of(context) ==
                        TextDirection.rtl
                    ? Alignment(-x, 0)
                    : Alignment(x, 0);
                return Stack(
                  children: [
                    // Sliding selection pill, behind the items.
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      alignment: alignment,
                      child: IgnorePointer(
                        child: Container(
                          width: slotWidth - 8,
                          height: 48,
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < items.length; i++)
                          Expanded(
                            child: _NovaNavItemView(
                              item: items[i],
                              selected: i == selectedIndex,
                              onTap: () => onSelect(i),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NovaNavItemView extends StatelessWidget {
  const _NovaNavItemView({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final NovaNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.labelSmall;
    // Rebuilds with a new end (0/1) on selection change; matches the
    // sliding pill's duration/curve so icon and label move with it.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: selected ? 1 : 0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        final foreground = Color.lerp(
          scheme.onSurfaceVariant,
          scheme.onPrimaryContainer,
          t,
        )!;
        return Tooltip(
          message: item.label,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.scale(
                      scale: 1 + 0.15 * t,
                      child: Icon(
                        selected ? item.selectedIcon : item.icon,
                        size: 22,
                        color: foreground,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textStyle?.copyWith(
                        fontSize: 11,
                        color: foreground,
                        fontWeight: FontWeight.lerp(
                          FontWeight.w500,
                          FontWeight.w700,
                          t,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Slide-and-fade entrance for the nav bar: plays once per mount (keyboard
/// close, focus-mode exit), never on selection changes. Removals stay
/// instant (the bar is simply unmounted) so hiding reclaims space now.
class NovaNavBarEntrance extends StatefulWidget {
  const NovaNavBarEntrance({super.key, required this.child});

  final Widget child;

  @override
  State<NovaNavBarEntrance> createState() => _NovaNavBarEntranceState();
}

class _NovaNavBarEntranceState extends State<NovaNavBarEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _slide =
        Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
        );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(opacity: _controller, child: widget.child),
    );
  }
}
