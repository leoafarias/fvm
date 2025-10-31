# Android Studio Integration Research Plan

**Created**: 2025-10-31
**Issue Context**: #697 - Android Studio can't find Flutter SDK
**Goal**: Investigate if FVM can automatically configure Android Studio settings

---

## Research Objectives

1. **Understand Android Studio Configuration**
   - Where does Android Studio store Flutter SDK path settings?
   - What file format? (XML, JSON, properties?)
   - Is it per-project or global?
   - Can it be safely automated?

2. **Learn from Melos**
   - How does Melos integrate with IDEs?
   - Does it modify any IDE settings files?
   - What patterns/best practices does it use?

3. **Analyze Current FVM Behavior**
   - What does FVM already do for VS Code?
   - Can similar patterns apply to Android Studio/IntelliJ?
   - What are the risks of automatic IDE configuration?

4. **Identify Technical Requirements**
   - What permission/safety checks are needed?
   - How to handle multiple IDEs installed?
   - How to detect Android Studio installation?

---

## Investigation Tasks

### Task 1: Map Android Studio Configuration Files

**Locations to check:**

**macOS:**
```
~/Library/Application Support/Google/AndroidStudio*/options/
~/Library/Preferences/AndroidStudio*/options/
~/.AndroidStudio*/config/options/
```

**Linux:**
```
~/.config/Google/AndroidStudio*/options/
~/.AndroidStudio*/config/options/
```

**Windows:**
```
%APPDATA%\Google\AndroidStudio*\options\
%USERPROFILE%\.AndroidStudio*\config\options\
```

**Files to investigate:**
- `flutter.settings.xml` - Flutter SDK path
- `jdk.table.xml` - SDK table definitions
- `project.default.xml` - Default project settings
- Any other relevant configuration files

**Search commands:**
```bash
# Find Flutter-related settings
find ~ -name "*flutter*" -path "*AndroidStudio*" 2>/dev/null

# Find SDK settings
find ~ -name "jdk.table.xml" -path "*AndroidStudio*" 2>/dev/null
find ~ -name "flutter.settings.xml" -path "*AndroidStudio*" 2>/dev/null

# Check what exists
ls -la ~/Library/Application\ Support/Google/AndroidStudio*/options/ 2>/dev/null
ls -la ~/.AndroidStudio*/config/options/ 2>/dev/null
```

**Questions to answer:**
- What's the exact XML/config structure?
- Is the path absolute or can it use variables?
- Does it store per-version or globally?
- Are there version-specific differences?

---

### Task 2: Analyze Melos IDE Integration

**Melos codebase investigation:**

```bash
# Clone or check existing Melos repo
cd /tmp
git clone https://github.com/invertase/melos.git
cd melos

# Search for IDE-related code
rg -i "intellij|android.?studio|ide|vscode" --type dart
rg -i "\.idea/|\.vscode/" --type dart
rg -i "settings\.xml|workspace\.xml" --type dart

# Check for IDE configuration workflows
find . -name "*ide*" -o -name "*vscode*" -o -name "*intellij*"
```

**Specific files to review:**
- Any IDE integration code
- Configuration update logic
- How they handle SDK paths
- Permission handling patterns

**Documentation to check:**
- https://melos.invertase.dev
- Look for IDE setup guides
- Check if they auto-configure anything

**Questions to answer:**
- Does Melos modify IDE configs automatically?
- If yes, what's their approach?
- If no, why not? (safety, complexity, support burden?)
- What lessons can FVM learn?

---

### Task 3: Review FVM's Current VS Code Integration

**Files to analyze:**
```
lib/src/workflows/update_vscode_settings.workflow.dart
lib/src/models/project_model.dart (vscodeSettingsFile)
```

**Questions to answer:**
- How does FVM update VS Code settings?
- What safety checks does it perform?
- Is it opt-in or automatic?
- How does it handle errors?
- Can this pattern extend to Android Studio?

**Key code sections to understand:**
```dart
// Check UpdateVsCodeSettingsWorkflow implementation
// Look for:
// - File existence checks
// - Permission handling
// - User consent/opt-in patterns
// - Error recovery
```

---

### Task 4: Investigate Android Studio Detection

**How to detect Android Studio installation:**

**macOS:**
```bash
# Application installations
ls /Applications/ | grep -i "android"
mdfind "kMDItemCFBundleIdentifier == 'com.google.android.studio'"

# Version detection
/Applications/Android\ Studio.app/Contents/MacOS/studio --version 2>/dev/null
```

