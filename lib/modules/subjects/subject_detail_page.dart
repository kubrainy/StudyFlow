import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/app_widgets.dart';
import '../../models/subject.dart';
import 'subjects_controller.dart';

class SubjectDetailPage extends StatelessWidget {
  const SubjectDetailPage({super.key, required this.subjectId});

  final String subjectId;

  @override
  Widget build(BuildContext context) {
    final controller = inject<SubjectsController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Ders detayı')),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final subject = controller.findById(subjectId);
          if (subject == null) {
            return const AppEmptyView(
              icon: Icons.search_off_outlined,
              title: 'Ders bulunamadı',
            );
          }
          return _buildContent(context, subject);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, Subject subject) {
    final description = subject.description;

    return ListView(
      padding: AppSpacing.pagePadding(Responsive.widthOf(context)),
      children: [
        AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.focusFill,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.menu_book_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      style: AppTextStyles.headlineMd.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (description != null && description.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        description,
                        style: AppTextStyles.bodyLg.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerLeft,
          child: AppChip(
            label: '${subject.totalStudyMinutes} dk çalışıldı',
            type: AppChipType.focus,
            icon: Icons.timer_outlined,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: AppIconSize.chip,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Oluşturulma: ${DateFormat('d.MM.yyyy').format(subject.createdAt)}',
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
