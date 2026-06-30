import 'package:flutter/material.dart';

/// Themed wrapper around [AppBar]. Styled entirely by
/// `Theme.of(context).appBarTheme`. See `docs/COMPONENT_SPEC.md` §5.
class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  const AppBarWidget({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.centerTitle = false,
  });

  /// A [String] is wrapped in [Text] using the app bar theme's
  /// `titleTextStyle`; pass a [Widget] for anything custom.
  final Object? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final bool centerTitle;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  Widget _resolveTitle(BuildContext context) {
    final value = title;
    if (value is Widget) return value;
    if (value is String) {
      return Text(value, style: Theme.of(context).appBarTheme.titleTextStyle);
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: _resolveTitle(context),
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      centerTitle: centerTitle,
    );
  }
}
