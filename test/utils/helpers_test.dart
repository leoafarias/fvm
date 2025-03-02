import 'dart:io';

import 'package:fvm/src/utils/helpers.dart';
import 'package:fvm/src/version.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../testing_utils.dart';

void main() {
  late TestCommandRunner runner;

  setUp(() {
    runner = TestFactory.commandRunner();
  });

  test('Does CLI version match', () async {
    final yaml = File(
      p.join(Directory.current.path, 'pubspec.yaml'),
    ).readAsStringSync();
    final pubspec = loadYamlNode(yaml);
    expect(pubspec.value['version'], packageVersion);
  });

  test('Test update env variables', () async {
    final envVars = Platform.environment;
    // final version = 'stable';
    final envName = 'PATH';
    final fakePath = 'FAKE_PATH';

    final newEnvVar = updateEnvironmentVariables(
      ['FAKE_PATH', 'ANOTHER_FAKE_PATH'],
      envVars,
      runner.context.logger,
    );

    // expect(newEnvVar[envName], envVars[envName]);
    expect(newEnvVar[envName]!.contains(fakePath), true);
    expect(newEnvVar[envName]!.contains('ANOTHER_FAKE_PATH'), true);
    expect(envVars, isNot(newEnvVar));
  });

  test('Assigns version weights', () async {
    expect('500.0.0', assignVersionWeight('2da03e5'));
    expect('500.0.0', assignVersionWeight('ce18d702e9'));
    expect(
      '500.0.0',
      assignVersionWeight('ce18d702e90d3dff9fee53d61a770c94f14f2811'),
    );
    expect('400.0.0', assignVersionWeight('master'));
    expect('300.0.0', assignVersionWeight('stable'));
    expect('200.0.0', assignVersionWeight('beta'));
    expect('100.0.0', assignVersionWeight('dev'));
  });

  group('extractFlutterVersionOutput', () {
    test('should correctly parse the EXAMPLE:1', () {
      final content =
          '''Flutter 3.15.0-15.1.pre • channel beta • https://github.com/flutter/flutter.git
Framework • revision b2ec15bfa3 (5 days ago) • 2023-09-14 15:31:44 -0500
Engine • revision 5c86194494
Tools • Dart 3.2.0 (build 3.2.0-134.1.beta) • DevTools 2.27.0''';

      final result = extractFlutterVersionOutput(content);

      expect(result.flutterVersion, '3.15.0-15.1.pre');
      expect(result.channel, 'beta');
      expect(result.dartVersion, '3.2.0');
      expect(result.dartBuildVersion, '3.2.0-134.1.beta');
    });

    test('should correctly parse the EXAMPLE:2', () {
      final content =
          '''Flutter 3.10.5 • channel stable • https://github.com/flutter/flutter.git
Framework • revision 796c8ef792 (3 months ago) • 2023-06-13 15:51:02 -0700
Engine • revision 45f6e00911
Tools • Dart 3.0.5 • DevTools 2.23.1''';

      final result = extractFlutterVersionOutput(content);

      expect(result.flutterVersion, '3.10.5');
      expect(result.channel, 'stable');
      expect(result.dartVersion, '3.0.5');
      expect(result.dartBuildVersion, '3.0.5');
    });

    test('should correctly parse the EXAMPLE:3', () {
      final content =
          '''Flutter 2.2.0 • channel stable • https://github.com/flutter/flutter.git
Framework • revision b22742018b (2 years, 4 months ago) • 2021-05-14 19:12:57 -0700
Engine • revision a9d88a4d18
Tools • Dart 2.13.0''';

      final result = extractFlutterVersionOutput(content);

      expect(result.flutterVersion, '2.2.0');
      expect(result.channel, 'stable');
      expect(result.dartVersion, '2.13.0');
      expect(result.dartBuildVersion, '2.13.0');
    });

    test('should correctly parse the EXAMPLE:4', () {
      final content =
          '''  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                     Dload  Upload   Total   Spent    Left  Speed
    
      0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
     27  203M   27 56.1M    0     0  61.8M      0  0:00:03 --:--:--  0:00:03 61.8M
     88  203M   88  180M    0     0  94.9M      0  0:00:02  0:00:01  0:00:01 94.9M
    100  203M  100  203M    0     0  95.9M      0  0:00:02  0:00:02 --:--:-- 96.0M
    Resolving dependencies...
    + _fe_analyzer_shared 58.0.0 (64.0.0 available)
    + analyzer 5.10.0 (6.2.0 available)
    + archive 3.3.2 (3.3.9 available)
    + args 2.4.0 (2.4.2 available)
    + async 2.11.0
    + boolean_selector 2.1.1
    + browser_launcher 1.1.1
    + built_collection 5.1.1
    + built_value 8.4.4 (8.6.2 available)
    + checked_yaml 2.0.2 (2.0.3 available)
    + clock 1.1.1
    + collection 1.17.1 (1.18.0 available)
    + completion 1.0.1
    + convert 3.1.1
    + coverage 1.6.3
    + crypto 3.0.2 (3.0.3 available)
    + csslib 0.17.2 (1.0.0 available)
    + dds 2.7.10 (2.9.4 available)
    + dds_service_extensions 1.3.3 (1.6.0 available)
    + devtools_shared 2.23.0 (4.0.1 available)
    + dwds 19.0.0 (21.0.0 available)
    + fake_async 1.3.1
    + file 6.1.4 (7.0.0 available)
    + file_testing 3.0.0
    + fixnum 1.1.0
    + flutter_template_images 4.2.0 (4.2.1 available)
    + frontend_server_client 3.2.0
    + glob 2.1.1 (2.1.2 available)
    + html 0.15.2 (0.15.4 available)
    + http 0.13.5 (1.1.0 available)
    + http_multi_server 3.2.1
    + http_parser 4.0.2
    + intl 0.18.0 (0.18.1 available)
    + io 1.0.4
    + js 0.6.7
    + json_annotation 4.8.0 (4.8.1 available)
    + json_rpc_2 3.0.2
    + logging 1.1.1 (1.2.0 available)
    + matcher 0.12.15 (0.12.16 available)
    + meta 1.9.1 (1.10.0 available)
    + mime 1.0.4
    + multicast_dns 0.3.2+3 (0.3.2+4 available)
    + mustache_template 2.0.0
    + native_stack_traces 0.5.5 (0.5.6 available)
    + node_preamble 2.0.2
    + package_config 2.1.0
    + path 1.8.3
    + petitparser 5.3.0 (6.0.1 available)
    + platform 3.1.0 (3.1.2 available)
    + pool 1.5.1
    + process 4.2.4 (5.0.0 available)
    + pub_semver 2.1.3 (2.1.4 available)
    + pubspec_parse 1.2.2 (1.2.3 available)
    + shelf 1.4.0 (1.4.1 available)
    + shelf_packages_handler 3.0.1 (3.0.2 available)
    + shelf_proxy 1.0.2 (1.0.4 available)
    + shelf_static 1.1.1 (1.1.2 available)
    + shelf_web_socket 1.0.3 (1.0.4 available)
    + source_map_stack_trace 2.1.1
    + source_maps 0.10.12
    + source_span 1.9.1 (1.10.0 available)
    + sse 4.1.2
    + stack_trace 1.11.0 (1.11.1 available)
    + standard_message_codec 0.0.1+3 (0.0.1+4 available)
    + stream_channel 2.1.1 (2.1.2 available)
    + string_scanner 1.2.0
    + sync_http 0.3.1
    + term_glyph 1.2.1
    + test 1.24.1 (1.24.6 available)
    + test_api 0.5.1 (0.6.1 available)
    + test_core 0.5.1 (0.5.6 available)
    + typed_data 1.3.1 (1.3.2 available)
    + unified_analytics 1.1.0 (4.0.0 available)
    + usage 4.1.0 (4.1.1 available)
    + uuid 3.0.7 (4.0.0 available)
    + vm_service 11.3.0 (11.10.0 available)
    + vm_snapshot_analysis 0.7.2 (0.7.6 available)
    + watcher 1.0.2 (1.1.0 available)
    + web_socket_channel 2.3.0 (2.4.0 available)
    + webdriver 3.0.2
    + webkit_inspection_protocol 1.2.0 (1.2.1 available)
    + xml 6.2.2 (6.4.2 available)
    + yaml 3.1.1 (3.1.2 available)
    Changed 83 dependencies!
    53 packages have newer versions incompatible with dependency constraints.
    Try `dart pub outdated` for more information.
    Flutter 3.10.5 • channel stable • https://github.com/flutter/flutter.git
    Framework • revision 796c8ef792 (3 months ago) • 2023-06-13 15:51:02 -0700
    Engine • revision 45f6e00911
    Tools • Dart 3.0.5 • DevTools 2.23.1''';

      final result = extractFlutterVersionOutput(content);

      expect(result.flutterVersion, '3.10.5');
      expect(result.channel, 'stable');
      expect(result.dartVersion, '3.0.5');
      expect(result.dartBuildVersion, '3.0.5');
    });
  });

  test('should correctly parse the EXAMPLE:5', () {
    final content =
        '''Flutter 3.15.0-15.2.pre â€¢ channel beta â€¢ https://github.com/flutter/flutter.git
Framework â€¢ revision 0d074ced6c (12 hours ago) â€¢ 2023-09-21 10:24:15 -0700
Engine â€¢ revision 453411bcf3
Tools â€¢ Dart 3.2.0 (build 3.2.0-134.1.beta) â€¢ DevTools 2.27.0
''';

    final result = extractFlutterVersionOutput(content);

    expect(result.flutterVersion, '3.15.0-15.2.pre');
    expect(result.channel, 'beta');
    expect(result.dartVersion, '3.2.0');
    expect(result.dartBuildVersion, '3.2.0-134.1.beta');
  });

  test('formatFriendlyBytes', () {
    expect(formatFriendlyBytes(1024), '1.00 KB');
    expect(formatFriendlyBytes(1024 * 1024), '1.00 MB');
    expect(formatFriendlyBytes(1024 * 1024 * 1024), '1.00 GB');
    expect(formatFriendlyBytes(1024 * 1024 * 1024 * 1024), '1.00 TB');
    expect(formatFriendlyBytes(1024 * 1024 * 1024 * 1024 * 1024), '1.00 PB');
    expect(formatFriendlyBytes(1024 * 1024 * 1024 * 1024 * 1024 * 1024),
        '1.00 EB');
  });

  group('Version Weight Tests', () {
    // Define both weight functions for testing
    int bitwiseVersionWeight(Version version) {
      final major = version.major.clamp(0, 1023);
      final minor = version.minor.clamp(0, 1023);
      final patch = version.patch.clamp(0, 1023);
      final isRelease = version.isPreRelease ? 0 : 1;

      return (major << 21) | (minor << 11) | (patch << 1) | isRelease;
    }

    int simpleVersionWeight(Version version) {
      const int majorWeight = 1000000;
      const int minorWeight = 1000;

      int weight = version.major * majorWeight +
          version.minor * minorWeight +
          version.patch;

      if (version.isPreRelease) {
        weight -= 999;

        if (version.preRelease.isNotEmpty && version.preRelease[0] is int) {
          weight += (version.preRelease[0] as int).clamp(0, 99);
        }
      }

      return weight;
    }

    // Helper function to test if weights correctly order versions
    void testVersionOrdering(
        List<String> versionStrings, int Function(Version) weightFn) {
      final versions = versionStrings.map(Version.parse).toList();
      final weights = versions.map(weightFn).toList();

      for (int i = 0; i < versions.length - 1; i++) {
        expect(weights[i] < weights[i + 1], isTrue,
            reason: "${versions[i]} (weight=${weights[i]}) should be less than "
                "${versions[i + 1]} (weight=${weights[i + 1]})");
      }
    }

    test('Basic version ordering - bitwise', () {
      testVersionOrdering(
          ['1.0.0', '1.0.1', '1.1.0', '1.2.0', '2.0.0'], bitwiseVersionWeight);
    });

    test('Basic version ordering - simple', () {
      testVersionOrdering(
          ['1.0.0', '1.0.1', '1.1.0', '1.2.0', '2.0.0'], simpleVersionWeight);
    });

    test('Pre-release vs release versions - bitwise', () {
      testVersionOrdering(['1.0.0-alpha', '1.0.0-beta', '1.0.0-rc.1', '1.0.0'],
          bitwiseVersionWeight);
    });

    test('Pre-release vs release versions - simple', () {
      testVersionOrdering(['1.0.0-alpha', '1.0.0-beta', '1.0.0-rc.1', '1.0.0'],
          simpleVersionWeight);
    });

    test('Complex version ordering - bitwise', () {
      testVersionOrdering([
        '0.9.9-beta',
        '0.9.9',
        '1.0.0-alpha',
        '1.0.0-alpha.1',
        '1.0.0-beta',
        '1.0.0-rc.1',
        '1.0.0',
        '1.0.1',
        '1.1.0-alpha',
        '1.1.0'
      ], bitwiseVersionWeight);
    });

    test('Build metadata is ignored - bitwise', () {
      final v1 = Version.parse('1.0.0+build.1');
      final v2 = Version.parse('1.0.0+build.2');

      expect(bitwiseVersionWeight(v1), equals(bitwiseVersionWeight(v2)));
    });

    test('Edge cases - bitwise', () {
      // Test version 0.0.0
      final zero = Version.parse('0.0.0');
      expect(bitwiseVersionWeight(zero),
          equals(1)); // Should be 1 (non-prerelease)

      // Test max versions (within our 10-bit limit)
      final max = Version.parse('1023.1023.1023');
      expect(bitwiseVersionWeight(max), isPositive);

      // Test overflow clamping
      final overflow = Version.parse('1024.1024.1024');
      expect(bitwiseVersionWeight(overflow), equals(bitwiseVersionWeight(max)));
    });

    test('Consistent with Version.prioritize - sample cases', () {
      final versions = [
        '2.0.0-alpha',
        '1.9.0',
        '2.0.0-beta',
        '1.9.1',
        '2.0.0',
        '1.8.0'
      ].map(Version.parse).toList();

      // Sort by our weight function
      versions.sort(
          (a, b) => bitwiseVersionWeight(a).compareTo(bitwiseVersionWeight(b)));

      // Create a copy and sort by Version.prioritize
      final versionsByPrioritize = List<Version>.from(versions);
      versionsByPrioritize.sort(Version.prioritize);

      // The ordering should be the same
      for (int i = 0; i < versions.length; i++) {
        expect(versions[i], equals(versionsByPrioritize[i]),
            reason: "Weight-based sorting should match Version.prioritize");
      }
    });

    test('Numeric pre-release identifiers are handled correctly', () {
      testVersionOrdering([
        '1.0.0-alpha.1',
        '1.0.0-alpha.2',
        '1.0.0-alpha.10',
      ], bitwiseVersionWeight);

      // This is a more complex case to ensure numeric ordering is correct
      final v1 = Version.parse('1.0.0-alpha.1');
      final v2 = Version.parse('1.0.0-alpha.2');
      final v3 = Version.parse('1.0.0-alpha.10');

      // Test raw prioritize function
      expect(Version.prioritize(v1, v2) < 0, isTrue);
      expect(Version.prioritize(v2, v3) < 0, isTrue);

      // Check our weight function gives same results
      expect(bitwiseVersionWeight(v1) < bitwiseVersionWeight(v2), isTrue);
      expect(bitwiseVersionWeight(v2) < bitwiseVersionWeight(v3), isTrue);
    });

    test('Large version component tests', () {
      // Testing with large but valid version components
      testVersionOrdering(
          ['100.200.300', '100.200.301', '100.201.0', '101.0.0'],
          bitwiseVersionWeight);
    });

    test('Bit position verification', () {
      // Verify bit positions are correct
      final v1 = Version(1, 0, 0); // 1.0.0
      final v2 = Version(0, 1, 0); // 0.1.0
      final v3 = Version(0, 0, 1); // 0.0.1

      final w1 = bitwiseVersionWeight(v1);
      final w2 = bitwiseVersionWeight(v2);
      final w3 = bitwiseVersionWeight(v3);

      // Major is in bits 21-30, so 1 << 21
      expect(w1 & (1023 << 21), equals(1 << 21));

      // Minor is in bits 11-20, so 1 << 11
      expect(w2 & (1023 << 11), equals(1 << 11));

      // Patch is in bits 1-10, so 1 << 1
      expect(w3 & (1023 << 1), equals(1 << 1));
    });
  });
}
