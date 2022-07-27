---
id: running_flutter
title: Flutter em execução
sidebar_position: 1
---

Existem algumas maneiras de interagir com a configuração do Flutter SDK. Estes dependerão principalmente da preferência.

## Comandos de proxy {#proxy-commands}

Você pode fazer proxy de qualquer comando `flutter` ou `dart` para a versão configurada adicionando `fvm` na frente dele.

### Flutter {#flutter}

```bash
# Usar
> fvm flutter {command}
# Ao invés de
> flutter {command}
```

### Dart {#dart}

```bash
# Usar
> fvm dart {command}
# Ao invés de
> dart {command}
```

:::tip

Configure o alias a seguir para uma versão abreviada do comando

```bash
# aliases
f="fvm flutter"
d="fvm dart"

# Agora você pode usar
f run
```

:::

### Benefícios {#benefits}

- Encontre configurações de projeto relativas.
- Compatibilidade Monorepo.
- Fallback para a versão configurada `global` ou `PATH` configurada.

### Roteamento {#routing}

Ao fazer proxy de comandos, o `FVM` procurará um sdk na seguinte ordem.

1. Projeto
2. Diretório ancestral
3. Global (definido por meio de FVM)
4. Ambiente (versão do Flutter configurada em `PATH`)

## Chamar SDK diretamente {#call-sdk-directly}

As versões instaladas pelo FVM são instalações padrão do Flutter SDK. Isso significa que você pode chamá-los diretamente sem proxy por meio do FVM.

O uso do link simbólico chamará dinamicamente a versão configurada para o projeto.

```bash
# flutter run
.fvm/flutter_sdk/bin/flutter run
```

:::tip

Configure o alias a seguir para chamar a versão relativa do projeto, sem a necessidade de proxy.

```bash
fv=".fvm/flutter_sdk/bin/flutter"
```

:::

## Comando de spawn {#spawn-command}

Gera um comando em qualquer SDK do Flutter instalado.

```bash
fvm spawn {version}
```

**Exemplo**

O seguinte executará o `flutter analyze` no canal `master`

```bash
fvm spawn master analyze
```
