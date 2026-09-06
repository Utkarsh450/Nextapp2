/// Direct port of `highlightSegments` (`lib/notes/markdown.ts`) — splits
/// text into plain and matched runs for search-result highlighting.
library;

class const HighlightSegment({
  required final String text,
  required final bool match,
});

List<HighlightSegment> highlightSegments(String text, String query) {
  final q = query.trim();
  if (q.isEmpty) return [HighlightSegment(text: text, match: false)];
  final escaped = RegExp.escape(q);
  final splitter = RegExp('($escaped)', caseSensitive: false);
  final lowerQ = q.toLowerCase();
  final segments = <HighlightSegment>[];
  var last = 0;
  for (final match in splitter.allMatches(text)) {
    if (match.start > last) {
      segments.add(
        HighlightSegment(text: text.substring(last, match.start), match: false),
      );
    }
    final part = text.substring(match.start, match.end);
    segments.add(
      HighlightSegment(text: part, match: part.toLowerCase() == lowerQ),
    );
    last = match.end;
  }
  if (last < text.length) {
    segments.add(HighlightSegment(text: text.substring(last), match: false));
  }
  return segments;
}
