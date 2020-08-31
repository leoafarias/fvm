/// Regex to select numbers.
final _regNum = RegExp('[0-9]');

// Pad version with zero but make empty version larger for compare
String _padZero(String str) =>
    str != '' ? str.padRight(10, '0') : '1'.padRight(11, '0');

/// Function to filter string using _regNum RegExp
int _filNum(String str) =>
    int.parse(_padZero(_regNum.allMatches(str).map((m) => m.group(0)).join()));

/// Compare function to sort version
int _versionCmp(String a, String b) => _filNum(b) - _filNum(a);

/// Public function to sort list of version strings
List<String> versionSort(List<String> str) => str..sort(_versionCmp);
