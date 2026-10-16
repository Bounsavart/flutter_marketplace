import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:provider/provider.dart';

import '../auth_state.dart';
import '../config.dart';
import '../constants/stat_colors.dart';
import '../theme.dart';
import 'notification_bell.dart';

/// Gradient hero header on top, rounded card filling the rest.
/// The header and [pinned] stay fixed; only [body] scrolls inside the card.
class HeroScaffold extends StatelessWidget {
  const HeroScaffold({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.trailingIcon,
    this.headerBottom,
    this.pinned,
    required this.body,
    this.floatingActionButton,
  });

  final String title;

  /// Small line above [title].
  final String? eyebrow;

  /// Small line below [title].
  final String? subtitle;
  final IconData? trailingIcon;
  final Widget? headerBottom;

  /// Non-scrolling section at the top of the card (stats, filters), followed
  /// by a divider.
  final Widget? pinned;
  final Widget body;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final c = Palette.of(context);
    final canPop = Navigator.of(context).canPop();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        floatingActionButton: floatingActionButton,
        body: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(gradient: c.heroGradient),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (canPop) ...[const HeroBackButton(), const SizedBox(width: 12)],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (eyebrow != null)
                                  Text(eyebrow!, style: const TextStyle(color: AppTheme.accentLight, fontSize: 12)),
                                Text(
                                  title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (subtitle != null)
                                  Text(subtitle!, style: const TextStyle(color: AppTheme.accentLight, fontSize: 13)),
                              ],
                            ),
                          ),
                          if (trailingIcon != null)
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(trailingIcon, color: Colors.white, size: 22),
                            ),
                          const NotificationBell(),
                        ],
                      ),
                      if (headerBottom != null) ...[const SizedBox(height: 14), headerBottom!],
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: OverlapCard(
                child: pinned == null
                    ? body
                    : Column(
                        children: [
                          pinned!,
                          const Divider(),
                          Expanded(child: body),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Square-cornered surface sitting flush under the header.
class OverlapCard extends StatelessWidget {
  const OverlapCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: Palette.of(context).card, child: child);
  }
}

/// Pads a small tappable [child] (chip, pill, icon button) out to a 48px
/// touch target without changing how it looks. Taps on the child itself still
/// hit its own InkWell; taps in the padding fall through to [onTap].
class TapTarget extends StatelessWidget {
  const TapTarget({super.key, required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: Align(widthFactor: 1, heightFactor: 1, child: child),
      ),
    );
  }
}

class HeroBackButton extends StatelessWidget {
  const HeroBackButton({super.key, this.solid = false});

  /// Solid white circle (used over photos) instead of translucent.
  final bool solid;

  @override
  Widget build(BuildContext context) {
    return CircleIconButton(icon: TablerIcons.arrow_left, solid: solid, onTap: () => Navigator.of(context).pop());
  }
}

class CircleIconButton extends StatelessWidget {
  const CircleIconButton({super.key, required this.icon, required this.onTap, this.solid = false, this.color});

  final IconData icon;
  final VoidCallback onTap;
  final bool solid;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return TapTarget(
      onTap: onTap,
      child: Material(
        color: solid ? Colors.white : Colors.white.withValues(alpha: 0.18),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 22, color: color ?? (solid ? AppTheme.textOnLight : Colors.white)),
          ),
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.tone});

  final String label;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final c = Palette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: tone.bgOn(c), borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: TextStyle(color: tone.fgOn(c), fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class PillChip extends StatelessWidget {
  const PillChip({super.key, required this.label, required this.selected, required this.onTap, this.icon});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = Palette.of(context);
    final fg = selected ? Colors.white : c.accent;
    return TapTarget(
      onTap: onTap,
      child: Material(
        color: selected ? AppTheme.primary : c.card,
        shape: StadiumBorder(side: BorderSide(color: selected ? AppTheme.primary : c.border)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 16, color: fg), const SizedBox(width: 4)],
                Text(
                  label,
                  style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PillTabs extends StatelessWidget {
  const PillTabs({super.key, required this.labels, required this.index, required this.onChanged});

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = Palette.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Material(
                color: i == index ? c.tint : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onChanged(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        color: i == index ? c.text : c.muted,
                        fontWeight: i == index ? FontWeight.w500 : FontWeight.w400,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AmenityTag extends StatelessWidget {
  const AmenityTag(this.name, {super.key, this.large = false});

  final String name;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final c = Palette.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 10 : 8, vertical: large ? 5 : 3),
      decoration: BoxDecoration(color: c.amenityBg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        name,
        style: TextStyle(color: c.amenityText, fontSize: large ? 14 : 13),
      ),
    );
  }
}

/// Stat tile on the neutral card fill; only the icon chip carries the stat's
/// color. [horizontal] puts the icon left of the number instead of above it.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.color = StatColor.purple,
    this.horizontal = false,
  });

  final String value;
  final String label;
  final IconData? icon;
  final StatColor color;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final c = Palette.of(context);
    // scaleDown shrinks long Lao labels on narrow phones instead of clipping.
    Widget fit(Widget child) => FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: child);
    final number = fit(
      Text(
        value,
        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: color.number(c), height: 1.15),
      ),
    );
    final caption = fit(Text(label, maxLines: 1, style: TextStyle(fontSize: 13, color: color.label(c))));
    final iconBox = icon == null
        ? null
        : Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: color.bg(c), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 26, color: color.icon(c)),
          );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: horizontal
            ? Row(
                children: [
                  ?iconBox,
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [number, caption]),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (iconBox != null) ...[iconBox, const SizedBox(height: 6)],
                  number,
                  caption,
                ],
              ),
      ),
    );
  }
}

