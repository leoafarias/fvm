import Image from "next/image";

export const Logo = ({ size = 25 }) => (
  <Image alt="FVM logo" width={size} height={size} src="/assets/logo.svg" />
);
