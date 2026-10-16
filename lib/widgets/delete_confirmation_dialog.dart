import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../theme.dart';

Future<bool?> showDeleteConfirmationDialog({
  required BuildContext context,
  required String title,
  required String description,
  String? warning,
  String deleteLabel = 'ລຶບ',
}) {
  final palette = Palette.of(context);
  const danger = AppTheme.dangerFg;
  final warningBg = Tone.warning.bgOn(palette);
  final warningFg = Tone.warning.fgOn(palette);

  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: palette.card,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(TablerIcons.trash, color: danger, size: 30),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: palette.text,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(color: palette.text, fontSize: 14),
              ),
              if (warning != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: warningBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: warningFg.withValues(alpha: 0.24),
                    ),
                  ),
                  child: Text(
                    warning,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: warningFg,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'ການກະທຳນີ້ບໍ່ສາມາດກູ້ຄືນໄດ້',
                textAlign: TextAlign.center,
                style: TextStyle(color: palette.muted, fontSize: 13),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: danger,
                          side: const BorderSide(color: danger, width: 1.5),
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('ຍົກເລີກ'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: danger,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: Text(deleteLabel),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
