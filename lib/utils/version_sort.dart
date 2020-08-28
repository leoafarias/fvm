final _regNum = RegExp('[0-9]');
final _filNum =
    (String str) => _regNum.allMatches(str).map((m) => m.group(0)).join();
final _versionCmp = (String a, String b) => _filNum(b).compareTo(_filNum(a));

List<String> versionSort(List<String> str) => str..sort(_versionCmp);
