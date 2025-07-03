---
id: overview
title: Overview
---

# Overview

FVM helps with the need for consistent app builds by referencing the Flutter SDK version used on a per-project basis. It also allows you to have multiple Flutter versions installed to quickly validate and test upcoming Flutter releases with your apps without waiting for Flutter installation every time.

## Quick Start

```bash
# Install FVM
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

1. [Install FVM](./installation) on your system
2. [Configure](./configuration) your first project
3. Check the [FAQ](./faq) for common questions
