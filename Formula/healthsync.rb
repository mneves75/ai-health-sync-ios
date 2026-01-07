# Copyright 2026 Marcus Neves
# SPDX-License-Identifier: Apache-2.0

class Healthsync < Formula
  desc "Secure sync of Apple HealthKit data between iPhone and Mac"
  homepage "https://github.com/mneves75/ai-health-sync-ios"
  url "https://github.com/mneves75/ai-health-sync-ios/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "0019dfc4b32d63c1392aa264aed2253c1e0c2fb09216f8e2cc269bbfb8bb49b5"
  license "Apache-2.0"
  head "https://github.com/mneves75/ai-health-sync-ios.git", branch: "master"

  depends_on xcode: ["16.0", :build]
  depends_on macos: :sequoia

  def install
    cd "macOS/HealthSyncCLI" do
      system "swift", "build", "-c", "release", "--disable-sandbox"
      bin.install ".build/release/healthsync"
    end
  end

  test do
    assert_match "healthsync", shell_output("#{bin}/healthsync --help")
  end
end
