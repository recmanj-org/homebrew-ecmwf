class EcmwfToolbox < Formula
  desc "ECMWF software bundle: ecCodes, Magics, Metview, Atlas, and more"
  homepage "https://github.com/recmanj/ecmwf-toolbox"
  url "https://github.com/recmanj/ecmwf-toolbox.git",
      tag:      "2026.01.0.0",
      revision: "bbbf647ae3c43326de15781d033c547b75bee8f4"
  license "Apache-2.0"

  livecheck do
    url "https://github.com/recmanj/ecmwf-toolbox/tags"
    regex(/^v?(\d(?:\.\d+)+)$/i)
  end

  depends_on "cmake" => :build
  depends_on "ecbundle" => :build
  depends_on "cairo"
  depends_on "curl"
  depends_on "eigen"
  depends_on "expat"
  depends_on "fftw"
  depends_on "gcc"
  depends_on "jasper"
  depends_on "libaec"
  depends_on "libomp"
  depends_on "libpng"
  depends_on "libzip"
  depends_on "lz4"
  depends_on "netcdf"
  depends_on "open-mpi"
  depends_on "openjpeg"
  depends_on "pango"
  depends_on "proj"
  depends_on "python@3.13"
  depends_on "qhull"
  depends_on "snappy"
  uses_from_macos "bzip2"
  uses_from_macos "ncurses"

  def install
    # Projects on ECMWF Bitbucket that have public GitHub mirrors
    github_mirrors = {
      "ECKIT"  => "ecmwf/eckit",
      "ODC"    => "ecmwf/odc",
      "METKIT" => "ecmwf/metkit",
      "MAGICS" => "ecmwf/magics",
      "FDB5"   => "ecmwf/fdb",
    }

    # Private GitHub repos (need ECMWF_TOOLBOX_TOKEN)
    private_github = {
      "MARS_CLIENT" => "ecmwf/mars-client",
      "METVIEW"     => "ecmwf/metview",
    }

    # Private Bitbucket repos (need ECMWF_BITBUCKET_TOKEN)
    private_bitbucket = {
      "ODB"       => "odb/odb",
      "ODB_TOOLS" => "odb/odb-tools",
    }

    # Redirect mirrored Bitbucket projects to GitHub HTTPS (always works)
    github_mirrors.each do |name, gh_repo|
      ENV["ECMWF_TOOLBOX_#{name}_GIT"] = "https://github.com/#{gh_repo}.git"
    end

    # With Bitbucket token: use authenticated HTTPS for Bitbucket-only projects
    bb_token = ENV["ECMWF_BITBUCKET_TOKEN"]
    if bb_token
      private_bitbucket.each do |name, bb_path|
        ENV["ECMWF_TOOLBOX_#{name}_GIT"] = "https://#{bb_token}@git.ecmwf.int/scm/#{bb_path}.git"
      end
    else
      private_bitbucket.each_key do |name|
        ENV["ECMWF_TOOLBOX_SKIP_#{name}"] = "1" unless ENV["ECMWF_TOOLBOX_SKIP_#{name}"]
      end
    end

    # With GitHub token: use authenticated HTTPS for private GitHub projects
    gh_token = ENV["ECMWF_TOOLBOX_TOKEN"]
    if gh_token
      private_github.each do |name, gh_repo|
        ENV["ECMWF_TOOLBOX_#{name}_GIT"] = "https://#{gh_token}@github.com/#{gh_repo}.git"
      end
    else
      private_github.each_key do |name|
        ENV["ECMWF_TOOLBOX_SKIP_#{name}"] = "1" unless ENV["ECMWF_TOOLBOX_SKIP_#{name}"]
      end
    end

    # Ensure all dependency headers/libs are visible to the compiler
    # (Linuxbrew ARM shims don't always propagate include paths)
    deps.each do |dep|
      inc = dep.opt_include
      lib = dep.opt_lib
      ENV.append_to_cflags "-I#{inc}" if inc.directory?
      ENV.append "LDFLAGS", "-L#{lib}" if lib.directory?
    end

    # ecbundle create: downloads all git repos + generates CMakeLists.txt
    system "ecbundle", "create", "--bundle", buildpath.to_s

    # ecbundle build: cmake configure + compile + install
    system "ecbundle", "build",
           "--src-dir", "source",
           "--build-dir", "build",
           "--install-dir", prefix.to_s,
           "--build-type", "Release",
           "--without-tests",
           "--cmake", "ENABLE_AEC=ON",
           "--cmake", "ENABLE_FFTW=ON",
           "--cmake", "ENABLE_NETCDF=ON",
           "--cmake", "ENABLE_PROJ=ON",
           "--cmake", "ENABLE_PNG=ON",
           "--cmake", "ENABLE_FDB5=ON",
           "--cmake", "INSTALL_LIB_DIR=lib",
           "--cmake", "CMAKE_PREFIX_PATH=#{ENV["CMAKE_PREFIX_PATH"]}",
           "--cmake", "OpenMP_ROOT=#{Formula["libomp"].opt_prefix}",
           "--install",
           "-j#{ENV.make_jobs}"

    # Fix shim references in pkg-config files and ecbuild config headers
    Dir[lib/"pkgconfig/*.pc", include/"**/*_ecbuild_config.h"].each do |f|
      inreplace f, Superenv.shims_path/ENV.cxx, ENV.cxx if File.read(f).include?(Superenv.shims_path.to_s)
      inreplace f, Superenv.shims_path/ENV.cc, ENV.cc if File.read(f).include?(Superenv.shims_path.to_s)
    end

    # Remove build log that contains shim references
    rm pkgshare/"build.log" if (pkgshare/"build.log").exist?
  end

  test do
    system bin/"codes_info"
  end
end
