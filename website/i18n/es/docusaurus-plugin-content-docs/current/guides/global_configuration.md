---
id: global_version
title: "Configura la Versión Global"
sidebar_position: 2
---

Puede tener la versión predeterminada de Flutter en su máquina, pero aún así, conserve el cambio dinámico. Le permite no realizar ningún cambio en la forma en que usa Flutter actualmente, pero se beneficia de un cambio más rápido y el almacenamiento en caché de versiones.

Para lograr esto, FVM le proporciona un comando auxiliar para configurar una versión global.

```bash
fvm global {version}
```

Ahora podrá hacer lo siguiente.

```bash title="Example"
# Establezca el canal `beta` como global
fvm global beta

# Ver la versión
flutter --version # Será el release `beta`

# Establecer el canal `stable` como global
fvm global stable

# Ver la versión
flutter --version # Será el release `stable`
```

:::info Información
Después de ejecutar el comando, FVM verificará si la versión global está configurada en la ruta de su entorno. Si no es así, le proporcionará la ruta que debe configurar.
:::
