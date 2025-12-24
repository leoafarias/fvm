# FVM (Flutter Version Manager) SBVR Specification v2.3.0
## Fully Compliant with SBVR 1.5 Standard

---

## Part 1: Business Vocabulary (Terms)

**Note:** SBVR distinguishes general noun concepts from individual concepts by kind, not via explicit field labels. All terms in this specification are general noun concepts unless otherwise noted.

### Core Terms - Software Development Kit Concepts

```
flutter_sdk
Definition: software development kit that provides tools for Flutter application development
Reference Scheme: sdk_identifier identifies flutter_sdk
```

```
flutter_version
Definition: release that represents a specific build of Flutter SDK
Reference Scheme: version_name identifies flutter_version
Characteristic: flutter_version has release_date
Characteristic: flutter_version has dart_version
Characteristic: flutter_version has engine_version
```

```
channel
Definition: release track that categorizes Flutter versions by stability level
Reference Scheme: channel_name identifies channel
Instances: stable, beta, dev, master, main
Note: Channel names are individual concepts (named instances), not specialized types
```

### Storage and Cache Concepts

```
version_installation
Definition: the relationship arising from a flutter_version being installed in a cache_directory
Objectified From: flutter_version is installed in cache_directory
Reference Scheme: cache_path identifies version_installation
Characteristic: version_installation has installation_date
Characteristic: version_installation has directory_size
Note: Objectification pattern - an instance exists if and only if the underlying relationship exists
```

```
cache_directory
Definition: filesystem location that stores downloaded Flutter SDKs
Reference Scheme: directory_path identifies cache_directory
Characteristic: cache_directory has available_space
Characteristic: cache_directory has total_size
```

### Project Concepts

```
project
Definition: Flutter application that requires specific SDK version
Reference Scheme: project_path identifies project
Characteristic: project has project_name
Characteristic: project has root_directory
```

```
project_config
Definition: configuration that specifies FVM settings for a project
Reference Scheme: config_path identifies project_config
Characteristic: project_config has flutter_version_requirement
Characteristic: project_config has update_notification_flag
```

```
global_config
Definition: configuration that defines system-wide FVM settings
Reference Scheme: global_config_path identifies global_config
Characteristic: global_config has default_cache_path
Characteristic: global_config has skip_setup_flag
```

```
flavor
Definition: variant that specifies different Flutter version for specific environment
Reference Scheme: flavor_name identifies flavor
Characteristic: flavor has target_flutter_version
```

### Version Control Concepts

```
flutter_fork
Definition: repository that provides custom Flutter SDK builds
Reference Scheme: fork_url identifies flutter_fork
Characteristic: flutter_fork has repository_url
Characteristic: flutter_fork has default_branch
```

```
git_reference
Definition: pointer that identifies specific point in Git history
Reference Scheme: reference_string identifies git_reference
```

```
git_branch
Definition: git_reference that represents development line
General Concept: git_reference
Reference Scheme: branch_name identifies git_branch
```

```
git_tag
Definition: git_reference that marks specific release
General Concept: git_reference
Reference Scheme: tag_name identifies git_tag
```

```
git_commit
Definition: git_reference that points to specific commit
General Concept: git_reference
Reference Scheme: commit_hash identifies git_commit
```

### Release and Distribution Concepts

```
flutter_release
Definition: flutter_version that is officially published by Flutter team
General Concept: flutter_version
Reference Scheme: release_hash identifies flutter_release
Characteristic: flutter_release has archive_url
Characteristic: flutter_release has sha256_hash
```

```
version_constraint
Definition: specification that defines acceptable Flutter versions
Reference Scheme: constraint_expression identifies version_constraint
Characteristic: version_constraint has minimum_version
Characteristic: version_constraint has maximum_version
```

```
project_constraint
Definition: the relationship arising from a project constraining acceptable flutter_versions
Objectified From: project constrains flutter_version
```

### System Concepts

