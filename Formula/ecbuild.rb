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
    root_url "https://github.com/recmanj-org/homebrew-ecmwf/releases/download/ecbuild-3.13.1"
    sha256 cellar: :any_skip_relocation, arm64_tahoe:   "de2aa2b264893911c57e961fbbeea5c6f5324ab58a971cc3874021c869464f4a"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "a7a3c3aae0a418a939306b40571097a8e86f0b7fddebaa82b71630648b4be6c1"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:  "7790bc22f340533270ed509feb9622a9a695ec924011c9d3eac9833bc0d187a2"
    sha256 cellar: :any_skip_relocation, tahoe:         "7296bd5b00510a385c8752e673ea1f96e97a801647f389992b7e5c0ae8646ebd"
    sha256 cellar: :any_skip_relocation, sequoia:       "cfef4db4241ae650a8de3b4d6c975344b3806232d52f3b2bc0cae50a7133b512"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "4bc8d11440e910b0afa7d83edc719718a88f9f5a421e12aceedac27f84f7d79c"
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
