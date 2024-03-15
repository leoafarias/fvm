const withNextra = require("nextra")({
  theme: "nextra-theme-docs",
  themeConfig: "./theme.config.tsx",
});

module.exports = withNextra({
  reactStrictMode: true,

  async redirects() {
    return [
      {
        source: "/docs",
        destination: "/documentation/getting-started",
        permanent: true,
      },
      {
        source: "/documentation",
        destination: "/documentation/getting-started",
        permanent: true,
      },
      {
        source: "/docs/guides/faq",
        destination: "/documentation/getting-started/faq",
        permanent: true,
      },
      {
        source: "/docs/guides/global_version",
        destination: "/documentation/guides/global-configuration",
        permanent: true,
      },
      {
        source: "/documentation/advanced/custom-version",
        destination: "/documentation/guides/custom-version",
        permanent: true,
      },

      {
        source: "/documentation/advanced/release-multiple-channels",
        destination: "/documentation/guides/release-multiple-channels",
        permanent: true,
      },
    ];
  },
});