**Linux:**
```bash
# Common locations
ls /opt/ | grep -i android
ls /usr/local/ | grep -i android
which studio.sh

# Snap/Flatpak
snap list | grep android-studio
flatpak list | grep android
```

**Windows:**
```cmd
# Program Files
dir "C:\Program Files\Android\Android Studio"
dir "%LOCALAPPDATA%\Google\AndroidStudio*"

# Registry
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Android Studio"
```

**Questions to answer:**
- Can we reliably detect Android Studio?
- How to determine the version?
- Can we detect IntelliJ IDEA separately?
- Should we support both?

---

### Task 5: Analyze Issue #697 Context

**Review the full issue thread:**
```bash
gh issue view 697 --repo leoafarias/fvm --json body,comments --jq '.comments[].body'
```

**Questions to extract:**
- What exactly failed for the user?
- What steps did they try?
- Did they get it working eventually?
- Are there common patterns in similar issues?

**Search for related issues:**
```bash
# Find similar Android Studio issues
gh issue list --repo leoafarias/fvm --search "Android Studio" --state all --limit 50
gh issue list --repo leoafarias/fvm --search "IntelliJ" --state all --limit 50
gh issue list --repo leoafarias/fvm --search "IDE SDK" --state all --limit 50
```

**Questions to answer:**
- How common is this problem?
- Do users eventually figure it out?
- What documentation improvements would help?
- Is automation worth the complexity?

---

### Task 6: Research Android Studio Documentation

**Official documentation to review:**
- Android Studio SDK configuration docs
- Flutter plugin for Android Studio docs
- IntelliJ IDEA Flutter plugin docs

**Questions to answer:**
- Does Google provide APIs for SDK configuration?
- Are there CLI tools for Android Studio?
- What's the "official" way to set Flutter SDK?
- Are there stability/compatibility concerns?

---

## Risk Assessment Matrix

For each potential solution, evaluate:

| Risk Factor | Low | Medium | High |
|-------------|-----|--------|------|
| File corruption | | | |
| Version compatibility | | | |
| Permission issues | | | |
| Cross-platform support | | | |
| Maintenance burden | | | |
| User confusion | | | |

---

## Decision Framework

After research, answer these questions:

### Should FVM Auto-Configure Android Studio?

**YES if:**
- ✅ Configuration files are stable and well-documented
- ✅ We can detect Android Studio reliably
- ✅ The approach is safe (minimal corruption risk)
- ✅ It provides significant user value
- ✅ Other tools (like Melos) do this successfully
- ✅ It can be opt-in with clear user consent

**NO if:**
- ❌ Configuration format is unstable/undocumented
- ❌ High risk of breaking user setups
- ❌ Maintenance burden is too high
- ❌ Can't reliably detect installations
- ❌ User needs to configure once anyway (marginal benefit)

### Alternative Approaches to Consider

1. **Enhanced Documentation**
   - Better screenshots and guides
   - Video walkthrough
   - Common troubleshooting steps

2. **Doctor Command Enhancement**
   - `fvm doctor` detects Android Studio
   - Shows exact configuration steps needed
   - Validates if setup is correct

3. **Interactive Setup Wizard**
   - Optional `fvm setup android-studio`
   - Guides user through configuration
   - Validates each step

4. **Configuration Helper**
   - Generate XML snippet for manual paste
   - Show exact file location to edit
   - Validate syntax before user applies

---

## Expected Deliverables

1. **Technical Report**
   - Android Studio configuration format documented
   - Melos approach analyzed and summarized
   - FVM current patterns evaluated

2. **Feasibility Assessment**
   - Risk analysis completed
   - Recommendation: automate, enhance docs, or hybrid

3. **Implementation Plan (if proceeding)**
   - Files to create/modify
   - Safety checks required
   - Testing strategy
   - Rollout plan (feature flag, opt-in, etc.)

4. **Documentation Plan**
   - What to document regardless of automation
   - User guidance improvements
   - Common pitfall prevention

---

## Notes

- Focus on understanding **existing solutions** before proposing new approaches
- Prioritize **user safety** over convenience
- Consider **long-term maintenance** costs
- Look for **proven patterns** from similar tools
- Remember: **good documentation** might be better than fragile automation

---

## Agent Execution Instructions

When running this research plan:

1. Use `Grep`, `Read`, `Bash` tools to investigate codebase and files
2. Use `WebFetch` for documentation research
3. Use `gh` commands to analyze issue patterns
4. Document findings in a new artifact: `android-studio-research-findings.md`
5. Include specific file paths, code snippets, and evidence
6. Make a clear recommendation at the end
7. If automation seems viable, outline implementation approach
8. If not viable, suggest documentation/UX improvements instead
