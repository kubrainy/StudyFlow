import 'package:flutter/material.dart';

import '../../../core/widgets/modal_blur.dart';
import '../../../models/subject.dart';
import '../view_model/subjects_view_model.dart';
import 'widgets/subject_form.dart';

/// Ekleme (subject == null) ve düzenleme formunu alt panelde açar.
Future<void> showSubjectForm(
  BuildContext context,
  SubjectsViewModel viewModel, [
  Subject? subject,
]) {
  return showBlurredSheet<void>(
    context: context,
    builder: (_) => SubjectForm(
      subject: subject,
      onSubmit: (name, description) => subject == null
          ? viewModel.add(name, description)
          : viewModel.update(subject, name, description),
    ),
  );
}

/// Silme onay diyaloğu; "Sil" denirse true döner.
Future<bool> confirmSubjectDelete(BuildContext context, Subject subject) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => ModalBlur(
      child: AlertDialog(
        title: const Text('Dersi sil'),
        content: Text(
          '"${subject.name}" dersi ve ona bağlı görevler silinecek. '
          'Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    ),
  );
  return confirmed == true;
}
