import 'dart:io';

import 'package:fvm/fvm.dart';
import 'package:fvm/src/api/models/json_response.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../mocks.dart';
import '../../testing_utils.dart';

void main() {
  late ServicesProvider services;

  late FVMContext context;

  setUpAll(() {
    // Register any custom fallbacks for mocktail
    registerFallbackValue(MockFvmDirectory());
  });

  setUp(() {
    // Initialize all mocks

    context = TestFactory.context(
      generators: {
        ProjectService: (_) => MockProjectService(),
        // FlutterReleasesService: (_) => MockFlutterReleasesService(),
      },
    );

    services = context.get<ServicesProvider>();
  });

  group('getContext', () {
    test('returns context wrapped in response object', () {
      // Execute
      final result = services.api.getContext();

      // Verify
      expect(result, isA<GetContextResponse>());
    });
  });

  group('getProject', () {
    test('returns project for null directory', () {
      // Set up
      final mockProject = MockProject();
      when(() => services.project.findAncestor(directory: null))
          .thenReturn(mockProject);

      // Execute
      final result = services.api.getProject();

      // Verify
      expect(result, isA<GetProjectResponse>());
      expect(result.project, equals(mockProject));
      verify(() => services.project.findAncestor(directory: null)).called(1);
    });

    test('returns project for specified directory', () {
      // Set up
      final directory = Directory('/test/path');
      final mockProject = MockProject();
      when(() => services.project.findAncestor(directory: directory))
          .thenReturn(mockProject);

      // Execute
      final result = services.api.getProject(directory);

      // Verify
      expect(result, isA<GetProjectResponse>());
      expect(result.project, equals(mockProject));
      verify(() => services.project.findAncestor(directory: directory))
          .called(1);
    });
  });

  group('getCachedVersions', () {
    test('returns versions with size calculation', () async {
      await services.flutter.install(
        FlutterVersion.parse('beta'),
      );

      await services.flutter.install(
        FlutterVersion.parse('stable'),
      );

      final stableDir = services.cache.getVersionCacheDir('stable');
      final flutter3Dir = services.cache.getVersionCacheDir('beta');

      final stableDirSize = await getDirectorySize(stableDir);
      final flutter3DirSize = await getDirectorySize(flutter3Dir);

      final cachedVersionsResponse = await services.cache.getAllVersions();

      // Execute
      final result = await services.api.getCachedVersions();

      // Verify
      expect(result, isA<GetCacheVersionsResponse>());
      expect(result.versions, equals(cachedVersionsResponse));
      expect(
          result.size,
          equals(
            formatFriendlyBytes(stableDirSize + flutter3DirSize),
          ));
    });

    test(
        'returns versions without size calculation when skipCacheSizeCalculation is true',
        () async {
      await services.flutter.install(
        FlutterVersion.parse('3.0.0'),
      );

      await services.flutter.install(
        FlutterVersion.parse('stable'),
      );

      final cachedVersionsResponse = await services.cache.getAllVersions();

      // Execute
      final result = await services.api.getCachedVersions(
        skipCacheSizeCalculation: true,
      );

      // Verify
      expect(result, isA<GetCacheVersionsResponse>());
      expect(result.versions, equals(cachedVersionsResponse));
      expect(result.size, equals(formatFriendlyBytes(0)));
    });
  });

  group('getReleases', () {
    late FVMContext context;
    late FlutterReleasesResponse releasesResponse;

    setUp(() async {
      context = TestFactory.context();
      releasesResponse = await services.releases.getReleases();
    });

    test('returns all releases when no filters applied', () async {
      // Execute
      final result = await services.api.getReleases();

      // Verify
      expect(result, isA<GetReleasesResponse>());
      expect(result.versions, equals(releasesResponse.versions));
      expect(result.channels, equals(releasesResponse.channels));
    });

    test('returns limited releases when limit is specified', () async {
      // Execute
      final result = await services.api.getReleases(limit: 2);

      // Verify
      expect(result, isA<GetReleasesResponse>());
      expect(result.versions.length, equals(2));
      expect(result.channels, equals(releasesResponse.channels));
    });

    test('returns filtered releases when channel is specified', () async {
      // Execute
      final result = await services.api.getReleases(channelName: 'stable');

      // Verify
      expect(result, isA<GetReleasesResponse>());
      expect(result.versions.every((v) => v.channel.name == 'stable'), isTrue);
      expect(result.channels, equals(releasesResponse.channels));
    });

    test(
        'returns limited and filtered releases when both limit and channel specified',
        () async {
      // Execute
      final result =
          await services.api.getReleases(limit: 1, channelName: 'stable');

      // Verify
      expect(result, isA<GetReleasesResponse>());
      expect(result.versions.length, equals(1));
      expect(result.versions.first.channel.name, equals('stable'));
      expect(result.channels, equals(releasesResponse.channels));
    });
  });
}
