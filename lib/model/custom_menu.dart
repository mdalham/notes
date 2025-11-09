import 'package:flutter/material.dart';

import 'custom_container.dart';

void customMenuWidget({
  required BuildContext context,
  required Offset position,
  required List<String> titles,
  required List<VoidCallback> onTapCallbacks,
  required ColorScheme colorScheme,
  List<IconData>? icons,
}) {
  assert(titles.length == onTapCallbacks.length);

  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  final animationController = AnimationController(
    duration: const Duration(milliseconds: 200),
    vsync: Navigator.of(context),
  );

  final animation = CurvedAnimation(
    parent: animationController,
    curve: Curves.easeOutBack,
  );

  entry = OverlayEntry(
    builder: (context) => Stack(
      children: [
        // Tap outside to close
        GestureDetector(
          onTap: () {
            animationController.reverse().then((_) => entry.remove());
          },
          behavior: HitTestBehavior.translucent,
        ),

        // Animated menu
        Positioned(
          left: position.dx - 60, // show left of the icon
          top: position.dy - 10,
          child: FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.2, 0), // start slightly right
                end: Offset.zero,
              ).animate(animation),
              child: Material(
                borderRadius: BorderRadius.circular(10),
                child: CustomContainer(
                  color: colorScheme.primaryContainer,
                  outlineColor: colorScheme.outline,
                  circularRadius: 10,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(titles.length, (i) {
                      final hasIcon = icons != null && i < icons.length;

                      return GestureDetector(
                        onTap: () {
                          animationController.reverse().then((_) {
                            entry.remove();
                            onTapCallbacks[i]();
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 14,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasIcon) ...[
                                Icon(
                                  icons[i],
                                  size: 18,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                                const SizedBox(width: 10),
                              ],
                              Text(
                                titles[i],
                                style: TextStyle(fontSize: 14, color: colorScheme.onPrimary)
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  overlay.insert(entry);
  animationController.forward();
}
