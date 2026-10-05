import 'package:flutter/material.dart';

import '../../core/widgets/app_widgets.dart';
import '../../models/subject.dart';

class SubjectCard extends StatelessWidget {
  const SubjectCard({
    super.key,
    required this.subject,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  final Subject subject;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final description = subject.description;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,

    child: AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  subject.name,
                  style: textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: 'Düzenle',
                icon: const Icon(Icons.edit_outlined),
                onPressed: onEdit,
              ),
              IconButton(
                tooltip: 'Sil',
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
              ),
            ],
          ),
          if (description != null && description.isNotEmpty) ...[
            Text(description, style: textTheme.bodyMedium),
            const SizedBox(height: 8),
          ],
          AppChip(
            label: '${subject.totalStudyMinutes} dk',
            type: AppChipType.focus,
            icon: Icons.timer_outlined,
          ),
        ],
      ),
    )
    );
  }
}
