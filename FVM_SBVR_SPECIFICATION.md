# FVM (Flutter Version Manager) SBVR Specification v2.4.0

## Aligned with SBVR 1.5 Standard

---

## Part 1: Business Vocabulary (Terms)

**Note:** SBVR distinguishes general noun concepts from individual concepts by kind, not via explicit field labels. All terms in this specification are general noun concepts unless otherwise noted.

### 1.1 Core Terms - Software Development Kit Concepts

**flutter sdk**
- Definition: software development kit that provides tools for Flutter application development
- Reference Scheme: sdk identifier identifies flutter sdk

---

**flutter version**
- Definition: release that represents a specific build of Flutter SDK
- Reference Scheme: version name identifies flutter version

---

**channel**
- Definition: release track that categorizes Flutter versions by stability level
- Reference Scheme: channel name identifies channel
- Note: Channel names are individual concepts (named instances), not specialized types
- Definitional Rules:
  - It is impossible that a channel is other than stable, beta, dev, master, or main

---

### 1.2 Storage and Cache Concepts

**version installation**
- Definition: the relationship arising from a flutter version being installed in a cache directory
- Objectified From: flutter version is installed in cache directory
- Reference Scheme: cache path identifies version installation
- Note: Objectification pattern - an instance exists if and only if the underlying relationship exists

---

**cache directory**
- Definition: filesystem location that stores downloaded Flutter SDKs
- Reference Scheme: directory path identifies cache directory

---

### 1.3 Project Concepts

**project**
- Definition: Flutter application that requires specific SDK version
- Reference Scheme: project path identifies project

---

**project config**
- Definition: configuration that specifies FVM settings for a project
- Reference Scheme: config path identifies project config

---

**global config**
- Definition: configuration that defines system-wide FVM settings
- Reference Scheme: global config path identifies global config

---

**flavor**
- Definition: variant that specifies different Flutter version for specific environment
- Reference Scheme: flavor name identifies flavor

---

### 1.4 Version Control Concepts

**flutter fork**
- Definition: repository that provides custom Flutter SDK builds
- Reference Scheme: fork url identifies flutter fork

---

**git reference**
- Definition: pointer that identifies specific point in Git history
- Reference Scheme: reference string identifies git reference

---

**git branch**
- Definition: git reference that represents development line
- General Concept: git reference
- Reference Scheme: branch name identifies git branch

---

**git tag**
- Definition: git reference that marks specific release
- General Concept: git reference
- Reference Scheme: tag name identifies git tag

---

**git commit**
- Definition: git reference that points to specific commit
- General Concept: git reference
- Reference Scheme: commit hash identifies git commit

---

### 1.5 Release and Distribution Concepts

**flutter release**
- Definition: flutter version that is officially published by Flutter team
- General Concept: flutter version
- Reference Scheme: release hash identifies flutter release

---

**version constraint**
- Definition: specification that defines acceptable Flutter versions
- Reference Scheme: constraint expression identifies version constraint

---

**project constraint**
- Definition: the relationship arising from a project constraining acceptable flutter versions
- Objectified From: project constrains flutter version

---

### 1.6 System Concepts

**fvm**
- Definition: software application that manages multiple Flutter SDK versions for development
- Note: Individual concept. FVM (Flutter Version Manager) is the single system instance that executes operations defined in behavioral rules

---

**fvm link**
- Definition: symbolic link that points to active Flutter SDK
- Reference Scheme: link path identifies fvm link

---

**environment variable**
- Definition: system variable that configures FVM behavior
- Reference Scheme: variable name identifies environment variable

---

**flutter command**
- Definition: executable that performs Flutter operations
- Reference Scheme: command name identifies flutter command

---

**architecture**
- Definition: processor type that executes Flutter SDK
- Reference Scheme: architecture name identifies architecture

---

**operating system**
- Definition: platform that runs FVM and Flutter SDK
- Reference Scheme: os name identifies operating system

---

**user**
- Definition: person that manages Flutter versions using FVM
- Reference Scheme: user identifier identifies user

---

## Part 2: Fact Types (Relationships)

### 2.1 Value Attribute Fact Types

These fact types represent value attributes of noun concepts (moved from Part 1 Characteristics).

