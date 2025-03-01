import 'dart:io';

import 'package:fvm/fvm.dart';
import 'package:fvm/src/api/api_service.dart';
import 'package:fvm/src/api/models/json_response.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../mocks.dart';
import '../../testing_utils.dart';

void main() {
  late APIService apiService;
  late ProjectService projectService;
  late CacheService cacheService;
  late FlutterReleasesService releasesService;

  late FvmController controller;

  setUpAll(() {
    // Register any custom fallbacks for mocktail
    registerFallbackValue(MockFvmDirectory());
  });

  setUp(() {
    // Initialize all mocks

    APIService createMockApiService(FVMContext context) {
      return APIService(
        context,
        projectService: projectService,
        cacheService: cacheService,
        flutterReleasesServices: releasesService,
      );
    }

    controller = TestFactory.controller(TestFactory.context(
      generators: {
        APIService: createMockApiService,
        ProjectService: (_) => MockProjectService(),
        FlutterReleasesService: (_) => MockFlutterReleasesService(),
      },
    ));

    projectService = controller.project;
    cacheService = controller.cache;
    releasesService = controller.releases;
    apiService = controller.api;
  });

  group('getContext', () {
    test('returns context wrapped in response object', () {
      // Execute
      final result = apiService.getContext();

      // Verify
      expect(result, isA<GetContextResponse>());
    });
  });

  group('getProject', () {
    test('returns project for null directory', () {
      // Set up
      final mockProject = MockProject();
      when(() => projectService.findAncestor(directory: null))
          .thenReturn(mockProject);

      // Execute
      final result = apiService.getProject();

      // Verify
      expect(result, isA<GetProjectResponse>());
      expect(result.project, equals(mockProject));
      verify(() => projectService.findAncestor(directory: null)).called(1);
    });

    test('returns project for specified directory', () {
      // Set up
      final directory = Directory('/test/path');
      final mockProject = MockProject();
      when(() => projectService.findAncestor(directory: directory))
          .thenReturn(mockProject);

      // Execute
      final result = apiService.getProject(directory);

      // Verify
      expect(result, isA<GetProjectResponse>());
      expect(result.project, equals(mockProject));
      verify(() => projectService.findAncestor(directory: directory)).called(1);
    });
  });

  group('getCachedVersions', () {
    late FvmController controller;

    setUp(() {
      controller = TestFactory.controller();
    });
    test('returns versions with size calculation', () async {
      await controller.flutter.install(
        FlutterVersion.parse('beta'),
        useGitCache: true,
      );

      await controller.flutter.install(
        FlutterVersion.channel('stable'),
        useGitCache: true,
      );

      final stableDir = controller.cache.getVersionCacheDir('stable');
      final flutter3Dir = controller.cache.getVersionCacheDir('beta');

      final stableDirSize = await getDirectorySize(stableDir);
      final flutter3DirSize = await getDirectorySize(flutter3Dir);

      final cachedVersionsResponse = await controller.cache.getAllVersions();

      // Execute
      final result = await controller.api.getCachedVersions();

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
      await controller.flutter.install(
        FlutterVersion.parse('3.0.0'),
        useGitCache: true,
      );

      await controller.flutter.install(
        FlutterVersion.channel('stable'),
        useGitCache: true,
      );

      final cachedVersionsResponse = await controller.cache.getAllVersions();

      // Execute
      final result = await controller.api
          .getCachedVersions(skipCacheSizeCalculation: true);

      // Verify
      expect(result, isA<GetCacheVersionsResponse>());
      expect(result.versions, equals(cachedVersionsResponse));
      expect(result.size, equals(formatFriendlyBytes(0)));
    });
  });

  group('getReleases', () {
    late FvmController controller;
    late FlutterReleasesResponse releasesResponse;

    setUp(() async {
      controller = TestFactory.controller();
      releasesResponse = await controller.releases.getReleases();
    });

    test('returns all releases when no filters applied', () async {
      // Execute
      final result = await controller.api.getReleases();

      // Verify
      expect(result, isA<GetReleasesResponse>());
      expect(result.versions, equals(releasesResponse.versions));
      expect(result.channels, equals(releasesResponse.channels));
    });

    test('returns limited releases when limit is specified', () async {
      // Execute
      final result = await controller.api.getReleases(limit: 2);

      // Verify
      expect(result, isA<GetReleasesResponse>());
      expect(result.versions.length, equals(2));
      expect(result.channels, equals(releasesResponse.channels));
    });

    test('returns filtered releases when channel is specified', () async {
      // Execute
      final result = await controller.api.getReleases(channelName: 'stable');

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
          await controller.api.getReleases(limit: 1, channelName: 'stable');

      // Verify
      expect(result, isA<GetReleasesResponse>());
      expect(result.versions.length, equals(1));
      expect(result.versions.first.channel.name, equals('stable'));
      expect(result.channels, equals(releasesResponse.channels));
    });
  });
}
