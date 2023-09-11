# Detect OS
$OS = "windows"

Write-Host "Detected OS: $OS"

# Check for curl
if (-Not (Get-Command "curl" -ErrorAction SilentlyContinue)) {
    Write-Host "curl is required but not installed. Exiting."
    exit 1
}

# Get installed FVM version if exists
$INSTALLED_FVM_VERSION = ""
if (Get-Command "fvm" -ErrorAction SilentlyContinue) {
    $INSTALLED_FVM_VERSION = fvm --version
}

# Define the URL of the FVM binary
$FVM_VERSION = $null
if ($args.Length -eq 0) {
    $FVM_VERSION = (Invoke-RestMethod -Uri 'https://api.github.com/repos/fluttertools/fvm/releases/latest').tag_name
    if ($null -eq $FVM_VERSION) {
        Write-Host "Failed to fetch latest FVM version. Exiting."
        exit 1
    }
} else {
    $FVM_VERSION = $args[0]
}

# Prompt for user input if needed
if ($INSTALLED_FVM_VERSION -eq $FVM_VERSION) {
    $REINSTALL = Read-Host "FVM version $FVM_VERSION is already installed. Would you like to reinstall it? (y/n)"
    if ($REINSTALL -ne "y") { exit 0 }
}

Write-Host "Installing FVM Version: $FVM_VERSION"

# Download FVM
$URL = "https://github.com/fluttertools/fvm/releases/download/$FVM_VERSION/fvm-$FVM_VERSION-$OS-x64.zip"
Invoke-WebRequest -Uri $URL -OutFile "fvm.zip"

# Binary directory
$FVM_DIR = "$env:LOCALAPPDATA\Programs\fvm"

# Extract binary to a temporary directory
Expand-Archive -Path "fvm.zip" -DestinationPath "$FVM_DIR\tmp" -Force

# Move the files to the desired directory
Move-Item -Path "$FVM_DIR\tmp\*" -Destination $FVM_DIR -Force

# Cleanup
Remove-Item -Path "$FVM_DIR\tmp" -Recurse -Force
Remove-Item -Path "fvm.zip" -Force

# Verify installation
if (-Not (Get-Command "fvm" -ErrorAction SilentlyContinue)) {
    Write-Host "Installation failed. Exiting."
    exit 1
}

$INSTALLED_FVM_VERSION = fvm --version
Write-Host "FVM $INSTALLED_FVM_VERSION installed successfully."
