import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_buttons.dart';
import '../../models/subject.dart';
import '../../models/task.dart';

class TaskFormData {
  const TaskFormData({
    required this.title,
    this.description,
    this.subjectId,
    required this.priority,
    this.dueDate,
  });

  final String title;
  final String? description;
  final String? subjectId;
  final TaskPriority priority;
  final DateTime? dueDate;
}

class TaskForm extends StatefulWidget {
  const TaskForm({
    super.key,
    this.task,
    this.initialSubjectId,
    required this.subjects,
    required this.onSubmit,
    this.onDelete,
  });

  final Task? task;
  final String? initialSubjectId;
  final List<Subject> subjects;
  final Future<void> Function(TaskFormData data) onSubmit;

  /// Verilirse (düzenleme modunda) Kaydet'in yanında Sil butonu çıkar.
  final VoidCallback? onDelete;

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  String? _subjectId;
  late TaskPriority _priority;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title);
    _descriptionController = TextEditingController(text: task?.description);
    final wanted = task?.subjectId ?? widget.initialSubjectId;
    final hasSubject = widget.subjects.any((s) => s.id == wanted);
    _subjectId = hasSubject ? wanted : null;
    _priority = task?.priority ?? TaskPriority.medium;
    _dueDate = task?.dueDate;
    _titleController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _canSave => _titleController.text.trim().isNotEmpty;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    final description = _descriptionController.text.trim();
    await widget.onSubmit(
      TaskFormData(
        title: _titleController.text.trim(),
        description: description.isEmpty ? null : description,
        subjectId: _subjectId,
        priority: _priority,
        dueDate: _dueDate,
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  String get _subjectName {
    for (final s in widget.subjects) {
      if (s.id == _subjectId) return s.name;
    }
    return 'Ders yok';
  }

  /// Ders listesini satırın sağ kenarına hizalı açar.
  Future<void> _pickSubject(BuildContext rowContext) async {
    const noSubject = '';
    final box = rowContext.findRenderObject()! as RenderBox;
    final top = box.localToGlobal(Offset.zero).dy + box.size.height;
    final screenWidth = MediaQuery.sizeOf(context).width;

    final picked = await showMenu<String>(
      context: context,
      // left ekran dışında: menü ekranın sağ kenarına yaslanır.
      position: RelativeRect.fromLTRB(screenWidth, top, 0, 0),
      items: [
        const PopupMenuItem(value: noSubject, child: Text('Ders yok')),
        for (final s in widget.subjects)
          PopupMenuItem(value: s.id, child: Text(s.name)),
      ],
    );
    if (picked == null) return;
    setState(() => _subjectId = picked == noSubject ? null : picked);
  }

  bool _isDay(DateTime? date, DateTime day) =>
      date != null && DateUtils.isSameDay(date, day);

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.task != null;
    final dueDate = _dueDate;
    final today = DateUtils.dateOnly(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    final isToday = _isDay(dueDate, today);
    final isTomorrow = _isDay(dueDate, tomorrow);
    final isCustom = dueDate != null && !isToday && !isTomorrow;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Kapat',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const Spacer(),
              AppPrimaryButton(
                label: 'Kaydet',
                onPressed: _canSave ? _save : null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isEdit ? 'Görevi düzenle' : 'Görev ekle',
            style: AppTextStyles.headlineMd.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Görev başlığı'),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Column(
              children: [
                _SettingRow(
                  icon: Icons.notes_outlined,
                  child: TextField(
                    controller: _descriptionController,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Açıklama ekle',
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),
                Builder(
                  builder: (rowContext) => InkWell(
                    onTap: () => _pickSubject(rowContext),
                    child: _SettingRow(
                      icon: Icons.menu_book_outlined,
                      label: 'Ders',
                      value: _subjectName,
                    ),
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),
                _SettingRow(
                  icon: Icons.flag_outlined,
                  label: 'Öncelik',
                  chips: [
                    _SelectChip(
                      label: 'Düşük',
                      dot: AppColors.textDisabled,
                      selected: _priority == TaskPriority.low,
                      selectedColors: _lowColors,
                      onTap: () => setState(() => _priority = TaskPriority.low),
                    ),
                    _SelectChip(
                      label: 'Orta',
                      dot: AppColors.primary,
                      selected: _priority == TaskPriority.medium,
                      selectedColors: _mediumColors,
                      onTap: () =>
                          setState(() => _priority = TaskPriority.medium),
                    ),
                    _SelectChip(
                      label: 'Yüksek',
                      dot: AppColors.danger,
                      selected: _priority == TaskPriority.high,
                      selectedColors: _highColors,
                      onTap: () =>
                          setState(() => _priority = TaskPriority.high),
                    ),
                  ],
                ),
                const Divider(height: 1, color: AppColors.border),
                _SettingRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Son tarih',
                  chips: [
                    _SelectChip(
                      label: 'Bugün',
                      selected: isToday,
                      selectedColors: _mediumColors,
                      onTap: () =>
                          setState(() => _dueDate = isToday ? null : today),
                    ),
                    _SelectChip(
                      label: 'Yarın',
                      selected: isTomorrow,
                      selectedColors: _mediumColors,
                      onTap: () => setState(
                        () => _dueDate = isTomorrow ? null : tomorrow,
                      ),
                    ),
                    _SelectChip(
                      label: isCustom
                          ? DateFormat('d.MM.yyyy').format(dueDate)
                          : 'Tarih seç',
                      icon: isCustom ? null : Icons.calendar_today_outlined,
                      selected: isCustom,
                      selectedColors: _mediumColors,
                      onTap: _pickDate,
                      onClear: isCustom
                          ? () => setState(() => _dueDate = null)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (widget.onDelete != null) ...[
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: widget.onDelete,
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: const Text('Görevi sil'),
            ),
          ],
        ],
      ),
    );
  }
}

typedef _ChipColors = (Color fill, Color border, Color text);

const _lowColors = (
  AppColors.surfaceSubdued,
  AppColors.border,
  AppColors.textSecondary,
);
const _mediumColors = (
  AppColors.focusFill,
  AppColors.focusBorder,
  AppColors.primary,
);
const _highColors = (
  AppColors.highFill,
  AppColors.highBorder,
  AppColors.danger,
);

/// Seçilebilir küçük çip; seçiliyken [selectedColors] ile boyanır.
class _SelectChip extends StatelessWidget {
  const _SelectChip({
    required this.label,
    required this.selected,
    required this.selectedColors,
    required this.onTap,
    this.dot,
    this.icon,
    this.onClear,
  });

  final String label;
  final bool selected;
  final _ChipColors selectedColors;
  final VoidCallback onTap;
  final Color? dot;
  final IconData? icon;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final (fill, border, text) = selected
        ? selectedColors
        : (AppColors.surface, AppColors.border, AppColors.textSecondary);

    return Semantics(
      label: label,
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 36,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: border),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (dot != null) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: dot,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (icon != null) ...[
                  Icon(icon, size: AppIconSize.chip, color: text),
                  const SizedBox(width: 6),
                ],
                Text(label, style: AppTextStyles.bodySm.copyWith(color: text)),
                if (onClear != null) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: onClear,
                    child: Icon(
                      Icons.close,
                      size: AppIconSize.chip,
                      color: text,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ayarlar listesi satırı: ikon + (etiket / değer), etiket altında çipler ya da serbest içerik.
class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    this.label,
    this.value,
    this.child,
    this.chips,
  });

  final IconData icon;
  final String? label;
  final String? value;
  final Widget? child;
  final List<Widget>? chips;

  @override
  Widget build(BuildContext context) {
    final leading = Icon(
      icon,
      size: AppIconSize.chip + 4,
      color: AppColors.textSecondary,
    );

    final Widget content;
    if (child != null) {
      content = Row(
        children: [
          leading,
          const SizedBox(width: AppSpacing.md),
          Expanded(child: child!),
        ],
      );
    } else if (chips != null) {
      // Etiket yok: ikon satırı tanıtıyor; çipler satırı eşit paylaşır.
      content = Row(
        children: [
          leading,
          const SizedBox(width: AppSpacing.md),
          for (var i = 0; i < chips!.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.xs),
            Expanded(child: chips![i]),
          ],
        ],
      );
    } else {
      content = Row(
        children: [
          leading,
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(label ?? '', style: AppTextStyles.bodyLg)),
          Flexible(
            child: Text(
              value ?? '',
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyLg.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: chips != null ? AppSpacing.sm : 0,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: content,
      ),
    );
  }
}