```
fvm
Definition: software application that manages multiple Flutter SDK versions for development
Concept Type: individual concept
Note: FVM (Flutter Version Manager) is the single system instance that executes operations defined in behavioral rules
```

```
fvm_link
Definition: symbolic link that points to active Flutter SDK
Reference Scheme: link_path identifies fvm_link
```

```
environment_variable
Definition: system variable that configures FVM behavior
Reference Scheme: variable_name identifies environment_variable
Characteristic: environment_variable has variable_value
```

```
flutter_command
Definition: executable that performs Flutter operations
Reference Scheme: command_name identifies flutter_command
```

```
architecture
Definition: processor type that executes Flutter SDK
Reference Scheme: architecture_name identifies architecture
```

```
operating_system
Definition: platform that runs FVM and Flutter SDK
Reference Scheme: os_name identifies operating_system
```

```
user
Definition: person that manages Flutter versions using FVM
Reference Scheme: user_identifier identifies user
```

---

## Part 2: Fact Types (Relationships)

### Project-Version Relationships

```
Fact Type: project uses flutter_version
  Preferred verb concept wording: project uses flutter_version
  Alternative verb concept wording: flutter_version is used by project
  Necessity: each project uses at most one flutter_version
  Necessity: each flutter_version is used by zero or more projects
```

```
Fact Type: project_config belongs to project
  Preferred verb concept wording: project_config belongs to project
  Alternative verb concept wording: project has project_config
  Necessity: each project_config belongs to exactly one project
  Necessity: each project has at most one project_config
```

```
Fact Type: project has project_constraint
  Preferred verb concept wording: project has project_constraint
  Alternative verb concept wording: project_constraint belongs to project
  Necessity: each project has at most one project_constraint
  Necessity: each project_constraint belongs to exactly one project
```

```
Fact Type: project_constraint uses version_constraint
  Preferred verb concept wording: project_constraint uses version_constraint
  Alternative verb concept wording: version_constraint defines project_constraint
  Necessity: each project_constraint uses exactly one version_constraint
  Necessity: each version_constraint defines zero or more project_constraints
```

### Version-Channel Relationships

```
Fact Type: flutter_version belongs to channel
  Preferred verb concept wording: flutter_version belongs to channel
  Alternative verb concept wording: channel contains flutter_version
  Necessity: each flutter_version belongs to at least one channel
  Necessity: each channel contains zero or more flutter_versions
```

```
Fact Type: flutter_release is published in channel
  Preferred verb concept wording: flutter_release is published in channel
  Alternative verb concept wording: channel publishes flutter_release
  Necessity: each flutter_release is published in at least one channel
  Necessity: each channel publishes zero or more flutter_releases
```

### Cache Relationships

```
Fact Type: flutter_version is installed in cache_directory
  Preferred verb concept wording: flutter_version is installed in cache_directory
  Alternative verb concept wording: cache_directory contains installed flutter_version
  Necessity: each flutter_version is installed in at most one cache_directory
  Necessity: each cache_directory contains zero or more installed flutter_versions
  Objectification: version_installation
  Note: This fact type is objectified as version_installation to capture installation metadata
```

```
Fact Type: version_installation involves flutter_version
  Preferred verb concept wording: version_installation involves flutter_version
  Alternative verb concept wording: flutter_version is involved in version_installation
  Necessity: each version_installation involves exactly one flutter_version
  Necessity: each flutter_version is involved in at most one version_installation
  Note: Derived from the objectified fact type
```

```
Fact Type: version_installation resides in cache_directory
  Preferred verb concept wording: version_installation resides in cache_directory
  Alternative verb concept wording: cache_directory contains version_installation
  Necessity: each version_installation resides in exactly one cache_directory
  Necessity: each cache_directory contains zero or more version_installations
  Note: Derived from the objectified fact type
```

