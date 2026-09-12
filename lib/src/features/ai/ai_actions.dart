import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'ai_client.dart';
import 'ai_providers.dart';

/// Bottom sheet with 3 AI code actions + key field + result preview.
///
/// To avoid coupling to another agent's SettingsStore file, [baseUrl] and
/// [model] are accepted as params with OpenAI-compatible defaults; callers
/// may pass values from settings instead.
class AiActionsSheet extends ConsumerStatefulWidget {
  final String selectedCode;
  final String baseUrl;
  final String model;
  final AiClient? clientOverride;

  const AiActionsSheet({
    super.key,
    required this.selectedCode,
    this.baseUrl = 'https://api.openai.com/v1',
    this.model = 'gpt-4o-mini',
    this.clientOverride,
  });

  /// Convenience helper to show the sheet.
  static Future<void> show(
    BuildContext context, {
    required String selectedCode,
    String baseUrl = 'https://api.openai.com/v1',
    String model = 'gpt-4o-mini',
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AiActionsSheet(
        selectedCode: selectedCode,
        baseUrl: baseUrl,
        model: model,
      ),
    );
  }

  @override
  ConsumerState<AiActionsSheet> createState() => _AiActionsSheetState();
}

class _AiActionsSheetState extends ConsumerState<AiActionsSheet> {
  final _keyController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  bool _keyLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadKey();
  }

  Future<void> _loadKey() async {
    final saved = await _storage.read(key: kNovaAiKeyStorageKey);
    if (mounted && saved != null) {
      _keyController.text = saved;
    }
    if (mounted) {
      setState(() => _keyLoaded = true);
    }
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _saveKey() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) return;
    await _storage.write(key: kNovaAiKeyStorageKey, value: key);
    ref.invalidate(aiKeyProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ المفتاح')),
      );
    }
  }

  String _promptFor(String kind) {
    final code = widget.selectedCode;
    switch (kind) {
      case 'explain':
        return 'اشرح الكود التالي:\n$code';
      case 'fix':
        return 'أصلح الخطأ في الكود التالي:\n$code';
      case 'complete':
        return 'أكمل الكود التالي:\n$code';
      default:
        return code;
    }
  }

  Future<void> _runAction(String kind) async {
    final apiKey = _keyController.text.trim();
    if (apiKey.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('أدخل مفتاح API أولا')),
        );
      }
      return;
    }
    if (widget.selectedCode.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يوجد كود محدد')),
        );
      }
      return;
    }

    final notifier = ref.read(aiStateProvider.notifier);
    final prompt = _promptFor(kind);

    if (widget.clientOverride != null) {
      // Standalone path (useful in tests / previews): bypass provider.
      try {
        notifier.setBusy();
        final content = await widget.clientOverride!.call(
          baseUrl: widget.baseUrl,
          apiKey: apiKey,
          model: widget.model,
          messages: <Map<String, String>>[
            {'role': 'user', 'content': prompt},
          ],
        );
        notifier.setResult(content);
      } on AiException catch (e) {
        notifier.setError(e.message);
      } catch (e) {
        notifier.setError(e.toString());
      }
      return;
    }

    await notifier.run(
      baseUrl: widget.baseUrl,
      apiKey: apiKey,
      model: widget.model,
      messages: <Map<String, String>>[
        {'role': 'user', 'content': prompt},
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiStateProvider);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'إجراءات الذكاء الاصطناعي',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: const BoxConstraints(maxHeight: 140),
              child: SingleChildScrollView(
                child: Text(
                  widget.selectedCode.isEmpty
                      ? 'لا يوجد كود محدد'
                      : widget.selectedCode,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _keyController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'API Key',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _saveKey,
                  child: const Text('حفظ'),
                ),
              ],
            ),
            if (!_keyLoaded) const SizedBox(height: 4),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton(
                  onPressed:
                      aiState.loading ? null : () => _runAction('explain'),
                  child: const Text('اشرح الكود'),
                ),
                ElevatedButton(
                  onPressed: aiState.loading ? null : () => _runAction('fix'),
                  child: const Text('أصلح الخطأ'),
                ),
                ElevatedButton(
                  onPressed:
                      aiState.loading ? null : () => _runAction('complete'),
                  child: const Text('أكمل الكود'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (aiState.loading)
              const Center(child: CircularProgressIndicator()),
            if (aiState.error.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(aiState.error),
              ),
            if (aiState.result.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                constraints: const BoxConstraints(maxHeight: 240),
                child: SingleChildScrollView(child: Text(aiState.result)),
              ),
          ],
        ),
      ),
    );
  }
}

