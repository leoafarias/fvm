# FVM Issue Triage System

## Overview
This directory contains a structured system for triaging and validating GitHub issues for FVM v4.0.0.

## Quick Start

### For AI Agents
Read [TRIAGE_AGENT.md](TRIAGE_AGENT.md) for complete instructions on the validation workflow.

### For Humans
1. Review [artifacts/triage-log.md](artifacts/triage-log.md) for current progress
2. Check specific priority folders for validated issues
3. Refer to [artifacts/issue-{number}.md](artifacts/) for detailed validation reports

## Directory Structure

```
issue-triage/
├── README.md                    # This file
├── TRIAGE_AGENT.md             # AI agent system instructions
├── pending_issues/              # Raw issues awaiting validation
│   └── open_issues.json        # 18 open issues from GitHub
├── validated/                   # Confirmed valid for v4.0.0
│   ├── p0-critical/            # Broken docs, critical bugs (PRIORITY 1)
│   ├── p1-high/                # Setup blockers, high-impact (PRIORITY 2)
│   ├── p2-medium/              # Standard bugs, enhancements (PRIORITY 3)
│   └── p3-low/                 # Edge cases, minor issues (PRIORITY 4)
├── resolved/                    # Already fixed in v4.0.0
├── version_specific/            # Only affects v3.x
├── needs_info/                  # Requires user clarification
└── artifacts/                   # Validation logs, screenshots, notes
    ├── triage-log.md           # Progress tracker
    ├── validation-template.md   # Template for validation reports
    └── issue-{number}.md       # Individual validation reports
```

## Process Overview

Each issue goes through:
1. **Extract & Understand** - Read and identify key details
2. **Research Context** - Search codebase and documentation
3. **Validate Locally** - Test claims and reproduce issues
4. **Document Findings** - Create detailed validation report
5. **Classify & Move** - Assign priority and move to appropriate folder
6. **Update Log** - Track progress in triage-log.md

## Priority Guidelines

### P0 - Critical (Handle First)
- Broken documentation links (404s)
- Critical installation blockers
- Dead links from official docs

### P1 - High (Handle Second)
- Installation/setup failures
- Major functionality broken
- IDE integration issues

### P2 - Medium (Handle Third)
- Standard bugs
- Platform-specific issues
- Useful enhancements

### P3 - Low (Handle Last)
- Edge cases
- Minor issues
- Nice-to-have features

## Current Status

- **Total Issues**: 18
- **Triaged**: 0
- **Pending**: 18

See [artifacts/triage-log.md](artifacts/triage-log.md) for detailed progress.

## Issue List (from v3.x era)

Issues reported span from 2025-06 to 2025-10, mostly against v3.x:
- #944 - Documentation 404 errors
- #940 - Homebrew installation dependency issue
- #938 - Symbolic link resolution on Linux
- #935 - RISC-V architecture support
- #933 - Package manager naming
- #915 - Documentation broken links
- #914 - Git path issues on Windows
- #906 - Android Studio terminal performance
- #904 - Kotlin deprecation warning
- #897 - Nix/homemanager compatibility
- #895 - v4.0.0 release timeline
- #894 - Multi-user cache sharing
- #893 - VSCode terminal Flutter version
- #884 - gitignore flag feature request
- #881 - SSH URL support in fork command
- #880 - Force flag for spawn command
- #841 - Global Flutter setup failure
- (1 more truncated)

## Next Steps

1. Start with P0 documentation issues (quick wins)
2. Validate installation/setup issues (P1)
3. Work through bugs and enhancements (P2-P3)
4. Provide recommendations for each issue

## For Code Agent

To start triaging:
```bash
# Read the system instructions
cat issue-triage/TRIAGE_AGENT.md

# Check pending issues
cat issue-triage/pending_issues/open_issues.json

# Follow the 6-step workflow for each issue
# Document everything in artifacts/
# Update the triage log as you progress
```

---

**Created**: 2025-10-30
**FVM Version**: v4.0.0
**Branch**: issue-triage
