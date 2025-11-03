# fvm

![GitHub stars](https://img.shields.io/github/stars/leoafarias/fvm?style=for-the-badge&logo=GitHub&logoColor=black&labelColor=white&color=dddddd)
[![Pub Version](https://img.shields.io/pub/v/fvm?label=version&style=for-the-badge&logo=dart&logoColor=3DB0F3&labelColor=white&color=3DB0F3)](https://pub.dev/packages/fvm/changelog)
[![Pub Likes](https://img.shields.io/pub/likes/fvm?style=for-the-badge&logo=dart&logoColor=3DB0F3&label=Pub%20Likes&labelColor=white&color=3DB0F3)](https://pub.dev/packages/fvm/score)
[![Pub Points](https://img.shields.io/pub/points/fvm?style=for-the-badge&logo=dart&logoColor=3DB0F3&label=Points&labelColor=white&color=3DB0F3)](https://pub.dev/packages/fvm/score)
[![All Contributors](https://img.shields.io/github/contributors/leoafarias/fvm?style=for-the-badge&color=018D5B&labelColor=004F32)](https://github.com/leoafarias/fvm/graphs/contributors)
[![MIT License](https://img.shields.io/github/license/leoafarias/fvm?style=for-the-badge&color=FF2E00&labelColor=CB2500)](https://opensource.org/licenses/mit-license.php)
![Codecov](https://img.shields.io/codecov/c/github/leoafarias/fvm?style=for-the-badge&color=FFD43A&labelColor=F3BE00)
[![Awesome Flutter](https://img.shields.io/badge/awesome-flutter-8A00CB?style=for-the-badge&color=8A00CB&labelColor=630092)](https://github.com/Solido/awesome-flutter)

FVM manages Flutter SDK versions per project. Switch between Flutter versions instantly without reinstalling, making it easy to test new releases and maintain consistent builds across your team.

## Why FVM?

- Need for simultaneous use of multiple Flutter SDKs.
- SDK testing requires constant [channel](https://github.com/flutter/flutter/wiki/Flutter-build-release-channels) switching.
- Channel switches are slow and need repeated reinstalls.
- Difficulty managing the latest successful SDK version used in an app.
- Flutter's major updates demand total app migration.
- Inconsistencies occur in development environments within teams.

For more information, read the [Getting Started guide](https://fvm.app/documentation/getting-started).

## Release Process (For Maintainers)

FVM uses GitHub releases to trigger automated deployments across all platforms:

### Creating a New Release

1. **Ensure main branch is ready**
   - All changes merged and tested
   - Version will be set automatically from release tag

2. **Create GitHub Release**
   - Go to [GitHub Releases](https://github.com/leoafarias/fvm/releases)
   - Click "Create a new release"  
   - Choose tag: `v4.0.0-beta.2` (follows semver with 'v' prefix)
   - Write release notes in GitHub editor
   - Click "Publish release"

3. **Automated Deployment**
   - [`release.yml`](.github/workflows/release.yml) triggers automatically
   - Deploys to: pub.dev, GitHub binaries, Homebrew, Chocolatey, Docker
   - Monitor progress in [Actions tab](https://github.com/leoafarias/fvm/actions)

### Emergency Releases

For hotfixes or emergency releases:
1. **Update version manually** in `pubspec.yaml`
2. **Use individual platform workflows** via manual dispatch:
   - `deploy_homebrew.yml` for Homebrew updates
   - `deploy_docker.yml` for Docker deployment
   - Individual platform deployments as needed

For complete emergency deployment, create a GitHub release as normal.

See [Workflow Documentation](.github/workflows/README.md) for detailed information.

## Contributors

<a href="https://github.com/leoafarias/fvm/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=leoafarias/fvm" />
</a>

---

Checkout Flutter Sidekick. [Read more about it here.](https://github.com/leoafarias/sidekick)

## Troubleshooting

Please view our [FAQ](https://fvm.app/documentation/getting-started/faq).

## License

This project is licensed under the MIT License; see [LICENSE](LICENSE) file for details.

# FVM Version Format Testing Guide

This directory contains a testing environment for validating the Flutter Version Manager (FVM) version format handling. The tests focus on ensuring that all valid version formats are correctly parsed and applied, while invalid formats are properly rejected.

## Test Script Overview

The `run_tests.sh` script automates the testing of various version formats with FVM. It:

1. Creates a clean Flutter test environment
2. Tests different version formats including:
   - Channel versions (stable, beta, dev, master)
   - Semantic versions (e.g., 2.10.0)
   - Versions with 'v' prefix (e.g., v2.10.0)  
   - Versions with channel specification (e.g., 2.10.0@beta)
   - Fork specifications (e.g., custom-fork/stable)
3. Validates error handling for invalid formats
4. Reports test results

## Running the Tests

To run the tests with standard output:

```bash
./run_tests.sh
```

For detailed debugging output:

```bash
./run_tests.sh --verbose
```

## Tested Version Formats

The script tests the following version formats:

| Format | Example | Description |
|--------|---------|-------------|
| Channel | `stable`, `beta` | Flutter release channels |
| Semantic Version | `2.10.0` | Specific Flutter version |
| V-prefixed Version | `v2.10.0` | Version with 'v' prefix |
| Version with Channel | `2.10.0@beta` | Specific version from a channel |
| V-prefixed with Channel | `v2.10.0@beta` | V-prefixed version from a channel |
| Fork with Channel | `custom-fork/stable` | Fork with specified channel |

## Error Cases

The script also validates proper rejection of invalid formats:

- Invalid channel specification (`2.10.0@invalid`)
- Custom build with channel (`custom_build@beta`)
- Non-existent fork (`unknown-fork/stable`)

## Test Results

After running the tests, review the output to ensure all tests passed. If any failures occur, the script will provide details about what went wrong.

For a complete record of test outcomes, refer to the `TEST_RESULTS.md` file which may be generated after running the tests.

## Prerequisites

- Dart SDK must be installed and available in PATH
- Flutter SDK must be installed and available in PATH
- The script should be run from the `test/fixtures/sample_app` directory

## Troubleshooting

If some tests are skipped, it may be because:

1. The required Flutter versions are not installed
2. The `list` command in the FVM implementation has issues

In these cases, the script will continue with available tests and provide warnings about what was skipped.
