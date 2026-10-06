import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/modal_blur.dart';
import '../../../../models/subject.dart';
import 'pomodoro_sizes.dart';

/// Halkanın altındaki "kitap  Matematik  ▾" seçim alanı (input ölçüsünde:
/// 48dp, 8dp köşe); bulunduğu satırı doldurur. Sayaç çalışırken
/// [locked] olur: soluk görünür, kilit ikonu çıkar ve dokunulmaz.
class PomodoroSubjectField extends StatelessWidget {
  const PomodoroSubjectField({
    super.key,
    required this.subjectName,
    required this.locked,
    this.onTap,
  });

  /// null ise "Serbest çalışma" yazılır.
  final String? subjectName;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: locked ? 0.6 : 1,
      child: GestureDetector(
        onTap: locked ? null : onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: PomodoroSizes.subjectField,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: locked ? AppColors.surfaceSubdued : AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: AppRadius.controlAll,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.menu_book_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  subjectName ?? 'Serbest çalışma',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                locked ? Icons.lock_outline : Icons.expand_more,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Seçimin sonucu. Panel seçmeden kapanırsa Future null döner; "Serbest
/// çalışma" seçilirse id null olan bir kayıt döner. Bu ikisini ayırmak için
/// sonucu kayıtla (record) sarıyoruz.
typedef PomodoroSubjectChoice = ({String? id});

Future<PomodoroSubjectChoice?> showPomodoroSubjectPicker(
  BuildContext context, {
  required List<Subject> subjects,
  required String? selectedId,
  required int Function(String? subjectId) todayMinutesOf,
}) {
  return showBlurredSheet<PomodoroSubjectChoice>(
    context: context,
    builder: (sheetContext) {
      Widget option(String? id, String name) {
        final selected = id == selectedId;
        return InkWell(
          onTap: () => Navigator.of(sheetContext).pop((id: id)),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyLg.copyWith(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${todayMinutesOf(id)} dk',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(Icons.check, color: AppColors.primary),
                ],
              ],
            ),
          ),
        );
      }

      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.6,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Text(
                  'Ders seç',
                  style: AppTextStyles.headlineMd.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              option(null, 'Serbest çalışma'),
              for (final s in subjects) option(s.id, s.name),
            ],
          ),
        ),
      );
    },
  );
}
