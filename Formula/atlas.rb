class Atlas < Formula
  desc "ECMWF library for numerical weather prediction and climate modelling"
  homepage "https://github.com/ecmwf/atlas"
  url "https://github.com/ecmwf/atlas/archive/refs/tags/0.45.0.tar.gz"
  sha256 "ca4b23f1489a1ecbdadb2ee152c8a7a8575784ed3b87b84b9db45a2d4f4d5838"
  license "Apache-2.0"

  bottle do
    root_url "https://get-test.ecmwf.int/repository/homebrew"
  end

  depends_on "cmake" => :build
  depends_on "ecbuild" => :build
  depends_on "eckit"
  depends_on "fftw"
  depends_on "libomp"
  depends_on "eigen" => :recommended

  conflicts_with "ecmwf-toolbox", because: "ecmwf-toolbox includes atlas"

  def install
    mkdir "build" do
      system "ecbuild", "..", "-DENABLE_FORTRAN=OFF", *std_cmake_args
      system "make", "install"
    end

    shim_references = [
      lib/"pkgconfig/atlas.pc",
      lib/"pkgconfig/atlas-c++.pc",
      include/"atlas/atlas_ecbuild_config.h",
    ]
    inreplace shim_references, Superenv.shims_path/ENV.cxx, ENV.cxx
    inreplace shim_references, Superenv.shims_path/ENV.cc, ENV.cc
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/atlas --version")
  end
end
