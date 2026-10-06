import 'package:flutter/material.dart';

import '../../core/widgets/modal_blur.dart';
import '../../models/subject.dart';
import 'subject_form.dart';
import 'subjects_controller.dart';

/// Ekleme (subject == null) ve düzenleme formunu alt panelde açar.
Future<void> showSubjectForm(
  BuildContext context,
  SubjectsController controller, [
  Subject? subject,
]) {
  return showBlurredSheet<void>(
    context: context,
    builder: (_) => SubjectForm(
      subject: subject,
      onSubmit: (name, description) => subject == null
          ? controller.add(name, description)
          : controller.update(subject, name, description),
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
          '"${subject.name}" dersi silinecek. Bu işlem geri alınamaz.',
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
