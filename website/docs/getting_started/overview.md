---
id: overview
title: Overview
sidebar_position: 0
---

FVM helps with the need for consistent app builds by referencing the Flutter SDK version used on a per-project basis. It also allows you to have multiple Flutter versions installed to quickly validate and test upcoming Flutter releases with your apps without waiting for Flutter installation every time.

## Motivation

- We need to have more than one Flutter SDK at a time.
- Testing new SDK features requires switching between [Channels](https://flutter.dev/docs/development/tools/sdk/releases).
- The switch between channels is slow and requires reinstalling every time.
- No way of keeping track of the latest working/used version of the SDK in an app.
- Major Flutter updates require migration of all Flutter apps in the machine.
- Inconsistent development environments between other devs in the team.

## Video Guides & Walkthroughs

You can view a playlist of many Youtube guides & walkthroughs done by the incredible Flutter community in many different languages.

<iframe width="560" height="315" src="https://www.youtube.com/embed/videoseries?list=PLVnlSO6aQelAAddOFQVJNoaRGZ1mMsj2Q" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

## Principles

We follow these principles when building and adding new features to FVM.

- Always use Flutter tools when interacting with the SDK.
- Do not override any Flutter CLI commands.
- Follow Flutter suggested installation instructions accomplish caching.
- Should extend Flutter behavior and not modify them.
- API should be simple and easy to understand.

## Contributors

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tbody>
    <tr>
      <td align="center" valign="top" width="20%"><a href="https://github.com/leoafarias"><img src="https://avatars1.githubusercontent.com/u/435833?v=4?s=50" width="50px;" alt="Leo Farias"/><br /><sub><b>Leo Farias</b></sub></a><br /><a href="https://github.com/fluttertools/fvm/commits?author=leoafarias" title="Documentation">📖</a> <a href="#ideas-leoafarias" title="Ideas, Planning, & Feedback">🤔</a> <a href="https://github.com/fluttertools/fvm/commits?author=leoafarias" title="Code">💻</a> <a href="#example-leoafarias" title="Examples">💡</a> <a href="https://github.com/fluttertools/fvm/pulls?q=is%3Apr+reviewed-by%3Aleoafarias" title="Reviewed Pull Requests">👀</a> <a href="#maintenance-leoafarias" title="Maintenance">🚧</a> <a href="#infra-leoafarias" title="Infrastructure (Hosting, Build-Tools, etc)">🚇</a></td>
      <td align="center" valign="top" width="20%"><a href="https://github.com/ianko"><img src="https://avatars3.githubusercontent.com/u/723360?v=4?s=50" width="50px;" alt="Ianko Leite"/><br /><sub><b>Ianko Leite</b></sub></a><br /><a href="#ideas-ianko" title="Ideas, Planning, & Feedback">🤔</a></td>
      <td align="center" valign="top" width="20%"><a href="https://www.kikt.top"><img src="https://avatars0.githubusercontent.com/u/14145407?v=4?s=50" width="50px;" alt="Caijinglong"/><br /><sub><b>Caijinglong</b></sub></a><br /><a href="https://github.com/fluttertools/fvm/commits?author=CaiJingLong" title="Code">💻</a> <a href="#ideas-CaiJingLong" title="Ideas, Planning, & Feedback">🤔</a></td>
      <td align="center" valign="top" width="20%"><a href="https://juejin.im/user/5bdc1a32518825170b101080"><img src="https://avatars1.githubusercontent.com/u/16477333?v=4?s=50" width="50px;" alt="zmtzawqlp"/><br /><sub><b>zmtzawqlp</b></sub></a><br /><a href="https://github.com/fluttertools/fvm/issues?q=author%3Azmtzawqlp" title="Bug reports">🐛</a></td>
      <td align="center" valign="top" width="20%"><a href="https://github.com/kuhnroyal"><img src="https://avatars3.githubusercontent.com/u/1260818?v=4?s=50" width="50px;" alt="Peter Leibiger"/><br /><sub><b>Peter Leibiger</b></sub></a><br /><a href="https://github.com/fluttertools/fvm/commits?author=kuhnroyal" title="Code">💻</a> <a href="#maintenance-kuhnroyal" title="Maintenance">🚧</a> <a href="#question-kuhnroyal" title="Answering Questions">💬</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="20%"><a href="https://github.com/panthe"><img src="https://avatars0.githubusercontent.com/u/250296?v=4?s=50" width="50px;" alt="Luca Panteghini"/><br /><sub><b>Luca Panteghini</b></sub></a><br /><a href="https://github.com/fluttertools/fvm/commits?author=panthe" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="20%"><a href="https://github.com/davidmartos96"><img src="https://avatars1.githubusercontent.com/u/22084723?v=4?s=50" width="50px;" alt="David Martos"/><br /><sub><b>David Martos</b></sub></a><br /><a href="https://github.com/fluttertools/fvm/commits?author=davidmartos96" title="Code">💻</a> <a href="https://github.com/fluttertools/fvm/commits?author=davidmartos96" title="Tests">⚠️</a> <a href="https://github.com/fluttertools/fvm/commits?author=davidmartos96" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="20%"><a href="https://github.com/svenjacobs"><img src="https://avatars1.githubusercontent.com/u/255313?v=4?s=50" width="50px;" alt="Sven Jacobs"/><br /><sub><b>Sven Jacobs</b></sub></a><br /><a href="https://github.com/fluttertools/fvm/commits?author=svenjacobs" title="Code">💻</a></td>
      <td align="center" valign="top" width="20%"><a href="https://github.com/Cir0X"><img src="https://avatars0.githubusercontent.com/u/4539597?v=4?s=50" width="50px;" alt="Wolfhard Prell"/><br /><sub><b>Wolfhard Prell</b></sub></a><br /><a href="https://github.com/fluttertools/fvm/commits?author=Cir0X" title="Code">💻</a></td>
      <td align="center" valign="top" width="20%"><a href="https://github.com/jascodes"><img src="https://avatars2.githubusercontent.com/u/1231593?v=4?s=50" width="50px;" alt="Jaspreet Singh"/><br /><sub><b>Jaspreet Singh</b></sub></a><br /><a href="#ideas-jascodes" title="Ideas, Planning, & Feedback">🤔</a> <a href="https://github.com/fluttertools/fvm/commits?author=jascodes" title="Code">💻</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="20%"><a href="https://deandreamatias.com/"><img src="https://avatars2.githubusercontent.com/u/21011641?v=4?s=50" width="50px;" alt="Matias de Andrea"/><br /><sub><b>Matias de Andrea</b></sub></a><br /><a href="https://github.com/fluttertools/fvm/commits?author=deandreamatias" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="20%"><a href="https://github.com/znjameswu"><img src="https://avatars2.githubusercontent.com/u/61373469?v=4?s=50" width="50px;" alt="znjameswu"/><br /><sub><b>znjameswu</b></sub></a><br /><a href="https://github.com/fluttertools/fvm/issues?q=author%3Aznjameswu" title="Bug reports">🐛</a></td>
      <td align="center" valign="top" width="20%"><a href="https://github.com/orestesgaolin"><img src="https://avatars3.githubusercontent.com/u/16854239?v=4?s=50" width="50px;" alt="Dominik Roszkowski"/><br /><sub><b>Dominik Roszkowski</b></sub></a><br /><a href="https://github.com/fluttertools/fvm/commits?author=orestesgaolin" title="Documentation">📖</a> <a href="#talk-orestesgaolin" title="Talks">📢</a></td>
      <td align="center" valign="top" width="20%"><a href="https://me.sgr-ksmt.org/"><img src="https://avatars0.githubusercontent.com/u/9350581?v=4?s=50" width="50px;" alt="Suguru Kishimoto"/><br /><sub><b>Suguru Kishimoto</b></sub></a><br /><a href="https://github.com/fluttertools/fvm/issues?q=author%3Asgr-ksmt" title="Bug reports">🐛</a></td>
      <td align="center" valign="top" width="20%"><a href="https://github.com/mx1up"><img src="https://avatars2.githubusercontent.com/u/178714?v=4?s=50" width="50px;" alt="mx1up"/><br /><sub><b>mx1up</b></sub></a><br /><a href="https://github.com/fluttertools/fvm/issues?q=author%3Amx1up" title="Bug reports">🐛</a> <a href="https://github.com/fluttertools/fvm/commits?author=mx1up" title="Code">💻</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="20%"><a href="https://github.com/nank1ro"><img src="https://avatars.githubusercontent.com/u/60045235?v=4?s=50" width="50px;" alt="Alexandru Mariuti"/><br /><sub><b>Alexandru Mariuti</b></sub></a><br /><a href="https://github.com/fluttertools/fvm/commits?author=nank1ro" title="Code">💻</a></td>
      <td align="center" valign="top" width="20%"><a href="https://github.com/andreadelfante"><img src="https://avatars.githubusercontent.com/u/7781176?v=4?s=50" width="50px;" alt="Andrea Del Fante"/><br /><sub><b>Andrea Del Fante</b></sub></a><br /><a href="#ideas-andreadelfante" title="Ideas, Planning, & Feedback">🤔</a> <a href="https://github.com/fluttertools/fvm/commits?author=andreadelfante" title="Code">💻</a></td>
      <td align="center" valign="top" width="20%"><a href="https://github.com/Kavantix"><img src="https://avatars.githubusercontent.com/u/6243755?v=4?s=50" width="50px;" alt="Pieter van Loon"/><br /><sub><b>Pieter van Loon</b></sub></a><br /><a href="https://github.com/fluttertools/fvm/commits?author=Kavantix" title="Code">💻</a> <a href="#ideas-Kavantix" title="Ideas, Planning, & Feedback">🤔</a></td>
      <td align="center" valign="top" width="20%"><a href="https://github.com/YangLang116"><img src="https://avatars.githubusercontent.com/u/15442222?v=4?s=50" width="50px;" alt="Mr Yang"/><br /><sub><b>Mr Yang</b></sub></a><br /><a href="https://github.com/fluttertools/fvm/commits?author=YangLang116" title="Code">💻</a></td>
      <td align="center" valign="top" width="20%"><a href="https://github.com/Saancreed"><img src="https://avatars.githubusercontent.com/u/26201033?v=4?s=50" width="50px;" alt="Krzysztof Bogacki"/><br /><sub><b>Krzysztof Bogacki</b></sub></a><br /><a href="https://github.com/fluttertools/fvm/issues?q=author%3ASaancreed" title="Bug reports">🐛</a> <a href="https://github.com/fluttertools/fvm/commits?author=Saancreed" title="Code">💻</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="20%"><a href="https://github.com/ened"><img src="https://avatars.githubusercontent.com/u/269860?v=4?s=50" width="50px;" alt="Sebastian Roth"/><br /><sub><b>Sebastian Roth</b></sub></a><br /><a href="https://github.com/fluttertools/fvm/commits?author=ened" title="Code">💻</a> <a href="#ideas-ened" title="Ideas, Planning, & Feedback">🤔</a></td>
      <td align="center" valign="top" width="20%"><a href="https://github.com/taras"><img src="https://avatars.githubusercontent.com/u/74687?v=4?s=50" width="50px;" alt="Taras Mankovski"/><br /><sub><b>Taras Mankovski</b></sub></a><br /><a href="#infra-taras" title="Infrastructure (Hosting, Build-Tools, etc)">🚇</a> <a href="#ideas-taras" title="Ideas, Planning, & Feedback">🤔</a></td>
      <td align="center" valign="top" width="20%"><a href="https://github.com/jmewes"><img src="https://avatars.githubusercontent.com/u/5235584?v=4?s=50" width="50px;" alt="Jan Mewes"/><br /><sub><b>Jan Mewes</b></sub></a><br /><a href="https://github.com/fluttertools/fvm/commits?author=jmewes" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="20%"><a href="https://permanent.ee"><img src="https://avatars.githubusercontent.com/u/740826?v=4?s=50" width="50px;" alt="Allan Laal"/><br /><sub><b>Allan Laal</b></sub></a><br /><a href="https://github.com/fluttertools/fvm/commits?author=allanlaal" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="20%"><a href="https://github.com/rhalff"><img src="https://avatars.githubusercontent.com/u/274358?v=4?s=50" width="50px;" alt="Rob Halff"/><br /><sub><b>Rob Halff</b></sub></a><br /><a href="https://github.com/fluttertools/fvm/commits?author=rhalff" title="Documentation">📖</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="20%"><a href="https://sharezone.net"><img src="https://avatars.githubusercontent.com/u/24459435?v=4?s=50" width="50px;" alt="Nils Reichardt"/><br /><sub><b>Nils Reichardt</b></sub></a><br /><a href="#infra-nilsreichardt" title="Infrastructure (Hosting, Build-Tools, etc)">🚇</a> <a href="https://github.com/fluttertools/fvm/commits?author=nilsreichardt" title="Code">💻</a> <a href="https://github.com/fluttertools/fvm/commits?author=nilsreichardt" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="20%"><a href="https://rcjuancarlosuwu.medium.com"><img src="https://avatars.githubusercontent.com/u/67658540?v=4?s=50" width="50px;" alt="Juan Carlos Ramón Condezo"/><br /><sub><b>Juan Carlos Ramón Condezo</b></sub></a><br /><a href="https://github.com/fluttertools/fvm/commits?author=rcjuancarlosuwu" title="Documentation">📖</a> <a href="#translation-rcjuancarlosuwu" title="Translation">🌍</a></td>
      <td align="center" valign="top" width="20%"><a href="https://github.com/zeshuaro"><img src="https://avatars.githubusercontent.com/u/12210067?v=4?s=50" width="50px;" alt="zeshuaro"/><br /><sub><b>zeshuaro</b></sub></a><br /><a href="https://github.com/fluttertools/fvm/commits?author=zeshuaro" title="Code">💻</a></td>
      <td align="center" valign="top" width="20%"><a href="https://github.com/ziehlke"><img src="https://avatars.githubusercontent.com/u/10786117?v=4?s=50" width="50px;" alt="ziehlke"/><br /><sub><b>ziehlke</b></sub></a><br /><a href="https://github.com/fluttertools/fvm/commits?author=ziehlke" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="20%"><a href="https://github.com/fpinzn"><img src="https://avatars.githubusercontent.com/u/345207?v=4?s=50" width="50px;" alt="Francisco Pinzón"/><br /><sub><b>Francisco Pinzón</b></sub></a><br /><a href="https://github.com/fluttertools/fvm/commits?author=fpinzn" title="Documentation">📖</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="20%"><a href="http://thorgalle.me"><img src="https://avatars.githubusercontent.com/u/11543641?v=4?s=50" width="50px;" alt="Thor Galle"/><br /><sub><b>Thor Galle</b></sub></a><br /><a href="https://github.com/fluttertools/fvm/commits?author=th0rgall" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="20%"><a href="https://www.linkedin.com/in/giuseppe-cianci/"><img src="https://avatars.githubusercontent.com/u/39117631?v=4?s=50" width="50px;" alt="Giuseppe Cianci"/><br /><sub><b>Giuseppe Cianci</b></sub></a><br /><a href="https://github.com/fluttertools/fvm/commits?author=Giuspepe" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="20%"><a href="https://shreyam.ml"><img src="https://avatars.githubusercontent.com/u/38105595?v=4?s=50" width="50px;" alt="Shreyam Maity"/><br /><sub><b>Shreyam Maity</b></sub></a><br /><a href="https://github.com/fluttertools/fvm/commits?author=ShreyamMaity" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="20%"><a href="https://github.com/BrianRigii"><img src="https://avatars.githubusercontent.com/u/51914354?v=4?s=50" width="50px;" alt="John Brian"/><br /><sub><b>John Brian</b></sub></a><br /><a href="https://github.com/fluttertools/fvm/commits?author=BrianRigii" title="Documentation">📖</a></td>
    </tr>
  </tbody>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->
