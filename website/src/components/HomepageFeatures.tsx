import clsx from "clsx";
import React from "react";
import styles from "./HomepageFeatures.module.css";

const FeatureList = [
  {
    title: "Multiple Flutter SDKs",
    Svg: require("../../static/img/multiple_versions.svg").default,
    description: (
      <>
        Ability to manage and cache multiple Flutter SDK Versions. Fast
        switching between channels & releases. View available channels &
        releases.
      </>
    ),
  },
  {
    title: "Project Versioning",
    Svg: require("../../static/img/project_versioning.svg").default,
    description: (
      <>
        Configure and use Flutter SDK version per project. Dynamic SDK paths for
        IDE debugging support. Allows for consistency across teams and CI
        environments.
      </>
    ),
  },
  {
    title: "Advanced Tooling",
    Svg: require("../../static/img/advanced_tooling.svg").default,
    description: (
      <>
        Manage global Flutter SDK version. Spawn processes in any Flutter SDK
        version. Docker images for CI & dev workflow. Install Flutter from
        specific commits.
      </>
    ),
  },
];

function Feature({ Svg, title, description }) {
  return (
    <div className={clsx("col col--4")}>
      <div className="text--center">
        <Svg
          className={styles.featureSvg}
          alt={title}
          style={{ width: 50, height: 50 }}
        />
      </div>

      <div className="text--center padding-horiz--md">
        <h3>{title}</h3>
        <p>{description}</p>
      </div>
    </div>
  );
}

export default function HomepageFeatures() {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}
