import 'package:flutter/material.dart';

/// İsim yazma penceresi. Kaydet'e basılırsa yazılan metni (boş olabilir),
/// vazgeçilirse null döndürür.
Future<String?> showEditNameDialog(BuildContext context, String current) {
  return showDialog<String>(
    context: context,
    builder: (_) => _EditNameDialog(current: current),
  );
}

class _EditNameDialog extends StatefulWidget {
  const _EditNameDialog({required this.current});

  final String current;

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.current,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adın'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 30,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(hintText: 'Adını yaz'),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Vazgeç'),
        ),
        TextButton(onPressed: _save, child: const Text('Kaydet')),
      ],
    );
  }
}