#### Flutter Version Attributes

| Fact Type | Necessity |
|-----------|-----------|
| flutter version has release date | each flutter version has at most one release date |
| flutter version has dart version | each flutter version has exactly one dart version |
| flutter version has engine version | each flutter version has exactly one engine version |

#### Version Installation Attributes

| Fact Type | Necessity |
|-----------|-----------|
| version installation has installation date | each version installation has exactly one installation date |
| version installation has directory size | each version installation has exactly one directory size |

#### Cache Directory Attributes

| Fact Type | Necessity |
|-----------|-----------|
| cache directory has available space | each cache directory has exactly one available space |
| cache directory has total size | each cache directory has exactly one total size |

#### Project Attributes

| Fact Type | Necessity |
|-----------|-----------|
| project has project name | each project has exactly one project name |
| project has root directory | each project has exactly one root directory |

#### Project Config Attributes

| Fact Type | Necessity |
|-----------|-----------|
| project config has flutter version requirement | each project config has at most one flutter version requirement |
| project config has update notification flag | each project config has exactly one update notification flag |

#### Global Config Attributes

| Fact Type | Necessity |
|-----------|-----------|
| global config has default cache path | each global config has exactly one default cache path |
| global config has skip setup flag | each global config has exactly one skip setup flag |

#### Flavor Attributes

| Fact Type | Necessity |
|-----------|-----------|
| flavor has target flutter version | each flavor has exactly one target flutter version |

#### Flutter Fork Attributes

| Fact Type | Necessity |
|-----------|-----------|
| flutter fork has repository url | each flutter fork has exactly one repository url |
| flutter fork has default branch | each flutter fork has at most one default branch |

#### Flutter Release Attributes

| Fact Type | Necessity |
|-----------|-----------|
| flutter release has archive url | each flutter release has exactly one archive url |
| flutter release has sha256 hash | each flutter release has exactly one sha256 hash |

#### Version Constraint Attributes

| Fact Type | Necessity |
|-----------|-----------|
| version constraint has minimum version | each version constraint has at most one minimum version |
| version constraint has maximum version | each version constraint has at most one maximum version |

#### Environment Variable Attributes

| Fact Type | Necessity |
|-----------|-----------|
| environment variable has variable value | each environment variable has exactly one variable value |

---

### 2.2 Project-Version Relationships

**Fact Type: project uses flutter version**
- Preferred: project uses flutter version
- Alternative: flutter version is used by project
- Necessity: each project uses at most one flutter version
- Necessity: each flutter version is used by zero or more projects

---

**Fact Type: project config belongs to project**
- Preferred: project config belongs to project
- Alternative: project has project config
- Necessity: each project config belongs to exactly one project
- Necessity: each project has at most one project config

---

**Fact Type: project has project constraint**
- Preferred: project has project constraint
- Alternative: project constraint belongs to project
- Necessity: each project has at most one project constraint
- Necessity: each project constraint belongs to exactly one project

---

**Fact Type: project constraint uses version constraint**
- Preferred: project constraint uses version constraint
- Alternative: version constraint defines project constraint
- Necessity: each project constraint uses exactly one version constraint
- Necessity: each version constraint defines zero or more project constraints

---

### 2.3 Version-Channel Relationships

**Fact Type: flutter version belongs to channel**
- Preferred: flutter version belongs to channel
- Alternative: channel contains flutter version
- Necessity: each flutter version belongs to at least one channel
- Necessity: each channel contains zero or more flutter versions

---

**Fact Type: flutter release is published in channel**
- Preferred: flutter release is published in channel
- Alternative: channel publishes flutter release
- Necessity: each flutter release is published in at least one channel
- Necessity: each channel publishes zero or more flutter releases

---

### 2.4 Cache Relationships

**Fact Type: flutter version is installed in cache directory**
- Preferred: flutter version is installed in cache directory
- Alternative: cache directory contains installed flutter version
- Necessity: each flutter version is installed in at most one cache directory
- Necessity: each cache directory contains zero or more installed flutter versions
- Note: This fact type is objectified as version installation to capture installation metadata

---

