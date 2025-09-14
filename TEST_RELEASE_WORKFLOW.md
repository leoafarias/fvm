# Testing the New GitHub Release-Driven Workflow

## Pre-Test Validation

Before testing the new `release.yml` workflow, verify these components:

### ✅ Files Created/Modified
- [ ] `.github/workflows/release.yml` - New main workflow
- [ ] `.github/workflows/release-legacy.yml` - Renamed from release.yml
- [ ] `.github/workflows/README.md` - Workflow documentation
- [ ] `CHANGELOG.md` - Updated with GitHub release links
- [ ] `README.md` - Added release process section
- [ ] `TEST_RELEASE_WORKFLOW.md` - This testing guide

### ✅ Environment Requirements
- [ ] All secrets configured:
  - `PUB_CREDENTIALS`
  - `GITHUB_TOKEN` 
  - `CHOCOLATEY_TOKEN`
  - `HOMEBREW_FVM_GH_TOKEN`
  - `DOCKERHUB_USERNAME`
  - `DOCKERHUB_TOKEN`

## Testing Strategy

### Phase 1: Syntax Validation
```bash
# Validate GitHub Actions workflow syntax
cd .github/workflows
curl -s https://api.github.com/repos/SchemaStore/schemastore/contents/src/schemas/json/github-workflow.json | jq -r .download_url | xargs curl -s > /tmp/workflow-schema.json

# Use online validators or GitHub's built-in validation
```

### Phase 2: Manual Dispatch Test
1. **Trigger manual workflow** (no need to manually update pubspec.yaml):
   - Go to Actions → "Deploy from GitHub Release"  
   - Click "Run workflow"
   - Enter: `v4.0.0-beta.2-test`
   - Monitor execution

2. **Expected Results**:
   - [ ] **Test job**: All tests pass
   - [ ] **Validate job**: 
     - [ ] Version extracted correctly: `4.0.0-beta.2-test`
     - [ ] pubspec.yaml updated dynamically  
     - [ ] version.dart generated with correct version
     - [ ] `dart pub publish --dry-run` passes ✅ **KEY VALIDATION**
   - [ ] **Deploy jobs**: All jobs complete successfully (only if validation passes)

3. **Validation Benefits**:
   - [ ] ⚡ **Fast failure**: Issues caught in ~2 minutes vs 30+ minutes
   - [ ] 💰 **Resource efficient**: No wasted compute on bad deployments  
   - [ ] 🔒 **Version safety**: Guaranteed pub.dev compatibility before deployment

### Phase 3: GitHub Release Test
1. **Create draft GitHub release**:
   - Tag: `v4.0.0-beta.2-test`
   - Title: `4.0.0-beta.2-test` 
   - Description: "Test release for new automation workflow"
   - Mark as "Pre-release"
   - Save as draft

2. **Publish release and monitor**:
   - Click "Publish release"
   - Watch Actions tab for automatic trigger
   - Monitor all deployment jobs

3. **Expected Results**:
   - [ ] Workflow triggers automatically on release publish
   - [ ] Version `4.0.0-beta.2-test` extracted correctly
   - [ ] All platform deployments succeed:
     - [ ] pub.dev publish
     - [ ] Linux binaries uploaded to GitHub release
     - [ ] Windows binaries + Chocolatey deployment  
     - [ ] macOS binaries + Homebrew update
     - [ ] Docker image built and pushed

## Validation Checklist

### Core Functionality
- [ ] **Version Extraction**: Release tag → version (handles 'v' prefix)
- [ ] **Dynamic Version Update**: pubspec.yaml modified correctly in all jobs
- [ ] **Version Generation**: build_runner creates version.dart with correct content
- [ ] **No Release Creation**: Workflow skips `pkg-github-release` successfully

### Platform Deployments
- [ ] **pub.dev**: Package published with correct version
- [ ] **GitHub Linux**: Binaries uploaded to existing release
- [ ] **GitHub Windows**: Binaries uploaded to existing release  
- [ ] **GitHub macOS**: Binaries uploaded to existing release
- [ ] **Chocolatey**: Package deployed with correct version
- [ ] **Homebrew**: Formula updated with new version
- [ ] **Docker**: Image built and tagged correctly

### Error Scenarios
- [ ] **Invalid Tag Format**: Graceful handling of malformed tags
- [ ] **Missing Secrets**: Clear error messages for missing credentials
- [ ] **Failed Builds**: Proper job failure handling and notifications
- [ ] **Network Issues**: Retry logic and timeout handling

## Post-Test Cleanup

After successful testing:

1. **Delete test release and tag**:
   ```bash
   # Delete release via GitHub UI
   # Delete tag
   git tag -d v4.0.0-beta.2-test
   git push origin :refs/tags/v4.0.0-beta.2-test
   ```

2. **Clean up test artifacts**:
   - Remove test version from pub.dev if published
   - Clean up any test Docker images
   - Revert pubspec.yaml to original version

## Rollback Plan

If testing reveals issues:

1. **Immediate**: Disable new workflow
   ```bash
   # Rename to disable
   mv .github/workflows/release.yml .github/workflows/release.yml.disabled
   ```

2. **Fallback**: Use legacy workflow
   ```bash
   mv .github/workflows/release-legacy.yml .github/workflows/release.yml
   ```

3. **Emergency Release**: Use manual tag approach
   ```bash
   git tag v4.0.0-beta.2 && git push origin v4.0.0-beta.2
   ```

## Success Criteria

✅ **Workflow Ready for Production When**:
- [ ] Manual dispatch test passes completely
- [ ] GitHub release test passes completely  
- [ ] All platform deployments work correctly
- [ ] Version management is fully automated
- [ ] No manual intervention required
- [ ] Proper error handling and notifications
- [ ] Documentation is comprehensive and accurate

## Next Steps After Testing

1. **Update this checklist** with any findings
2. **Adjust workflows** based on test results
3. **Train team members** on new process
4. **Announce the change** in project communications
5. **Monitor first few production releases** closely