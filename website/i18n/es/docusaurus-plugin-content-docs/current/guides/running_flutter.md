---
id: running_flutter
title: "Ejecutar Flutter"
sidebar_position: 1
---

Hay algunas formas de interactuar con la configuración del SDK de Flutter. Estos dependerán principalmente de la preferencia.

## Comandos Proxy

Puede transferir cualquier comando `flutter` o `dart` a la versión configurada agregando `fvm` delante.

### Flutter

```bash
# Usar
> fvm flutter {command}
# En vez de
> flutter {command}
```

### Dart

```bash
# Usar
> fvm dart {command}
# En vez de
> dart {command}
```

:::tip

Configure el siguiente alias para una versión abreviada del comando

```bash
# alias
f="fvm flutter"
d="fvm dart"

# Ahora puedes usar
f run
```

:::

### Beneficios

- Encuentra configuraciones de proyecto relativo.
- Compatibilidad Monorepo.
- Fallback a la versión configurada `global` o la configuración `PATH`.

### Enrutamiento

Al enviar comandos por proxy, `FVM` buscará un SDK en el siguiente orden.

1. Proyecto
2. Directorio padre
3. Global (Configurado a través de FVM)
4. Enviroment (Versión de Flutter configurada en `PATH`)

## Llame Directamente al SDK

Las versiones instaladas por FVM son instalaciones estándar de Flutter SDK. Eso significa que puede llamarlos directamente sin usar proxy a través de FVM.

El uso del enlace simbólico llamará dinámicamente a la versión configurada para el proyecto.

```bash
# flutter run
.fvm/flutter_sdk/bin/flutter run
```

:::tip

Configure el siguiente alias para llamar a la versión relativa del proyecto, sin necesidad de proxy.

```bash
fv=".fvm/flutter_sdk/bin/flutter"
```

:::

## Comando Spawn

Ejecuta un comando en cualquier SDK de Flutter instalado.

```bash
fvm spawn {version}
```

**Ejemplo**

Lo siguiente ejecutará `flutter analyze` en el canal `master`

```bash
fvm spawn master analyze
```
