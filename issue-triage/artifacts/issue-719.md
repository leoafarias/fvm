# Issue #719: Add documentation to optionally allow users to forward all `flutter`, `dart` calls to fvm

## Metadata
- **Reporter**: Anvith Bhat (@humblerookie)
- **Created**: 2024-04-30
- **Reported Version**: Not specified (docs prior to v4 rework)
- **Issue Type**: enhancement
- **URL**: https://github.com/leoafarias/fvm/issues/719

## Problem Summary
The requester asked for official guidance showing how to reroute direct `flutter`/`dart` invocations so they proxy through `fvm flutter` and `fvm dart`, helping scripts that expect the bare commands.

## Version Context
- Reported against: Pre-v4 docs (unspecified)
- Current version: v4.0.0
- Version-specific: no
- Reason: The request targets documentation behavior and is now covered in the consolidated v4 guides.

## Validation Steps
1. Loaded the live “Running Flutter” guide at `https://fvm.app/documentation/guides/running-flutter` and confirmed it returns HTTP 200.
2. Reviewed `docs/pages/documentation/guides/running-flutter.mdx` and found an info callout (lines 62-99) documenting the exact reroute commands for macOS and Linux, plus removal instructions and collision warnings.
3. Checked `docs/pages/documentation/guides/_meta.json` to verify the “Running Flutter” guide is part of the published navigation, ensuring discoverability from the docs sidebar.

## Evidence
```
$ curl -s -I https://fvm.app/documentation/guides/running-flutter | head -n 1
HTTP/2 200

$ sed -n '62,99p' docs/pages/documentation/guides/running-flutter.mdx
<Callout type="info">
If you wish to reroute `flutter` and `dart` calls to FVM, i.e., ensure that running `flutter` on the terminal internally runs `fvm flutter`, then you could run the below commands.
**On Mac**
sudo echo 'fvm flutter ${@:1}' > "/usr/local/bin/flutter" && sudo chmod +x /usr/local/bin/flutter
sudo echo 'fvm dart ${@:1}' > "/usr/local/bin/dart" && sudo chmod +x /usr/local/bin/dart
**On Linux**
echo 'fvm flutter ${@:1}' > "$HOME/.local/bin/flutter" && chmod +x "$HOME/.local/bin/flutter"
echo 'fvm dart ${@:1}' > "$HOME/.local/bin/dart" && chmod +x "$HOME/.local/bin/dart"
...

$ cat docs/pages/documentation/guides/_meta.json | rg "running-flutter"
  "running-flutter": {
    "title": "Running Flutter"
  },
```

**Files/Code References:**
- [docs/pages/documentation/guides/running-flutter.mdx#L62](../docs/pages/documentation/guides/running-flutter.mdx#L62) – Contains the reroute callout with command examples.
- [docs/pages/documentation/guides/_meta.json#L7](../docs/pages/documentation/guides/_meta.json#L7) – Confirms the guide is surfaced in navigation.

## Current Status in v4.0.0
- [ ] Still reproducible
- [x] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information
- [ ] Cannot reproduce

## Troubleshooting/Implementation Plan

### Root Cause Analysis
The original documentation set lacked explicit guidance for users wanting bare `flutter`/`dart` wrappers. The v4.0.0 docs revamp added an info callout in the “Running Flutter” guide reproducing the requested steps, addressing the gap without changing CLI behavior.

### Proposed Solution
1. Reply on issue #719 linking to the updated “Running Flutter” guide section (`/documentation/guides/running-flutter#reroute-flutter-and-dart`) and note that macOS/Linux instructions now match the request.
2. Confirm with the docs team that the section will remain in the public site (part of ongoing docs QA checklists).
3. Optionally capture a follow-up task to add Windows-specific instructions if contributors can validate the commands, since the guide still calls for community input there.
4. Close the GitHub issue as resolved once the response is posted.

### Alternative Approaches (if applicable)
- Keep the instructions in a FAQ entry instead of the “Running Flutter” guide, but the current placement alongside proxy command docs is clearer.
- Rely solely on shell aliases; rejected because scripts need executable wrappers, which was the original motivation.

### Dependencies & Risks
- Minimal; documentation-only change already deployed.
- Risk of divergence if future docs restructuring moves the guide—ensure nav metadata keeps the page prominent.
- Adding Windows instructions would require validation to avoid publishing untested guidance.

### Related Code Locations
- [docs/pages/documentation/guides/running-flutter.mdx#L54](../docs/pages/documentation/guides/running-flutter.mdx#L54) – Section introducing proxy commands leading into the reroute guidance.

## Recommendation
**Action**: resolved

**Reason**: The requested documentation now exists in the published v4.0.0 “Running Flutter” guide, including the exact command snippets and caveats the reporter described.

## Notes
- When replying, invite the reporter to contribute a Windows snippet if they or the community can test it.

---
**Validated by**: Code Agent
**Date**: 2025-10-31
