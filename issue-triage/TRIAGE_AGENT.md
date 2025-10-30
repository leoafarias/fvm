# FVM Issue Triage Agent Instructions

## Mission
Systematically validate and classify GitHub issues to determine their validity, priority, and relevance to FVM v4.0.0.

**IMPORTANT**: Triage is about **research and planning**, NOT fixing. Your goal is to:
1. Validate if the issue is legitimate
2. Create a detailed troubleshooting/fixing plan
3. Save the plan for later execution
4. Classify and prioritize the issue

DO NOT attempt to fix issues during triage. Focus on evidence-based analysis and planning.

## Context
- FVM is currently at v4.0.0 (released 2025-10-30)
- Many issues were reported against v3.x
- Documentation has been restructured for v4.0.0
- Some issues may already be resolved in v4.0.0

## Directory Structure
```
issue-triage/
├── pending_issues/          # Raw issues awaiting validation
├── validated/               # Confirmed valid for v4.0.0
│   ├── p0-critical/        # Broken docs, critical bugs
│   ├── p1-high/            # Setup blockers, high-impact
│   ├── p2-medium/          # Standard bugs, enhancements
│   └── p3-low/             # Edge cases, minor issues
├── resolved/                # Already fixed in v4.0.0
├── version_specific/        # Only affects v3.x
├── needs_info/              # Requires user clarification
└── artifacts/               # Validation logs, screenshots, notes
```

## Validation Workflow

For EACH issue, follow this 6-step process:

### Step 1: Extract & Understand
1. Read the issue from `pending_issues/`
2. Identify:
   - Issue number and title
   - Reported FVM version (3.x vs 4.x)
   - Issue type (bug, feature request, documentation)
   - Core problem description
   - Steps to reproduce (if provided)

### Step 2: Research Context
1. Check if issue mentions specific version constraints
2. Search codebase for related code using Grep/Glob
3. Check current documentation state
4. Look for related resolved issues or PRs
5. Verify if functionality still exists in v4.0.0

### Step 3: Validate Locally
Based on issue type:

**For Documentation Issues:**
- Verify links are broken/working
- Check if pages exist at new locations
- Test installation instructions
- Validate examples in docs

**For Bug Reports:**
- Check if code path still exists in v4.0.0
- Try to reproduce with current version
- Test on relevant platform (if possible)
- Verify error messages match current behavior

**For Feature Requests:**
- Check if feature already exists in v4.0.0
- Assess alignment with FVM principles
- Document current workarounds if any

### Step 4: Document Findings & Create Plan
Create a validation report in `artifacts/issue-{number}.md` using this template:

```markdown
# Issue #{number}: {title}

## Metadata
- **Reporter**: {author}
- **Created**: {date}
- **Reported Version**: {version}
- **Issue Type**: [bug|feature|documentation]
- **URL**: {github_url}

## Problem Summary
{concise description}

## Version Context
- Reported against: v{X.X.X}
- Current version: v4.0.0
- Version-specific: [yes|no]

## Validation Steps
1. {what you checked}
2. {what you tested}
3. {what you found}

## Evidence
```
{command outputs, file paths, line numbers}
```

## Current Status in v4.0.0
- [ ] Still reproducible
- [ ] Already fixed
- [ ] Not applicable to v4.0.0
- [ ] Needs more information

## Troubleshooting/Implementation Plan
**IMPORTANT**: This section should contain a detailed, evidence-based plan for resolving the issue. DO NOT implement the fix during triage - only create the plan.

### Root Cause Analysis
{Based on codebase research, what's causing this issue?}

### Proposed Solution
{Step-by-step plan for fixing or validating the issue:}
1. {Specific file to modify: [path/to/file.dart:123](path/to/file.dart#L123)}
2. {What changes are needed and why}
3. {Tests to run or create}
4. {Verification steps}

### Alternative Approaches (if applicable)
- {Other possible solutions and trade-offs}

### Dependencies & Risks
- {Files/features that might be impacted}
- {Potential breaking changes}
- {Testing requirements}

### Related Code Locations
- [file.dart:42](path/to/file.dart#L42) - {why this is relevant}
- [another.dart:15](path/to/another.dart#L15) - {why this is relevant}

## Recommendation
**Action**: [validate-p0|validate-p1|validate-p2|validate-p3|resolved|version-specific|needs-info]
**Reason**: {brief justification}

## Notes
{any additional context, related issues, etc.}
```

### Step 5: Classify & Move
Based on findings, move the validation report to appropriate folder:

