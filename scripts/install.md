## Install on Mac and Linux

### Install FVM

Run the command below in your terminal.

```bash
curl -fsSL https://fvm.app/install.sh | bash
```

You can customise the directory fvm is installed to by setting `SYMLINK_DIR` in
your environment as so:

```bash
curl -fsSL https://fvm.app/install.sh | SYMLINK_DIR=$HOME/.local/bin bash
```

### Install FVM on Windows

**Run as Admin**: Open PowerShell as Administrator.

**Install**: Paste and run the below command.

```powershell
Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://fvm.app/install.ps1')
```
