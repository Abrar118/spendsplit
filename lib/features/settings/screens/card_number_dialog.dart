import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';

/// Edits the stored card number (12–19 digits). Only the first and last four
/// are ever shown.
class CardNumberEditorDialog extends StatefulWidget {
  const CardNumberEditorDialog({
    required this.initialDigits,
    required this.onSave,
    super.key,
  });

  final String initialDigits;
  final Future<void> Function(String value) onSave;

  @override
  State<CardNumberEditorDialog> createState() => _CardNumberEditorDialogState();
}

class _CardNumberEditorDialogState extends State<CardNumberEditorDialog> {
  late final TextEditingController _controller;
  String? _errorText;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialDigits);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Card number'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Enter 12–19 digits. Only the first and last four will be visible.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 19,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: 'Card number',
              counterText: '',
              errorText: _errorText,
            ),
            onChanged: (_) {
              if (_errorText != null) {
                setState(() => _errorText = null);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textPrimary,
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final value = _controller.text.trim();
    if (value.length < 12) {
      setState(() => _errorText = 'Enter at least 12 digits.');
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.onSave(value);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorText = "Couldn't save the card number. Try again.";
      });
    }
  }
}
