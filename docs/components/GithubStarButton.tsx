import Link from "next/link";

export default function GithubStartButton() {
  return (
    <Link href="https://github.com/leoafarias/fvm">
      <img
        alt="FVM on GitHub"
        src="https://img.shields.io/github/stars/leoafarias/fvm?style=for-the-badge&logo=GitHub&logoColor=black&labelColor=white&color=%23eeeeee"
      />
    </Link>
  );
}
