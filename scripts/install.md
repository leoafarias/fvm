## Install on Mac and Linux

### Install FVM

Run the command below in your terminal.

```bash
curl -fsSL https://fvm.app/install.sh | bash
```

FVM will be installed to the following paths.

```bash
FVM_DIR="$HOME/.fvm_flutter}"
FVM_DIR_BIN="$HOME/bin}"
FVM_SYMLINK_TARGET="/usr/local/bin/fvm"
```

Target paths can be overridden using environment variables.

```bash
curl -fsSL https://fvm.app/install.sh | FVM_SYMLINK_TARGET=$HOME/.local/bin/fvm bash
```

### Install FVM on Windows

**Run as Admin**: Open PowerShell as Administrator.

**Install**: Paste and run the below command.

```powershell
Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://fvm.app/install.ps1')
```
