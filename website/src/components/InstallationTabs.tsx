import TabItem from "@theme/TabItem";
import Tabs from "@theme/Tabs";
import React from "react";

interface TabValue {
  label: string;
  value: string;
}

function osfunction(): string {
  const os = navigator.userAgent;

  if (os.search("Windows") !== -1) {
    return "windows";
  } else if (os.search("Mac") !== -1) {
    return "macos";
  } else if (os.search("Linux") !== -1 && os.search("X11") !== -1) {
    return "linux";
  }

  return "pub";
}

export const InstallationTabs: React.FC = () => {
  const tabValues: TabValue[] = [
    { label: "MacOS", value: "macos" },
    { label: "Windows", value: "windows" },
    { label: "Linux", value: "linux" },
    { label: "Pub", value: "pub" },
  ];

  return (
    <div>
      {/* ADd padding horizontal */}
      <div
        style={{
          backgroundColor: "#222",
          paddingRight: 10,
          paddingLeft: 10,
          paddingBottom: 5,
          paddingTop: 10,
          borderRadius: 20,
          borderColor: "#333",
          borderWidth: 1,
          borderStyle: "solid",
        }}
      >
        <Tabs defaultValue={osfunction()} values={tabValues}>
          <TabItem value="macos">
            <p>
              If you use the{" "}
              <a href="https://brew.sh">Homebrew package manager</a> for Mac OS
              X, you can install FVM by running
            </p>
            <h3>Install</h3>
            <pre>
              <code>
                brew tap leoafarias/fvm
                <br />
                brew install fvm
              </code>
            </pre>
            <h3>Uninstall</h3>
            <pre>
              <code>
                brew uninstall fvm
                <br />
                brew untap leoafarias/fvm
              </code>
            </pre>
          </TabItem>

          <TabItem value="windows">
            {}
            <p>
              To install fvm (Install), run the following command from the
              command line or from PowerShell:
            </p>
            <pre>
              <code>choco install fvm</code>
            </pre>
          </TabItem>

          <TabItem value="linux">
            <p>
              If you use the{" "}
              <a href="https://brew.sh">Homebrew package manager</a> for Linux,
              you can install FVM by running
            </p>
            <h3>Install</h3>
            <pre>
              <code>
                brew tap leoafarias/fvm
                <br />
                brew install fvm
              </code>
            </pre>
            <h3>Uninstall</h3>
            <pre>
              <code>
                brew uninstall fvm
                <br />
                brew untap leoafarias/fvm
              </code>
            </pre>
          </TabItem>
          <TabItem value="Pub">
            <h2>Pub package</h2>
            <p>
              You are also able to install FVM as a{" "}
              <a href="https://pub.dev/packages/fvm">pub package</a>.
            </p>
            <p>
              However, if you plan on using FVM to manage your{" "}
              <a href="/docs/guides/global_version">global Flutter install</a>,
              we recommend installing it as a standalone.
            </p>
            <pre>
              <code>dart pub global activate fvm</code>
            </pre>
          </TabItem>
        </Tabs>
      </div>
    </div>
  );
};