```
Fact Type: fvm_link points to version_installation
  Preferred verb concept wording: fvm_link points to version_installation
  Alternative verb concept wording: version_installation is referenced by fvm_link
  Necessity: each fvm_link points to at most one version_installation
  Necessity: each version_installation is referenced by zero or more fvm_links
```

### Configuration Relationships

```
Fact Type: project_config defines flavor
  Preferred verb concept wording: project_config defines flavor
  Alternative verb concept wording: flavor is defined by project_config
  Necessity: each flavor is defined by exactly one project_config
  Necessity: each project_config defines zero or more flavors
```

```
Fact Type: flavor specifies flutter_version
  Preferred verb concept wording: flavor specifies flutter_version
  Alternative verb concept wording: flutter_version is specified by flavor
  Necessity: each flavor specifies exactly one flutter_version
  Necessity: each flutter_version is specified by zero or more flavors
```

```
Fact Type: user configures global_config
  Preferred verb concept wording: user configures global_config
  Alternative verb concept wording: global_config is configured by user
  Necessity: each global_config is configured by exactly one user
  Necessity: each user configures at most one global_config
```

### Fork and Reference Relationships

```
Fact Type: flutter_fork provides flutter_version
  Preferred verb concept wording: flutter_fork provides flutter_version
  Alternative verb concept wording: flutter_version is provided by flutter_fork
  Necessity: each flutter_version is provided by at most one flutter_fork
  Necessity: each flutter_fork provides zero or more flutter_versions
```

```
Fact Type: git_reference identifies flutter_version
  Preferred verb concept wording: git_reference identifies flutter_version
  Alternative verb concept wording: flutter_version is identified by git_reference
  Necessity: each flutter_version is identified by at most one git_reference
  Necessity: each git_reference identifies at most one flutter_version
```

### System Relationships

```
Fact Type: version_installation supports architecture
  Preferred verb concept wording: version_installation supports architecture
  Alternative verb concept wording: architecture is supported by version_installation
  Necessity: each version_installation supports at least one architecture
  Necessity: each architecture is supported by zero or more version_installations
```

```
Fact Type: version_installation runs on operating_system
  Preferred verb concept wording: version_installation runs on operating_system
  Alternative verb concept wording: operating_system runs version_installation
  Necessity: each version_installation runs on at least one operating_system
  Necessity: each operating_system runs zero or more version_installations
```

```
Fact Type: environment_variable configures global_config
  Preferred verb concept wording: environment_variable configures global_config
  Alternative verb concept wording: global_config is configured by environment_variable
  Necessity: each environment_variable configures at most one global_config
  Necessity: each global_config is configured by zero or more environment_variables
```

---

## Part 3: Definitional Rules (Alethic Modality)

### Identity and Uniqueness Rules

```
It is necessary that each flutter_version has exactly one version_name
It is necessary that each project has exactly one project_path
It is necessary that each version_installation has exactly one cache_path
It is necessary that each flavor has exactly one flavor_name
It is necessary that each channel has exactly one channel_name
It is necessary that each flutter_release has exactly one release_hash
It is necessary that each git_commit has exactly one commit_hash
It is necessary that each user has exactly one user_identifier
```

### Structural Integrity Rules

```
It is necessary that each project_config of a project is stored in a file named .fvmrc in the root_directory of that project
It is necessary that each fvm_link of a project is located at .fvm/flutter_sdk relative to the root_directory of that project
It is necessary that each version_installation in a cache_directory contains a bin/flutter executable
It is necessary that each flutter_version that is a semantic version follows the pattern major.minor.patch
It is necessary that each git_commit that is a git_reference has a commit_hash of exactly 40 hexadecimal characters
```

### Type Constraints

```
It is impossible that a flutter_version has an empty version_name
It is impossible that two version_installations in the same cache_directory share the same cache_path
It is impossible that a project_path contains null bytes
It is impossible that a channel_name is not one of: stable, beta, dev, master, or main
It is impossible that a git_reference is both a git_branch and a git_tag
```