**Fact Type: version installation involves flutter version**
- Preferred: version installation involves flutter version
- Alternative: flutter version is involved in version installation
- Necessity: each version installation involves exactly one flutter version
- Necessity: each flutter version is involved in at most one version installation
- Note: Derived from the objectified fact type

---

**Fact Type: version installation resides in cache directory**
- Preferred: version installation resides in cache directory
- Alternative: cache directory contains version installation
- Necessity: each version installation resides in exactly one cache directory
- Necessity: each cache directory contains zero or more version installations
- Note: Derived from the objectified fact type

---

**Fact Type: fvm link points to version installation**
- Preferred: fvm link points to version installation
- Alternative: version installation is referenced by fvm link
- Necessity: each fvm link points to at most one version installation
- Necessity: each version installation is referenced by zero or more fvm links

---

### 2.5 Configuration Relationships

**Fact Type: project config defines flavor**
- Preferred: project config defines flavor
- Alternative: flavor is defined by project config
- Necessity: each flavor is defined by exactly one project config
- Necessity: each project config defines zero or more flavors

---

**Fact Type: flavor specifies flutter version**
- Preferred: flavor specifies flutter version
- Alternative: flutter version is specified by flavor
- Necessity: each flavor specifies exactly one flutter version
- Necessity: each flutter version is specified by zero or more flavors

---

**Fact Type: user configures global config**
- Preferred: user configures global config
- Alternative: global config is configured by user
- Necessity: each global config is configured by exactly one user
- Necessity: each user configures at most one global config

---

### 2.6 Fork and Reference Relationships

**Fact Type: flutter fork provides flutter version**
- Preferred: flutter fork provides flutter version
- Alternative: flutter version is provided by flutter fork
- Necessity: each flutter version is provided by at most one flutter fork
- Necessity: each flutter fork provides zero or more flutter versions

---

**Fact Type: git reference identifies flutter version**
- Preferred: git reference identifies flutter version
- Alternative: flutter version is identified by git reference
- Necessity: each flutter version is identified by at most one git reference
- Necessity: each git reference identifies at most one flutter version

---

### 2.7 System Relationships

**Fact Type: version installation supports architecture**
- Preferred: version installation supports architecture
- Alternative: architecture is supported by version installation
- Necessity: each version installation supports at least one architecture
- Necessity: each architecture is supported by zero or more version installations

---

**Fact Type: version installation runs on operating system**
- Preferred: version installation runs on operating system
- Alternative: operating system runs version installation
- Necessity: each version installation runs on at least one operating system
- Necessity: each operating system runs zero or more version installations

---

**Fact Type: environment variable configures global config**
- Preferred: environment variable configures global config
- Alternative: global config is configured by environment variable
- Necessity: each environment variable configures at most one global config
- Necessity: each global config is configured by zero or more environment variables

---

## Part 3: Definitional Rules (Alethic Modality)

### 3.1 Identity and Uniqueness Rules

**D1:** It is necessary that each flutter version has exactly one version name

**D2:** It is necessary that each project has exactly one project path

**D3:** It is necessary that each version installation has exactly one cache path

**D4:** It is necessary that each flavor has exactly one flavor name

**D5:** It is necessary that each channel has exactly one channel name

**D6:** It is necessary that each flutter release has exactly one release hash

**D7:** It is necessary that each git commit has exactly one commit hash

**D8:** It is necessary that each user has exactly one user identifier

---

### 3.2 Structural Integrity Rules

**D9:** It is necessary that each project config of a project is stored in a file named .fvmrc in the root directory of that project

**D10:** It is necessary that each fvm link of a project is located at .fvm/flutter_sdk relative to the root directory of that project

**D11:** It is necessary that each version installation in a cache directory contains a bin/flutter executable

**D12:** It is necessary that each flutter version that is a semantic version follows the pattern major.minor.patch

**D13:** It is necessary that each git commit that is a git reference has a commit hash of exactly 40 hexadecimal characters

---

### 3.3 Type Constraints

**D14:** It is impossible that a flutter version has an empty version name

**D15:** It is impossible that two version installations in the same cache directory share the same cache path

**D16:** It is impossible that a project path contains null bytes

**D17:** It is impossible that a git reference is both a git branch and a git tag

---

### 3.4 Composition Rules

