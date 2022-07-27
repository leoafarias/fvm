---
id: faq
title: Perguntas frequentes
sidebar_position: 4
---

### Atualize o Canal Flutter {#upgrade-flutter-channel}

Conforme descrito em nossos [Princípios](../getting_started/overview/#principles), o FVM não substitui o comportamento padrão do Flutter. Portanto, para atualizar um canal, você terá que usar o `flutter upgrade` padrão. Você pode encontrar mais sobre isso na seção [Running Flutter](/docs/guides/running_flutter).

---

### Suporte a Monorepo {#monorepo-support}

Suponha que você tenha um pacote aninhado que deseja compartilhar a mesma versão do Flutter. Você pode configurar a configuração do FVM na raiz do monorepo.

O FVM fará uma pesquisa de ancestral para encontrar a configuração e usá-la como padrão.

---

### Não é possível instalar a versão mais recente do FVM {#cannot-install-latest-version-of-fvm}

Ao executar o `pub global activate fvm`, o pub obterá a versão mais recente do FVM compatível com o dart-sdk instalado. Atualize para a versão mais recente do Dart e execute o comando novamente. Acesse https://dart.dev/get-dart para obter mais informações.

---

### Como desinstalar o FVM {#how-to-uninstall-fvm}

Execute o comando `fvm list` para gerar o diretório usado para o cache Flutter. Exclua esse diretório.
Se você instalou usando pub execute `dart pub global deactivate fvm`, se você usou uma instalação autônoma, siga as instruções.

---

### Comandos são executados duas vezes no Windows {#commands-run-twice-on-windows}

Isso acontece devido a um problema de publicação https://github.com/dart-lang/pub/issues/2934. Para evitar que esse problema aconteça, certifique-se de que o PATH esteja na seguinte ordem. [Leia o seguinte](#environment-variables-order-for-windows-in-path).

---

### Binário de kernel inválido ou hash sdk inválido ao executar o FVM {#invalid-kernel-binary-or-invalid-sdk-hash-when-running-fvm}

Existem algumas razões pelas quais isso pode acontecer. No entanto, isso significa que o instantâneo do FVM não é compatível com a versão do Dart que está instalada.

Por favor, faça o seguinte:

1. No Windows, certifique-se de que suas variáveis ​​de ambiente estejam na seguinte ordem, conforme descrito [aqui](#environment-variables-order-for-windows-in-path).
2. Execute `dart pub global deactivate fvm`
3. Execute `dart pub global activate fvm`

---

### Comando 'pub' não encontrado {#command-pub-not-found}

Se você receber `Command 'pub' not found`, certifique-se de anexar `export PATH="$PATH:/usr/lib/dart/bin"` ao seu `~/.bashrc` (é reiniciado cada vez que você abre um shell bash) ou arquivo `~/.profile` (somente lido no login).

---

### Ordem de variáveis ​​de ambiente para Windows em PATH {#environment-variables-order-for-windows-in-path}

Flutter vem com Dart embutido. Por causa disso, você pode encontrar alguns conflitos ao executar o Dart e o Flutter autônomos juntos. Aqui está uma sugestão do que descobrimos ser a ordem correta das dependências para evitar problemas.

1. Pub Cache para pacotes globais
2. SDK do Dart (se instalado fora do Flutter)
3. SDK Flutter

Deve ficar assim.

```
C:\Users\<user>\AppData\Roaming\Pub\Cache\bin
C:\src\flutter\bin\cache\dart-sdk\bin
C:\src\flutter\bin
```
