import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n.dart';
import '../../core/date_formats.dart';

class FeedbackView extends ConsumerStatefulWidget {
  const FeedbackView({super.key});

  @override
  ConsumerState<FeedbackView> createState() => _FeedbackViewState();
}

class _FeedbackViewState extends ConsumerState<FeedbackView> {
  final _formKey = GlobalKey<FormState>();
  final _textCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t.feedbackTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.feedbackSubtitle,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _textCtrl,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                minLines: 6,
                maxLines: 10,
                decoration: InputDecoration(
                  labelText: t.feedbackHint,
                  hintText: t.feedbackHint,
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 20) {
                    return t.feedbackTooShort;
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 24),
            Text(
              t.feedbackLimitInfo,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.send),
                label: Text(t.feedbackSubmit),
                onPressed: _sending ? null : _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final t = ref.read(stringsProvider);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      messenger?.showSnackBar(SnackBar(content: Text(t.feedbackError)));
      return;
    }
    setState(() => _sending = true);
    try {
      final now = DateTime.now();
      final windowStart = now.subtract(const Duration(days: 3));
      final latest = await FirebaseFirestore.instance
          .collection('userFeedback')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      if (latest.docs.isNotEmpty) {
        final ts = latest.docs.first['createdAt'];
        DateTime? lastSent;
        if (ts is Timestamp) {
          lastSent = ts.toDate();
        } else if (ts is DateTime) {
          lastSent = ts;
        }
        if (lastSent != null && lastSent.isAfter(windowStart)) {
          final next = lastSent.add(const Duration(days: 3));
          final formatted = DateFormats.feedback.format(next);
          final msg = t.feedbackLimitReached.replaceFirst('{date}', formatted);
          messenger?.showSnackBar(SnackBar(content: Text(msg)));
          setState(() => _sending = false);
          return;
        }
      }

      await FirebaseFirestore.instance.collection('userFeedback').add({
        'userId': user.uid,
        'message': _textCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'userEmail': user.email ?? '',
        'userName': user.displayName ?? '',
      });
      if (!mounted) return;
      messenger?.showSnackBar(SnackBar(content: Text(t.feedbackSuccess)));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      messenger?.showSnackBar(SnackBar(content: Text(t.feedbackError)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}
