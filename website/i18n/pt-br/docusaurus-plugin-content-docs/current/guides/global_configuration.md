---
id: global_version
title: Configurar versão global
sidebar_position: 2
---

Você pode ter a versão padrão do Flutter em sua máquina, mas ainda assim, preserve a comutação dinâmica. Ele permite que você não faça nenhuma alteração em como você usa atualmente o Flutter, mas se beneficia de uma troca mais rápida e cache de versão.

Para isso, o FVM fornece um comando auxiliar para configurar uma versão global.

```bash
fvm global {version}
```

Agora você poderá fazer o seguinte.

```bash title="Exemplo"
# Definir canal beta como global
fvm global beta

# Verificar versão
flutter --version # Será a versão beta

# Definir canal estável como global
fvm global stable

# Verificar versão
flutter --version # Será versão estável
```

:::info
Após executar o comando, o FVM verificará se a versão global está configurada no caminho do seu ambiente. Se não for, ele fornecerá o caminho que precisa ser configurado.
:::
