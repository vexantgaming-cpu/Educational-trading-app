import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:market_sim/market_sim.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_info.dart';
import '../game/game_scope.dart';
import '../progress/progress_scope.dart';
import '../settings/settings_store.dart';
import '../theme/app_colors.dart';
import '../widgets/gradient_button.dart';

/// Opens [uri] (a `mailto:` link) and reports whether an app took it.
typedef FeedbackLauncher = Future<bool> Function(Uri uri);

Future<bool> _openEmailApp(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

const feedbackTopics = [
  'Lessons',
  'Trading game',
  'League',
  'Something broke',
  'Idea',
  'Other',
];

const _ratingWords = ['Poor', 'Not great', 'Okay', 'Good', 'Love it'];

/// Collects a rating, a topic and a message, then hands them to the user's
/// email app addressed to [feedbackEmail]. Nothing is sent without the user
/// pressing send in their email app.
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key, this.launcher = _openEmailApp});

  final FeedbackLauncher launcher;

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _message = TextEditingController();
  int _rating = 0;
  String? _topic;
  bool _includeDetails = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _message.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  bool get _canSend => _message.text.trim().isNotEmpty || _rating > 0;

  String _subject() =>
      ['Upwiq feedback', ?_topic, if (_rating > 0) '$_rating/5'].join(' · ');

  String _body() {
    final lines = <String>[
      if (_message.text.trim().isNotEmpty) ...[_message.text.trim(), ''],
      '---',
      if (_rating > 0) 'Rating: $_rating/5 (${_ratingWords[_rating - 1]})',
      if (_topic != null) 'Topic: $_topic',
    ];
    if (_includeDetails) {
      final progress = ProgressScope.of(context);
      final game = GameScope.of(context);
      final platform = kIsWeb ? 'web' : defaultTargetPlatform.name;
      lines.addAll([
        'App: Upwiq $appVersion ($platform)',
        'Appearance: ${SettingsScope.of(context).themeMode.name}',
        'Lessons completed: ${progress.completedCount}',
        'League: ${game.league.title}',
      ]);
    }
    return lines.join('\n');
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    final subject = _subject();
    final body = _body();
    // Encoded by hand: Uri's queryParameters would turn spaces into "+",
    // which some email apps show literally.
    final uri = Uri.parse(
      'mailto:$feedbackEmail'
      '?subject=${Uri.encodeComponent(subject)}'
      '&body=${Uri.encodeComponent(body)}',
    );
    final opened = await widget.launcher(uri);
    if (!mounted) return;
    setState(() => _sending = false);
    if (opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you! Press send in your email app to finish.'),
        ),
      );
      Navigator.of(context).pop();
      return;
    }
    await Clipboard.setData(ClipboardData(text: '$subject\n\n$body'));
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No email app found'),
        content: Text(
          'Your feedback has been copied. Paste it into an email to '
          '$feedbackEmail and we\'ll read it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    return Scaffold(
      appBar: AppBar(title: const Text('Leave feedback')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text(
              'Help us make Upwiq better. Tell us what works, what doesn\'t, '
              'and what you\'d like to see next. We read every message.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            _Section(
              title: 'How are you finding Upwiq?',
              child: Column(
                children: [
                  Row(
                    children: [
                      for (var i = 1; i <= 5; i++)
                        Expanded(
                          child: IconButton(
                            tooltip: '$i of 5: ${_ratingWords[i - 1]}',
                            iconSize: 34,
                            onPressed: () => setState(() => _rating = i),
                            icon: Icon(
                              i <= _rating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: i <= _rating
                                  ? AppColors.gradientGold
                                  : palette.textMuted,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    _rating == 0 ? 'Tap a star' : _ratingWords[_rating - 1],
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Section(
              title: 'What is it about?',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in feedbackTopics)
                    ChoiceChip(
                      label: Text(t),
                      selected: _topic == t,
                      onSelected: (on) =>
                          setState(() => _topic = on ? t : null),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Section(
              title: 'Your message',
              child: TextField(
                key: const Key('feedback-message'),
                controller: _message,
                minLines: 4,
                maxLines: 8,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText:
                      'For example: "The stop-loss lesson was clear, but I '
                      'got stuck on…"',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _includeDetails,
              onChanged: (v) => setState(() => _includeDetails = v),
              title: const Text('Include app details'),
              subtitle: const Text(
                'App version, phone type, appearance, lessons completed and '
                'league. Helps us fix problems faster.',
              ),
            ),
            const SizedBox(height: 16),
            GradientButton(
              label: 'Send feedback',
              icon: Icons.send_rounded,
              onPressed: _canSend && !_sending ? _send : null,
            ),
            const SizedBox(height: 10),
            Text(
              'Opens your email app with your message ready. You can read it '
              'before you send it. Please don\'t include passwords or bank '
              'details.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.palette.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
