class Odc < Formula
  desc "Package to read/write ODB data"
  homepage "https://github.com/ecmwf/odc"
  url "https://github.com/ecmwf/odc/archive/refs/tags/1.6.0.tar.gz"
  sha256 "7b214b1d347231dc356416fbad86bb0ac6fc741048ef0b8024d66ec38d7630be"
  license "Apache-2.0"

  livecheck do
    url "https://github.com/ecmwf/odc/tags"
    regex(/^v?(\d(?:\.\d+)+)$/i)
  end

  bottle do
    root_url "https://get-test.ecmwf.int/repository/homebrew"
  end

  depends_on "cmake" => :build
  depends_on "ecbuild" => :build
  depends_on "eckit"
  depends_on "gcc"

  conflicts_with "ecmwf-toolbox", because: "ecmwf-toolbox includes odc"

  def install
    mkdir "build" do
      system "ecbuild", "..", "-DENABLE_FORTRAN=ON", *std_cmake_args
      system "cmake", "--build", "."
      system "cmake", "--install", "."
    end

    shim_references = [
      lib/"pkgconfig/odc.pc",
      include/"odc/odc_ecbuild_config.h",
    ]
    inreplace shim_references, Superenv.shims_path/ENV.cxx, ENV.cxx
    inreplace shim_references, Superenv.shims_path/ENV.cc, ENV.cc
  end

  test do
    assert_match "ODBAPI Version: #{version}", shell_output("#{bin}/odc --version")
  end
end