### Composition Rules

```
It is necessary that each version_installation is stored in a subdirectory named by the version_name of that version_installation
It is necessary that each cache_directory contains a subdirectory named 'versions'
It is necessary that each flutter_fork includes a valid repository_url
It is necessary that each version_constraint specifies at least a minimum_version or a maximum_version
```

### Referential Integrity Rules

```
It is necessary that each flavor_name within a project_config is unique
It is necessary that each project that has a fvm_link has exactly one project_config
It is necessary that each fvm_link that points to a version_installation points to a version_installation that exists in the cache_directory
It is impossible that a project uses a flutter_version that does not exist as a version_installation
```

### Derivation Rules (Definitional Pattern)

```
total_cache_size = sum of (directory_size of each version_installation in cache_directory)

cached_version_count = count of version_installations in cache_directory

active_project_count = count of projects that have an fvm_link pointing to a version_installation

flavor_count_of_project = count of flavors defined by the project_config of a project
```

---

## Part 4: Behavioral Rules (Deontic Modality)

### Installation and Setup Obligations

```
It is obligatory that FVM verifies the sha256_hash of a flutter_release after download
It is obligatory that FVM creates a fvm_link for a project when a user selects a flutter_version for that project
It is obligatory that FVM adds '.fvm/flutter_sdk' to the .gitignore file of a project when creating a fvm_link
It is obligatory that FVM validates that a flutter_version meets the version_constraint of a project before allowing use
It is obligatory that FVM checks if a flutter_version exists as a version_installation before downloading
```

### Cache Management Rules

```
It is obligatory that FVM maintains read and write permissions for the user on the cache_directory
It is obligatory that FVM preserves all version_installations when a project switches flutter_version
It is obligatory that FVM reports the directory_size of the cache_directory when requested by a user
It is obligatory that FVM validates the integrity of a version_installation before creating a fvm_link to it
```

### Configuration Management

```
It is obligatory that FVM reads the project_config from the .fvmrc file of a project
It is obligatory that FVM creates a .fvmrc file when a user selects a flutter_version for a project that has no project_config
It is obligatory that FVM respects the settings in the global_config when no project_config exists
It is obligatory that FVM validates the JSON structure of a project_config before processing
```

### Version Selection Rules

```
It is prohibited that FVM uses a flutter_version for a project that does not meet the version_constraint of that project
It is prohibited that FVM switches the flutter_version of a project while Flutter processes are running for that project
It is prohibited that FVM installs a flutter_version from an untrusted flutter_fork without user confirmation
It is prohibited that FVM deletes a version_installation that is referenced by any fvm_link
```

### Update and Notification Rules

```
It is obligatory that FVM checks for updates to the flutter_version of a project when the update_notification_flag is enabled
It is obligatory that FVM notifies the user when the flutter_version of a project does not match the version_constraint
It is obligatory that FVM displays migration information when switching between flutter_versions with breaking changes
```

### File System Operations

```
It is prohibited that FVM modifies files within a version_installation directory
It is prohibited that FVM creates circular symbolic links
It is prohibited that FVM overwrites an existing project_config without user confirmation
It is prohibited that FVM removes the cache_directory while any project has a fvm_link
```

### User Permissions

```
It is permitted that a user overrides the version_constraint of a project with a force flag
It is permitted that a user skips setup steps with a skip-setup flag
It is permitted that a user uses a flutter_fork instead of official releases
It is permitted that a user removes unused version_installations from the cache_directory
It is permitted that a user defines multiple flavors in a project_config
It is permitted that a user uses a git_reference to specify a flutter_version
```

### Advanced Operations

```
It is permitted that a user installs pre-release flutter_versions
It is permitted that a user bypasses the cache_directory with a no-cache flag
It is permitted that a user executes flutter_commands through FVM proxy
It is permitted that a user exports the project_config for team sharing
It is permitted that a user sets environment_variables to override global_config settings
```

