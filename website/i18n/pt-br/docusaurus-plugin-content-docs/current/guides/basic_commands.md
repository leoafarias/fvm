---
id: basic_commands
title: Comandos básicos
sidebar_position: 0
---

## Use {#use}

Define a versão do SDK Flutter que você gostaria de usar em um projeto. Se a versão não existir, ele perguntará se você deseja instalar.

```bash
Usage:
    fvm use {version}

Option:
    -h, --help     Print this usage information.
    -f, --force    Skips Flutter project checks.
    -p, --pin      Pins latest release channel instead of channel itself.
        --flavor   Sets version for a project flavor
```

Se você está iniciando um novo projeto e planeja usar o `fvm flutter create`, você terá que usar o sinalizador `--force`

## Install {#install}

Instala a versão do SDK do Flutter. Dá a você a capacidade de instalar versões ou canais do Flutter.

```bash
Usage:
    fvm install - # Installs version found in project config
    fvm install {version} - # Installs specific version

Option:
    -h, --help          Print this usage information.
    -s, --skip-setup    Skips Flutter setup after install
```

## Remove {#remove}

Remove a versão do SDK do Flutter. Afetará qualquer projeto que dependa dessa versão do SDK.

```bash
Usage:
    fvm remove {version}

Option:
    -h, --help     Print this usage information.
        --force    Skips version global check.
```

## List {#list}

Lista as versões do SDK do Flutter instaladas. Também imprimirá o diretório de cache usado pelo FVM.

```bash
Usage:
    fvm list

Option:
    -h, --help     Print this usage information.
```

## Releases {#releases}

Veja todas as versões do Flutter SDK disponíveis para instalação.

```bash
Usage:
    fvm releases

Option:
    -h, --help     Print this usage information.
```

## Doctor {#doctor}

Mostra informações sobre o ambiente e a configuração do projeto.

```bash
Usage:
    fvm doctor

Option:
    -h, --help     Print this usage information.
```
