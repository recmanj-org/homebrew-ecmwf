class Ecbuild < Formula
  desc "ECMWF macros for CMake build system"
  homepage "https://github.com/ecmwf/ecbuild"
  url "https://github.com/ecmwf/ecbuild/archive/refs/tags/3.13.1.tar.gz"
  sha256 "9759815aef22c9154589ea025056db086c575af9dac635614b561ab825f9477e"
  license "Apache-2.0"
  revision 2

  livecheck do
    url "https://github.com/ecmwf/ecbuild/tags"
    regex(/^v?(\d(?:\.\d+)+)$/i)
  end

  bottle do
    root_url "https://github.com/recmanj-org/homebrew-ecmwf/releases/download/ecbuild-3.13.1_2"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:   "6ea59b3368ecff6ec842ac180ac61ec2e3b3044b4b25cc8e55daf4ca5179dc14"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "a6582e55e68892a1708b4ddd6af53296d4467660d85f85fc910e6d611a1155eb"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:  "78e5fb35ff62d126dd2070266170aa3b80e1b26fe603661eb99bd68f3bcc5056"
    sha256 cellar: :any_skip_relocation, tahoe:         "8845cbb6813f21f390a705cb6daef29193e9acd54507e3a7c5cee40695145f3d"
    sha256 cellar: :any_skip_relocation, sequoia:       "d33588bde5fb94caf825f33a22677acdf61933e8a30ea358a0208ea09e18cc7b"
    sha256 cellar: :any_skip_relocation, arm64_linux:   "9fe7128e6fcef030a66109814e0dd468d6be4dc1aacaf34d5de90b5cdf62ce61"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "609a7a34de09ceeb74a3342defdd19c70d85280aaafacb6f7d77a18cbab042e8"
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
