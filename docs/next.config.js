const path = require("path");
const CopyPlugin = require("copy-webpack-plugin");
const withNextra = require("nextra")({
  theme: "nextra-theme-docs",
  themeConfig: "./theme.config.tsx",
});

module.exports = withNextra({
  reactStrictMode: true,
  webpack: (config, options) => {
    config.plugins.push(new CopyPlugin({
      patterns: [
        { from: "../scripts/install.sh", to: path.resolve(__dirname, "public") },
        { from: "../scripts/uninstall.sh", to: path.resolve(__dirname, "public") },
      ],
    }));
    return config
  },
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
    ];
  },
});
