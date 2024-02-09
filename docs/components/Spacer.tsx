type Props = {
  size: number;
};

function Spacer({ size = 10 }: Props) {
  return <span style={{ height: size, width: size }} />;
}

export default Spacer;
