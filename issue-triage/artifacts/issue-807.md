# Issue #807: Option to specify FVM_HOME directory

## Metadata
- **Reporter**: @pbartyik
- **Created**: 2024-12-22
- **Issue Type**: feature request (already supported)
- **URL**: https://github.com/leoafarias/fvm/issues/807

## Summary
Reporter wants to change FVM's default directory via environment variable (`FVM_HOME`).

## Validation
- FVM already supports `FVM_CACHE_PATH` (preferred) and legacy `FVM_HOME`. See `lib/src/models/config_model.dart` and `AppConfigService._loadEnvironment()`.

## Recommendation
Document existing env vars (`FVM_CACHE_PATH`, `FVM_HOME`) and close issue as already supported.

## Classification Recommendation
- Folder: `resolved/`
