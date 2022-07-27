---
id: project_flavors
title: Projetos flavors
sidebar_position: 3
---

Você pode ter várias versões do Flutter SDK configuradas por ambiente de projeto ou tipo de lançamento. O FVM segue a mesma convenção do Flutter e chama isso de `flavors`.

Ele permite que você crie a seguinte configuração para seu projeto.

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

## Fixar versão do flavor {#pin-flavor-version}

Para escolher uma versão do Flutter SDK para um flavor específico, basta usar o comando `use`.

```bash
fvm use {versão} --flavor {nome_flavor}
```

Isto irá fixar `versão` ao `nome do flavor`

## Alternar flavors {#switch-flavors}

Obterá a versão configurada para o sabor e definida como a versão do projeto.

```bash
fvm flavor {nome_flavor}
```

## Ver flavors {#view-flavors}

Para listar todos os flavors configurados:

```bash
fvm flavor
```

[Saiba mais sobre os flavors Flutter](https://flutter.dev/docs/deployment/flavors)
