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
    ];
  },
});
