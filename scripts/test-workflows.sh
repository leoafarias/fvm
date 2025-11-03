#!/usr/bin/env bash
# Script to test GitHub Actions workflows locally using act

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if act is installed
if ! command -v act &> /dev/null; then
    print_error "act is not installed. Please install it first:"
    echo "  macOS: brew install act"
    echo "  Linux: curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash"
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    print_error "Docker is not running. Please start Docker first."
    exit 1
fi

# Default values
WORKFLOW=""
EVENT="push"
JOB=""
DRY_RUN=false
LIST_ONLY=false
VERBOSE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -w|--workflow)
            WORKFLOW="$2"
            shift 2
            ;;
        -e|--event)
            EVENT="$2"
            shift 2
            ;;
        -j|--job)
            JOB="$2"
            shift 2
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -l|--list)
            LIST_ONLY=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -w, --workflow WORKFLOW   Specify workflow file (e.g., test.yml)"
            echo "  -e, --event EVENT        Specify event type (default: push)"
            echo "  -j, --job JOB           Run specific job only"
            echo "  -d, --dry-run           Show what would be run without executing"
            echo "  -l, --list              List all available workflows and jobs"
            echo "  -v, --verbose           Enable verbose output"
            echo "  -h, --help              Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                      # Run default push event"
            echo "  $0 -w test.yml          # Run test workflow"
            echo "  $0 -w test.yml -j test  # Run only test job"
            echo "  $0 -e pull_request      # Run pull request event"
            echo "  $0 -l                   # List all workflows"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Build act command
ACT_CMD="act"

# Add event
ACT_CMD="$ACT_CMD $EVENT"

# Add workflow if specified
if [ -n "$WORKFLOW" ]; then
    ACT_CMD="$ACT_CMD -W .github/workflows/$WORKFLOW"
fi

# Add job if specified
if [ -n "$JOB" ]; then
    ACT_CMD="$ACT_CMD -j $JOB"
fi

# Add environment file
if [ -f ".env.act" ]; then
    ACT_CMD="$ACT_CMD --env-file .env.act"
fi

# Add secrets file if exists
if [ -f ".secrets.act" ]; then
    ACT_CMD="$ACT_CMD --secret-file .secrets.act"
fi

# Add verbose flag
if [ "$VERBOSE" = true ]; then
    ACT_CMD="$ACT_CMD --verbose"
fi

# Add dry run flag
if [ "$DRY_RUN" = true ]; then
    ACT_CMD="$ACT_CMD --dryrun"
fi

# List workflows and exit if requested
if [ "$LIST_ONLY" = true ]; then
    print_info "Available workflows and jobs:"
    act -l
    exit 0
fi

# Show what will be run
print_info "Running command: $ACT_CMD"

# Create required directories
mkdir -p /tmp/.pub-cache

# Run act
if [ "$DRY_RUN" = true ]; then
    print_info "Dry run mode - showing what would be executed:"
    $ACT_CMD
else
    print_info "Starting workflow execution..."
    $ACT_CMD
fi

# Check exit code
if [ $? -eq 0 ]; then
    print_info "Workflow completed successfully!"
else
    print_error "Workflow failed!"
    exit 1
fi