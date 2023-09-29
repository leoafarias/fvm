import Translate, { translate } from "@docusaurus/Translate";
import clsx from "clsx";
import React from "react";
import styles from "./HomepageFeatures.module.css";

const FeatureList = [
  {
    title: translate({
      id: "home.feature_multiple_flutter_sdk_title",
      message: "Multiple Flutter SDKs",
    }),
    Svg: require("../../static/img/multiple_versions.svg").default,
    description: (
      <Translate id="home.feature_multiple_flutter_sdk">
        Swiftly manage, cache, and switch Flutter SDK versions and channels, all
        in one go.
      </Translate>
    ),
  },
  {
    title: translate({
      id: "home.feature_project_versioning_title",
      message: "Project Versioning",
    }),
    Svg: require("../../static/img/project_versioning.svg").default,
    description: (
      <Translate id="home.feature_project_versioning">
        Project-specific Flutter SDK configuration, integrated VsCode support,
        and SDK consistency across your team
      </Translate>
    ),
  },
  {
    title: translate({
      id: "home.feature_advanced_tooling_title",
      message: "Advanced Tooling",
    }),
    Svg: require("../../static/img/advanced_tooling.svg").default,
    description: (
      <Translate id="home.feature_advanced_tooling">
        Global Flutter SDK, spawn processes across versions, different SDKs
        across envs, and install Flutter from commits
      </Translate>
    ),
  },
];

function Feature({ Svg, title, description }) {
  return (
    <div className={clsx("col col--4")}>
      <div className="text--left padding-horiz--md padding-vert--sm">
        <Svg
          className={styles.featureSvg}
          alt={title}
          style={{ width: 35, height: 35 }}
        />
      </div>

      <div className="text--left padding-horiz--md">
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
