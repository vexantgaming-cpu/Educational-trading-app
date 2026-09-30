import 'package:flutter/material.dart';

/// Renders lesson text: blank lines separate paragraphs, **double stars**
/// make bold key terms.
class LessonText extends StatelessWidget {
  const LessonText(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = style ?? Theme.of(context).textTheme.bodyLarge;
    final paragraphs = text.split(RegExp(r'\n\s*\n'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < paragraphs.length; i++)
          Padding(
            padding: EdgeInsets.only(
              bottom: i == paragraphs.length - 1 ? 0 : 12,
            ),
            child: Text.rich(
              TextSpan(style: base, children: spans(paragraphs[i].trim())),
            ),
          ),
      ],
    );
  }

  static List<TextSpan> spans(String text) {
    final parts = text.split('**');
    return [
      for (var i = 0; i < parts.length; i++)
        if (parts[i].isNotEmpty)
          TextSpan(
            text: parts[i],
            style: i.isOdd
                ? const TextStyle(fontWeight: FontWeight.w700)
                : null,
          ),
    ];
  }
}