**D18:** It is necessary that each version installation is stored in a subdirectory named by the version name of that version installation

**D19:** It is necessary that each cache directory contains a subdirectory named 'versions'

**D20:** It is necessary that each flutter fork includes a valid repository url

**D21:** It is necessary that each version constraint specifies at least a minimum version or a maximum version

---

### 3.5 Referential Integrity Rules

**D22:** It is necessary that each flavor name within a project config is unique

**D23:** It is necessary that each project that has a fvm link has exactly one project config

**D24:** It is necessary that each fvm link that points to a version installation points to a version installation that exists in the cache directory

**D25:** It is impossible that a project uses a flutter version that does not exist as a version installation

---

### 3.6 Derivation Rules (Definitional Pattern)

**DR1:** total cache size = sum of (directory size of each version installation in cache directory)

**DR2:** cached version count = count of version installations in cache directory

**DR3:** active project count = count of projects that have an fvm link pointing to a version installation

**DR4:** flavor count of project = count of flavors defined by the project config of a project

---

## Part 4: Behavioral Rules (Deontic Modality)

### 4.1 Installation and Setup

**Obligations:**

**B1:** It is obligatory that the sha256 hash of a flutter release is verified after download

**B2:** It is obligatory that a fvm link is created for a project when a user selects a flutter version for that project

**B3:** It is obligatory that '.fvm/flutter_sdk' is added to the .gitignore file of a project when a fvm link is created

**B4:** It is obligatory that a flutter version is validated to meet the version constraint of a project before use is allowed

**B5:** It is obligatory that a flutter version is checked for existence as a version installation before downloading

---

### 4.2 Cache Management

**Obligations:**

**B6:** It is obligatory that read and write permissions are maintained for the user on the cache directory

**B7:** It is obligatory that all version installations are preserved when a project switches flutter version

**B8:** It is obligatory that the directory size of the cache directory is reported when requested by a user

**B9:** It is obligatory that the integrity of a version installation is validated before a fvm link is created to it

---

### 4.3 Configuration Management

**Obligations:**

**B10:** It is obligatory that the project config is read from the .fvmrc file of a project

**B11:** It is obligatory that a .fvmrc file is created when a user selects a flutter version for a project that has no project config

**B12:** It is obligatory that the settings in the global config are respected when no project config exists

**B13:** It is obligatory that the JSON structure of a project config is validated before processing

---

### 4.4 Version Selection

**Prohibitions:**

**B14:** It is prohibited that a flutter version is used for a project that does not meet the version constraint of that project

**B15:** It is prohibited that the flutter version of a project is switched while Flutter processes are running for that project

**B16:** It is prohibited that a flutter version is installed from an untrusted flutter fork without user confirmation

**B17:** It is prohibited that a version installation is deleted that is referenced by any fvm link

---

### 4.5 Update and Notification

**Obligations:**

**B18:** It is obligatory that updates to the flutter version of a project are checked when the update notification flag is enabled

**B19:** It is obligatory that the user is notified when the flutter version of a project does not match the version constraint

**B20:** It is obligatory that migration information is displayed when switching between flutter versions with breaking changes

---

### 4.6 File System Operations

**Prohibitions:**

**B21:** It is prohibited that files within a version installation directory are modified

**B22:** It is prohibited that circular symbolic links are created

**B23:** It is prohibited that an existing project config is overwritten without user confirmation

**B24:** It is prohibited that the cache directory is removed while any project has a fvm link

---

### 4.7 User Permissions

**Permissions:**

**B25:** It is permitted that a user overrides the version constraint of a project with a force flag

**B26:** It is permitted that a user skips setup steps with a skip-setup flag

**B27:** It is permitted that a user uses a flutter fork instead of official releases

**B28:** It is permitted that a user removes unused version installations from the cache directory

**B29:** It is permitted that a user defines multiple flavors in a project config

**B30:** It is permitted that a user uses a git reference to specify a flutter version

---

### 4.8 Advanced Operations

**Permissions:**

**B31:** It is permitted that a user installs pre-release flutter versions

**B32:** It is permitted that a user bypasses the cache directory with a no-cache flag

**B33:** It is permitted that a user executes flutter commands through FVM proxy

