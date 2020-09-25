import React from "react";
import clsx from "clsx";
import Layout from "@theme/Layout";
import Link from "@docusaurus/Link";
import useDocusaurusContext from "@docusaurus/useDocusaurusContext";
import useBaseUrl from "@docusaurus/useBaseUrl";
import styles from "./styles.module.css";

const features = [
  {
    title: "Multiple Flutter SDK Versions",
    imageUrl: "img/multiple_versions.svg",
    description: (
      <>
        Ability to install and cache multiple Flutter SDK Versions. Fast
        switching between channels & releases. Search available channels &
        releases. Remove unused SDK versions.
      </>
    ),
  },
  {
    title: "Version SDK per Project",
    imageUrl: "img/project_version.svg",
    description: (
      <>
        Configure and use Flutter SDK version per project. Dynamic SDK paths for
        IDE debugging support. Allows for consistency across teams and CI
        environments.
      </>
    ),
  },
  {
    title: "GUI & CLI",
    imageUrl: "img/gui_cli.svg",
    description: (
      <>
        Flutter & Dart allows for full compatibility between the command-line
        tool and the graphical user interface while being cross platform.
      </>
    ),
  },
];

function Feature({ imageUrl, title, description }) {
  const imgUrl = useBaseUrl(imageUrl);
  return (
    <div className={clsx("col col--4", styles.feature)}>
      {imgUrl && (
        <div className="text--left">
          <img className={styles.featureImage} src={imgUrl} alt={title} />
        </div>
      )}
      <p></p>
      <h3>{title}</h3>
      <p>{description}</p>
    </div>
  );
}

function Home() {
  const context = useDocusaurusContext();
  const { siteConfig = {} } = context;
  return (
    <Layout
      title={`Hello from ${siteConfig.title}`}
      description="Description will go into a meta tag in <head />"
    >
      <header className={clsx("hero hero--primary", styles.heroBanner)}>
        <div className="container">
          <h1 className="hero__title">{siteConfig.title}</h1>
          <p className="hero__subtitle">{siteConfig.tagline}</p>
          <div className={styles.buttons}>
            <Link
              className={clsx(
                "button button--outline button--secondary button--lg",
                styles.getStarted
              )}
              to={useBaseUrl("docs/")}
            >
              Get Started
            </Link>
          </div>
        </div>
      </header>
      <main>
        {features && features.length > 0 && (
          <section className={styles.features}>
            <div className="container">
              <div className="row">
                {features.map((props, idx) => (
                  <Feature key={idx} {...props} />
                ))}
              </div>
            </div>
          </section>
        )}
      </main>
    </Layout>
  );
}

export default Home;
