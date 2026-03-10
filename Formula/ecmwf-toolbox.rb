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
