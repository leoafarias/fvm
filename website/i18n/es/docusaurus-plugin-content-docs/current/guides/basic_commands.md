---
id: basic_commands
title: "Comandos Básicos"
sidebar_position: 0
---

## Uso

Establece la versión del SDK de Flutter que le gustaría usar en un proyecto. Si la versión no existe, le preguntará si desea instalarla.

```bash
Usage:
    fvm use {version}

Option:
    -h, --help     Print this usage information.
    -f, --force    Skips Flutter project checks.
    -p, --pin      Pins latest release channel instead of channel itself.
        --flavor   Sets version for a project flavor
```

Si está comenzando un nuevo proyecto y planea usar `fvm flutter create`, tendrá que usar el flag `--force`

## Install

Instala la versión del SDK de Flutter. Te da la posibilidad de instalar lanzamientos o canales de Flutter.

```bash
Usage:
    fvm install - # Instala la versión encontrada en la configuración del proyecto
    fvm install {version} - # Instalar versión específica

Option:
    -h, --help          Print this usage information.
    -s, --skip-setup    Skips Flutter setup after install
```

## Remove

Elimina la versión del SDK de Flutter. Afectará a cualquier proyecto que dependa de esa versión del SDK.

```bash
Usage:
    fvm remove {version}

Option:
    -h, --help     Print this usage information.
        --force    Skips version global check.
```

## List

Enumera las versiones instaladas del SDK de Flutter. También imprimirá el directorio de caché utilizado por FVM.

```bash
Usage:
    fvm list

Option:
    -h, --help     Print this usage information.
```

## Releases

Vea todas las versiones del SDK de Flutter disponibles para instalar.

```bash
Usage:
    fvm releases

Option:
    -h, --help     Print this usage information.
```

## Doctor

Muestra información sobre el entorno y la configuración del proyecto.

```bash
Usage:
    fvm doctor

Option:
    -h, --help     Print this usage information.
```
