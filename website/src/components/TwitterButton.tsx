import Link from "@docusaurus/Link";
import React, { useEffect, useState } from "react";

export default function TwitterButton() {
  const [mounted, setMounted] = useState(false);
  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) {
    return null;
  }

  return (
    <Link href="https://twitter.com/leoafarias">
      <img
        alt="X (formerly Twitter) Follow"
        src="https://img.shields.io/badge/Follow-blue?style=for-the-badge&logo=twitter&logoColor=white"
      />
    </Link>
  );
}
