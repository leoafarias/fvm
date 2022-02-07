---
id: faq
title: "Preguntas Más Frecuentes"
sidebar_position: 4
---

### Actualizar el Canal de Flutter

Como se describe en nuestros [Principios](../getting_started/overview/#principios), FVM sobrescribe el comportamiento estándar de Flutter. Por lo tanto, para actualizar un canal, deberá usar `flutter upgrade`. Puede encontrar más información al respecto en la sección [Ejecutar Flutter](/docs/guides/running_flutter).

---

### Soporte para Mono repositorios

Suponga que tiene paquetes anidados que desea compartir con la misma versión de Flutter. Puede configurar la configuración de FVM en la raíz del monorepo.

FVM realizará una búsqueda ​​para encontrar la configuración y usarla como predeterminada.

---

### No se puede instalar la última versión de FVM

Al ejecutar `pub global active fvm`, pub obtendrá la última versión de FVM que sea compatible con el dart-sdk instalado. Actualice a la última versión de Dart y vuelva a ejecutar el comando. Vaya a https://dart.dev/get-dart para obtener más información.

---

### Cómo desinstalar FVM

Ejecute el comando `fvm list`, esto generará el directorio utilizado para el caché de Flutter. Elimina ese directorio. Si instaló usando pub run `dart pub global deactivate fvm`, si usó una instalación independiente, siga sus instrucciones.

---

### Los comandos se ejecutan dos veces en Windows

Esto sucede debido a un problema de pub https://github.com/dart-lang/pub/issues/2934. Para evitar que suceda este problema, asegúrese de que su PATH esté en el siguiente orden. [Lea lo siguiente](#orden-de-variables-de-entorno-para-windows-en-path).

---

### Invalid kernel binary or invalid sdk hash al ejecutar FVM

Hay algunas razones por las que esto puede suceder. Sin embargo, significa que la instantánea (snapshot) de FVM no es compatible con la versión de Dart que está instalada.

1. En Windows, asegúrese de que sus variables env estén en el siguiente orden como se describe [aquí](#orden-de-variables-de-entorno-para-windows-en-path).
2. Ejecutar `dart pub global deactivate fvm`
3. Ejecutar `dart pub global activate fvm`

---

### Comando 'pub' no encontrado

Si obtienes `Command 'pub' not found`, entonces asegúrate de añadir `export PATH="$PATH:/usr/lib/dart/bin"` a tu `~/.bashrc` (se reinicia cada vez que abres un bash shell) o archivo `~/.profile` (solo se lee en el inicio de sesión)

---

### Orden de variables de entorno para Windows en PATH

Flutter viene con Dart integrado. Debido a eso, puede encontrar algunos conflictos cuando ejecuta Dart y Flutter de forma independiente juntos. Aquí hay una sugerencia de lo que encontramos que es el orden correcto de las dependencias para evitar problemas.

1. Caché de Pub para paquetes globales
2. Dart SDK (Si se instala fuera de Flutter)
3. Flutter SDK

Debe verse así

```
C:\Users\<user>\AppData\Roaming\Pub\Cache\bin
C:\src\flutter\bin\cache\dart-sdk\bin
C:\src\flutter\bin
```
