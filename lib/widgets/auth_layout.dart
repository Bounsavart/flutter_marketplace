import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../theme.dart';
import 'ui.dart';

/// Gradient hero with an icon badge and title, then a rounded white card.
/// The whole page scrolls so the form stays reachable above the keyboard.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
    this.step,
    this.steps = 2,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  /// 0-based index for the progress dots; null hides them.
  final int? step;
  final int steps;

  @override
  Widget build(BuildContext context) {
    final c = Palette.of(context);
    final canPop = Navigator.of(context).canPop();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: c.card,
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(gradient: c.heroGradient),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            height: 44,
                            child: canPop ? const HeroBackButton() : null,
                          ),
                        ),
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, size: 36, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.accentLight,
                            fontSize: 14,
                          ),
                        ),
                        if (step != null) ...[
                          const SizedBox(height: 16),
                          ProgressDots(count: steps, active: step!),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Container(
                color: c.card,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                child: SafeArea(
                  top: false,
                  // Login/register keep the white bordered cards rather than the
                  // app-wide gray ones.
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      cardTheme: AppTheme.cardTheme(c.card, c.border, 0.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: children,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProgressDots extends StatelessWidget {
  const ProgressDots({super.key, required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == active ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i <= active
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

/// "Or connect using" divider followed by the single Google button.
class SocialConnect extends StatelessWidget {
  const SocialConnect({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'ຫຼື ເຊື່ອມຕໍ່ດ້ວຍ',
                style: TextStyle(
                  color: Palette.of(context).muted,
                  fontSize: 13,
                ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 14),
        Material(
          color: const Color(0xFFDB4437),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            // Google OAuth isn't configured yet (no client IDs / backend
            // endpoint), so the button only tells the user it's unavailable.
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'ການເຂົ້າສູ່ລະບົບດ້ວຍ Google ຍັງບໍ່ທັນພ້ອມໃຊ້ງານ',
                ),
              ),
            ),
            child: const SizedBox(
              width: 36,
              height: 36,
              child: Icon(
                TablerIcons.brand_google,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
