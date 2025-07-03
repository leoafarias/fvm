# Act Testing Notes

## Container Differences

When testing workflows locally with act, be aware of these differences:

1. **Default Containers**:
   - Act uses: `catthehacker/ubuntu:act-latest` (feature-rich)
   - GitHub Actions uses: `ubuntu:latest` (minimal)
   
2. **Missing Commands in Minimal Containers**:
   - `file` - not available in ubuntu:latest
   - `shellcheck` - needs to be installed
   - Other common tools may be missing

3. **Best Practices**:
   - Test with actual container images when specified
   - Don't rely on commands that aren't universally available
   - Follow KISS principle - use basic tools like `tar`, `grep`, etc.
   - Always test the `test-container` job which uses ubuntu:latest

4. **Running Specific Container Tests**:
   ```bash
   # Test the container job specifically
   ./scripts/test-workflows.sh -w test-install.yml -j test-container
   ```

This ensures compatibility with the actual GitHub Actions environment.
