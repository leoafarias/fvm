import 'dart:io';

import 'package:fvm/fvm.dart';
import 'package:fvm/src/api/api_service.dart';
import 'package:fvm/src/api/models/json_response.dart';
import 'package:fvm/src/commands/api_command.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../testing_utils.dart';

class _MockAPIService extends Mock implements APIService {}

void main() {
  // Set up common test variables
  late FvmController controller;
  late APIService apiService;
  late TestCommandRunner runner;

  // Setup function that runs before each test
  setUp(() {
    // Initialize mocks
    controller = TestFactory.controller(
      TestFactory.context(generators: {
        APIService: (_) => _MockAPIService(),
      }),
    );
    apiService = controller.api;

    // Create a command runner for testing
    runner = TestFactory.commandRunner(controller: controller);
  });

  group('APICommand', () {
    test('adds all subcommands', () {
      // Get the API command
      final command = runner.commands['api'] as APICommand;

      // Verify subcommands are added
      expect(command.subcommands.containsKey('context'), isTrue);
      expect(command.subcommands.containsKey('project'), isTrue);
      expect(command.subcommands.containsKey('list'), isTrue);
      expect(command.subcommands.containsKey('releases'), isTrue);

      // Verify the correct number of subcommands
      expect(command.subcommands.length, equals(4));
    });
  });

  group('APIContextCommand', () {
    late GetContextResponse response;

    setUp(() {
      response = GetContextResponse(context: controller.context);

      when(() => apiService.getContext()).thenAnswer(
        (_) => response,
      );
    });

    test('returns context data without compression', () async {
      final result = await runnerZoned(runner, ['fvm', 'api', 'context']);

      final json = result.join();

      // Verify results
      verify(() => apiService.getContext()).called(1);
      expect(json, equals(response.toPrettyJson()));
    });

    test('returns compressed context data with compress flag', () async {
      final result = await runnerZoned(
        runner,
        ['fvm', 'api', 'context', '--compress'],
      );

      // Verify results
      verify(() => apiService.getContext()).called(1);
      expect(result, hasLength(1));
      expect(result[0], isExpectedJson(response.toJson()));
    });
  });

  group('APIProjectCommand', () {
    test('returns project data for current directory', () async {
      final project = runner.controller.project.findAncestor();
      final response = GetProjectResponse(project: project);

      when(() => apiService.getProject(null)).thenReturn(response);
      final result = await runnerZoned(runner, ['fvm', 'api', 'project']);

      // Verify results
      verify(() => apiService.getProject(null)).called(1);
      expect(result, isExpectedJson(response.toPrettyJson()));
    });

    test('returns project data for specified path', () async {
      final directory = Directory('/test/path');
      final project =
          runner.controller.project.findAncestor(directory: directory);
      final response = GetProjectResponse(project: project);

      when(() => apiService.getProject(any())).thenReturn(response);

      final result = await runnerZoned(
        runner,
        ['fvm', 'api', 'project', '--path', directory.path],
      );

      // Combine verification and capture in one step
      final captured =
          verify(() => apiService.getProject(captureAny())).captured;

      // Verify it was called exactly once
      expect(captured.length, equals(1));

      // Verify the directory path is correct
      final capturedArg = captured.single as Directory?;
      expect(capturedArg?.path, equals(directory.path));

      // Verify the response
      expect(result, isExpectedJson(response.toPrettyJson()));
    });
  });

  group('APIListCommand', () {
    late GetCacheVersionsResponse withoutSizeCalculationResponse;
    late GetCacheVersionsResponse sizeCalculationResponse;
    List<CacheFlutterVersion> versions;

    setUp(() {
      versions = [
        CacheFlutterVersion(
          FlutterVersion.channel('stable'),
          directory: runner.controller.context.versionsCachePath,
        )
      ];
      // Setup mock list response
      withoutSizeCalculationResponse = GetCacheVersionsResponse(
        size: '',
        versions: versions,
      );

      sizeCalculationResponse = GetCacheVersionsResponse(
        size: '100MB',
        versions: versions,
      );

      // Configure API service mock
      when(() => apiService.getCachedVersions(skipCacheSizeCalculation: true))
          .thenAnswer((_) async => withoutSizeCalculationResponse);
      when(() => apiService.getCachedVersions(skipCacheSizeCalculation: false))
          .thenAnswer((_) async => sizeCalculationResponse);
    });

    test('returns list data with size calculation', () async {
      final result = await runnerZoned(runner, ['fvm', 'api', 'list']);

      // Verify results
      verify(() =>
              apiService.getCachedVersions(skipCacheSizeCalculation: false))
          .called(1);
      expect(result, isExpectedJson(sizeCalculationResponse.toPrettyJson()));
    });

    test('returns list data without size calculation', () async {
      final result = await runnerZoned(
        runner,
        ['fvm', 'api', 'list', '--skip-size-calculation'],
      );

      // Verify results
      verify(() => apiService.getCachedVersions(skipCacheSizeCalculation: true))
          .called(1);
      expect(result, hasLength(1));
      expect(result,
          isExpectedJson(withoutSizeCalculationResponse.toPrettyJson()));
    });

    test('returns compressed list data', () async {
      final result = await runnerZoned(
        runner,
        ['fvm', 'api', 'list', '--compress'],
      );

      // Verify results
      verify(() =>
              apiService.getCachedVersions(skipCacheSizeCalculation: false))
          .called(1);
      expect(result, hasLength(1));
      expect(result[0], isExpectedJson(sizeCalculationResponse.toJson()));
    });
  });

  group('APIReleasesCommand', () {
    late GetReleasesResponse response;

    setUp(() async {
      // Setup mock releases response
      final releases = await runner.controller.releases.getReleases();
      response = GetReleasesResponse(
        versions: releases.versions,
        channels: releases.channels,
      );

      // Configure API service mock
      when(() => apiService.getReleases(limit: null, channelName: null))
          .thenAnswer((_) async => response);
      when(() => apiService.getReleases(limit: 10, channelName: null))
          .thenAnswer((_) async => response);
      when(() => apiService.getReleases(limit: null, channelName: 'stable'))
          .thenAnswer((_) async => response);
      when(() => apiService.getReleases(limit: 10, channelName: 'stable'))
          .thenAnswer((_) async => response);
    });

    test('returns all releases', () async {
      final result = await runnerZoned(runner, ['fvm', 'api', 'releases']);

      // Verify results
      verify(() => apiService.getReleases(limit: null, channelName: null))
          .called(1);
      expect(result, hasLength(1));
      expect(result[0], isExpectedJson(response.toPrettyJson()));
    });

    test('returns limited releases', () async {
      final result = await runnerZoned(
        runner,
        ['fvm', 'api', 'releases', '--limit', '10'],
      );

      // Verify results
      verify(() => apiService.getReleases(limit: 10, channelName: null))
          .called(1);
      expect(result, hasLength(1));
      expect(result[0], isExpectedJson(response.toPrettyJson()));
    });

    test('returns filtered releases by channel', () async {
      final result = await runnerZoned(
        runner,
        ['fvm', 'api', 'releases', '--filter-channel', 'stable'],
      );

      // Verify results
      verify(() => apiService.getReleases(limit: null, channelName: 'stable'))
          .called(1);
      expect(result, hasLength(1));
      expect(result[0], isExpectedJson(response.toPrettyJson()));
    });

    test('returns limited and filtered releases', () async {
      final result = await runnerZoned(
        runner,
        [
          'fvm',
          'api',
          'releases',
          '--limit',
          '10',
          '--filter-channel',
          'stable'
        ],
      );

      // Verify results
      verify(() => apiService.getReleases(limit: 10, channelName: 'stable'))
          .called(1);
      expect(result, hasLength(1));
    });

    test('returns compressed releases data', () async {
      final result = await runnerZoned(
        runner,
        ['fvm', 'api', 'releases', '--compress'],
      );

      // Verify results
      verify(() => apiService.getReleases(limit: null, channelName: null))
          .called(1);
      expect(result, hasLength(1));
      expect(result[0], isExpectedJson(response.toJson()));
    });
  });
}