**Priority Classification:**
- **P0-Critical**: Broken documentation, dead links, critical setup blockers
- **P1-High**: Installation failures, setup issues, major functionality broken
- **P2-Medium**: Standard bugs, platform-specific issues, useful enhancements
- **P3-Low**: Edge cases, minor issues, nice-to-have features

**Special Categories:**
- **Resolved**: Issue fixed in v4.0.0 (provide evidence)
- **Version-specific**: Only affects v3.x, not applicable to v4.0.0
- **Needs-info**: Cannot validate without user response

### Step 6: Create Summary
After validating, add entry to `artifacts/triage-log.md`:
```markdown
- [x] #{number} - {title} → {destination} ({reason})
```

## Prioritization Guidelines

### Process in this order:
1. **Documentation bugs** (P0) - Quick wins, high user impact
2. **Installation/setup issues** (P1) - Blocks all users
3. **Runtime bugs** (P2) - Affects active users
4. **Feature requests** (P3) - Future enhancements

### Red Flags for P0:
- 404 errors in documentation
- Broken installation instructions
- Dead links from official docs
- Critical command failures

### Red Flags for P1:
- `fvm install` failures
- `fvm use` not working
- Path/environment setup broken
- IDE integration failures

## Investigation Tools

### Search Commands:
```bash
# Find related code
grep -r "keyword" lib/ test/

# Find files
glob "**/*keyword*.dart"

# Check git history
git log --grep="keyword" --oneline

# Find related issues/PRs
gh issue list --search "keyword"
gh pr list --search "keyword"
```

### Testing Commands:
```bash
# Run FVM commands
fvm doctor --verbose
fvm list
fvm install --help

# Check documentation
ls docs/
cat README.md

# Validate links (if using web docs)
curl -I https://fvm.app/documentation/...
```

## Documentation Structure (v4.0.0)
- Main site: https://fvm.app/
- Docs base: https://fvm.app/documentation/
- Getting started: https://fvm.app/documentation/getting-started/
- Check actual structure in `/docs` folder

## Important Notes

1. **Triage ≠ Fixing**: Your job is to research, validate, and plan - NOT to implement fixes
2. **Plan Must Be Actionable**: Base your implementation plan on actual codebase evidence (file paths, line numbers)
3. **Version Context Matters**: An issue reported for v3.2.1 may not exist in v4.0.0
4. **Verify, Don't Assume**: Test claims before accepting them using current codebase
5. **Document Evidence**: Include file paths, line numbers, command outputs in your research
6. **Be Thorough**: One issue at a time, complete validation AND planning before moving on
7. **Ask for Help**: If unsure, mark as `needs_info` and document what's unclear

## Output Expectations

At the end of triage session:
- Each issue has a validation report with **implementation plan** in `artifacts/`
- Issues are sorted into appropriate folders based on priority
- `artifacts/triage-log.md` shows progress
- Implementation plans are ready for execution in future sessions
- Clear recommendations for next steps

## Starting a Triage Session

1. Check `pending_issues/` for issues to process
2. Start with ONE issue at a time
3. Follow the 6-step workflow above
4. Create validation report WITH implementation plan
5. Document everything in artifacts
6. Move to next issue

**Remember**: Research → Validate → Plan → Save. DO NOT implement fixes during triage.

## Example Workflow

```bash
# 1. Pick an issue
cat pending_issues/issue-944.json

# 2. Research codebase (use Grep/Glob/Read tools)
grep -r "documentation" docs/
glob "**/*install*.dart"
# Identify relevant files with line numbers

# 3. Validate findings
# Test commands, check links, verify claims

# 4. Create implementation plan
# Based on codebase research, outline:
# - Root cause (with file references)
# - Step-by-step fix plan
# - Testing approach
# - Related code locations

# 5. Create validation artifact
# Write to artifacts/issue-944.md with full plan

# 6. Classify and move
# Move to validated/p0-critical/ (or appropriate folder)

# 7. Log it
# Add entry to artifacts/triage-log.md
```

## Key Success Criteria

✅ **Good Triage Report**:
- Has evidence from current codebase (file paths with line numbers)
- Contains actionable implementation plan
- Clearly states if issue is valid for v4.0.0
- No fixes attempted - only research and planning

❌ **Bad Triage Report**:
- Generic recommendations without code references
- Missing implementation plan
- Attempts to fix during triage
- No evidence from actual codebase validation

---

**Remember**: Quality over speed. One well-validated issue is better than ten hasty assessments.
