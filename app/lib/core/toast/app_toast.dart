import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

import '../theme/app_colors.dart';

/// Global success/error/warning toast, floating at the **top** of the
/// screen — no [BuildContext] required.
///
/// Wire [navigatorKey] into `MaterialApp.navigatorKey` once, then call
/// [AppToast.success]/[error]/[warning] from any screen, dialog, or even an
/// [AppState] method.
class AppToast {
  const AppToast._();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static OverlayEntry? _entry;

  static void success(String message) => _show(message, icon: Icons.check_circle, background: _successColor);
  static void warning(String message) => _show(message, icon: Icons.warning_amber_rounded, background: _warningColor);

  static void error(String message) {
    final context = navigatorKey.currentContext;
    final scheme = context == null ? null : Theme.of(context).colorScheme;
    _show(
      message,
      icon: Icons.error_outline,
      background: scheme?.error ?? Colors.red,
      foreground: scheme?.onError ?? Colors.white,
    );
  }

  static Color get _successColor => AppColors.toastBackground(AppColors.hueSavings);
  static Color get _warningColor => AppColors.toastBackground(AppColors.hueWarning);

  static void _show(
    String message, {
    required IconData icon,
    required Color background,
    Color foreground = Colors.white,
  }) {
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    _entry?.remove();
    _entry = null;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _ToastBanner(
        message: message,
        icon: icon,
        background: background,
        foreground: foreground,
        onDismissed: () {
          entry.remove();
          if (identical(_entry, entry)) _entry = null;
        },
      ),
    );
    _entry = entry;
    overlay.insert(entry);
  }
}

class _ToastBanner extends StatefulWidget {
  const _ToastBanner({
    required this.message,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onDismissed,
  });

  final String message;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onDismissed;

  @override
  State<_ToastBanner> createState() => _ToastBannerState();
}

class _ToastBannerState extends State<_ToastBanner> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
  late final _offset = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    _controller.forward();
    Future.delayed(const Duration(seconds: 3), _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    // A newer toast may have force-removed this entry (and disposed this
    // state) while the reverse animation was still in flight — don't call
    // onDismissed twice in that case.
    if (!mounted) return;
    widget.onDismissed();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: SlideTransition(
          position: _offset,
          child: FadeTransition(
            opacity: _controller,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: _dismiss,
                  onVerticalDragEnd: (details) {
                    if ((details.primaryVelocity ?? 0) < 0) _dismiss();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.mdPlus,
                    ),
                    decoration: BoxDecoration(
                      color: widget.background,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      // Exceção deliberada ao `AppPalette.shadowMedium`, que
                      // some no tema escuro: o fundo do toast é escuro fixo
                      // nos dois temas, então ele precisa da sombra sempre
                      // para se descolar do conteúdo atrás.
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(widget.icon, color: widget.foreground, size: 20),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            widget.message,
                            style: TextStyle(color: widget.foreground, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
