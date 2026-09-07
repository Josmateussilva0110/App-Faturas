import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// An SVG from `assets/illustrations/`, drawn with the current theme's
/// `onSurface` color fed in as the SVG's `currentColor`. The illustrations
/// paint their neutral parts (card outlines, placeholder text bars) with
/// `currentColor` so they read correctly in both light and dark mode, while
/// keeping their brand accents fixed.
class AppIllustration extends StatelessWidget {
  const AppIllustration(
    this.name, {
    super.key,
    this.width,
    this.height,
    this.semanticLabel,
  });

  /// File name without the `assets/illustrations/` prefix or `.svg` suffix.
  final String name;

  final double? width;
  final double? height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/illustrations/$name.svg',
      width: width,
      height: height,
      fit: BoxFit.contain,
      semanticsLabel: semanticLabel,
      theme: SvgTheme(currentColor: Theme.of(context).colorScheme.onSurface),
    );
  }
}
