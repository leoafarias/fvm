const _snakeCaseSeparator = '_';
const _paramCaseSeparator = '-';
const _spaceSeparator = ' ';
const _nospaceSeparator = '';
final RegExp _upperAlphaRegex = RegExp(r'[A-Z]');

final _symbolSet = {
  _snakeCaseSeparator,
  _paramCaseSeparator,
  _spaceSeparator,
};

class ChangeCase {
  final String text;

  const ChangeCase(this.text);

  List<String> _groupWords(String text) {
    final sb = StringBuffer();
    final words = <String>[];
    final isAllCaps = text.toUpperCase() == text;

    for (var i = 0; i < text.length; i++) {
      final char = text[i];
      final nextChar = i + 1 == text.length ? null : text[i + 1];

      if (_symbolSet.contains(char)) {
        continue;
      }

      sb.write(char);

      final isEndOfWord = nextChar == null ||
          (_upperAlphaRegex.hasMatch(nextChar) && !isAllCaps) ||
          _symbolSet.contains(nextChar);

      if (isEndOfWord) {
        words.add(sb.toString());
        sb.clear();
      }
    }

    return words;
  }

  String _getCamelCase() {
    final words = _words.map(_upperCaseFirstLetter).toList();
    if (_words.isNotEmpty) {
      words[0] = words[0].toLowerCase();
    }

    return words.join(_nospaceSeparator);
  }

  String _uppercase(String separator) => _words.uppercase.join(separator);

  String _lowerCase(String separator) => _words.lowercase.join(separator);

  String _upperCaseFirstLetter(String word) {
    if (word.isEmpty) return '';
    return word.capitalize;
  }

  List<String> get _words => _groupWords(text);

  /// camelCase
  String get camelCase => _getCamelCase();

  /// CONSTANT_CASE
  String get constantCase => _uppercase(_snakeCaseSeparator);

  /// snake_case
  String get snakeCase => _lowerCase(_snakeCaseSeparator);

  /// param-case
  String get paramCase => _lowerCase(_paramCaseSeparator);
}

extension on String {
  String get capitalize {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}

extension on List<String> {
  List<String> get lowercase => map((e) => e.toLowerCase()).toList();
  List<String> get uppercase => map((e) => e.toUpperCase()).toList();
}
