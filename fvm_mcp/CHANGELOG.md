# Changelog

All notable changes to `fvm_mcp` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.0.1-alpha.1 - 2026-02-13

### Added

- Initial public alpha release of the standalone `fvm_mcp` server.
- MCP tool surface for FVM JSON API, mutating commands, and command proxies.
- FVM version gating for JSON API support and non-interactive mutation support.
- Cross-platform CI checks for formatting, analysis, and tests under `fvm_mcp`.
- Automated GitHub release pipeline for `fvm_mcp` binaries (`fvm-mcp-v*` tags).

### Changed

- Default server-reported version set to `0.0.1-alpha.1`.
- Enabled pub.dev publishing by removing `publish_to: "none"` and adding
  package repository metadata.
- README expanded with source run instructions, binary install flow, and deployment plan.
