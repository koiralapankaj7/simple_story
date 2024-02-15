import 'package:flutter/material.dart';

/// Hero widget for story player
class StoryHero extends StatelessWidget {
  const StoryHero({
    required this.tag,
    required this.child,
    super.key,
    this.heroSize = 70.0,
  });

  final Object tag;
  final Widget child;
  final double heroSize;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      transitionOnUserGestures: true,
      flightShuttleBuilder: (
        flightContext,
        animation,
        flightDirection,
        fromHeroContext,
        toHeroContext,
      ) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final size = MediaQuery.of(context).size;
            return FittedBox(
              fit: BoxFit.cover,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  (1 - animation.value) * heroSize,
                ),
                child: SizedBox(
                  height: heroSize.clamp(heroSize, size.height),
                  width: heroSize.clamp(heroSize, size.width),
                  child: fromHeroContext.widget,
                ),
              ),
            );
          },
        );
      },
      child: child,
    );
  }
}
