import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/app_widgets.dart';
import 'subject_card.dart';
import 'subjects_controller.dart';
import '../../models/subject.dart';
import 'subject_form.dart';


class SubjectsPage extends StatefulWidget {
  const SubjectsPage({super.key});

  @override
  State<SubjectsPage> createState() => _SubjectsPageState();
}

class _SubjectsPageState extends State<SubjectsPage> {
  late final SubjectsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = inject<SubjectsController>();
    _controller.load();
  }

  Future<void> _openForm([Subject? subject]) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SubjectForm(
        subject: subject,
        onSubmit: (name, description) => subject == null
            ? _controller.add(name, description)
            : _controller.update(subject, name, description),
      ),
    );
  }

  Future<void> _confirmDelete(Subject subject) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
    );
    if (confirmed != true) return;

    await _controller.delete(subject.id);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Ders silindi')));
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dersler')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Ders ekle',
        onPressed: _openForm,
        child: const Icon(Icons.add),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => switch (_controller.status) {
          SubjectsStatus.loading => const AppLoadingView(),
          SubjectsStatus.error => AppErrorView(
            message: _controller.errorMessage ?? 'Bir hata oluştu',
            onRetry: _controller.load,
          ),
          SubjectsStatus.empty => const AppEmptyView(
            icon: Icons.menu_book_outlined,
            title: 'Henüz ders yok',
            message: 'İlk dersini eklemek için + butonuna dokun.',
          ),
          SubjectsStatus.success => _buildList(context),
        },
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    final columns = Responsive.columns(context);
    final padding = AppSpacing.pagePadding(Responsive.widthOf(context));
    final subjects = _controller.subjects;

    Widget cardAt(int i) => SubjectCard(
      subject: subjects[i],
      onTap: () => context.pushNamed('/subjects/${subjects[i].id}'),
      onEdit: () => _openForm(subjects[i]),
      onDelete: () => _confirmDelete(subjects[i]),
    );

    if (columns == 1) {
      return ListView.separated(
        padding: padding,
        itemCount: subjects.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.listGap),
        itemBuilder: (_, i) => cardAt(i),
      );
    }

    return GridView.builder(
      padding: padding,
      itemCount: subjects.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: AppSpacing.listGap,
        crossAxisSpacing: AppSpacing.gutterTablet,
        mainAxisExtent: 170,
      ),
      itemBuilder: (_, i) => cardAt(i),
    );
  }
}
