# Open-Issue Validity and Closure Audit — 2026-08-11

## Outcome

The full 57-issue queue was rechecked against live GitHub, `origin/main` at `2871c7d8ef924210689a10115695d137c9c776cb`, FVM 4.1.2, current documentation, and the issue threads. Nine issues were closed with issue-specific explanations. The live queue now contains 48 issues.

## Closed

| Issue | GitHub outcome | Evidence-based disposition |
|---|---|---|
| #575 | Completed | `fvm flavor <name> <flutter command>` already implements temporary flavor-specific execution. |
| #697 | Completed; `working as intended` | `fvm global` maintains the global default link; Android Studio requires a one-time SDK-path selection. Project-specific IDE gaps remain tracked separately. |
| #720 | Not planned; `duplicate` | No-argument `fvm install` implements the `.fvmrc` workflow; the remaining pubspec fallback is tracked in #577. |
| #748 | Completed; `working as intended` | The Windows question had already received PATH guidance; the closure reply provides current setup and diagnosis commands and invites a textual current report. |
| #754 | Not planned; `working as intended` | Homebrew owns the Xcode requirement; FVM provides a prebuilt installer and release archives that bypass local compilation. |
| #774 | Completed; `documentation` | The current global setup guide documents adding the FVM default SDK `bin` directory to PATH, which is required by global Dart packages such as `rps`. |
| #791 | Completed | Fork aliases and `alias/version` cache namespacing implement the requested feature. |
| #794 | Completed | FVM 4.1.2 publishes Linux ARM/ARM64 archives, including musl builds, and the installer maps Raspberry Pi ARM architectures. |
| #1055 | Completed; `question`, `documentation` | The issue was answered with installed/latest-version checks, update commands for each installation method, and PATH diagnostics. |

## Still open and valid

- **P1:** #688 remains the only high-priority issue. Archive/mirror installation support is not in the release; PR #1013 still requires repair and review.
- **P2/P3:** 40 additional issues remain valid bugs, enhancements, documentation work, or packaging requests. Age alone was not used as a reason to reject them.
- **Open pull requests:** all six remain open. Their associated issues were not closed unless the requested behavior already existed independently.
- Examples of confirmed current work include VS Code JSONC preservation (#635), Android Studio/project-reference gaps (#724 and #767), fatal SDK setup failures (#968), fish SIGINT cleanup (#1046), and disabled-VS Code warning behavior (#1048).

## Needs information

Seven issues remain open because the current evidence is insufficient for either implementation or a defensible invalid/wont-fix decision:

| Issue | Why it remains open |
|---|---|
| #731 | Screenshot-era git-cache failure lacks a current 4.1.2 reproduction after cache repair changes. |
| #759 | VS Code/global mismatch lacks workspace settings, doctor output, and an exact failure. |
| #781 | Chocolatey missing-executable report lacks a current package version and verbose install transcript. |
| #797 | `bash\r` indicates CRLF conversion, but the source of the line-ending mutation is unknown. |
| #809 | Report appears Sidekick-specific and lacks a standalone FVM CLI reproduction. |
| #906 | Android Studio terminal-delay report lacks timing, logs, and a comparison outside the IDE. |
| #1017 | Current diagnostics show a global PATH/IDE mismatch, but the requested fresh-terminal checks have not been supplied. |

These should receive targeted information requests or be closed later under an explicit stale-report policy. They were not closed speculatively in this audit.

## Updated queue

- Open issues: **48**
- P0 critical: **0**
- P1 high: **1**
- P2 medium: **28**
- P3 low: **12**
- Needs info: **7**
- Resolved/archived: **62**
- Open pull requests: **6**

## Verification

- Confirmed all nine target issues are `CLOSED` on GitHub with the intended state reason.
- Re-ran `issue-triage/scripts/sync_github.sh`; the live snapshot decreased from 57 to 48 issues.
- Archived each closed issue summary under `issue-triage/closed/` and removed it from its active classification folder.
- Recounted active classification JSON files and compared them with the refreshed live issue set.
