class EcmwfToolbox < Formula
  desc "ECMWF monolithic bundle: eckit, eccodes, atlas, odc, magics, and more"
  homepage "https://github.com/recmanj-org/homebrew-ecmwf"
  url "https://github.com/ecmwf/ecbundle/archive/refs/tags/2.4.0.tar.gz"
  version "2026.01.0.0"
  sha256 "542da932b6884383690b3ea144e3ec0f88f466364bec0422be11e6ea2faf457b"
  license "Apache-2.0"

  livecheck do
    skip "ecmwf-toolbox is a meta-bundle with no upstream release tags"
  end

  depends_on "cmake" => :build
  depends_on "ecbuild" => :build
  depends_on "ecbundle" => :build
  depends_on "cairo"
  depends_on "fftw"
  depends_on "gcc" # Fortran
  depends_on "lapack"
  depends_on "libaec"
  depends_on "libpng"
  depends_on "lz4"
  depends_on "netcdf"
  depends_on "openblas"
  depends_on "openjpeg"
  depends_on "openssl@3"
  depends_on "pango"
  depends_on "proj"
  depends_on "qhull"
  depends_on "eigen@3" => :recommended
  uses_from_macos "bison" => :build
  uses_from_macos "flex" => :build
  uses_from_macos "bzip2"
  uses_from_macos "ncurses"

  conflicts_with "recmanj-org/ecmwf/eckit", because: "ecmwf-toolbox includes eckit"
  conflicts_with "recmanj-org/ecmwf/atlas", because: "ecmwf-toolbox includes atlas"
  conflicts_with "recmanj-org/ecmwf/odc", because: "ecmwf-toolbox includes odc"

  resource "eckit" do
    url "https://github.com/ecmwf/eckit/archive/refs/tags/1.32.4.tar.gz"
    sha256 "8b2752016b4765c697c2ff85dda39366c9a8fdc798f6418565437759a8cbfed5"
  end

  resource "eccodes" do
    url "https://github.com/ecmwf/eccodes/archive/refs/tags/2.45.0.tar.gz"
    sha256 "88da6650a9995f20d73328ed8ae863f9688317837475a35613dd88bd7e31be2e"
  end

  resource "odc" do
    url "https://github.com/ecmwf/odc/archive/refs/tags/1.6.0.tar.gz"
    sha256 "7b214b1d347231dc356416fbad86bb0ac6fc741048ef0b8024d66ec38d7630be"
  end

  resource "metkit" do
    url "https://github.com/ecmwf/metkit/archive/refs/tags/1.16.0.tar.gz"
    sha256 "7b93e4fc1608c1ac205fbf3e094d50ba8a88e7223b65eab7a12362f55550c8e1"
  end

  resource "atlas" do
    url "https://github.com/ecmwf/atlas/archive/refs/tags/0.45.0.tar.gz"
    sha256 "ca4b23f1489a1ecbdadb2ee152c8a7a8575784ed3b87b84b9db45a2d4f4d5838"
  end

  resource "atlas-orca" do
    url "https://github.com/ecmwf/atlas-orca/archive/refs/tags/0.4.3.tar.gz"
    sha256 "e43fc8cdc4ad324c2d3180abd370d44c5126ff8a2624591007215a89873971d8"
  end

  resource "mir" do
    url "https://github.com/ecmwf/mir/archive/refs/tags/1.27.8.tar.gz"
    sha256 "3e72671dec07fb62fe3a9fc21f80cba4107fd972525b2b2850727d627c346006"
  end

  resource "magics" do
    url "https://github.com/ecmwf/magics/archive/refs/tags/4.16.0.tar.gz"
    sha256 "8300f8cb13705dfea87cbd48ca8f95b94279c70dfe9d71bf22904dc720309503"
  end

  resource "fdb" do
    url "https://github.com/ecmwf/fdb/archive/refs/tags/5.19.0.tar.gz"
    sha256 "1275c4b89dcdfcb342a255e22a7d500070d5d32251910c4c2a10d5734c0590eb"
  end

  def install
    # Stage each resource into staging/<project-name>/
    stagedir = buildpath/"staging"
    %w[eckit eccodes odc metkit atlas atlas-orca mir magics].each do |proj|
      resource(proj).stage(stagedir/proj)
    end
    resource("fdb").stage(stagedir/"fdb5")

    # Generate bundle.yml with dir: entries (no git cloning needed)
    (buildpath/"bundle.yml").write <<~YAML
      ---
      name: ecmwf-toolbox
      version: #{version}

      projects:
        - eckit:
            dir: #{stagedir}/eckit
            cmake: ECKIT_ENABLE_ECKIT_GEO=ON
        - eccodes:
            dir: #{stagedir}/eccodes
            cmake: >
              ECCODES_ENABLE_ECCODES_THREADS=ON
              ECCODES_INSTALL_EXTRA_TOOLS=ON
              ECCODES_ENABLE_MEMFS=ON
              ECCODES_ENABLE_FORTRAN=ON
              ECCODES_ENABLE_ECKIT_GEO=OFF
        - odc:
            dir: #{stagedir}/odc
            require: eckit
            cmake: ODC_ENABLE_FORTRAN=ON
        - metkit:
            dir: #{stagedir}/metkit
            require: eccodes eckit odc
            cmake: METKIT_ENABLE_BUILD_TOOLS=OFF
        - atlas:
            dir: #{stagedir}/atlas
            require: eckit
        - atlas-orca:
            dir: #{stagedir}/atlas-orca
            require: atlas
        - mir:
            dir: #{stagedir}/mir
            require: eccodes eckit atlas
            cmake: >
              MIR_ENABLE_BUILD_TOOLS=ON
              MIR_ENABLE_ECKIT_GEO=ON
        - magics:
            dir: #{stagedir}/magics
            require: eccodes odc
            cmake: MAGICS_ENABLE_ODB=ON
        - fdb5:
            dir: #{stagedir}/fdb5
            require: eccodes eckit metkit
            cmake: FDB5_ENABLE_BUILD_TOOLS=OFF
    YAML

    # ecbundle create — reads bundle.yml, generates source/CMakeLists.txt with symlinks
    mkdir_p buildpath/"source"
    system "ecbundle", "create", "--bundle", buildpath.to_s

    # ecbundle build — configure + build + install
    system "ecbundle", "build",
           "--src-dir", (buildpath/"source").to_s,
           "--build-dir", (buildpath/"build").to_s,
           "--install-dir", prefix.to_s,
           "--build-type", "Release",
           "--without-tests",
           "--cmake", "ENABLE_MPI=OFF",
           "--cmake", "ENABLE_PYTHON=OFF",
           "--cmake", "ENABLE_INSTALL_ECCODES_SAMPLES=ON",
           "--cmake", "INSTALL_LIB_DIR=lib",
           "--install",
           "-j#{ENV.make_jobs}"

    # Fix shim references in pkg-config files and ecbuild config headers
    Dir[lib/"pkgconfig/*.pc", include/"**/*_ecbuild_config.h"].each do |f|
      inreplace f, Superenv.shims_path/ENV.cxx, ENV.cxx if File.read(f).include?(Superenv.shims_path.to_s)
      inreplace f, Superenv.shims_path/ENV.cc, ENV.cc if File.read(f).include?(Superenv.shims_path.to_s)
    end

    # Remove build log that contains shim references
    rm_f share/"ecmwf-toolbox/build.log"
  end

  test do
    assert_match "eckit version", shell_output("#{bin}/eckit-version")
    assert_match "atlas", shell_output("#{bin}/atlas --version")
  end
end