**B34:** It is permitted that a user exports the project config for team sharing

**B35:** It is permitted that a user sets environment variables to override global config settings

---

## Part 5: Complex Business Rules

### 5.1 Version Resolution Algorithm

**B36:** It is obligatory that the flutter version specified in a command argument is used
  if a user specifies a flutter version in a command argument for a project

**B37:** It is obligatory that the flutter version specified by the active flavor of a project is used
  if no flutter version is specified in a command argument
  and a flavor is active for that project

**B38:** It is obligatory that the flutter version specified in the project config of a project is used
  if no flutter version is specified in a command argument
  and no flavor is active for that project
  and a project config exists for that project

**B39:** It is obligatory that the flutter version specified in the global config is used
  if no flutter version is specified in a command argument
  and no flavor is active for the project
  and no project config exists for the project
  and a global config exists

**B40:** It is obligatory that the system Flutter installation is used
  if no FVM configuration exists for a project

---

**B41:** It is obligatory that the dart version of a flutter version is validated for compatibility with the dependencies of a project before that flutter version is used for that project

**B42:** It is obligatory that a flutter version is validated to satisfy the version constraint of a project before that flutter version is used for that project

**B43:** It is obligatory that a version installation is validated to support the architecture of the system before that version installation is used

**B44:** It is obligatory that a version installation is validated to run on the operating system of the system before that version installation is used

---

### 5.2 Cache Management Policy

**B45:** It is permitted that a version installation is removed from the cache directory
  if the user explicitly requests removal of that version installation

**B46:** It is permitted that a version installation is removed from the cache directory
  if that version installation is corrupted or incomplete

**B47:** It is permitted that a version installation is removed from the cache directory
  if the directory size of the cache directory exceeds a configured limit

**B48:** It is prohibited that a version installation is removed that is referenced by any fvm link

**B49:** It is prohibited that a version installation is removed that is marked as protected by the user

**B50:** It is prohibited that a version installation is removed that is the only version installation satisfying the version constraint of an active project

---

**B51:** It is permitted that multiple projects share the same version installation

**D26:** It is necessary that each project maintains its own fvm link

**B52:** It is prohibited that any project modifies a shared version installation

**B53:** It is obligatory that file locking is used when multiple projects access the same version installation concurrently

---

### 5.3 Fork and Custom Build Management

**B54:** It is permitted that a user uses a flutter fork for testing experimental features

**B55:** It is permitted that a user uses a flutter fork for enterprise-specific Flutter builds

**B56:** It is permitted that a user uses a flutter fork for contributing to Flutter development

**B57:** It is obligatory that a warning is displayed when a flutter fork is used

**B58:** It is obligatory that the fork url is recorded in the metadata of a version installation from a flutter fork

**B59:** It is prohibited that a flutter version from a flutter fork is auto-updated

---

### 5.4 Flavor Management Protocol

**B60:** It is obligatory that the flutter version specified by a flavor is switched to when a user activates that flavor

**B61:** It is obligatory that the fvm link is updated atomically when switching flutter version to prevent corruption

**B62:** It is prohibited that multiple flavors of the same project are active simultaneously

**B63:** It is permitted that different flavors of a project reference the same version installation

---

**B64:** It is permitted that a flavor inherits settings from the project config of its project

**D27:** It is necessary that flavor-specific settings override inherited settings from project config

**B65:** It is obligatory that each flavor is validated to specify a valid flutter version

**B66:** It is prohibited that a flavor references a flutter version incompatible with the project

---

## Part 6: State Management Rules

### 6.1 Version State Transitions

**ST1:** It is necessary that downloading of a flutter version precedes installation of that flutter version

**ST2:** It is necessary that installation of a flutter version precedes caching of that flutter version as a version installation

**ST3:** It is necessary that caching of a flutter version precedes linking of that version installation by a fvm link

**ST4:** It is necessary that unlinking of a version installation precedes deletion of that version installation

**ST5:** It is impossible that a flutter version skips the downloading state before installation

**ST6:** It is impossible that a version installation is deleted before it is unlinked from all fvm links

**B67:** It is obligatory that each state transition of a flutter version is logged

---

### 6.2 Project Configuration States

