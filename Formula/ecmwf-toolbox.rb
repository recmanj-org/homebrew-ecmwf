class EcmwfToolbox < Formula
  desc "ECMWF monolithic bundle: eckit, eccodes, atlas, odc, magics, and more"
  homepage "https://github.com/ecmwf/ecmwf-toolbox"
  url "https://github.com/ecmwf/ecmwf-toolbox/archive/refs/tags/2026.01.0.0.tar.gz"
  sha256 "0019dfc4b32d63c1392aa264aed2253c1e0c2fb09216f8e2cc269bbfb8bb49b5"
  license "Apache-2.0"

  livecheck do
    url "https://github.com/ecmwf/ecmwf-toolbox/tags"
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  depends_on "cmake" => :build
  depends_on "ecbuild" => :build
  depends_on "cairo"
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
  depends_on "eigen@3" => :recommended
  uses_from_macos "bison" => :build
  uses_from_macos "flex" => :build
  uses_from_macos "bzip2"
  uses_from_macos "ncurses"

  conflicts_with "eckit", because: "ecmwf-toolbox includes eckit"
  conflicts_with "atlas", because: "ecmwf-toolbox includes atlas"
  conflicts_with "odc", because: "ecmwf-toolbox includes odc"

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
    # Stage each sub-project resource into source/<name>/
    srcdir = buildpath/"source"
    %w[eckit eccodes odc metkit atlas atlas-orca mir magics].each do |proj|
      resource(proj).stage(srcdir/proj)
    end
    # fdb repo maps to the fdb5 project name in the bundle
    resource("fdb").stage(srcdir/"fdb5")

    # Generate the CMakeLists.txt that ecbundle would normally create
    (srcdir/"CMakeLists.txt").write <<~CMAKE
      cmake_minimum_required( VERSION 3.12 FATAL_ERROR )

      ####################################################################

      macro( ecbundle_add_project package_name )
          set( BUILD_${package_name} ON CACHE BOOL "" )
          if( BUILD_${package_name} )
              set( dir ${ARGV1} )
              if( NOT dir )
                  set( dir ${package_name} )
              endif()
              add_subdirectory( ${dir} )
          endif()
      endmacro()

      macro( ecbundle_set key value )
          set( ${key} ${value} CACHE STRING "" )
          if( "${${key}}" STREQUAL "${value}" )
             message("  - ${key} = ${value}" )
          else()
             message("  - ${key} = ${${key}} [default=${value}]" )
          endif()
      endmacro()

      ####################################################################

      message( "" )
      message( "ecmwf-toolbox [#{version}]" )
      message( "  - source     : ${CMAKE_CURRENT_SOURCE_DIR}" )
      message( "  - build      : ${CMAKE_CURRENT_BINARY_DIR}" )
      message( "  - install    : ${CMAKE_INSTALL_PREFIX}"     )
      message( "  - build type : ${CMAKE_BUILD_TYPE}"       )
      message( "" )
      message( "Bundle variables set for this build:" )

      ecbundle_set( ECKIT_ENABLE_ECKIT_GEO ON )
      ecbundle_set( ECCODES_ENABLE_ECCODES_THREADS ON )
      ecbundle_set( ECCODES_INSTALL_EXTRA_TOOLS ON )
      ecbundle_set( ECCODES_ENABLE_MEMFS ON )
      ecbundle_set( ECCODES_ENABLE_FORTRAN ON )
      ecbundle_set( ECCODES_ENABLE_ECKIT_GEO OFF )
      ecbundle_set( ODC_ENABLE_FORTRAN ON )
      ecbundle_set( METKIT_ENABLE_BUILD_TOOLS OFF )
      ecbundle_set( MIR_ENABLE_BUILD_TOOLS ON )
      ecbundle_set( MIR_ENABLE_ECKIT_GEO ON )
      ecbundle_set( MAGICS_ENABLE_ODB ON )
      ecbundle_set( FDB5_ENABLE_BUILD_TOOLS OFF )
      message("")

      ####################################################################

      find_package( ecbuild 3.0 QUIET )
      project( ecmwf-toolbox VERSION #{version} )

      ## Initialize
      include(${CMAKE_CURRENT_BINARY_DIR}/init.cmake OPTIONAL)

      ## Projects

      ecbundle_add_project( eckit )
      ecbundle_add_project( eccodes )
      ecbundle_add_project( odc )
      ecbundle_add_project( metkit )
      ecbundle_add_project( atlas )
      ecbundle_add_project( atlas-orca )
      ecbundle_add_project( mir )
      ecbundle_add_project( magics )
      ecbundle_add_project( fdb5 )

      ## Finalize
      include(${CMAKE_CURRENT_BINARY_DIR}/final.cmake OPTIONAL)

      if( ecbuild_FOUND )
        ecbuild_install_project(NAME ${PROJECT_NAME})
        ecbuild_print_summary()
      endif()
    CMAKE

    mkdir "build" do
      system "ecbuild", srcdir.to_s,
             "-DENABLE_MPI=OFF",
             "-DENABLE_TESTS=OFF",
             *std_cmake_args
      system "cmake", "--build", ".", "--", "-j#{ENV.make_jobs}"
      system "cmake", "--install", "."
    end

    # Fix shim references in pkg-config files and ecbuild config headers
    Dir[lib/"pkgconfig/*.pc", include/"**/*_ecbuild_config.h"].each do |f|
      inreplace f, Superenv.shims_path/ENV.cxx, ENV.cxx if File.read(f).include?(Superenv.shims_path.to_s)
      inreplace f, Superenv.shims_path/ENV.cc, ENV.cc if File.read(f).include?(Superenv.shims_path.to_s)
    end
  end

  test do
    assert_match "eckit version", shell_output("#{bin}/eckit-version")
    assert_match "atlas", shell_output("#{bin}/atlas --version")
  end
end
