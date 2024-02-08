import { DocsThemeConfig } from "nextra-theme-docs";
import Logo from "./components/Logo";

const config: DocsThemeConfig = {
  logo: (
    <>
      <Logo />
      FVM
    </>
  ),
  project: {
    link: "https://github.com/leoafarias/fvm",
  },
  docsRepositoryBase: "https://github.com/leoafarias/fvm/tree/main/docs",
  footer: {
    text: "Copyright © 2023 Leo Farias.",
  },
  search: {
    placeholder: "Search Documentation...",
  },
  useNextSeoProps() {
    return {
      titleTemplate: "%s – FVM - Flutter Version Management",
      twitter: {
        cardType: "summary_large_image",
        handle: "@leoafarias",
        site: "https://fvm.app",
      },
      additionalMetaTags: [
        { name: "twitter:dnt", content: "on" },
        { name: "twitter:widgets:theme", content: "dark" },
      ],
    };
  },
  darkMode: false,
  nextThemes: {
    defaultTheme: "dark",
    forcedTheme: "dark",
  },
  // i18n: [{ locale: "en", text: "English" }],
};

export default config;
