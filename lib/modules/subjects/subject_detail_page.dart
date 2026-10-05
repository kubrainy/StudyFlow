import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/app_widgets.dart';
import 'subjects_controller.dart';

class SubjectDetailPage extends StatelessWidget {
  const SubjectDetailPage({super.key, required this.subjectId});

  final String subjectId;

  @override
  Widget build(BuildContext context) {
    final subject = inject<SubjectsController>().findById(subjectId);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Ders detayı')),
      body: subject == null
          ? const AppEmptyView(
              icon: Icons.search_off_outlined,
              title: 'Ders bulunamadı',
            )
          : ListView(
              padding: AppSpacing.pagePadding(Responsive.widthOf(context)),
              children: [
                Text(subject.name, style: textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.md),
                if (subject.description != null &&
                    subject.description!.isNotEmpty) ...[
                  Text(subject.description!, style: textTheme.bodyLarge),
                  const SizedBox(height: AppSpacing.md),
                ],
                AppChip(
                  label: '${subject.totalStudyMinutes} dk çalışıldı',
                  type: AppChipType.focus,
                  icon: Icons.timer_outlined,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Oluşturulma: ${DateFormat('d.MM.yyyy').format(subject.createdAt)}',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
    );
  }
}
