---
id: project_flavors
title: "Flavors del Proyecto"
sidebar_position: 3
---

Puede tener varias versiones del SDK de Flutter configuradas por entorno de proyecto o tipo de versión. FVM sigue la misma convención de Flutter y llama a esto `flavors`.

Le permite crear la siguiente configuración para su proyecto.

```json
{
  "flutterSdkVersion": "stable",
  "flavors": {
    "dev": "beta",
    "staging": "2.0.3",
    "production": "1.22.6"
  }
}
```

## Fijar versión de flavor

Para elegir una versión del SDK de Flutter para un flavor específico, simplemente use el comando `use`.

```bash
fvm use {version} --flavor {flavor_name}
```

Esto fijará la versión `version` al nombre del flavor `flavor_name`

## Cambiar flavors

Obtendrá la versión configurada para el flavor y se establecerá como la versión del proyecto.

```bash
fvm flavor {flavor_name}
```

## Ver flavors

Para enumerar todos los flavors configurados:

```bash
fvm flavor
```

[Aprende más sobre los flavor de Flutter](https://flutter.dev/docs/deployment/flavors)
