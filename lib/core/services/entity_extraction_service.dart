import '../models/ocr_models.dart';

class EntityExtractionService {
  static final _email = RegExp(
    r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}',
    caseSensitive: false,
  );
  static final _phone = RegExp(
    r'(?:(?:\+?\d{1,3}[\s.-]?)?(?:\(?\d{2,5}\)?[\s.-]?)?\d{3,4}[\s.-]?\d{3,4})',
  );
  static final _date = RegExp(
    r'\b(?:\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|\d{4}[/-]\d{1,2}[/-]\d{1,2})\b',
  );
  static final _url = RegExp(
    r'\b(?:https?://)?(?:www\.)?[a-z0-9.-]+\.[a-z]{2,}(?:/[^\s]*)?\b',
    caseSensitive: false,
  );

  List<EntityMatch> extract(String text) {
    final results = <EntityMatch>[];
    void add(String type, RegExp regex) {
      for (final match in regex.allMatches(text)) {
        final value = match.group(0)?.trim();
        if (value != null &&
            value.length >= 3 &&
            !results.any((e) => e.value == value)) {
          results.add(EntityMatch(type: type, value: value));
        }
      }
    }

    add('Email', _email);
    add('Phone', _phone);
    add('Date', _date);
    add('URL', _url);
    return results;
  }
}
