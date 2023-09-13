import Link from "@docusaurus/Link";
import Translate from "@docusaurus/Translate";
import useDocusaurusContext from "@docusaurus/useDocusaurusContext";
import Layout from "@theme/Layout";
import clsx from "clsx";
import React from "react";

import GithubStartButton from "../components/GithubStarButton";
import HomepageFeatures from "../components/HomepageFeatures";
import { InstallationTabs } from "../components/InstallationTabs";
import MainHeading from "../components/MainHeading";
import TwitterButton from "../components/TwitterButton";
import styles from "./index.module.css";

function HomepageHeader() {
  const { siteConfig } = useDocusaurusContext();
  return (
    <header className={clsx("hero hero--dark", styles.heroBanner)}>
      <div className="container">
        <h1 className="hero__title">{siteConfig.title}</h1>
        <p className="hero__subtitle">
          <Translate id="home.tagline">
            A simple CLI to manage Flutter SDK versions.
          </Translate>
        </p>

        <div className={styles.buttons}>
          <GithubStartButton />
          <Spacer />
          <Link href="https://pub.dev/packages/fvm">
            <img
              alt="Pub Likes"
              src="https://img.shields.io/pub/likes/fvm?style=for-the-badge&logo=flutter&logoColor=%2358CDFA&label=Pub%20Likes&labelColor=white&color=%2358CDFA"
            />
          </Link>
          <Spacer />
          <Link href="https://github.com/leoafarias/fvm/graphs/contributors">
            <img src="https://img.shields.io/github/all-contributors/leoafarias/fvm?style=for-the-badge" />
          </Link>
          <TwitterButton />
        </div>
        <Spacer />
        <Spacer />
        <div className={styles.buttons}>
          <Link
            className="button button--secondary button--lg"
            to="/docs/getting_started/overview"
          >
            <Translate id="home.get_started">Getting Started</Translate>
          </Link>
        </div>
      </div>
      <InstallationTabs />
    </header>
  );
}

function Spacer() {
  return <div style={{ width: "10px", height: "10px" }}></div>;
}

export default function Home() {
  const { siteConfig } = useDocusaurusContext();
  return (
    <Layout title="fvm" description={`${siteConfig.tagline}`}>
      <MainHeading />
      <main>
        <HomepageFeatures />
      </main>
    </Layout>
  );
}
