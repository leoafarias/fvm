/** @type {import('@docusaurus/types').DocusaurusConfig} */
module.exports = {
  title: "Flutter Version Management",
  tagline: "A simple CLI to manage Flutter SDK versions.",
  url: "https://fvm.app",
  baseUrl: "/",
  onBrokenLinks: "throw",
  onBrokenMarkdownLinks: "warn",
  favicon: "img/favicon.ico",
  organizationName: "leoafarias", // Usually your GitHub org/user name.
  projectName: "FVM", // Usually your repo name.

  i18n: {
    defaultLocale: "en",
    locales: ["en", "es"],
  },
  themeConfig: {
    algolia: {
      appId: "NHQT1G41IK",
      apiKey: "b07d9adbf54ef4306a11233dd605d924",
      indexName: "fvm",
    },
    colorMode: {
      defaultMode: "dark",
      disableSwitch: true,
      respectPrefersColorScheme: false,
    },

    image: "img/share-image.png",

    announcementBar: {
      id: "support_us", // Any value that will identify this message.
      content:
        "⭐ If you like FVM, give it a star on <a target='_blank' rel='noopener noreferrer' href='https://github.com/leoafarias/fvm'>GitHub</a> ⭐",
      backgroundColor: "#fff", // Defaults to `#fff`.
      textColor: "#000", // Defaults to `#000`.
      isCloseable: true,
    },
    navbar: {
      title: "FVM",
      logo: {
        alt: "FVM Logo",
        src: "img/logo.svg",
      },
      items: [
        {
          type: "doc",
          docId: "getting_started/overview",
          position: "right",
          label: "Getting Started",
        },
        {
          type: "doc",
          docId: "guides/basic_commands",
          position: "right",
          label: "Guides",
        },
        {
          type: "localeDropdown",
          position: "right",
        },
        {
          type: "search",
          position: "right",
        },
        {
          href: "https://github.com/leoafarias/fvm",
          label: "GitHub",
          position: "right",
        },
      ],
    },
    footer: {
      // style: 'dark',
      links: [
        {
          title: "Docs",
          items: [
            {
              label: "Getting Started",
              to: "/docs/getting_started/overview",
            },

            {
              label: "Guides",
              to: "/docs/guides/basic_commands",
            },

            {
              label: "Advanced",
              to: "/docs/advanced/custom_version",
            },
          ],
        },
        {
          title: "Info",
          items: [
            {
              label: "Bugs & Issues",
              href: "https://github.com/leoafarias/fvm/issues",
            },
            {
              label: "GUI for FVM",
              href: "https://github.com/leoafarias/sidekick",
            },
          ],
        },
        {
          title: "Links",
          items: [
            {
              label: "Twitter",
              href: "https://twitter.com/leoafarias",
            },

            {
              label: "GitHub",
              href: "https://github.com/leoafarias/fvm",
            },
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} Leo Farias. `,
    },
  },
  presets: [
    [
      "@docusaurus/preset-classic",
      {
        docs: {
          editLocalizedFiles: true,
          sidebarCollapsible: false,
          sidebarPath: require.resolve("./sidebars.js"),
          editUrl: "https://github.com/fluttertools/fvm/edit/main/website/",
        },
        googleAnalytics: {
          trackingID: "UA-175155757-1",
          anonymizeIP: true, // Should IPs be anonymized?
        },
        blog: {
          showReadingTime: true,
          // Please change this to your repo.
          editUrl: "https://github.com/fluttertools/fvm/edit/main/doc/blog/",
        },
        theme: {
          customCss: require.resolve("./src/css/custom.css"),
        },
      },
    ],
  ],
};
