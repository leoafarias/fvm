---
id: overview
title: Overview
---

# Overview

FVM ensures consistent app builds by managing Flutter SDK versions per project. Install multiple Flutter versions and switch between them instantly to test new releases without reinstalling Flutter.

## Quick Start

```bash
# Install FVM
brew tap leoafarias/fvm
brew install fvm

# Set Flutter version for a project
cd my_project
fvm use 3.19.0

# Run Flutter commands
fvm flutter doctor
```

## Key Features

- **Per-project Flutter versions** - Each project can use a different Flutter SDK
- **Fast switching** - Change versions instantly without re-downloading
- **Team consistency** - Everyone uses the same Flutter version via `.fvmrc`
- **CI/CD friendly** - Simple commands for automation
- **Fork support** - Use custom Flutter repositories

## Next Steps

1. [Install FVM](./getting-started/installation) on your system
2. [Configure](./getting-started/configuration) your first project
3. Check the [FAQ](./getting-started/faq) for common questions
