/** @type {import('@docusaurus/types').DocusaurusConfig} */
module.exports = {
  title: 'Flutter Version Management (fvm)',
  tagline: 'A simple CLI to manage Flutter SDK versions.',
  url: 'https://fvm.app',
  baseUrl: '/',
  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',
  favicon: 'img/favicon.ico',
  organizationName: 'leoafarias', // Usually your GitHub org/user name.
  projectName: 'fvm', // Usually your repo name.
  themeConfig: {
    sidebarCollapsible: false,
    navbar: {
      title: 'fvm',
      logo: {
        alt: 'FVM Logo',
        src: 'img/logo.svg',
      },
      items: [
        
        {
          type: 'doc',
          docId: 'getting_started/overview',
          position: 'right',
          label: 'Getting Started',
        },
        {
          type: 'doc',
          docId: 'guides/basic_commands',
          position: 'right',
          label: 'Guides',
        },
        {
          href: 'https://github.com/leoafarias/fvm',
          label: 'GitHub',
          position: 'right',
        },

      ],
    },
    footer: {
      // style: 'dark',
      links: [
        {
          title: 'Docs',
          items: [
            {
              label: 'Getting Started',
              to: '/docs/getting_started/overview',
            },

            {
              label: 'Guides',
              to: '/docs/guides/basic_commands',
            },

            {
              label: 'Advanced',
              to: '/docs/advanced/custom_version',
            },
          ],
        },
        {
          title: 'Info',
          items: [
            {
              label: 'Bugs & Issues',
              href: 'https://github.com/leoafarias/fvm/issues',
            },
            {
              label: 'GUI for FVM',
              href: 'https://github.com/leoafarias/sidekick',
            },
          
          ],
        },
        {
          title: 'Links',
          items: [
          
            {
              label: 'Twitter',
              href: 'https://twitter.com/leoafarias',
            },

            {
              label: 'GitHub',
              href: 'https://github.com/facebook/docusaurus',
            },
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} Leo Farias. `,
    },
  },
  presets: [
    [
      '@docusaurus/preset-classic',
      {
        docs: {
          sidebarPath: require.resolve('./sidebars.js'),
          // Please change this to your repo.
          editUrl:
            'https://github.com/leoafarias/fvm/edit/master/doc/',
        },
        blog: {
          showReadingTime: true,
          // Please change this to your repo.
          editUrl:
            'https://github.com/leoafarias/fvm/edit/master/doc/blog/',
        },
        theme: {
          customCss: require.resolve('./src/css/custom.css'),
        },
      },
    ],
  ],
};
