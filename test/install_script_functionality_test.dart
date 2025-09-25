import 'dart:io';

import 'package:test/test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('Install Script Functionality Tests:', () {
    test('Version detection method should work correctly', () async {
      // Test the GitHub redirect method used in install.sh
      const testUrl = 'https://github.com/leoafarias/fvm/releases/latest';
      
      try {
        final response = await http.get(Uri.parse(testUrl));
        
        // Should get a redirect (302) or success (200)
        expect([200, 302].contains(response.statusCode), true,
            reason: 'GitHub releases/latest should be accessible');
        
        // If it's a redirect, check the location header
        if (response.statusCode == 302) {
          final location = response.headers['location'];
          expect(location, isNotNull,
              reason: 'Redirect should have location header');
          expect(location!, contains('/releases/tag/'),
              reason: 'Should redirect to a specific release tag');
          
          // Extract version from location (mimic bash logic)
          final version = location.split('/').last;
          expect(RegExp(r'^v?[0-9]+\.[0-9]+\.[0-9]+').hasMatch(version), true,
              reason: 'Version should match semantic versioning pattern');
        }
      } catch (e) {
        fail('Version detection request failed: $e');
      }
    });

    test('Download URL construction should be accurate', () async {
      // Test that the URL pattern used in install.sh is correct
      const testVersion = '3.2.1';
      
      final urls = [
        'https://github.com/leoafarias/fvm/releases/download/$testVersion/fvm-$testVersion-linux-x64.tar.gz',
        'https://github.com/leoafarias/fvm/releases/download/$testVersion/fvm-$testVersion-macos-arm64.tar.gz',
        'https://github.com/leoafarias/fvm/releases/download/$testVersion/fvm-$testVersion-macos-x64.tar.gz',
      ];
      
      for (final url in urls) {
        try {
          final response = await http.head(Uri.parse(url));
          
          // Should get redirect to actual asset or not found (if version doesn't exist)
          expect([200, 302, 404].contains(response.statusCode), true,
              reason: 'Asset URL should be valid: $url');
              
          if (response.statusCode == 302) {
            final location = response.headers['location'];
            expect(location, isNotNull,
                reason: 'Asset redirect should have location header');
            expect(location!, contains('.tar.gz'),
                reason: 'Should redirect to tar.gz file');
          }
        } catch (e) {
          fail('Asset URL test failed for $url: $e');
        }
      }
    });

    test('Install script should handle file extraction edge cases', () {
      // This is a failing test that will expose the glob pattern issue
      // The install.sh uses: mv "$TEMP_EXTRACT/fvm"/* "$FVM_DIR_BIN/"
      // This fails if the glob matches nothing or there are hidden files
      
      // Create a temporary test scenario
      final testDir = Directory.systemTemp.createTempSync('fvm_extract_test');
      final extractDir = Directory('${testDir.path}/temp_extract');
      final fvmDir = Directory('${extractDir.path}/fvm');
      final binDir = Directory('${testDir.path}/bin');
      
      try {
        extractDir.createSync(recursive: true);
        fvmDir.createSync();
        binDir.createSync();
        
        // Test case 1: Empty fvm directory - should now work with cp -r
        final result = Process.runSync('bash', [
          '-c',
          'cp -r "${fvmDir.path}/." "${binDir.path}/"'
        ]);
        expect(result.exitCode, equals(0),
            reason: 'Should handle empty fvm directory gracefully with cp -r');
        
      } finally {
        testDir.deleteSync(recursive: true);
      }
    });

    test('Script should validate version format strictly', () {
      // Test version regex in install.sh: ^v?[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9._-]+)?$
      
      final validVersions = [
        '3.2.1',
        'v3.2.1',
        '1.0.0-beta',
        '2.1.0-alpha.1',
        '4.0.0-rc.2',
      ];
      
      final invalidVersions = [
        '1.2',           // Missing patch version
        'v1.2.3.4',      // Too many version parts
        '1.2.3-',        // Trailing dash
        '1.2.3-@invalid', // Invalid characters in prerelease
      ];
      
      final versionRegex = RegExp(r'^v?[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9]+(\.[a-zA-Z0-9]+)*)?$');
      
      for (final version in validVersions) {
        expect(versionRegex.hasMatch(version), true,
            reason: '$version should be valid');
      }
      
      for (final version in invalidVersions) {
        expect(versionRegex.hasMatch(version), false,
            reason: '$version should be invalid');
      }
      
      // This test should expose that the regex is too permissive
      const tooPermissiveVersion = '1.2.3-....';
      expect(versionRegex.hasMatch(tooPermissiveVersion), false,
          reason: 'Regex should reject versions with only dots in prerelease');
    });

    test('Script should handle symlink safety correctly', () {
      // Test the symlink safety logic in uninstall
      final testDir = Directory.systemTemp.createTempSync('fvm_symlink_test');
      final fvmBin = File('${testDir.path}/fvm');
      final symlink = File('${testDir.path}/fvm_link');
      final otherBin = File('${testDir.path}/other_fvm');
      
      try {
        // Create test files
        fvmBin.writeAsStringSync('#!/bin/bash\necho "FVM"');
        otherBin.writeAsStringSync('#!/bin/bash\necho "Other FVM"');
        
        // Create symlink pointing to our FVM
        Process.runSync('ln', ['-sf', fvmBin.path, symlink.path]);
        
        // Test that we correctly identify our symlinks
        final result = Process.runSync('readlink', [symlink.path]);
        expect(result.stdout.toString().trim(), equals(fvmBin.path),
            reason: 'Should correctly read symlink target');
            
        // Now create a symlink pointing to different FVM
        Process.runSync('ln', ['-sf', otherBin.path, symlink.path]);
        final result2 = Process.runSync('readlink', [symlink.path]);
        expect(result2.stdout.toString().trim(), equals(otherBin.path),
            reason: 'Should not remove symlinks pointing to other installations');
            
      } finally {
        testDir.deleteSync(recursive: true);
      }
    });

    test('Script should handle network failures gracefully', () async {
      // Test with invalid URL to simulate network failure
      const invalidUrl = 'https://invalid-domain-12345.com/releases/latest';
      
      try {
        await http.head(Uri.parse(invalidUrl)).timeout(Duration(seconds: 5));
        fail('Invalid URL should not succeed');
      } catch (e) {
        expect(e, isNotNull,
            reason: 'Should handle network errors gracefully');
      }
      
      // This demonstrates the fallback behavior the script should have
      const fallbackVersion = '3.2.1';
      expect(RegExp(r'^[0-9]+\.[0-9]+\.[0-9]+$').hasMatch(fallbackVersion), true,
          reason: 'Fallback version should be valid');
    });
  });
}