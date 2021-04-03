/// Checks if string contains
bool containsIgnoringWhitespace(String source, String toSearch) {
  return collapseWhitespace(source).contains(collapseWhitespace(toSearch));
}

/// Utility function to collapse whitespace runs to single spaces
/// and strip leading/trailing whitespace.
/// taken from matcher
String collapseWhitespace(String string) {
  var result = StringBuffer();
  var skipSpace = true;
  for (var i = 0; i < string.length; i++) {
    var character = string[i];
    if (_isWhitespace(character)) {
      if (!skipSpace) {
        result.write(' ');
        skipSpace = true;
      }
    } else {
      result.write(character);
      skipSpace = false;
    }
  }
  return result.toString().trim();
}

bool _isWhitespace(String ch) =>
    ch == ' ' || ch == '\n' || ch == '\r' || ch == '\t';
