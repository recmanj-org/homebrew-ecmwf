class EcmwfToolbox < Formula
  desc "ECMWF software bundle: ecCodes, Magics, Metview, Atlas, and more"
  homepage "https://github.com/recmanj/ecmwf-toolbox"
  url "https://github.com/recmanj/ecmwf-toolbox/archive/refs/tags/2026.01.0.0.tar.gz",
      headers: ["Authorization: token #{ENV.fetch("HOMEBREW_ECMWF_TOOLBOX_TOKEN", ENV["ECMWF_TOOLBOX_TOKEN"])}"]
  sha256 "0019dfc4b32d63c1392aa264aed2253c1e0c2fb09216f8e2cc269bbfb8bb49b5"
  license "Apache-2.0"

  livecheck do
    url "https://github.com/recmanj/ecmwf-toolbox/tags"
    regex(/^v?(\d(?:\.\d+)+)$/i)
  end

  depends_on "cmake" => :build
  depends_on "ecbundle" => :build
  depends_on "gcc" # for Fortran (eccodes, odc, metview enable Fortran)

  def install
    # Map BITBUCKET projects to their Bitbucket Server paths
    bitbucket_projects = {
      "ECKIT"       => "ecsdk/eckit",
      "ODC"         => "odb/odc",
      "METKIT"      => "ecsdk/metkit",
      "ODB"         => "odb/odb",
      "ODB_TOOLS"   => "odb/odb-tools",
      "MAGICS"      => "mag/magics",
      "FDB5"        => "mars/fdb5",
      "MARS_CLIENT" => "mars/mars-client",
      "METVIEW"     => "metv/metview",
    }

    # If ECMWF_BITBUCKET_TOKEN is set, construct HTTPS URLs for all BITBUCKET projects
    token = ENV["ECMWF_BITBUCKET_TOKEN"]
    if token
      bitbucket_projects.each do |name, bb_path|
        ENV["ECMWF_TOOLBOX_#{name}_GIT"] = "https://#{token}@git.ecmwf.int/scm/#{bb_path}.git"
      end
    end

    # Skip packages without public mirrors by default (user can unset to include them)
    %w[ODB ODB_TOOLS FDB5].each do |name|
      ENV["ECMWF_TOOLBOX_SKIP_#{name}"] = "1" unless ENV["ECMWF_TOOLBOX_SKIP_#{name}"]
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
