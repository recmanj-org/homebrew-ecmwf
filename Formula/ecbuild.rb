class Ecbuild < Formula
  desc "ECMWF macros for CMake build system"
  homepage "https://github.com/ecmwf/ecbuild"
  url "https://github.com/ecmwf/ecbuild/archive/refs/tags/3.13.1.tar.gz"
  sha256 "9759815aef22c9154589ea025056db086c575af9dac635614b561ab825f9477e"
  license "Apache-2.0"
  revision 1

  livecheck do
    url "https://github.com/ecmwf/ecbuild/tags"
    regex(/^v?(\d(?:\.\d+)+)$/i)
  end

  bottle do
    root_url "https://github.com/recmanj-org/homebrew-ecmwf/releases/download/ecbuild-3.13.1_1"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:   "d8c37120852c480e5a39e8d49860971c33b3fae224ba5426af6214938e1e2453"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "f59fefb113c6272707365fb53d1dfe8e3f2182e53f001ac4d52ff2b1b5d8e3c4"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:  "1859e55b7ca0b13fc325cde8a7b81a6ab26d9e4abba4d6704de0e89bdbd6636b"
    sha256 cellar: :any_skip_relocation, tahoe:         "5012a3cd7c1b96772dbfcdaab1cda5d4aaf72847fa7716a39646170b164c9b76"
    sha256 cellar: :any_skip_relocation, sequoia:       "4418b1c2803cf6ae0cc7b0f797c3b1d3f21d9509f776ed419ca7f7d5549f6abc"
    sha256 cellar: :any_skip_relocation, arm64_linux:   "9a2cbd83559e12f59f583c6b83980fb01b2d079dc1fd9461bf59706e1c22e8a8"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "70962d2e0c8f379752b1c63310199ce7b2a25126535da9f27c8112af4d2eff6a"
  end

  depends_on "cmake"

  def install
    mkdir "build" do
      system "cmake", "..", "-DENABLE_INSTALL=ON", *std_cmake_args
      system "make", "install"
    end
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/ecbuild --version")

    # create a small sample CMake project that uses ecbuild features
    (testpath/"src/CMakeLists.txt").write <<~EOS
      cmake_minimum_required(VERSION 3.11 FATAL_ERROR)
      find_package(ecbuild REQUIRED)
      project(test_ecbuild_install VERSION 0.1.0 LANGUAGES NONE)
      ecbuild_add_option(FEATURE TEST_A DEFAULT OFF)
      if(HAVE_TEST_A)
        message(STATUS "TEST_A ON")
      else()
        message(STATUS "TEST_A OFF")
      endif()
    EOS

    default_output = shell_output("#{bin}/ecbuild -Wno-dev ./src")
    assert_match "TEST_A OFF", default_output
    rm "CMakeCache.txt"

    on_output = shell_output("#{bin}/ecbuild -Wno-dev ./src -DENABLE_TEST_A=ON")
    assert_match "TEST_A ON", on_output
    rm "CMakeCache.txt"

    off_output = shell_output("#{bin}/ecbuild -Wno-dev ./src -DENABLE_TEST_A=OFF")
    assert_match "TEST_A OFF", off_output
  end
end
