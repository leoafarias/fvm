# fvm

![GitHub stars](https://img.shields.io/github/stars/leoafarias/fvm?style=social)
[![Pub Version](https://img.shields.io/pub/v/fvm?label=version&style=flat-square)](https://pub.dev/packages/fvm/changelog)
![Pub Likes](https://img.shields.io/pub/likes/fvm?label=Pub%20Likes&style=flat-squar)
![Pub Points](https://img.shields.io/pub/points/fvm?label=Pub%20Points&style=flat-squar)  ![Coverage](https://raw.githubusercontent.com/leoafarias/fvm/master/coverage_badge.svg?sanitize=true)
[![Github All Contributors](https://img.shields.io/github/all-contributors/leoafarias/fvm?style=flat-square)](https://github.com/leoafarias/fvm/graphs/contributors) [![MIT Licence](https://img.shields.io/github/license/leoafarias/fvm?style=flat-square&longCache=true)](https://opensource.org/licenses/mit-license.php) [![Awesome Flutter](https://img.shields.io/badge/awesome-flutter-purple?longCache=true&style=flat-square)](https://github.com/Solido/awesome-flutter)

Flutter Version Management (FVM): A simple CLI tool to manage Flutter SDK versions.

FVM helps with the need for consistent app builds by allowing to reference a Flutter SDK version used on a per-project basis. It also allows you to have multiple Flutter versions installed to quickly validate and test upcoming Flutter releases with your apps, without waiting for Flutter installation every time.

**Features:**

- Configure and use any Flutter SDK version per project.
- Ability to install and locally cache multiple Flutter SDK versions.
- Fast switch between Flutter channels and SDK versions.
- Dynamic Flutter SDK paths for IDE debugging support.
- Version FVM config with your project for consistency across teams and CI environments.

For more information, read [FVM documentation](https://fvm.app).

---

Checkout Flutter Sidekick. [Read more about it here.](https://github.com/leoafarias/sidekick)

[![FVM App Screenshot](https://raw.githubusercontent.com/leoafarias/sidekick/main/assets/promo-gh/screenshot.png)](https://github.com/leoafarias/sidekick)

## Working with this repo

### Tests

```bash
pub run test
```

### Publishing the package

Before pushing the package to [pub.dev](https://pub.dev), run the following command to create a version constant:

```bash
pub run build_runner build
```

## Troubleshooting

Please view our [FAQ](https://fvm.app/docs/guides/faq).

## License

This project is licensed under the MIT License; see [LICENSE](LICENSE) file for details.

## Contributors ✨

A sincere thank you goes to these wonderful people ([emoji key](https://allcontributors.org/docs/en/emoji-key)):

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
      <td align="center" valign="top" width="20%"><a href="https://jns.io/"><img src="https://avatars.githubusercontent.com/u/720469?v=4?s=50" width="50px;" alt="Niklas Schulze"/><br /><sub><b>Niklas Schulze</b></sub></a><br /><a href="https://github.com/fluttertools/fvm/commits?author=jnschulze" title="Code">💻</a> <a href="#ideas-jnschulze" title="Ideas, Planning, & Feedback">🤔</a> <a href="https://github.com/fluttertools/fvm/issues?q=author%3Ajnschulze" title="Bug reports">🐛</a></td>
      <td align="center" valign="top" width="20%"><a href="https://github.com/gonzalogauto"><img src="https://avatars.githubusercontent.com/u/44684314?v=4?s=50" width="50px;" alt="Gonzalo Gauto"/><br /><sub><b>Gonzalo Gauto</b></sub></a><br /><a href="#ideas-gonzalogauto" title="Ideas, Planning, & Feedback">🤔</a> <a href="https://github.com/fluttertools/fvm/commits?author=gonzalogauto" title="Code">💻</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="20%"><a href="https://www.etiennetheodore.com/"><img src="https://avatars.githubusercontent.com/u/8250175?v=4?s=50" width="50px;" alt="Etienne Théodore"/><br /><sub><b>Etienne Théodore</b></sub></a><br /><a href="https://github.com/fluttertools/fvm/commits?author=Kiruel" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="20%"><a href="https://github.com/BrianRigii"><img src="https://avatars.githubusercontent.com/u/51914354?v=4?s=50" width="50px;" alt="John Brian"/><br /><sub><b>John Brian</b></sub></a><br /><a href="https://github.com/fluttertools/fvm/commits?author=BrianRigii" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="20%"><a href="https://github.com/bryanoltman"><img src="https://avatars.githubusercontent.com/u/581764?v=4?s=50" width="50px;" alt="Bryan Oltman"/><br /><sub><b>Bryan Oltman</b></sub></a><br /><a href="https://github.com/fluttertools/fvm/commits?author=bryanoltman" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="20%"><a href="https://github.com/Inlesco"><img src="https://avatars.githubusercontent.com/u/5101235?v=4?s=50" width="50px;" alt="Dovydas Stepona"/><br /><sub><b>Dovydas Stepona</b></sub></a><br /><a href="https://github.com/fluttertools/fvm/commits?author=Inlesco" title="Documentation">📖</a></td>
    </tr>
  </tbody>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/all-contributors/all-contributors) specification. Contributions of any kind are very welcome!
