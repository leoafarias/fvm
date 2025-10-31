#!/bin/bash
# Extract minimum Dart SDK version from pubspec.yaml

set -e

# Read the SDK constraint from pubspec.yaml
sdk_constraint=$(grep -A 1 "^environment:" pubspec.yaml | grep "sdk:" | sed 's/.*sdk: *"\?\([^"]*\)"\?/\1/')

# Extract the minimum version from the constraint (e.g., ">=3.2.0 <4.0.0" -> "3.2.0")
if [[ $sdk_constraint =~ \>\=([0-9]+\.[0-9]+\.[0-9]+) ]]; then
    echo "${BASH_REMATCH[1]}"
else
    echo "Error: Could not parse minimum SDK version from: $sdk_constraint" >&2
    exit 1
fi
