# Draft Response for Issue #841

Hi @megumin31,

Apologies for the delayed response! I've reviewed your issue and can confirm this is actually working as intended, though I understand the confusion.

When you run `fvm global stable`, FVM creates a symlink at `~/.fvm/default` pointing to your global Flutter version. However, for the `flutter` command to work without the `fvm` prefix, you need to add `~/.fvm/default/bin` to your PATH.

## Solution for Arch Linux

Add this line to your shell configuration file:

**For Bash** (`~/.bashrc`):
```bash
export PATH="$HOME/.fvm/default/bin:$PATH"
```

**For Zsh** (`~/.zshrc`):
```zsh
export PATH="$HOME/.fvm/default/bin:$PATH"
```

**For Fish** (`~/.config/fish/config.fish`):
```fish
set -gx PATH $HOME/.fvm/default/bin $PATH
```

After adding the line, restart your terminal or run:
```bash
source ~/.bashrc  # or ~/.zshrc if using Zsh
```

Then verify with:
```bash
which flutter
# Should show: /home/yourusername/.fvm/default/bin/flutter

flutter --version
```

## Alternative Approach

If you prefer not to modify your PATH or work on a per-project basis, you can always use:
```bash
fvm flutter <command>
```

This will use the project-pinned version (if you're in a project directory) or the global version.

## Documentation

The installation guide covers PATH configuration here: https://fvm.app/documentation/getting-started/installation

Let me know if this resolves your issue!