**ST7:** It is necessary that configuration of a project precedes any use of a flutter version by that project through FVM

**B68:** It is obligatory that a backup of a project config is created before that project config is updated

**B69:** It is prohibited that a project has multiple simultaneous configuration operations

---

## Part 7: Error Recovery Rules

### 7.1 Installation Failure Recovery

**B70:** It is obligatory that partial installations are rolled back when download fails

**B71:** It is obligatory that the previous fvm link is preserved when version switching fails

**B72:** It is obligatory that the cache directory integrity is validated after unexpected termination

**B73:** It is obligatory that actionable error messages with recovery steps are provided

---

### 7.2 Configuration Error Handling

**B74:** It is obligatory that the project config schema is validated before processing

**B75:** It is obligatory that disk space is checked before downloading a flutter version

**B76:** It is obligatory that network connectivity is verified before accessing remote resources

**B77:** It is prohibited that corrupted or incomplete downloads are processed

---

## Part 8: Integration Rules

### 8.1 IDE Integration Protocol

**B78:** It is obligatory that VS Code settings.json is updated when flutter version is switched for a project

**B79:** It is obligatory that user customizations in IDE configuration files are preserved

**B80:** It is permitted that IntelliJ IDEA Flutter SDK path is configured

**B81:** It is obligatory that IDEs are notified of flutter version changes through filesystem watchers

---

### 8.2 CI/CD Integration

**B82:** It is obligatory that non-interactive mode is provided for automation environments

**B83:** It is obligatory that standardized exit codes are returned for script integration

**B84:** It is permitted that configuration is read from environment variables in CI environments

**B85:** It is obligatory that headless operation without GUI dependencies is supported

---

### 8.3 Tool Chain Integration

**B86:** It is permitted that Melos is integrated for monorepo management

**B87:** It is permitted that dart and pub commands are proxied to the active flutter version

**B88:** It is obligatory that PATH environment compatibility is maintained

**B89:** It is obligatory that all flutter command functionality is preserved

---

## Appendix A: Formal Validation Patterns

### Version Format Specifications

| Pattern Name | Regular Expression |
|--------------|-------------------|
| Semantic Version | `^(\d+)\.(\d+)\.(\d+)(?:-([a-zA-Z0-9\-\.]+))?$` |
| Channel Name | `^(stable\|beta\|dev\|master\|main)$` |
| Git Commit | `^[a-f0-9]{40}$` |
| Fork Reference | `^[a-zA-Z0-9\-]+\/[a-zA-Z0-9\-]+$` |

---

### Path Validation Requirements

**D28:** It is necessary that each project path is an absolute path or relative to current directory

**D29:** It is necessary that each cache path is an absolute filesystem path

**D30:** It is necessary that each link path resolves to a valid target

**D31:** It is prohibited that any path contains null bytes or filesystem-invalid characters

---

## Appendix B: Cardinality Reference

| Relationship | Subject Cardinality | Object Cardinality |
|--------------|--------------------|--------------------|
| project uses flutter version | 0..1 | 0..* |
| project config belongs to project | 1..1 | 0..1 |
| project has project constraint | 0..1 | 1..1 |
| project constraint uses version constraint | 1..1 | 0..* |
| flutter version belongs to channel | 1..* | 0..* |
| flutter version is installed in cache directory | 0..1 | 0..* |
| version installation involves flutter version | 1..1 | 0..1 |
| version installation resides in cache directory | 1..1 | 0..* |
| fvm link points to version installation | 0..1 | 0..* |
| flavor specifies flutter version | 1..1 | 0..* |
| project config defines flavor | 1..1 | 0..* |

---

## Document Metadata

- **Version**: 2.4.0
- **SBVR Standard**: 1.5
- **Based on**: FVM 4.0.0-beta.2
- **Status**: Final
- **Last Updated**: 2025-12-24
- **Aligned with**: SBVR Complete Implementation Guide

---

*This SBVR specification has been validated for compliance with SBVR 1.5 standard, ensuring proper vocabulary definitions (genus + differentia), complete fact types with preferred and alternative verb concept wordings, correct rule categorization (alethic vs deontic), derivation rules for computed values, proper objectification of complex relationships, and complete navigation paths in all rules.*
