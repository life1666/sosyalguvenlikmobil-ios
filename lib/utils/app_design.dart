import 'package:flutter/material.dart';
import 'theme_helper.dart';

/// Shared visual language for the first redesigned screens.
class AppDesign {
  static const background = Color(0xFFF4F6FA);
  static const ink = Color(0xFF17243B);
  static const muted = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
  static const radius = 20.0;
  static bool get isDark => ThemeHelper().darkMode;
  static Color get activeBackground =>
      isDark ? const Color(0xFF0F172A) : background;
  static Color get activeSurface =>
      isDark ? const Color(0xFF1E293B) : Colors.white;
  static Color get activeInk => isDark ? const Color(0xFFF1F5F9) : ink;
  static Color get activeMuted => isDark ? const Color(0xFF94A3B8) : muted;
  static Color get activeBorder => isDark ? const Color(0xFF334155) : border;

  static AppBar appBar(String title, {List<Widget>? actions}) =>
      AppMenuBar(title: Text(title), actions: actions);
}

/// Consistent toolbar for feature pages; all existing actions are retained.
class AppMenuBar extends AppBar {
  AppMenuBar({
    super.key,
    Widget? title,
    Widget? leading,
    super.actions,
    super.bottom,
  }) : super(
          leading: leading is IconButton
              ? AppBackButton(onPressed: leading.onPressed)
              : leading ??
                  Builder(
                      builder: (context) => Navigator.canPop(context)
                          ? const AppBackButton()
                          : const SizedBox.shrink()),
          title: title is Text && title.data != null
              ? Text(title.data!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: AppDesign.activeInk,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1.2))
              : title,
          backgroundColor: AppDesign.activeBackground,
          foregroundColor: AppDesign.activeInk,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleSpacing: 16,
          toolbarHeight: 64,
          iconTheme: IconThemeData(color: AppDesign.activeInk),
          actionsIconTheme: IconThemeData(color: AppDesign.activeInk),
        );
}

class AppBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const AppBackButton({super.key, this.onPressed});
  @override
  Widget build(BuildContext context) {
    final inkColor = AppDesign.activeInk;
    return Center(
        child: IconButton(
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: onPressed ?? () => Navigator.maybePop(context),
      style: IconButton.styleFrom(
        foregroundColor: inkColor,
        backgroundColor: AppDesign.activeSurface,
        minimumSize: const Size(48, 48),
        side: BorderSide(color: AppDesign.activeBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: Icon(Icons.arrow_back_rounded, color: inkColor, size: 24),
    ));
  }
}

class AppBottomMenu extends StatelessWidget {
  final int selectedIndex;
  final List<String> labels;
  final List<IconData> icons;
  final ValueChanged<int> onTap;
  const AppBottomMenu(
      {super.key,
      required this.selectedIndex,
      required this.labels,
      required this.icons,
      required this.onTap});
  @override
  Widget build(BuildContext context) => ColoredBox(
        color: Colors.transparent,
        child: SafeArea(
            top: false,
            child: AppContent(
                child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Material(
                color: AppDesign.activeSurface,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: AppDesign.activeBorder)),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < labels.length; i++)
                          Expanded(
                            child: Semantics(
                              button: true,
                              selected: selectedIndex == i,
                              child: InkWell(
                                onTap: () => onTap(i),
                                borderRadius: BorderRadius.circular(15),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 3, vertical: 5),
                                  child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 4),
                                            decoration: BoxDecoration(
                                                color: selectedIndex == i
                                                    ? Theme.of(context)
                                                        .primaryColor
                                                        .withValues(alpha: .1)
                                                    : AppDesign
                                                        .activeBackground,
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                            child: Icon(icons[i],
                                                size: 21,
                                                color: selectedIndex == i
                                                    ? Theme.of(context)
                                                        .primaryColor
                                                    : AppDesign.activeInk)),
                                        const SizedBox(height: 3),
                                        Text(labels[i],
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontSize: 10,
                                                height: 1.15,
                                                fontWeight: selectedIndex == i
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                                color: AppDesign.activeInk)),
                                      ]),
                                ),
                              ),
                            ),
                          ),
                      ]),
                ),
              ),
            ))),
      );
}

class AppContent extends StatelessWidget {
  final Widget child;
  const AppContent({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Align(
        heightFactor: 1,
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760), child: child),
      );
}

class AppSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const AppSurface(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(20)});
  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: AppDesign.activeSurface,
          borderRadius: BorderRadius.circular(AppDesign.radius),
          border: Border.all(color: AppDesign.activeBorder),
        ),
        child: child,
      );
}

class AppIntro extends StatelessWidget {
  final String eyebrow, title, description;
  final IconData icon;
  const AppIntro(
      {super.key,
      required this.eyebrow,
      required this.title,
      required this.description,
      required this.icon});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            AppDesign.ink,
            Color.lerp(AppDesign.ink, Theme.of(context).primaryColor, .55)!
          ], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(AppDesign.radius),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: const Color(0xFFB9D5FF), size: 20),
            const SizedBox(width: 8),
            Expanded(
                child: Text(eyebrow,
                    style: const TextStyle(
                        color: Color(0xFFB9D5FF),
                        fontWeight: FontWeight.w600,
                        fontSize: 12)))
          ]),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  height: 1.2,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text(description,
              style: const TextStyle(
                  color: Color(0xFFDBE4F1), fontSize: 14, height: 1.5)),
        ]),
      );
}

/// A secondary action inside an expanded feature category.
class AppSubmenuTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final String? badge;

  const AppSubmenuTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: AppDesign.activeSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppDesign.activeBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(icon, size: 21, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                            color: AppDesign.activeInk,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          )),
                      if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(subtitle!,
                            style: TextStyle(
                              color: AppDesign.activeMuted,
                              fontSize: 12,
                              height: 1.4,
                            )),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (badge != null) ...[
                      _AppStatusBadge(label: badge!),
                      const SizedBox(height: 5),
                    ],
                    Icon(Icons.chevron_right_rounded,
                        size: 20, color: AppDesign.activeMuted),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

class AppActionTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool expanded;
  final Color? foregroundColor;
  final String? badge;
  const AppActionTile(
      {super.key,
      required this.title,
      this.subtitle,
      required this.icon,
      required this.onTap,
      this.foregroundColor,
      this.badge,
      this.expanded = false});
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                        color: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(14)),
                    child: Icon(icon,
                        color: Theme.of(context).primaryColor, size: 23)),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(title,
                          style: TextStyle(
                              color: foregroundColor ?? AppDesign.activeInk,
                              fontWeight: FontWeight.w600,
                              fontSize: 15)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(subtitle!,
                            style: TextStyle(
                                color: AppDesign.activeMuted,
                                fontSize: 12,
                                height: 1.4))
                      ],
                    ])),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (badge != null) ...[
                      _AppStatusBadge(label: badge!),
                      const SizedBox(height: 5),
                    ],
                    Icon(
                        expanded
                            ? Icons.expand_more_rounded
                            : Icons.chevron_right_rounded,
                        color: AppDesign.activeMuted),
                  ],
                ),
              ])),
        ),
      );
}

class _AppStatusBadge extends StatelessWidget {
  final String label;

  const _AppStatusBadge({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppDesign.isDark
              ? const Color(0xFF123B2D)
              : const Color(0xFFECFDF3),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: AppDesign.isDark
                ? const Color(0xFF267A57)
                : const Color(0xFFB7E8CE),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: AppDesign.isDark
                ? const Color(0xFF6EE7A8)
                : const Color(0xFF168653),
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: .1,
          ),
        ),
      );
}
