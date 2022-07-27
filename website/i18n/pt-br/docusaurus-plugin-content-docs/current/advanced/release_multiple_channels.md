---
id: release_multiple_channels
title: Lançamento em vários canais
sidebar_position: 2
---

Em alguns casos, uma versão do Flutter pode aparecer em vários canais. A FVM priorizará o canal por estabilidade. Estável > Beta > Dev. O que significa que qualquer número de versão será resolvido para o canal mais "estável" se existir em vários canais.

Por exemplo, a versão `2.2.2` existe nos canais estável e beta. Isso significa que os sinalizadores de recursos que eles usam são diferentes.

```bash
fvm use 2.2.2 # Instala 2.2.2 do estável
```

No entanto, se você quiser forçar a instalação de uma versão de um canal específico, você pode fazer `fvm install CHANNEL@VERSION`. Isso se parece com o seguinte.

```bash
fvm use 2.2.2@beta # Instala 2.2.2 do beta
```