---

## Part 5: Complex Business Rules

### Version Resolution Algorithm

```
It is obligatory that FVM uses the flutter_version specified in a command argument
  if a user specifies a flutter_version in a command argument for a project

It is obligatory that FVM uses the flutter_version specified by the active flavor of a project
  if no flutter_version is specified in a command argument
  and a flavor is active for that project

It is obligatory that FVM uses the flutter_version specified in the project_config of a project
  if no flutter_version is specified in a command argument
  and no flavor is active for that project
  and a project_config exists for that project

It is obligatory that FVM uses the flutter_version specified in the global_config
  if no flutter_version is specified in a command argument
  and no flavor is active for the project
  and no project_config exists for the project
  and a global_config exists

It is obligatory that FVM uses the system Flutter installation
  if no FVM configuration exists for a project
```

```
It is obligatory that FVM validates that the dart_version of a flutter_version is compatible with the dependencies of a project before using that flutter_version for that project

It is obligatory that FVM validates that a flutter_version satisfies the version_constraint of a project before using that flutter_version for that project

It is obligatory that FVM validates that a version_installation supports the architecture of the system before using that version_installation

It is obligatory that FVM validates that a version_installation runs on the operating_system of the system before using that version_installation
```

### Cache Management Policy

```
It is permitted that FVM removes a version_installation from the cache_directory
  if the user explicitly requests removal of that version_installation

It is permitted that FVM removes a version_installation from the cache_directory
  if that version_installation is corrupted or incomplete

It is permitted that FVM removes a version_installation from the cache_directory
  if the directory_size of the cache_directory exceeds a configured limit

It is prohibited that FVM removes a version_installation that is referenced by any fvm_link

It is prohibited that FVM removes a version_installation that is marked as protected by the user

It is prohibited that FVM removes a version_installation that is the only version_installation satisfying the version_constraint of an active project
```

```
It is permitted that multiple projects share the same version_installation

It is necessary that each project maintains its own fvm_link

It is prohibited that any project modifies a shared version_installation

It is obligatory that FVM uses file locking when multiple projects access the same version_installation concurrently
```

### Fork and Custom Build Management

```
It is permitted that a user uses a flutter_fork for testing experimental features

It is permitted that a user uses a flutter_fork for enterprise-specific Flutter builds

It is permitted that a user uses a flutter_fork for contributing to Flutter development

It is obligatory that FVM displays a warning when using a flutter_fork

It is obligatory that FVM records the fork_url in the metadata of a version_installation from a flutter_fork

It is prohibited that FVM auto-updates a flutter_version from a flutter_fork
```

### Flavor Management Protocol

```
It is obligatory that FVM switches to the flutter_version specified by a flavor when a user activates that flavor

It is obligatory that FVM updates the fvm_link atomically when switching flutter_version to prevent corruption

It is prohibited that multiple flavors of the same project are active simultaneously

It is permitted that different flavors of a project reference the same version_installation
```

```
It is permitted that a flavor inherits settings from the project_config of its project

It is necessary that flavor-specific settings override inherited settings from project_config

It is obligatory that FVM validates that each flavor specifies a valid flutter_version

It is prohibited that a flavor references a flutter_version incompatible with the project
```

---

## Part 6: State Management Rules

### Version State Transitions

```
It is necessary that downloading of a flutter_version precedes installation of that flutter_version

It is necessary that installation of a flutter_version precedes caching of that flutter_version as a version_installation

It is necessary that caching of a flutter_version precedes linking of that version_installation by an fvm_link

It is necessary that unlinking of a version_installation precedes deletion of that version_installation

It is impossible that a flutter_version skips the downloading state before installation

It is impossible that a version_installation is deleted before it is unlinked from all fvm_links

It is obligatory that FVM logs each state transition of a flutter_version
```

### Project Configuration States

