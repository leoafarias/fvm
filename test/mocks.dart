// Mock classes
import 'dart:io';

import 'package:fvm/fvm.dart';
import 'package:mocktail/mocktail.dart';

class MockProjectService extends Mock implements ProjectService {}

class MockCacheService extends Mock implements CacheService {}

class MockFlutterReleasesService extends Mock implements FlutterReleaseClient {}

class MockFvmContext extends Mock implements FvmContext {}

class MockProject extends Mock implements Project {}

class MockCacheVersion extends Mock implements CacheFlutterVersion {}

class MockFvmDirectory extends Mock implements Directory {}

class MockDirectory extends Mock implements Directory {}

class MockFlutterSdkRelease extends Mock implements FlutterSdkRelease {}

class MockChannels extends Mock implements Channels {}

class MockFlutterReleasesResponse extends Mock
    implements FlutterReleasesResponse {}