/// Grid of [StatCard]s with a fixed number of columns.
class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.columns, required this.children, this.gap = 10});

  final int columns;
  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final slice = children.sublist(i, (i + columns).clamp(0, children.length));
      rows.add(
        Row(
          children: [
            for (var j = 0; j < columns; j++) ...[
              if (j > 0) SizedBox(width: gap),
              Expanded(child: j < slice.length ? slice[j] : const SizedBox()),
            ],
          ],
        ),
      );
      if (i + columns < children.length) rows.add(SizedBox(height: gap));
    }
    return Column(children: rows);
  }
}

class InfoBox extends StatelessWidget {
  const InfoBox({super.key, required this.text, this.icon = TablerIcons.info_circle});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = Palette.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: c.tint, borderRadius: BorderRadius.circular(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: c.text),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: c.text, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class AvatarCircle extends StatelessWidget {
  const AvatarCircle({super.key, this.icon = TablerIcons.user, this.text, this.size = 40});

  final IconData icon;
  final String? text;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = Palette.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: c.tint, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: text != null && text!.isNotEmpty
          ? Text(
              text!,
              style: TextStyle(color: c.accent, fontSize: size * 0.41, fontWeight: FontWeight.w600),
            )
          : Icon(icon, color: c.accent, size: size * 0.5),
    );
  }
}

final dangerButtonStyle = FilledButton.styleFrom(
  backgroundColor: AppTheme.dangerBg,
  foregroundColor: AppTheme.dangerFg,
  minimumSize: const Size(64, 34),
  padding: const EdgeInsets.symmetric(horizontal: 14),
  shape: const StadiumBorder(),
  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
);

// The theme's minimumSize has infinite width, which throws inside a Row.
final compactPrimaryStyle = FilledButton.styleFrom(
  minimumSize: const Size(64, 34),
  padding: const EdgeInsets.symmetric(horizontal: 16),
  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
);

final compactOutlinedStyle = OutlinedButton.styleFrom(
  minimumSize: const Size(64, 34),
  padding: const EdgeInsets.symmetric(horizontal: 16),
  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
);

/// Purple pill FAB with icon + label; the only element allowed a shadow.
class AppFab extends StatelessWidget {
  const AppFab({super.key, required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppTheme.primary.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = Palette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      // Light mode matches the gray cards; dark mode keeps its own darker inset.
      decoration: c.isDark
          ? BoxDecoration(color: c.pageBg, borderRadius: BorderRadius.circular(14))
          : ShapeDecoration(color: c.tile, shape: Theme.of(context).cardTheme.shape!),
      child: Column(
        children: [
          Icon(icon, size: 40, color: c.muted),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: c.muted),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.size = 16});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(fontSize: size, fontWeight: FontWeight.w600, color: Palette.of(context).text),
      ),
    );
  }
}

/// Room photo, or the purple gradient placeholder when there's none.
class RoomPhoto extends StatelessWidget {
  const RoomPhoto({super.key, required this.path, this.iconSize = 40});

  final String? path;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final url = AppConfig.fileUrl(path);
    final placeholder = DecoratedBox(
      decoration: BoxDecoration(gradient: Palette.of(context).imageGradient),
      child: Center(
        child: Icon(TablerIcons.home, size: iconSize, color: Colors.white.withValues(alpha: 0.7)),
      ),
    );
    if (url.isEmpty) return placeholder;
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}

class NavItem {
  const NavItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

class AppNavBar extends StatelessWidget {
  const AppNavBar({super.key, required this.items, required this.index, required this.onTap});

  final List<NavItem> items;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final c = Palette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.navBg,
        border: Border(top: BorderSide(color: c.navBorder, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => onTap(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: i == index ? c.navActive.withValues(alpha: 0.15) : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(items[i].icon, size: 22, color: i == index ? c.navActive : c.navInactive),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          items[i].label,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: i == index ? c.navActive : c.navInactive,
                            fontWeight: i == index ? FontWeight.w500 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sends a guest back to the login screen.
void goToLogin(BuildContext context) {
  Navigator.of(context).popUntil((route) => route.isFirst);
  context.read<AuthState>().exitGuest();
}

/// Placeholder tab content shown to guests for features that need an account.
class LoginRequired extends StatelessWidget {
  const LoginRequired({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return HeroScaffold(
      title: title,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const EmptyState(icon: TablerIcons.lock, text: 'ກະລຸນາເຂົ້າສູ່ລະບົບເພື່ອໃຊ້ງານສ່ວນນີ້'),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => goToLogin(context), child: const Text('ເຂົ້າສູ່ລະບົບ')),
          ],
        ),
      ),
    );
  }
}
