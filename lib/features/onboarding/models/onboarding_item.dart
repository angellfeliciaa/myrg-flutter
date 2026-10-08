import 'package:flutter/foundation.dart';

@immutable
class OnboardingItem {
  const OnboardingItem({
    required this.title,
    required this.description,
    required this.illustration,
    required this.indicator,
    required this.illustrationWidth,
  });

  final String title;
  final String description;
  final String illustration;
  final String indicator;
  final double illustrationWidth;
}
