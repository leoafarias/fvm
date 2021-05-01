import Link from "@docusaurus/Link";
import useDocusaurusContext from "@docusaurus/useDocusaurusContext";
import Layout from "@theme/Layout";
import clsx from "clsx";
import React from "react";
import GitHubButton from "react-github-btn";
import { Follow } from "react-twitter-widgets";
import HomepageFeatures from "../components/HomepageFeatures";
import styles from "./index.module.css";

function HomepageHeader() {
  const { siteConfig } = useDocusaurusContext();
  return (
    <header className={clsx("hero hero--dark", styles.heroBanner)}>
      <div className="container">
        <h1 className="hero__title">{siteConfig.title}</h1>
        <p className="hero__subtitle">{siteConfig.tagline}</p>

        <div className={styles.buttons}>
          <GitHubStarButton />
          <Spacer />
          <Link to="https://pub.dev/packages/fvm">
            <img src="https://img.shields.io/badge/dynamic/json?color=blue&label=Pub Likes&query=likes&url=http://www.pubscore.gq/likes?package=fvm&style=for-the-badge&cacheSeconds=90000" />
          </Link>
          <Spacer />
          <Link to="https://github.com/leoafarias/fvm/graphs/contributors">
            <img src="https://img.shields.io/github/all-contributors/leoafarias/fvm?style=for-the-badge" />
          </Link>
          <Spacer />
          <TwitterButton />
        </div>
        <Spacer />
        <Spacer />
        <div className={styles.buttons}>
          <Link
            className="button button--secondary button--lg"
            to="/docs/getting_started/overview"
          >
            Getting Started
          </Link>
        </div>
      </div>
    </header>
  );
}

function Spacer() {
  return <div style={{ width: "10px", height: "10px" }}></div>;
}

function TwitterButton() {
  return (
    <Follow
      username="leoafarias"
      options={{
        dnt: true,
        size: "large",
        showCount: false,
        showScreenName: false,
      }}
    />
  );
}

function GitHubStarButton() {
  return (
    <div className="github-button">
      <GitHubButton
        href="https://github.com/leoafarias/fvm"
        data-show-count="true"
        data-size="large"
        aria-label="Star leoafarias/fvm on GitHub"
      >
        Star
      </GitHubButton>
    </div>
  );
}

export default function Home() {
  const { siteConfig } = useDocusaurusContext();
  return (
    <Layout title="fvm" description={`${siteConfig.tagline}`}>
      <HomepageHeader />
      <main>
        <HomepageFeatures />
      </main>
    </Layout>
  );
}
