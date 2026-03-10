class Eckit < Formula
  desc "ECMWF cross-platform c++ toolkit"
  homepage "https://github.com/ecmwf/eckit"
  url "https://github.com/ecmwf/eckit/archive/refs/tags/2.0.2.tar.gz"
  sha256 "46b9c1f90e0b565698c5c79c54676401d33738ec82995c025d5d5aabeb13ad2b"
  license "Apache-2.0"
  revision 1

  livecheck do
    url "https://github.com/ecmwf/eckit/tags"
    regex(/^v?(\d(?:\.\d+)+)$/i)
  end

  bottle do
    root_url "https://github.com/recmanj-org/homebrew-ecmwf/releases/download/eckit-2.0.2_1"
    sha256 cellar: :any,                 arm64_tahoe:   "28e0dddcbed334202df3c6702155160ab6952bc81d7f4e3920ee19e072627db0"
    sha256 cellar: :any,                 arm64_sequoia: "c49c183af8817a679417f30ef18699b4cf1956297888d623a180967fe1ddca08"
    sha256 cellar: :any,                 arm64_sonoma:  "fe50ab335e221581ccc018ec01298520e774de8461a68ac9edd865ef98afa043"
    sha256 cellar: :any_skip_relocation, arm64_linux:   "47a2bab36efc09ef2aeb039b8350416b9393368674726cd58121017a3cdfd2dc"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "e5765219c5f406245627b90f98c8b5ffe1c5372634db0cc417a3003e5ce2ca12"
  end

  depends_on "cmake" => [:build, :test]
  depends_on "ecbuild" => [:build, :test]
  depends_on "lapack"
  depends_on "lz4"
  depends_on "openblas"
  depends_on "openssl@3"
  depends_on "eigen@3" => :recommended
  uses_from_macos "bzip2"
  uses_from_macos "ncurses"

  def install
    mkdir "build" do
      args = %W[
        -DENABLE_MPI=OFF
        -DCMAKE_PREFIX_PATH=#{Formula["eigen@3"].opt_prefix}
      ]
      system "ecbuild", "..", *args, *std_cmake_args
      system "make", "install"
    end

    shim_references = [
      lib/"pkgconfig/eckit_mpi.pc",
      lib/"pkgconfig/eckit_cmd.pc",
      lib/"pkgconfig/eckit_test_value_custom_params.pc",
      lib/"pkgconfig/eckit_option.pc",
      lib/"pkgconfig/eckit_maths.pc",
      lib/"pkgconfig/eckit_web.pc",
      lib/"pkgconfig/eckit_sql.pc",
      lib/"pkgconfig/eckit.pc",
      lib/"pkgconfig/eckit_linalg.pc",
      lib/"pkgconfig/eckit_geometry.pc",
      lib/"pkgconfig/eckit_distributed.pc",
      lib/"pkgconfig/eckit_spec.pc",
      lib/"pkgconfig/eckit_geo.pc",
      lib/"pkgconfig/eckit_codec.pc",
      include/"eckit/eckit_ecbuild_config.h",
    ]
    inreplace shim_references, Superenv.shims_path/ENV.cxx, ENV.cxx
    inreplace shim_references, Superenv.shims_path/ENV.cc, ENV.cc
  end

  test do
    # write a CMakeLists.txt for building the test
    (testpath/"src/CMakeLists.txt").write <<~EOS
      cmake_minimum_required(VERSION 3.11 FATAL_ERROR)
      find_package(ecbuild REQUIRED)
      project(test_eckit VERSION 0.1.0 LANGUAGES CXX)
      set(CMAKE_CXX_STANDARD 17)
      set(CMAKE_CXX_STANDARD_REQUIRED ON)
      ecbuild_find_package( NAME eckit REQUIRED )
      ecbuild_add_executable(
        TARGET      eckit-test
        SOURCES     test.cc
        LIBS        eckit_maths eckit )
    EOS

    # source code for the test
    (testpath/"src/test.cc").write <<~EOS
      #include <cassert>
      #include <iomanip>
      #include "eckit/testing/Test.h"
      #include "eckit/types/FloatCompare.h"
      #include "eckit/types/Hour.h"
      #include "eckit/maths/Matrix.h"
      #include "eckit/container/DenseMap.h"

      using namespace std;
      using namespace eckit;
      using namespace eckit::testing;

      int main() {

        // test time utilities
        assert(Hour(1.0/60.0) == Hour("0:01"));

        // test containers
        DenseMap<std::string, int> dm;
        dm.insert("two", 2);
        dm.insert("four", 4);
        dm.insert("nine", 9);
        dm.sort();
        assert(dm.get("two") == 2);
        assert(dm.get("nine") == 9);
        assert(dm.get("four") == 4);

        // test matrix functions
        constexpr double tolerance = 1.e-8;
        using eckit::types::is_approximately_equal;
        using Matrix = eckit::maths::Matrix<double>;
        Matrix m{{9., 6., 2., 0., 3.},
                 {3., 6., 8., 10., 12.},
                 {4., 8., 2., 6., 9.},
                 {1., 5., 5., 3., 2.},
                 {1., 3., 6., 8., 10}};
        assert(is_approximately_equal(m.determinant(), 1124., tolerance));
        return 0;
      }
    EOS

    # build using ecbuild to ensure correct compilation flags
    # also set build type to Debug so as to activate assert()
    system "ecbuild", "./src", "-DCMAKE_BUILD_TYPE=Debug"
    system "make"
    system "file", "./bin/eckit-test"
    system "./bin/eckit-test"
  end
end
