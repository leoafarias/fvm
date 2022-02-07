---
id: release_multiple_channels
title: "Lanzamiento en Múltiples Canales"
sidebar_position: 2
---

En algunos casos, un lanzamiento de Flutter puede aparecer en varios canales. FVM priorizará el canal por estabilidad. Stable > Beta > Dev. Lo que significa que cualquier número de versión se resolverá en el canal más estable o "stable" si existe en varios canales.

Por ejemplo, la versión `2.2.2` existe tanto en canales estables como beta. Eso significa que los flags de características que usan son diferentes.

```bash
fvm use 2.2.2 # Instala la versión 2.2.2 del canal `stable`
```

Sin embargo, si desea forzar la instalación de una versión desde un canal específico, puede hacer `fvm install CHANNEL@VERSION`. Esto se parece a lo siguiente.

```bash
fvm use 2.2.2@beta # Instala la versión 2.2.2 del canal `beta`
```
