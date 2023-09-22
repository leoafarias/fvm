class Fvm < Formula
  desc "Flutter Version Management: A CLI to manage Flutter SDK versions"
  homepage "https://github.com/leoafarias/fvm"
  version "{{VERSION}}"

  on_macos do
    if Hardware::CPU.arm?
      url "{{MACOS_ARM64_URL}}"
      sha256 "{{MACOS_ARM64_SHA256}}"
    else
      url "{{MACOS_X64_URL}}"
      sha256 "{{MACOS_X64_SHA256}}"
    end
  end

  def install
    bin.install "fvm"
  end

  test do
    assert_match "FVM #{version}", shell_output("#{bin}/fvm --version").strip
  end
end