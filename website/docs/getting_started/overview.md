---
id: overview
title: Overview
sidebar_position: 0
---

FVM helps with the need for consistent app builds by referencing the Flutter SDK version used on a per-project basis. It also allows you to have multiple Flutter versions installed to quickly validate and test upcoming Flutter releases with your apps without waiting for Flutter installation every time.

## Motivation

- We need to have more than one Flutter SDK at a time.
- Testing new SDK features requires switching between [Channels](https://flutter.dev/docs/development/tools/sdk/releases)
- The switch between channels is slow and requires reinstalling every time.
- No way of keeping track of the latest working/used version of the SDK in an app.
- Major Flutter updates require migration of all Flutter apps in the machine.
- Inconsistent development environments between other devs in the team.

## Video Guides & Walkthroughs

You can view a playlist of many Youtube guides & walkthroughs done by the incredible Flutter community in many different languages.

<iframe width="560" height="315" src="https://www.youtube.com/embed/videoseries?list=PLVnlSO6aQelAAddOFQVJNoaRGZ1mMsj2Q" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

## Principles

We follow these principles when building and adding new features to FVM.

- Always use Flutter tools when interacting with the SDK
- Do not override any Flutter CLI commands.
- Follow Flutter suggested installation instructions accomplish caching.
- Should extend Flutter behavior and not modify them.
- API should be simple and easy to understand.

## Contributors

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tr>
    <td align="center"><a href="https://github.com/leoafarias"><img src="https://avatars1.githubusercontent.com/u/435833?v=4?s=50" width="50px;" alt=""/><br /><sub><b>Leo Farias</b></sub></a><br /><a href="https://github.com/leoafarias/fvm/commits?author=leoafarias" title="Documentation">📖</a> <a href="#ideas-leoafarias" title="Ideas, Planning, & Feedback">🤔</a> <a href="https://github.com/leoafarias/fvm/commits?author=leoafarias" title="Code">💻</a> <a href="#example-leoafarias" title="Examples">💡</a> <a href="https://github.com/leoafarias/fvm/pulls?q=is%3Apr+reviewed-by%3Aleoafarias" title="Reviewed Pull Requests">👀</a> <a href="#maintenance-leoafarias" title="Maintenance">🚧</a> <a href="#infra-leoafarias" title="Infrastructure (Hosting, Build-Tools, etc)">🚇</a></td>
    <td align="center"><a href="https://github.com/ianko"><img src="https://avatars3.githubusercontent.com/u/723360?v=4?s=50" width="50px;" alt=""/><br /><sub><b>Ianko Leite</b></sub></a><br /><a href="#ideas-ianko" title="Ideas, Planning, & Feedback">🤔</a></td>
    <td align="center"><a href="https://www.kikt.top"><img src="https://avatars0.githubusercontent.com/u/14145407?v=4?s=50" width="50px;" alt=""/><br /><sub><b>Caijinglong</b></sub></a><br /><a href="https://github.com/leoafarias/fvm/commits?author=CaiJingLong" title="Code">💻</a> <a href="#ideas-CaiJingLong" title="Ideas, Planning, & Feedback">🤔</a></td>
    <td align="center"><a href="https://juejin.im/user/5bdc1a32518825170b101080"><img src="https://avatars1.githubusercontent.com/u/16477333?v=4?s=50" width="50px;" alt=""/><br /><sub><b>zmtzawqlp</b></sub></a><br /><a href="https://github.com/leoafarias/fvm/issues?q=author%3Azmtzawqlp" title="Bug reports">🐛</a></td>
    <td align="center"><a href="https://github.com/kuhnroyal"><img src="https://avatars3.githubusercontent.com/u/1260818?v=4?s=50" width="50px;" alt=""/><br /><sub><b>Peter Leibiger</b></sub></a><br /><a href="https://github.com/leoafarias/fvm/commits?author=kuhnroyal" title="Code">💻</a> <a href="#maintenance-kuhnroyal" title="Maintenance">🚧</a> <a href="#question-kuhnroyal" title="Answering Questions">💬</a></td>
  </tr>
  <tr>
    <td align="center"><a href="https://github.com/panthe"><img src="https://avatars0.githubusercontent.com/u/250296?v=4?s=50" width="50px;" alt=""/><br /><sub><b>Luca Panteghini</b></sub></a><br /><a href="https://github.com/leoafarias/fvm/commits?author=panthe" title="Documentation">📖</a></td>
    <td align="center"><a href="https://github.com/davidmartos96"><img src="https://avatars1.githubusercontent.com/u/22084723?v=4?s=50" width="50px;" alt=""/><br /><sub><b>David Martos</b></sub></a><br /><a href="https://github.com/leoafarias/fvm/commits?author=davidmartos96" title="Code">💻</a> <a href="https://github.com/leoafarias/fvm/commits?author=davidmartos96" title="Tests">⚠️</a> <a href="https://github.com/leoafarias/fvm/commits?author=davidmartos96" title="Documentation">📖</a></td>
    <td align="center"><a href="https://github.com/svenjacobs"><img src="https://avatars1.githubusercontent.com/u/255313?v=4?s=50" width="50px;" alt=""/><br /><sub><b>Sven Jacobs</b></sub></a><br /><a href="https://github.com/leoafarias/fvm/commits?author=svenjacobs" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/Cir0X"><img src="https://avatars0.githubusercontent.com/u/4539597?v=4?s=50" width="50px;" alt=""/><br /><sub><b>Wolfhard Prell</b></sub></a><br /><a href="https://github.com/leoafarias/fvm/commits?author=Cir0X" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/jascodes"><img src="https://avatars2.githubusercontent.com/u/1231593?v=4?s=50" width="50px;" alt=""/><br /><sub><b>Jaspreet Singh</b></sub></a><br /><a href="#ideas-jascodes" title="Ideas, Planning, & Feedback">🤔</a> <a href="https://github.com/leoafarias/fvm/commits?author=jascodes" title="Code">💻</a></td>
  </tr>
  <tr>
    <td align="center"><a href="https://deandreamatias.com/"><img src="https://avatars2.githubusercontent.com/u/21011641?v=4?s=50" width="50px;" alt=""/><br /><sub><b>Matias de Andrea</b></sub></a><br /><a href="https://github.com/leoafarias/fvm/commits?author=deandreamatias" title="Documentation">📖</a></td>
    <td align="center"><a href="https://github.com/znjameswu"><img src="https://avatars2.githubusercontent.com/u/61373469?v=4?s=50" width="50px;" alt=""/><br /><sub><b>znjameswu</b></sub></a><br /><a href="https://github.com/leoafarias/fvm/issues?q=author%3Aznjameswu" title="Bug reports">🐛</a></td>
    <td align="center"><a href="https://github.com/orestesgaolin"><img src="https://avatars3.githubusercontent.com/u/16854239?v=4?s=50" width="50px;" alt=""/><br /><sub><b>Dominik Roszkowski</b></sub></a><br /><a href="https://github.com/leoafarias/fvm/commits?author=orestesgaolin" title="Documentation">📖</a> <a href="#talk-orestesgaolin" title="Talks">📢</a></td>
    <td align="center"><a href="https://me.sgr-ksmt.org/"><img src="https://avatars0.githubusercontent.com/u/9350581?v=4?s=50" width="50px;" alt=""/><br /><sub><b>Suguru Kishimoto</b></sub></a><br /><a href="https://github.com/leoafarias/fvm/issues?q=author%3Asgr-ksmt" title="Bug reports">🐛</a></td>
    <td align="center"><a href="https://github.com/mx1up"><img src="https://avatars2.githubusercontent.com/u/178714?v=4?s=50" width="50px;" alt=""/><br /><sub><b>mx1up</b></sub></a><br /><a href="https://github.com/leoafarias/fvm/issues?q=author%3Amx1up" title="Bug reports">🐛</a> <a href="https://github.com/leoafarias/fvm/commits?author=mx1up" title="Code">💻</a></td>
  </tr>
  <tr>
    <td align="center"><a href="https://github.com/nank1ro"><img src="https://avatars.githubusercontent.com/u/60045235?v=4?s=50" width="50px;" alt=""/><br /><sub><b>Alexandru Mariuti</b></sub></a><br /><a href="https://github.com/leoafarias/fvm/commits?author=nank1ro" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/andreadelfante"><img src="https://avatars.githubusercontent.com/u/7781176?v=4?s=50" width="50px;" alt=""/><br /><sub><b>Andrea Del Fante</b></sub></a><br /><a href="#ideas-andreadelfante" title="Ideas, Planning, & Feedback">🤔</a> <a href="https://github.com/leoafarias/fvm/commits?author=andreadelfante" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/Kavantix"><img src="https://avatars.githubusercontent.com/u/6243755?v=4?s=50" width="50px;" alt=""/><br /><sub><b>Pieter van Loon</b></sub></a><br /><a href="https://github.com/leoafarias/fvm/commits?author=Kavantix" title="Code">💻</a> <a href="#ideas-Kavantix" title="Ideas, Planning, & Feedback">🤔</a></td>
    <td align="center"><a href="https://github.com/YangLang116"><img src="https://avatars.githubusercontent.com/u/15442222?v=4?s=50" width="50px;" alt=""/><br /><sub><b>Mr Yang</b></sub></a><br /><a href="https://github.com/leoafarias/fvm/commits?author=YangLang116" title="Code">💻</a></td>
    <td align="center"><a href="https://github.com/Saancreed"><img src="https://avatars.githubusercontent.com/u/26201033?v=4?s=50" width="50px;" alt=""/><br /><sub><b>Krzysztof Bogacki</b></sub></a><br /><a href="https://github.com/leoafarias/fvm/issues?q=author%3ASaancreed" title="Bug reports">🐛</a> <a href="https://github.com/leoafarias/fvm/commits?author=Saancreed" title="Code">💻</a></td>
  </tr>
  <tr>
    <td align="center"><a href="https://github.com/ened"><img src="https://avatars.githubusercontent.com/u/269860?v=4?s=50" width="50px;" alt=""/><br /><sub><b>Sebastian Roth</b></sub></a><br /><a href="https://github.com/leoafarias/fvm/commits?author=ened" title="Code">💻</a> <a href="#ideas-ened" title="Ideas, Planning, & Feedback">🤔</a></td>
    <td align="center"><a href="https://github.com/taras"><img src="https://avatars.githubusercontent.com/u/74687?v=4?s=50" width="50px;" alt=""/><br /><sub><b>Taras Mankovski</b></sub></a><br /><a href="#infra-taras" title="Infrastructure (Hosting, Build-Tools, etc)">🚇</a> <a href="#ideas-taras" title="Ideas, Planning, & Feedback">🤔</a></td>
    <td align="center"><a href="http://www.experimental-software.com"><img src="https://avatars.githubusercontent.com/u/5235584?v=4?s=50" width="50px;" alt=""/><br /><sub><b>Jan Mewes</b></sub></a><br /><a href="https://github.com/leoafarias/fvm/commits?author=jmewes" title="Documentation">📖</a></td>
  </tr>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->