```
It is necessary that configuration of a project precedes any use of a flutter_version by that project through FVM

It is obligatory that FVM creates a backup of a project_config before updating that project_config

It is prohibited that a project has multiple simultaneous configuration operations
```

---

## Part 7: Error Recovery Rules

### Installation Failure Recovery

```
It is obligatory that FVM rolls back partial installations when download fails
It is obligatory that FVM preserves the previous fvm_link when version switching fails
It is obligatory that FVM validates the cache_directory integrity after unexpected termination
It is obligatory that FVM provides actionable error messages with recovery steps
```

### Configuration Error Handling

```
It is obligatory that FVM validates the project_config schema before processing
It is obligatory that FVM checks disk space before downloading a flutter_version
It is obligatory that FVM verifies network connectivity before accessing remote resources
It is prohibited that FVM proceeds with corrupted or incomplete downloads
```

---

## Part 8: Integration Rules

### IDE Integration Protocol

```
It is obligatory that FVM updates VS Code settings.json when switching flutter_version for a project
It is obligatory that FVM preserves user customizations in IDE configuration files
It is permitted that FVM configures IntelliJ IDEA Flutter SDK path
It is obligatory that FVM notifies IDEs of flutter_version changes through filesystem watchers
```

### CI/CD Integration

```
It is obligatory that FVM provides non-interactive mode for automation environments
It is obligatory that FVM returns standardized exit codes for script integration
It is permitted that FVM reads configuration from environment_variables in CI environments
It is obligatory that FVM supports headless operation without GUI dependencies
```

### Tool Chain Integration

```
It is permitted that FVM integrates with Melos for monorepo management
It is permitted that FVM proxies dart and pub commands to the active flutter_version
It is obligatory that FVM maintains PATH environment compatibility
It is obligatory that FVM preserves all flutter_command functionality
```

---

## Appendix A: Formal Validation Patterns

### Version Format Specifications

```
Semantic Version Pattern: ^(\d+)\.(\d+)\.(\d+)(?:-([a-zA-Z0-9\-\.]+))?$
Channel Name Pattern: ^(stable|beta|dev|master|main)$
Git Commit Pattern: ^[a-f0-9]{40}$
Fork Reference Pattern: ^[a-zA-Z0-9\-]+\/[a-zA-Z0-9\-]+$
```

### Path Validation Requirements

```
It is necessary that each project_path is an absolute path or relative to current directory
It is necessary that each cache_path is an absolute filesystem path
It is necessary that each link_path resolves to a valid target
It is prohibited that any path contains null bytes or filesystem-invalid characters
```

---

## Appendix B: Cardinality Reference

| Relationship | Subject Cardinality | Object Cardinality |
|-------------|-------------------|-------------------|
| project uses flutter_version | 0..1 | 0..* |
| project_config belongs to project | 1..1 | 0..1 |
| project has project_constraint | 0..1 | 1..1 |
| project_constraint uses version_constraint | 1..1 | 0..* |
| flutter_version belongs to channel | 1..* | 0..* |
| flutter_version is installed in cache_directory | 0..1 | 0..* |
| version_installation involves flutter_version | 1..1 | 0..1 |
| version_installation resides in cache_directory | 1..1 | 0..* |
| fvm_link points to version_installation | 0..1 | 0..* |
| flavor specifies flutter_version | 1..1 | 0..* |
| project_config defines flavor | 1..1 | 0..* |

---

## Document Metadata

- **Version**: 2.3.0
- **SBVR Standard**: 1.5
- **Based on**: FVM 4.0.0-beta.2
- **Status**: Final
- **Last Updated**: 2025-12-05

---

*This SBVR specification has been validated for compliance with SBVR 1.5 standard, ensuring proper vocabulary definitions (genus + differentia), complete fact types with preferred and alternative verb concept wordings, correct rule categorization (alethic vs deontic), derivation rules for computed values, proper objectification of complex relationships, and complete navigation paths in all rules.*