# Requires admin rights
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Run the script as an admin"
    exit 1
}

Function CleanUp {
    Remove-Item -Path "fvm.tar.gz" -Force -ErrorAction SilentlyContinue
}

Function CatchErrors {
    param ($exitCode)
    if ($exitCode -ne 0) {
        Write-Host "An error occurred."
        CleanUp
        exit 1
    }
}

# Terminal colors
$Color_Off = ''
$Red = [System.ConsoleColor]::Red
$Green = [System.ConsoleColor]::Green
$Dim = [System.ConsoleColor]::Gray
$White = [System.ConsoleColor]::White

Function Write-ErrorLine {
    param ($msg)
    Write-Host -ForegroundColor $Red "error: $msg"
    exit 1
}

Function Write-Info {
    param ($msg)
    Write-Host -ForegroundColor $Dim $msg
}

Function Write-Success {
    param ($msg)
    Write-Host -ForegroundColor $Green $msg
}

# Detect OS and architecture
$OS = if ($env:OS -eq 'Windows_NT') { 'windows' } else { 'unknown' }
$ARCH = if ([Environment]::Is64BitOperatingSystem) { 'x64' } else { 'x86' }

Write-Info "Detected OS: $OS"
Write-Info "Detected Architecture: $ARCH"

# Check for curl
try {
    $curl = Get-Command curl -ErrorAction Stop
} catch {
    Write-ErrorLine "curl is required but not installed."
}

$github_repo = "fluttertools/fvm"

# Get FVM version
if ($args.Count -eq 0) {
    try {
        $FVM_VERSION = Invoke-RestMethod -Uri "https://api.github.com/repos/$github_repo/releases/latest" | Select-Object -ExpandProperty tag_name
    } catch {
        Write-ErrorLine "Failed to fetch the latest FVM version from GitHub."
    }
} else {
    $FVM_VERSION = $args[0]
}

Write-Info "Installing FVM Version: $FVM_VERSION"

# Download FVM
$URL = "https://github.com/fluttertools/fvm/releases/download/$FVM_VERSION/fvm-$FVM_VERSION-$OS-x64.zip"
Write-Host "Downloading from $URL"
try {
    Invoke-WebRequest -Uri $URL -OutFile "fvm.tar.gz"
} catch {
    Write-ErrorLine "Failed to download FVM from $URL."
}

$FVM_DIR = "C:\Program Files\fvm"

# Extract binary
try {
    tar -xzf fvm.tar.gz -C $FVM_DIR
} catch {
    Write-ErrorLine "Extraction failed."
}

# Cleanup
CleanUp

# Verify Installation
try {
    $INSTALLED_FVM_VERSION = & fvm --version
    if ($INSTALLED_FVM_VERSION -eq $FVM_VERSION) {
        Write-Success "FVM $INSTALLED_FVM_VERSION installed successfully."
    } else {
        Write-ErrorLine "FVM version verification failed."
    }
} catch {
    Write-ErrorLine "Installation failed. Exiting."
}
