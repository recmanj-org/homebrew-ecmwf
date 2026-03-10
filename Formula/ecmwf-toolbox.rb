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
  depends_on "gcc" # for Fortran (eccodes, odc, metview enable Fortran)

  def install
    # Projects on ECMWF Bitbucket that have public GitHub mirrors
    github_mirrors = {
      "ECKIT"       => "ecmwf/eckit",
      "ODC"         => "ecmwf/odc",
      "METKIT"      => "ecmwf/metkit",
      "MAGICS"      => "ecmwf/magics",
      "MARS_CLIENT" => "ecmwf/mars-client",
      "METVIEW"     => "ecmwf/metview",
    }

    # Projects on ECMWF Bitbucket with no public mirror (skip by default)
    private_projects = {
      "ODB"       => "odb/odb",
      "ODB_TOOLS" => "odb/odb-tools",
      "FDB5"      => "mars/fdb5",
    }

    token = ENV["ECMWF_BITBUCKET_TOKEN"]
    if token
      # With Bitbucket token: use authenticated HTTPS for all Bitbucket projects
      bitbucket_paths = {
        "ECKIT"       => "ecsdk/eckit",
        "ODC"         => "odb/odc",
        "METKIT"      => "ecsdk/metkit",
        "MAGICS"      => "mag/magics",
        "MARS_CLIENT" => "mars/mars-client",
        "METVIEW"     => "metv/metview",
      }.merge(private_projects)

      bitbucket_paths.each do |name, bb_path|
        ENV["ECMWF_TOOLBOX_#{name}_GIT"] = "https://#{token}@git.ecmwf.int/scm/#{bb_path}.git"
      end
    else
      # Without Bitbucket token: redirect mirrored projects to GitHub HTTPS
      github_mirrors.each do |name, gh_repo|
        ENV["ECMWF_TOOLBOX_#{name}_GIT"] = "https://github.com/#{gh_repo}.git"
      end

      # Skip private projects that have no public mirror
      private_projects.each_key do |name|
        ENV["ECMWF_TOOLBOX_SKIP_#{name}"] = "1" unless ENV["ECMWF_TOOLBOX_SKIP_#{name}"]
      end
    end

    # ecbundle create: downloads all git repos + generates CMakeLists.txt
    system "ecbundle", "create", "--bundle", buildpath.to_s

    # ecbundle build: cmake configure + compile + install
    system "ecbundle", "build",
           "--src-dir", "source",
           "--install-dir", prefix.to_s,
           "--build-type", "Release"
  end

  test do
    # eccodes is a core component - verify it's installed
    assert_path_exists lib/"libeccodes.dylib"
  end
end
